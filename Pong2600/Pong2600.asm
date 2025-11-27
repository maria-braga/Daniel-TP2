	processor 6502
	include "vcs.h"
	include "macro.h"
	include "xmacro.h"
        
SpriteHeight	equ 25
SpriteHeightBig	equ 42  ; altura maior para big paddles
ColorP0		equ $48
ColorP1		equ $a8
ScoreToWin	equ $20

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Variáveis de segmento

        seg.u Variables
	org $80

Temp		.byte

; Variável de modo de jogo
GameMode	.byte	; 0 = normal, 1 = bola rápida, 2 = paddles pequenos
GameSelectDebounce .byte ; debounce para switch de game select
CurrentSpriteHeight .byte ; altura atual dos sprites
CurrentSpritePtr .word ; ponteiro para o sprite atual (low byte, high byte)
GameFieldColor .byte ; cor da linha do campo de jogo

; Posição horizontal dos jogadores -> 2 bytes
HorizPosPlayer0	.byte
HorizPosPlayer1	.byte

; Posição vertical dos jogadores -> 2 bytes
PosPlayer0	.byte
PosPlayer1	.byte

; Placar de pontuação -> 17 bytes
Score0		.byte	; BCD de pontuação do jogador 0
Score1		.byte	; BCD de pontuação do jogador 1
FontBuf		.ds 10	; vetor de 2x5 bytes do campo de jogo
ColorScoreP0	.byte
ColorScoreP1	.byte
CountScoreFrame .byte
ScoredPlayer0	.byte	; 0 pontuado jogador 0, 1 pontuado jogador 1
PlayerWin	.byte

; Coordenadas da bola e direção -> 5 bytes
BallPosX	.byte
BallPosY	.byte
BallDirection	.byte	; Byte 7 y dir - bit 6 para x dir 
BallDirCounter	.byte
BallEnable	.byte


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Segmento de código

	seg Code
        org $f000


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Start e Inicialização
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Start
	CLEAN_START
        lda #80
        sta PosPlayer0
        lda #37
        sta PosPlayer1  

        ; Inicializa posições horizontais
        lda #10
        sta HorizPosPlayer0
        lda #148
        sta HorizPosPlayer1

        lda #0
        sta BallDirection
        sta BallDirCounter
        sta ScoredPlayer0
        sta PlayerWin
        sta GameMode
        sta GameSelectDebounce
        lda #SpriteHeight
        sta CurrentSpriteHeight
        lda #<PlayerSpriteBig
        sta CurrentSpritePtr
        lda #>PlayerSpriteBig
        sta CurrentSpritePtr+1
        lda #0
        sta CountScoreFrame
        ldx #0			; Inicializa com modo 0
        lda GameFieldLineColors,x	; Inicializa a cor do campo de jogo (verde)
        sta GameFieldColor
        
        lda #%00000010
        sta BallEnable

        lda #ColorP0
        sta ColorScoreP0
        sta COLUP0
        lda #ColorP1
        sta ColorScoreP1
        sta COLUP1
        
        lda #%00010000
        sta NUSIZ0
        
        lda #50
        sta BallPosX

        lda #140
        sta BallPosY
        
        lda #%00000010
        sta ENABL
        
        lda #0
        sta AUDV0
        lda #4
        sta AUDC0
        lda #5
        sta AUDF0
        
        lda #1
        sta VDELP1
 
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Game Loop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NextFrame
        lsr SWCHB	; testa switch de Game Reset
        bcc Start	; reset?

; Confere switch de Game Select
        lda SWCHB
        and #%00000010	; testa switch de Game Select
        bne GameSelectNotPressed
        lda GameSelectDebounce
        bne GameSelectNotPressed
        ; Game Select foi pressionado
        lda #15
        sta GameSelectDebounce
        inc GameMode
        lda GameMode
        cmp #3		; 3 modos (0, 1, 2)
        bcc GameSelectDone
        lda #0
        sta GameMode
GameSelectDone
        ; Retorno visual: muda a cor do campo de acordo com o modo de jogo
        ldx GameMode
        lda GameModeColors,x
        sta COLUPF
        lda GameFieldLineColors,x
        sta GameFieldColor
        jmp GameSelectNotPressed
GameSelectNotPressed
        lda GameSelectDebounce
        beq NoDebounceDecrement
        dec GameSelectDebounce
NoDebounceDecrement

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 1 + 3 linhas of VSYNC
	VERTICAL_SYNC
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;        
; 37 linnhas de underscan
	TIMER_SETUP 37
        
        lda #0
        sta AUDV0
        lda #4
        sta AUDC0
        lda #5
        sta AUDF0
        
        lda #%0000001
	sta CTRLPF
        
        ldx GameMode
        lda GameModeColors,x
        sta COLUPF
        
        lda Score0
        ldx #0
	jsr GetBCDBitmap
	lda Score1
        ldx #5
	jsr GetBCDBitmap
        

        lda BallPosX
        ldx #4
        jsr SetHorizPos
        
        ; Define posição horizontal do jogador 0 (usando variável)
        ldx #0
        lda HorizPosPlayer0
        jsr SetHorizPos
        ; Define posição vertical do jogador 1 (usando variável)
        ldx #1
        lda HorizPosPlayer1
        jsr SetHorizPos
        
       	sta WSYNC
        sta HMOVE        
        
	TIMER_WAIT
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;        
; 192 linhas por quadro

; Primeira parte do campo de jogo


; Primeiramente, desenhamos o placar
; Colocamos o campo de jogo em modo de pontuação (bit 2) o que produz 
; duas cores difrentes para os lados esquerdo e direito do
; campo de jogo (COLUP0 e COLUP1) 

; Desenha-se todos os 4 dígitos 

        lda #%0000001
	sta CTRLPF

	lda #%11111111        
        sta PF1
        sta PF2
        
       	lda #%11001111
        sta PF0   
        sta WSYNC        
       	lda #%11101111
        sta PF0   
        sta WSYNC        

	lda #%11111111        
        sta PF0
        
        REPEAT 4
          sta WSYNC
	REPEND
      
        ldy #0		; Y conterá a coordenada Y do quadro
        sty PF0
        sty PF1
        sty PF2
        lda #%11011010	; modo de pontuação + disco de 4 pixels
        sta CTRLPF
        lda ColorScoreP0
        sta COLUP0	; define cor na esquerda
        lda ColorScoreP1
        sta COLUP1	; define cor na direita
        sta WSYNC
ScanLoop1a
	sta WSYNC
        tya
        lsr		; divide Y em 2 para linhas com dobro de altura
        tax		; -> X
        lda FontBuf+0,x
        sta PF1		; define bitmap do placar da esquerda
        SLEEP 24
        lda FontBuf+5,x
        sta PF1		; define bitmap do placar da direita
        iny
        cpy #10
        bcc ScanLoop1a

        
	TIMER_SETUP 9
     
        lda #0		; Y conterá a coordenada Y do quadro
        sta PF0
        sta PF1
        sta PF2
        
        sta WSYNC
        sta WSYNC
        
        lda #%00010001
	sta CTRLPF        
	ldx GameMode
        lda GameModeColors,x
        sta COLUPF
	lda #%11111111
        sta PF0
        sta PF1
        sta PF2
        
        lda PlayerWin
        bne Finished
        
        ; Define tamanho dos sprietes e cores baseadas no modo de jogo 
        lda GameMode
        cmp #2
        bne NormalSizeInGame
        ; Modo 2: paddles pequenos (altura aumentada e sprite diferente)
        lda #SpriteHeight
        sta CurrentSpriteHeight
        lda #<PlayerSprite
        sta CurrentSpritePtr
        lda #>PlayerSprite
        sta CurrentSpritePtr+1
        lda #%00010000	; Largura do disco
        sta NUSIZ0
        lda #%00000000
        sta NUSIZ1
        jmp SizeDoneInGame
NormalSizeInGame
        lda #SpriteHeightBig
        sta CurrentSpriteHeight
        lda #<PlayerSpriteBig
        sta CurrentSpritePtr
        lda #>PlayerSpriteBig
        sta CurrentSpritePtr+1
        lda #%00010000	; Largura do disco
        sta NUSIZ0
        lda #%00000000
        sta NUSIZ1
SizeDoneInGame
        
        lda #ColorP0
        sta COLUP0	; define cor da esquerda
        lda #ColorP1
        sta COLUP1	; define cor da direita
        
Finished

        TIMER_WAIT
        

; Seção campo do jogo
        ldx #160-4

        lda GameFieldColor
        sta COLUPF
        
        lda #0
        sta PF1
	lda #%00010000        
        sta PF0        
        lda #%10000000
        sta PF2
        sta WSYNC
Loop

; Desenhar disco 
	STA WSYNC
        
	txa		; X -> A
        ldy #%00000000
        sec		; define carry para subtrair
        sbc BallPosY	; coordenada local
        cmp #2 
        bcs SetBall	
        ldy BallEnable	; lookup frame data
SetBall
        sty ENABL	; armazena bitmap

; Desenha sprites

	; Sprite 1
	txa		; X -> A
        sec		; define carry para subtrair
        sbc PosPlayer1	; coordenada local
        cmp CurrentSpriteHeight ; usa altura dinâmica
        bcc InSprite1	
        lda #0		; não está no sprite, carrega 0
InSprite1
	tay		; coordenada local -> Y
        lda (CurrentSpritePtr),y	; lookup frame data usando ponteiro
        sta GRP1	; armazena bitmap

	; Sprite 0
	txa		; X -> A
        sec		; define carry para subtrair
        sbc PosPlayer0	; coordenada local
        cmp CurrentSpriteHeight ; usa altura dinâmica
        bcc InSprite0	
        lda #0		; não está no sprite, carrega 0
InSprite0
	tay		; coordenada local -> Y
        lda (CurrentSpritePtr),y	; lookup frame data usando ponteiro
        sta GRP0	; armazena bitmap

	dex
        bne Loop


; Parte inferior do campo de jogo
	ldx GameMode
        lda GameModeColors,x
        sta COLUPF
        
       	lda #%11111111
        sta PF1
        sta PF0        
        sta PF2

	REPEAT 5
          sta WSYNC
        REPEND
        
       	lda #%11101111
        sta PF0   
        sta WSYNC
       	lda #%11001111
        sta PF0   
        sta WSYNC
        

; Limpar campo de jogo
	lda #0
        sta PF0
        sta PF1
        sta PF2  
        
        sta WSYNC
        sta WSYNC
        
        
; 29 linhas de overscan
	TIMER_SETUP 29
        

; Conferindo colisões entre bola e limites da direita e esquerda
; Atualizando a posição da bola e placar se preciso

	sed
	lda BallPosX
        cmp #$9B	; Confere se >= 155
        bcc NoHitRightWall
        ; parede da direita com gol
        lda BallPosY
        cmp #60
        bcc BounceRightWall
        cmp #120 
        bcs BounceRightWall
        lda #0
        sta ScoredPlayer0
        lda Score0
        cmp #ScoreToWin
        bne NotWonYet0
        lda #1
        sta PlayerWin
        lda #160
        jmp SetWin0
NotWonYet0        
        lda #20
SetWin0 
        sta CountScoreFrame
        lda #100
        sta BallPosX
        lda BallDirection
        eor #%01000000
        sta BallDirection
        ; Som quando pontua
        lda #12
        sta AUDV0
        lda #8
        sta AUDC0
        lda #10
        sta AUDF0
        clc
        lda Score0
        adc #1
        sta Score0

BounceRightWall:
        lda BallDirection
        eor #%01000000     ; reverte posição X
        sta BallDirection
        jmp NoHitRightWall ; pula pontuação

NoHitRightWall

	lda BallPosX
        cmp #10		; Confere se <= 10
        bcs NoHitLeftWall
        ;Gol da esquerda
        lda BallPosX
        cmp #10               ; <= 10 
        bcs NoHitLeftWall     
        lda BallPosY
        cmp #60
        bcc BounceLeftWall     ; parede esquerda
        cmp #120
        bcs BounceLeftWall     ; parede esquerda
        lda #1
        sta ScoredPlayer0
        lda Score1
        cmp #ScoreToWin
        bne NotWonYet1
        lda #1
        sta PlayerWin        
        lda #160
        jmp SetWin1
NotWonYet1        
        lda #20
SetWin1        
        sta CountScoreFrame
        lda #50
	sta BallPosX        
        lda BallDirection
        eor #%01000000
        sta BallDirection
        ; Som quando pontua
        lda #10
        sta AUDV0
        lda #5
        sta AUDC0
        lda #7
        sta AUDF0
        clc
        lda Score1
        adc #1
        sta Score1
BounceLeftWall:
        lda BallDirection
        eor #%01000000    ; reverte direção X
        sta BallDirection
        jmp NoHitLeftWall ; pula pontuação

NoHitLeftWall
	cld
        
; Gerencia movimento dos jogadores    

	lda CountScoreFrame
        bne NoCheckMovement

; Confere movimentos da bola        
        bit BallDirection
        bvc DecX
        
        inc BallPosX
        ; Confere modo de jogo para bola rápida (modo 2)
        lda GameMode
        cmp #1
        bne XDirection
        inc BallPosX	; Move bola 2 vezes mais rápido do que no modo 1
        jmp XDirection
DecX
	dec BallPosX
        ; Confere modo de jogo para bola rápida (modo 1)
        lda GameMode
        cmp #1
        bne XDirection
        dec BallPosX	; Move bola 2 vezes mais rápido do que no modo 1
XDirection


        bit BallDirection
        bpl DecY
	inc BallPosY
        jmp YDirection
DecY
	dec BallPosY
YDirection

        lda #%00000010
        sta BallEnable

; Movimentação do jogador 0 (vertical e horizontal)
        lda SWCHA
        and #%00010000  ; Baixo
        bne NoMovP0Down
        inc PosPlayer0
        inc PosPlayer0
NoMovP0Down
	lda SWCHA
        and #%00100000  ; Cima
        bne NoMovP0Up
        dec PosPlayer0
        dec PosPlayer0
NoMovP0Up
        lda SWCHA
        and #%01000000  ; Esquerda
        bne NoMovP0Left
        dec HorizPosPlayer0
NoMovP0Left
        lda SWCHA
        and #%10000000  ; Direita
        bne NoMovP0Right
        inc HorizPosPlayer0
NoMovP0Right

; Moivmentação do jogador 1 (vertical e horizontal)
        lda SWCHA
        and #%00000001  ; Baixo
        bne NoMovP1Down
        inc PosPlayer1
        inc PosPlayer1
NoMovP1Down
	lda SWCHA
        and #%00000010  ; Cima
        bne NoMovP1Up
        dec PosPlayer1
        dec PosPlayer1
NoMovP1Up
        lda SWCHA
        and #%00000100  ; Esquerda
        bne NoMovP1Left
        dec HorizPosPlayer1
NoMovP1Left
        lda SWCHA
        and #%00001000  ; Direita
        bne NoMovP1Right
        inc HorizPosPlayer1
NoMovP1Right
	jmp CheckMovement

NoCheckMovement
	lda #%00000000
        sta BallEnable
CheckMovement

; Verifica se os jogadores não saíram dos limites verticais
	lda PosPlayer1
        cmp #2
        bpl P1VertOK1
  	lda #2
        sta PosPlayer1
P1VertOK1
	lda PosPlayer0
        cmp #2
        bpl P0VertOK1
  	lda #2
        sta PosPlayer0
P0VertOK1
        ; Calcula posição máxima com base na altura do sprite
        ; Posição máxima = 160 - 4 (campo de jogo) -> CurrentSpriteHeight
        lda #160-4
        sec
        sbc CurrentSpriteHeight
        sta Temp	; Armazena posição máxima no Temp
        
        lda PosPlayer1
        cmp Temp
        bmi P1VertOK2
        lda Temp
        sta PosPlayer1         
P1VertOK2
      	lda PosPlayer0
        cmp Temp
        bmi P0VertOK2
        lda Temp
        sta PosPlayer0 
P0VertOK2

; Verifica se os jogadores não saíram dos limites horizontais
; Jogador 0 (esquerda): mínimo 10, máximo 75 (meio)
	lda HorizPosPlayer0
        cmp #10
        bpl P0HorizOK1
        lda #10
        sta HorizPosPlayer0
P0HorizOK1
	lda HorizPosPlayer0
        cmp #75
        bmi P0HorizOK2
        lda #75
        sta HorizPosPlayer0
P0HorizOK2

; Jogador 1 (direita): mínimo 85, máximo 148 (meio) 
	lda HorizPosPlayer1
        cmp #85
        bpl P1HorizOK1
        lda #85
        sta HorizPosPlayer1
P1HorizOK1
	lda HorizPosPlayer1
        cmp #148
        bmi P1HorizOK2
        lda #148
        sta HorizPosPlayer1
P1HorizOK2

; Confere colisões entre bola e jogadores 

	lda BallDirCounter
        bne DoNotCheckPlayerHitBall

	bit CXP0FB
        bvc NoHitPlayer0
        lda #10
        sta BallDirCounter        
        lda BallDirection
        eor #%01000000
        sta BallDirection
        lda #10
        sta AUDV0
NoHitPlayer0
    
	bit CXP1FB
        bvc NoHitPlayer1
        lda #10
        sta BallDirCounter        
        lda BallDirection
        eor #%01000000
        sta BallDirection
        lda #6
        sta AUDV0
NoHitPlayer1
	jmp NoBallCounterDec

DoNotCheckPlayerHitBall
	dec BallDirCounter
NoBallCounterDec

  ; Reseta status de colisão
        sta CXCLR


; Confere colisões entre bola e teto/chão

	lda BallPosY
        cmp #154
        bne NoHitTopWall
        lda BallDirection
        eor #%10000000
        sta BallDirection
        lda #6
        sta AUDV0
NoHitTopWall

	lda BallPosY
        cmp #2
        bne NoHitBottomWall
        lda BallDirection
        eor #%10000000
        sta BallDirection
        lda #6
        sta AUDV0
NoHitBottomWall

        lda CountScoreFrame
        beq NoActionScore
        dec CountScoreFrame
        bne NoCheckWin
        lda PlayerWin
        beq NoCheckWin
        jmp Start
NoCheckWin        
        ldy ScoredPlayer0        
        jmp SetScoreColor

NoActionScore
	lda #$48
        sta ColorScoreP0
        lda #$a8
        sta ColorScoreP1
        jmp ScoreCheckCompleted
SetScoreColor
	sta ColorScoreP0,y
ScoreCheckCompleted        

        TIMER_WAIT
        
; total = 262 linhas -> ir para próximo quadro
        jmp NextFrame


; Busca dado do bitmap para 2 dígitos
; de um número BCD-codificado, armazenando em seus endereços 
; FontBuf+x para FontBuf+4+x 
GetBCDBitmap subroutine
; Primeiro, busca os bytes do primeiro dígito 
	pha		; salva número BCD original
        and #$0F	; mascara o bit menos significante
        sta Temp
        asl
        asl
        adc Temp	; multiplica por 5
        tay		; -> Y
        lda #5
        sta Temp	; contagem regressiva a partir do 5
.loop1
        lda DigitsBitmap,y
        and #$0F	; mascara digito mais a esquerda
        sta FontBuf,x	; armazena digito mais a esquerda
        iny
        inx
        dec Temp
        bne .loop1
; Segundo dígito
        pla		; restaura número BCD original
        lsr
        lsr
        lsr
        lsr		; desloca para direita 4 (divide por 10 em BCD)
        sta Temp
        asl
        asl
        adc Temp	; multiplica por 5
        tay		; -> Y
        dex
        dex
        dex
        dex
        dex		; subtrai 5 de X (reset para o original)
        lda #5
        sta Temp	; contagem regressiva a partir do  5
.loop2
        lda DigitsBitmap,y
        and #$F0	; mascara dígito mais a esquerda
        ora FontBuf,x	; combina dígitos da esquerda e direita
        sta FontBuf,x	; armazena dígitos combinados
        iny
        inx
        dec Temp
        bne .loop2
	rts

	org $F700

; Cores de modo de jogo para retorno visual
GameModeColors
        .byte $C2	; Modo 0: Normal - verde
        .byte $46	; Modo 1: Bola rápida - vermelho  
        .byte $63	; Modo 2: Paddles pequenos - roxo

; Core do campo de jogo para cada modo
GameFieldLineColors
        .byte $0D       ; Modo 0: Normal - branco
        .byte $28	; Mode 1: Bola rápida - laranja
        .byte $EA	; Mode 2: Paddles pequenos - verde

; Padrão do bitmap para dígitos
DigitsBitmap ;;{w:8,h:5,count:10,brev:1};;
        .byte $EE,$AA,$AA,$AA,$EE
        .byte $22,$22,$22,$22,$22
        .byte $EE,$22,$EE,$88,$EE
        .byte $EE,$22,$66,$22,$EE
        .byte $AA,$AA,$EE,$22,$22
        .byte $EE,$88,$EE,$22,$EE
        .byte $EE,$88,$EE,$AA,$EE
        .byte $EE,$22,$22,$22,$22
        .byte $EE,$AA,$EE,$AA,$EE
        .byte $EE,$AA,$EE,$22,$EE
        
;---Graphics Data from PlayerPal 2600---

; Dados gráficos do jogador - MODO Small (30 linhas)
PlayerSprite
        .byte #%00000000;-- linha 0
        .byte #%00011000;-- linha 1
        .byte #%00111100;-- linha 2
        .byte #%00111100;-- linha 3
        .byte #%01111110;-- linha 4
        .byte #%01111110;-- linha 5
        .byte #%01111110;-- linha 6
        .byte #%01111110;-- linha 7
        .byte #%01111110;-- linha 8
        .byte #%01111110;-- linha 9
        .byte #%01111110;-- linha 10
        .byte #%01111110;-- linha 11
        .byte #%01111110;-- linha 12
        .byte #%01111110;-- linha 13
        .byte #%01111110;-- linha 14
        .byte #%01111110;-- linha 20
        .byte #%01111110;-- linha 21
        .byte #%01111110;-- linha 22
        .byte #%01111110;-- linha 23
        .byte #%01111110;-- linha 24
        .byte #%01111110;-- linha 25
        .byte #%01111110;-- linha 26
        .byte #%00111100;-- linha 27
        .byte #%00111100;-- linha 28
        .byte #%00011000;-- linha 29

; Dados gráficos do jogador - MODO Normal PADDLES (42 linhas - sem afunilamento)
PlayerSpriteBig
        .byte #%00000000;-- linha 0
        .byte #%00011000;-- linha 1
        .byte #%00111100;-- linha 2
        .byte #%00111100;-- linha 3
        .byte #%01111110;-- linha 4
        .byte #%01111110;-- linha 5
        .byte #%01111110;-- linha 6
        .byte #%01111110;-- linha 7
        .byte #%01111110;-- linha 8
        .byte #%01111110;-- linha 9
        .byte #%01111110;-- linha 10
        .byte #%01111110;-- linha 11
        .byte #%01111110;-- linha 12
        .byte #%01111110;-- linha 13
        .byte #%01111110;-- linha 14
        .byte #%01111110;-- linha 15
        .byte #%01111110;-- linha 16
        .byte #%01111110;-- linha 17
        .byte #%01111110;-- linha 18
        .byte #%01111110;-- linha 19
        .byte #%01111110;-- linha 20
        .byte #%01111110;-- linha 21
        .byte #%01111110;-- linha 22
        .byte #%01111110;-- linha 23
        .byte #%01111110;-- linha 24
        .byte #%01111110;-- linha 25
        .byte #%01111110;-- linha 26
        .byte #%01111110;-- linha 27
        .byte #%01111110;-- linha 28
        .byte #%01111110;-- linha 29
        .byte #%01111110;-- linha 30
        .byte #%01111110;-- linha 31
        .byte #%01111110;-- linha 32
        .byte #%01111110;-- linha 33
        .byte #%01111110;-- linha 34
        .byte #%01111110;-- linha 35
        .byte #%01111110;-- linha 36
        .byte #%01111110;-- linha 37
        .byte #%01111110;-- linha 38
        .byte #%00111100;-- linha 39
        .byte #%00111100;-- linha 40
        .byte #%00011000;-- linha 41
        
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SetHorizPos routine
; A = X coordinate
; X = player number (0 or 1)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Depois dessa subrotina é necessário usar
;
; 	sta WSYNC
; 	sta HMOVE
;
; para definir os parâmetros corretamente
; então melhor definir (depois de esperar 26 ciclos de CPU)
;
; 	sta HMCLR
;
; então, o próximo sta HMOVE não impactará a posição

; Tudo deve estar na mesma página 
; do contrário, o timing vai falhar

; Toda a rotina é posicionada na memória ao final para
; garantir que a branch não está se movendo para página errada
; tamanho total da rotina -> 18 bytes

SetHorizPos SUBROUTINE
	sec		; define flag do carry
	sta WSYNC	; começa nova linha
.DivideLoop
	sbc #15		; subtrai 15
	bcs .DivideLoop	; branch até ser negativo
	eor #7		; calcula deslocamento ok
        asl
        asl
        asl
        asl
	sta HMP0,x	; define offset ok
	sta RESP0,x	; corrige posição
	rts		; retorna para o caller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Epílogo
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	org $f7fc
        .word Start	; reseta vectora
        .word Start	; BRK vectordaw
