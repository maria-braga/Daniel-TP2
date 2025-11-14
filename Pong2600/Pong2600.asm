
	processor 6502
        include "vcs.h"
        include "macro.h"
        include "xmacro.h"
        
SpriteHeight	equ 33
ColorP0		equ $48
ColorP1		equ $a8
ScoreToWin	equ $20

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Variables segment

        seg.u Variables
	org $80

Temp		.byte

; Vertical position players 2 bytes
PosPlayer0	.byte
PosPlayer1	.byte

; For scoreboard 17 bytes
Score0		.byte	; BCD score of player 0
Score1		.byte	; BCD score of player 1
FontBuf		.ds 10	; 2x5 array of playfield bytes
ColorScoreP0	.byte
ColorScoreP1	.byte
CountScoreFrame .byte
ScoredPlayer0	.byte	; 0 scored player 0, 1 scored player 1
PlayerWin	.byte

; Ball coordinates and direction 5 bytes
BallPosX	.byte
BallPosY	.byte
BallDirection	.byte	; Byte 7 y dir - bit 6 for x dir 
BallDirCounter	.byte
BallEnable	.byte


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Code segment

	seg Code
        org $f000


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Start and Initialization
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Start
	CLEAN_START
        lda #80
        sta PosPlayer0
        lda #37
        sta PosPlayer1  

        lda #0
        sta BallDirection
        sta BallDirCounter
        sta ScoredPlayer0
        sta PlayerWin
        lda #0
        sta CountScoreFrame
        
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
        lsr SWCHB	; test Game Reset switch
        bcc Start	; reset?

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 1 + 3 lines of VSYNC
	VERTICAL_SYNC
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;        
; 37 lines of underscan
	TIMER_SETUP 37
        
        lda #0
        sta AUDV0
        
        lda #%0000001
	sta CTRLPF
        
        lda #$C2
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
        
        ; Set horizontal position player 1
        ldx #0
        lda #10
        jsr SetHorizPos
        ; Set horizontal position player 2
        ldx #1
        lda #148
        jsr SetHorizPos
        
       	sta WSYNC
        sta HMOVE        
        
	TIMER_WAIT
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;        
; 192 lines of frame

; First part playfield


; First, we'll draw the scoreboard.
; Put the playfield into score mode (bit 2) which gives
; two different colors for the left/right side of
; the playfield (given by COLUP0 and COLUP1).

; Now we draw all four digits.

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
      
        ldy #0		; Y will contain the frame Y coordinate
        sty PF0
        sty PF1
        sty PF2
        lda #%00010010	; score mode + 2 pixel ball
        sta CTRLPF
        lda ColorScoreP0
        sta COLUP0	; set color for left
        lda ColorScoreP1
        sta COLUP1	; set color for right        
        sta WSYNC
ScanLoop1a
	sta WSYNC
        tya
        lsr		; divide Y by two for double-height lines
        tax		; -> X
        lda FontBuf+0,x
        sta PF1		; set left score bitmap
        SLEEP 24
        lda FontBuf+5,x
        sta PF1		; set right score bitmap
        iny
        cpy #10
        bcc ScanLoop1a

        
	TIMER_SETUP 9
     
        lda #0		; Y will contain the frame Y coordinate
        sta PF0
        sta PF1
        sta PF2
        
        sta WSYNC
        sta WSYNC
        
        lda #%00010001
	sta CTRLPF        
	lda #$C2
        sta COLUPF
	lda #%11111111
        sta PF0
        sta PF1
        sta PF2
        
        lda PlayerWin
        bne Finished
        
        lda #ColorP0
        sta COLUP0	; set color for left
        lda #ColorP1
        sta COLUP1	; set color for right
        
Finished

        TIMER_WAIT
        

; Section game field
        ldx #160-4

        lda #$0E
        sta COLUPF
        
        lda #0
        sta PF1
	lda #%00010000        
        sta PF0        
        lda #%10000000
        sta PF2
        sta WSYNC
Loop

; Draw ball
	STA WSYNC
        
	txa		; X -> A
        ldy #%00000000
        sec		; set carry for subtract
        sbc BallPosY	; local coordinate
        cmp #4 ; in sprite?
        bcs SetBall	; yes, skip over next
        ldy BallEnable	; lookup frame data
SetBall
        sty ENABL	; store bitmap

; Draw Sprites

	; Sprite 1
	txa		; X -> A
        sec		; set carry for subtract
        sbc PosPlayer1	; local coordinate
        cmp #SpriteHeight ; in sprite?
        bcc InSprite1	; yes, skip over next
        lda #0		; not in sprite, load 0
InSprite1
	tay		; local coord -> Y
        lda PlayerSprite,y	; lookup frame data
        sta GRP1	; store bitmap

	; Sprite 0
	txa		; X -> A
        sec		; set carry for subtract
        sbc PosPlayer0	; local coordinate
        cmp #SpriteHeight ; in sprite?
        bcc InSprite0	; yes, skip over next
        lda #0		; not in sprite, load 0
InSprite0
	tay		; local coord -> Y
        lda PlayerSprite,y	; lookup frame data
        sta GRP0	; store bitmap

	dex
        bne Loop


; Lower part of the playfield
	lda #$C2
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
        

; Clear playfield
	lda #0
        sta PF0
        sta PF1
        sta PF2  
        
        sta WSYNC
        sta WSYNC
        
        
; 29 lines of overscan
	TIMER_SETUP 29
        

; Checking collisions between ball and left/right limit
; Also updating ball positiona and score if necessary

	sed
	lda BallPosX
        cmp #$9D
        bne NoHitRightWall
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
        clc
        lda Score0
        adc #1
        sta Score0
NoHitRightWall

	lda BallPosX
        cmp #8
        bne NoHitLeftWall
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
        clc
        lda Score1
        adc #1
        sta Score1
NoHitLeftWall
	cld
        
; Handles players movement    

	lda CountScoreFrame
        bne NoCheckMovement

; Checks ball movements        
        bit BallDirection
        bvc DecX
        
        inc BallPosX
        jmp XDirection
DecX
	dec BallPosX
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

        lda SWCHA
        and #%00010000
        bne NoMov
        inc PosPlayer0
        inc PosPlayer0
NoMov
	lda SWCHA
        and #%00100000
        bne NoMov2
        dec PosPlayer0
        dec PosPlayer0
NoMov2

        lda SWCHA
        and #%00000001
        bne NoMov3
        inc PosPlayer1
        inc PosPlayer1
   
NoMov3

	lda SWCHA
        and #%00000010
        bne NoMov4
        dec PosPlayer1
        dec PosPlayer1
NoMov4
	jmp CheckMovement

NoCheckMovement
	lda #%00000000
        sta BallEnable
CheckMovement

; Verifies that players do not move outside the limits
	lda PosPlayer1
        cmp #2
        bpl OK
  	lda #2
        sta PosPlayer1
OK

	lda PosPlayer0
        cmp #2
        bpl OK2
  	lda #2
        sta PosPlayer0
OK2
      
      
      	lda PosPlayer1
        cmp #$7C
        bmi OK3
        lda #$7B
        sta PosPlayer1         
OK3

      	lda PosPlayer0
        cmp #$7C
        bmi OK4
        lda #$7b
        sta PosPlayer0 
OK4

; Checking collisions between ball and players

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

	; Reset collition status
        sta CXCLR


; Checking collisions between ball and top/bottom wall

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
        
; total = 262 lines, go to next frame
        jmp NextFrame


; Fetches bitmap data for two digits of a
; BCD-encoded number, storing it in addresses
; FontBuf+x to FontBuf+4+x.
GetBCDBitmap subroutine
; First fetch the bytes for the 1st digit
	pha		; save original BCD number
        and #$0F	; mask out the least significant digit
        sta Temp
        asl
        asl
        adc Temp	; multiply by 5
        tay		; -> Y
        lda #5
        sta Temp	; count down from 5
.loop1
        lda DigitsBitmap,y
        and #$0F	; mask out leftmost digit
        sta FontBuf,x	; store leftmost digit
        iny
        inx
        dec Temp
        bne .loop1
; Now do the 2nd digit
        pla		; restore original BCD number
        lsr
        lsr
        lsr
        lsr		; shift right by 4 (in BCD, divide by 10)
        sta Temp
        asl
        asl
        adc Temp	; multiply by 5
        tay		; -> Y
        dex
        dex
        dex
        dex
        dex		; subtract 5 from X (reset to original)
        lda #5
        sta Temp	; count down from 5
.loop2
        lda DigitsBitmap,y
        and #$F0	; mask out leftmost digit
        ora FontBuf,x	; combine left and right digits
        sta FontBuf,x	; store combined digits
        iny
        inx
        dec Temp
        bne .loop2
	rts

	org $F700

; Bitmap pattern for digits
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

; Player graphics data
PlayerSprite
        .byte #%00000000;--
        .byte #%00011000;--
        .byte #%00111100;--
        .byte #%00111100;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--   
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--      
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%01111110;--
        .byte #%00111100;--
        .byte #%00111100;--
        .byte #%00011000;--
        
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SetHorizPos routine
; A = X coordinate
; X = player number (0 or 1)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; After this subroutine it is necessary to use
;
; 	sta WSYNC
; 	sta HMOVE
;
; to correctly set the parameters
; Then better to set (after waitin 26 cpu cycles)
;
; 	sta HMCLR
;
; so next sta HMOVE will not impact the position

; Everything should be in the same page
; otherwise the timing is not correct

; The entire routine is positioned in memory at the end just to
; assure that the branch is not moving to a different page
; Total size of the routine 18 bytes.

SetHorizPos SUBROUTINE
	sec		; set carry flag
	sta WSYNC	; start a new line
.DivideLoop
	sbc #15		; subtract 15
	bcs .DivideLoop	; branch until negative
	eor #7		; calculate fine offset
        asl
        asl
        asl
        asl
	sta HMP0,x	; set fine offset
	sta RESP0,x	; fix coarse position
	rts		; return to caller        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Epilogue
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	org $f7fc
        .word Start	; reset vector
        .word Start	; BRK vector
