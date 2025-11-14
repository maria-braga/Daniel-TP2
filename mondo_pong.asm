; Table Top Tennis Simulator 2012 - Com Movimento Horizontal

	processor 6502
	include vcs.h
	org $F000

;Constants
BGColor = $48
PFColor = $34
P0Color = $C6 ; Green
P1Color = $94 ; Blue
BallColor = $0E ; White
PF0Sprite = %00110000
PaddleOnSprite = %00011000
PaddleOffSprite = %00000000
BallOn = %00000010
BallOff = %00000000
PaddleHeight = 16
BallHeight = 2
MaxPaddleY = 186-PaddleHeight
MinPaddleY = 14
P1Goal = $33
P0Goal = $C2
BallStartX = $7A
BallStartY = 96
BallBaseTone = %00000001
BallXSpeedCap = 2
BallYSpeedCap = 3
BallYExVelMax = BallYSpeedCap+1
BallYExVelMin = 255-BallYSpeedCap
BallVolleyIncrement = 2
AITickRate = 2
ScoreLimit = 11
StartingWaitTime = 255
EndWaitTime = 80

;Variables
YPosP0 = $80
YPosP1 = $81
YPosBall = $82
ScoreP0 = $83
ScoreP1 = $84
P0Sprite = $85
P1Sprite = $86
BallEnabled = $87
YVelBall = $88
XVelBall = $89
XPosBall = $8A
P0Delta = $8B
P1Delta = $8C
VolleyCount = $8D
ScoreP0MemLoc = $8E
ScoreP1MemLoc = $8F
AITicks = $90
VictoryTime = $91
WaitTime = $92
NewXVelBall = $93
P0HorizMove = $94  ; Nova variável para movimento horizontal P0
P1HorizMove = $95  ; Nova variável para movimento horizontal P1

Start
	SEI
	CLD
	LDX #$FF
	TXS
	LDA #0
ClearMem
	STA 0,X
	DEX
	BNE ClearMem
Initialize
	LDA #BGColor
	STA COLUBK
	LDA #PFColor
	STA COLUPF
	LDA #P0Color
	STA COLUP0
	LDA #P1Color
	STA COLUP1
	LDA %00001111
	STA AUDV0
	STA AUDV1
	LDA %00000110
	STA AUDF1
PositionPaddles
	STA WSYNC
	NOP
	NOP
	NOP
	BIT ScoreP0
	NOP
	NOP
	NOP
	NOP
	NOP 
	NOP
	STA RESP0
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	BIT ScoreP0
	STA RESBL
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP 
	STA RESP1
	LDA #%01110000
	STA HMP1
	STA WSYNC
	STA HMOVE
	LDA #%00010000
	STA HMP1
	STA WSYNC
	STA HMOVE
	STA HMCLR
	LDA #96
	STA YPosP0
	STA YPosP1
	STA YPosBall
	JSR ResetBall
	LDA #0
	STA XVelBall
	STA YVelBall
	STA P0HorizMove
	STA P1HorizMove
	LDA #StartingWaitTime
	STA WaitTime
	STA WSYNC
	STA WSYNC

EndInitialize
MainLoop
Synching
	LDA #%00000010
	STA VSYNC
	STA WSYNC
	STA WSYNC
	STA WSYNC
	LDA  #43
	STA  TIM64T
	LDA #0
	STA VSYNC
FinishSynch
BeginInput
	LDA #0
	STA AUDC0
	STA P0Delta
	STA P1Delta
	STA P0HorizMove
	STA P1HorizMove
	LDA VictoryTime
	BNE EndInput
P0Up
	LDA #%00010000
	BIT SWCHA
	BNE P0Down
	INC YPosP0
	INC YPosP0
	LDA #1
	STA P0Delta
P0Down
	LDA #%00100000
	BIT SWCHA
	BNE P0Left
	DEC YPosP0
	DEC YPosP0
	LDA #-1
	STA P0Delta
P0Left
	LDA #%01000000
	BIT SWCHA
	BNE P0Right
	LDA #%11110000  ; Move left
	STA P0HorizMove
P0Right
	LDA #%10000000
	BIT SWCHA
	BNE P1Up
	LDA #%00010000  ; Move right
	STA P0HorizMove
P1Up
	LDA #%00000001
	BIT SWCHA
	BNE P1Down
	INC YPosP1
	INC YPosP1
	LDA #1
	STA P1Delta
P1Down
	LDA #%00000010
	BIT SWCHA
	BNE P1Left
	DEC YPosP1
	DEC YPosP1
	LDA #-1
	STA P1Delta
P1Left
	LDA #%00000100
	BIT SWCHA
	BNE P1Right
	LDA #%11110000  ; Move left
	STA P1HorizMove
P1Right
	LDA #%00001000
	BIT SWCHA
	BNE ApplyHorizontalMovement
	LDA #%00010000  ; Move right
	STA P1HorizMove
ApplyHorizontalMovement
	; Apply P0 horizontal movement
	LDA P0HorizMove
	BEQ SkipP0Horiz
	STA HMP0
	STA WSYNC
	STA HMOVE
SkipP0Horiz
	; Apply P1 horizontal movement
	LDA P1HorizMove
	BEQ EndInput
	STA HMP1
	STA WSYNC
	STA HMOVE
EndInput
BeginCollision
P0Playfield
	LDA #%10000000
	BIT CXP0FB
	BEQ P1Playfield
	PHA
	LDA YPosP0
	PHA
	JSR CapToMinMax
	PLA
	PLA
	STA YPosP0
P1Playfield
	LDA #%10000000
	BIT CXP1FB
	BEQ PlayerBallCheck
	PHA
	LDA YPosP1
	PHA
	JSR CapToMinMax
	PLA
	PLA
	STA YPosP1
PlayerBallCheck
	LDA WaitTime
	BEQ SkipWaitCheck
	DEC WaitTime
	LDA WaitTime
	CMP #EndWaitTime
	BNE SkipBallPhysics
	JMP ClearWait
SkipBallPhysics
	JMP EndCollision
ClearWait
	LDA #0
	STA WaitTime
	JSR ResetBall
SkipWaitCheck
	LDA P0Delta
	PHA
	LDA #%01000000
	BIT CXP0FB
	BNE PlayerBallConfirmed
	PLA
	LDA P1Delta
	PHA
	LDA #%01000000
	BIT CXP1FB
	BNE PlayerBallConfirmed
	PLA
	JMP BallPlayfield
PlayerBallConfirmed
	INC VolleyCount
	LDA VolleyCount
	CMP #BallVolleyIncrement
	BNE BallVelChanges
BallVelChanges
	LDA XVelBall
	CLC
	EOR #$FF
	ADC #1
	STA XVelBall
	PLA
	CLC
	ADC YVelBall
	CMP #BallYExVelMax
	BEQ CapBallToUpper
	CMP #BallYExVelMin
	BEQ CapBallToLower

	CMP #0
	JMP BallZeroYCheck
CapBallToUpper
	LDA #BallYExVelMax-1
	STA YVelBall
	JMP PRSound
CapBallToLower
	LDA #BallYExVelMin+1
	STA YVelBall
	JMP PRSound
BallZeroYCheck
	BNE PRSound
	LDA #1
	JMP PRSound
PRSound
	STA YVelBall
	LDA #BallBaseTone
	STA AUDC0
BallPlayfield
	LDA #%10000000
	BIT CXBLPF
	BEQ EndCollision
TestBallP0
	LDA XPosBall
	CMP #P0Goal
	BCC TestBallP1
	LDA #1
	PHA
	JSR OnScore
	PLA
	JMP EndCollision
TestBallP1
	CMP #P1Goal
	BCS BallRicochet
	LDA #-1
	PHA
	JSR OnScore
	PLA
	JMP EndCollision
BallRicochet
	LDA YVelBall
	CLC
	EOR #$FF
	ADC #1
	STA YVelBall
	LDA #BallBaseTone
	STA AUDC0
EndCollision
	STA CXCLR
	LDA YPosBall
	CLC
	ADC YVelBall
	STA YPosBall
	LDA XVelBall
	STA HMBL
	STA WSYNC
	STA HMOVE
	CMP #$80
	ROR
	CMP #$80
	ROR
	CMP #$80
	ROR
	CMP #$80
	ROR
	ADC XPosBall
	STA XPosBall
	LDA #$00
	STA COLUBK
	LDA %00000001
	STA CTRLPF
	LDX #0
	LDA ScoreP0
	ASL
	ASL
	ASL
	STA ScoreP0MemLoc
	LDA ScoreP1
	ASL
	ASL
	ASL
	STA ScoreP1MemLoc
	LDA YPosBall
ScoreCheck
	LDA VictoryTime
	BNE StillWinning
	LDA ScoreP0
	CMP #ScoreLimit
	BEQ P0Won
	LDA ScoreP1
	CMP #ScoreLimit
	BEQ P1Won
	JMP AICheck
P0Won
	INC ScoreP0
	LDA #255
	STA VictoryTime
	JMP StillWinning
P1Won
	INC ScoreP1
	LDA #255
	STA VictoryTime
	JMP StillWinning
StillWinning
	JSR OnWin
	LDA VictoryTime
	BNE WaitForVBlankEnd
	LDA #0
	STA AUDC1
	JMP Start
AICheck
	LDA AITicks
	CMP #AITickRate
	BEQ AIStart
	JMP AIEnd
AIStart
	LDA #0
	STA AITicks
	LDA YPosP1
	CMP YPosBall
	BEQ AIEnd
	BCS AIDown
	INC YPosP1
	INC YPosP1
	JMP AIEnd
AIDown
	DEC YPosP1
	DEC YPosP1
AIEnd
	INC AITicks
WaitForVBlankEnd
	LDA INTIM
	BNE WaitForVBlankEnd
	STA WSYNC
	STA VBLANK
	LDY #192
ScanLoop
	STA WSYNC
ProcessingLine
	TYA
	SEC
	SBC YPosP0
	BMI DisableP0
	CMP #PaddleHeight
	BCS DisableP0
	LDA #PaddleOnSprite
	STA P0Sprite
	JMP P1Check
DisableP0
	LDA #PaddleOffSprite
	STA P0Sprite
P1Check
	TYA
	SEC
	SBC YPosP1
	BMI DisableP1
	CMP #PaddleHeight
	BCS DisableP1
	LDA #PaddleOnSprite
	STA P1Sprite
	JMP BallCheck
DisableP1
	LDA #PaddleOffSprite
	STA P1Sprite
BallCheck
	LDA VictoryTime
	BNE DisableBall
	TYA
	SEC
	SBC YPosBall
	BMI DisableBall
	CMP #BallHeight
	BCS DisableBall
	LDA #BallOn
	STA BallEnabled
	JMP EndLineChecks
DisableBall
	LDA #BallOff
	STA BallEnabled
EndLineChecks 
EndProcessingLine
DrawLine
	DEY
	STA WSYNC
	LDA Playfield0,Y
	STA COLUPF
	STA PF0
	LDA Playfield1,Y
	STA PF1
	STA PF2
	LDA P0Sprite
	STA GRP0
	LDA BallEnabled
	STA ENABL
	LDA P1Sprite
	STA GRP1
	DEY
	CPY #10
	BNE ScanLoop
ScoreDrawLine
	LDA #0
	STA WSYNC
	LDA Playfield0,Y
	STA COLUBK
	LDA #0
	STA GRP0
	STA GRP1
	STA ENABL
	STA PF0
	STA PF2
	STA PF1
	STA WSYNC
	LDA %00000010
	STA CTRLPF
	LDX #8
ScoreLoop
	STA WSYNC
	LDA ScoreP0MemLoc
	TAY
	LDA Numbers,Y
	STA PF1
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	LDA ScoreP1MemLoc
	TAY
	LDA Numbers,Y
	STA PF1
	INC ScoreP0MemLoc
	INC ScoreP1MemLoc
	DEX
	BEQ EndScore
	JMP ScoreLoop
EndScore
	LDA #0
	STA WSYNC
	STA PF1
	STA PF0
	STA PF2
	LDA #2
	STA WSYNC
	STA VBLANK
	LDY #29
OverScanWait
	STA WSYNC
	DEY
	BNE OverScanWait
	JMP MainLoop

ToCap = $03
CapRetVal = $04
CapToMinMax
	TSX
	LDA #96
	CMP ToCap,X
	BCS CapMin
	JMP CapMax
CapMin
	LDA #MinPaddleY
	CMP ToCap,X
	BCC CapReturn
	STA ToCap,X
	JMP CapReturn
CapMax
	LDA #MaxPaddleY
	CMP ToCap,X
	BCS CapReturn
	STA ToCap,X
CapReturn
	LDA ToCap,X
	STA CapRetVal,X
	RTS

PlayerWhoScored = $03
OnScore
	TSX
	LDA PlayerWhoScored,X
	CMP #-1
	BEQ P0Scored
P1Scored
	INC ScoreP1
	JMP PostScored
P0Scored
	INC ScoreP0
PostScored
	JSR ResetBall
	LDA #0
	STA XVelBall
	STA YVelBall
	TSX
	LDA PlayerWhoScored,X
	ASL
	ASL
	ASL
	ASL
	STA XVelBall
	STA NewXVelBall
	LDA #%00001000
	STA AUDC0
	LDA #StartingWaitTime
	STA WaitTime
	LDA #0
	STA XVelBall
	STA YVelBall
	RTS

ResetBall
	LDA ScoreP0
	STA WSYNC
	NOP
	NOP
	NOP
	BIT ScoreP0
	NOP
	NOP
	NOP
	NOP
	NOP 
	NOP
	STA ScoreP0
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	BIT ScoreP0
	STA RESBL
	LDA #BallStartX
	STA XPosBall
	LDA #BallStartY
	STA YPosBall
	LDA ScoreP0
	CLC
	ADC ScoreP1
	TAY
	LDA StartingYVelTable,Y
	STA YVelBall
	LDA NewXVelBall
	BNE SkipResetXVel
	LDA #%00010000
SkipResetXVel
	STA XVelBall
	LDA #0
	STA VolleyCount
	RTS

OnWin
	LDA #%00001000
	STA AUDC1
	DEC VictoryTime
	BNE OnWinReturn
	LDA #0
	STA AUDC1
OnWinReturn
	RTS

Playfield0
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
Playfield1
Playfield2
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
Numbers
Zero
	.byte %00000111
	.byte %00000101
	.byte %00000101
	.byte %00000101
	.byte %00000101
	.byte %00000101
	.byte %00000101
	.byte %00000111
One
	.byte %00000100
	.byte %00000100
	.byte %00000111
Three
	.byte %00000111
	.byte %00000001
	.byte %00000001
	.byte %00000111
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %00000111
Four
	.byte %00000101
	.byte %00000101
	.byte %00000101
	.byte %00000111
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %00000001
Five
	.byte %00000111
	.byte %00000100
	.byte %00000100
	.byte %00000111
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %00000111
Six
	.byte %00000100
	.byte %00000100
	.byte %00000100
	.byte %00000100
	.byte %00000111
	.byte %00000101
	.byte %00000101
	.byte %00000111
Seven
	.byte %00000111
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %00000001
Eight
	.byte %00000111
	.byte %00000101
	.byte %00000101
	.byte %00000111
	.byte %00000101
	.byte %00000101
	.byte %00000101
	.byte %00000111
Nine
	.byte %00000111
	.byte %00000101
	.byte %00000101
	.byte %00000111
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %00000001
Ten
	.byte %00010111
	.byte %00010101
	.byte %00010101
	.byte %00010101
	.byte %00010101
	.byte %00010101
	.byte %00010101
	.byte %00010111
Eleven
	.byte %00010100
	.byte %00010100
	.byte %00010100
	.byte %00010100
	.byte %00010100
	.byte %00010100
	.byte %00010100
	.byte %00010100
Win
	.byte %10101001
	.byte %10101010
	.byte %10101010
	.byte %10101010
	.byte %10101010
	.byte %10101010
	.byte %10101010
	.byte %01001001
StartingYVelTable
	.byte %00000001
	.byte %11111111
	.byte %11111111
	.byte %00000000
	.byte %00000001
	.byte %00000001
	.byte %11111111
	.byte %11111111
	.byte %00000001
	.byte %11111111
	.byte %00000000
	.byte %00000001
	.byte %11111111
	.byte %00000001
	.byte %11111111
	.byte %00000000
	.byte %00000001
	.byte %00000000
	.byte %00000001
	.byte %11111111

	org $FFFC
	.word Start
	.word Start
	.byte %00000010
	.byte %00000010
	.byte %00000010
	.byte %00000010
	.byte %00000010
	.byte %00000010
Two
	.byte %00000111
	.byte %00000001
	.byte %00000001
	.byte %00000010
	.byte %00000010