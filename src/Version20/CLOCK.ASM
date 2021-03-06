; �ணࠬ�� �ᮢ

; �奬� ***********************************************************************

; ���ப���஫��� AT90S2313
.INCLUDE	"C:\DOC\AVR\2313def.inc"

; ���� �����
.EQU Fosc = 8000000
; ���ᨬ��쭮 �����⨬�� �६� � ᥪ㭤�� ����� �����ﬨ ������ �� ����ன��
.EQU INACTIVE_INTERVAL = 60
; ������⢮ ��⮯���஢ ������ ��। 㢥��祭��� ᪮���
.EQU AUTO_SPEEDUP_COUNT = 5
; ��ਮ� ����஢ � ���筮� ०���
.EQU SPEED1 = 90
; ��ਮ� ����஢ � �᪮७�� ०��� ०���
.EQU SPEED2 = 20
; �६� � ��� ��� ��⮬���᪮�� ���⠭������� �મ��
.EQU BRIGHT_TIME = 8

; ᥣ���� �������஢ ������祭� � �뢮��� ���� �
; ࠧ��� �������஢ ������祭� � ����� D, ���冷� ࠧ�冷� �������
; ����⠭⠬� ROW0...ROW3, ��� ROW0 - ���訩 ࠧ��
.EQU ROW0 = $40
.EQU ROW1 = $20
.EQU ROW2 = $10
.EQU ROW3 = $08

; ��ଥ��� *******************************************************************
.DEF	ResetType0 = r10
.DEF	ResetType1 = r2
.DEF	ResetType2 = r9
.DEF	DIG0 = r7
.DEF	DIG1 = r5
.DEF	DIG2 = r3
.DEF	DIG3 = r4
.DEF	Cnt1Sec = r6
.DEF	AutoCancelTime = r8
.DEF	BrightUpTimer = r29
.DEF	A = r16
.DEF	B = r17
.DEF	C = r18
.DEF	KeyTimer = r21
.DEF	ScanPos = r19
.DEF	FlashMask = r22
.DEF	ParNum = r25
.DEF	Second = r20
.DEF	Minute = r26
.DEF	Hour = r23
.DEF	ParVal = r28
.DEF	Accel = r12
.DEF	Correction = r27	; ���஢�� ���ࠢ�� 室� �ᮢ � ᥪ㭤�� �� ��⪨

.CSEG

.ORG	0
	RJMP	Reset

; ��ࠡ��稪 ���뢠���, ��뢠���� 800 ࠧ � ᥪ㭤� *************************
; ��� �᭮���� ࠡ�� �ணࠬ�� �믮������ �����
.ORG	OC1addr

	ANDI	ParNum,$FF
	BRNE	SetupModeShow
	; ��७�� �६��� �� Hour:Minute � DIG0:DIG1:DIG2:DIG3
	MOV	A,Minute	; �⮡ࠦ���� ���ଠ樨 � ���筮� ०���
	MOV	B,A
	ANDI	A,$0F
	ANDI	B,$F0
	MOV	DIG3,A
	MOV	DIG2,B
	MOV	A,Hour
	MOV	B,A
	ANDI	A,$0F
	ANDI	B,$F0
	MOV	DIG1,A
	MOV	DIG0,B
	SWAP	DIG0
	CLR	FlashMask
	RJMP	L006
SetupModeShow:
	MOV	DIG0,ParNum	; �⮡ࠦ���� ���ଠ樨 � ०��� ����ன��
	LDI	A,$0A
	MOV	DIG1,A
	MOV	A,ParVal
	MOV	B,A
	ANDI	A,$0F
	ANDI	B,$F0
	MOV	DIG3,A
	MOV	DIG2,B
	LDI	FlashMask,ROW1
L006:
	SWAP	DIG2

	; ��襭�� �������஢
	LDI	A,$FF
	OUT	PORTB,A
	IN	B,PORTD
	ANDI	B,~(ROW0 | ROW1 | ROW2 | ROW3)
	INC	ScanPos
	ANDI	ScanPos,3
	BRNE	L001
	; ࠧ�� 0   +---

	INC	Cnt1sec
	MOV	A,DIG0
	CLR	r0
	CPSE	A,r0
	ORI	B,ROW0
	RJMP	L000
L001:
	CPI	ScanPos,1
	BRNE	L002
	; ࠧ�� 1   -+--
	MOV	A,DIG1
	ORI	B,ROW1
	RJMP	L000
L002:
	CPI	ScanPos,2
	BRNE	L003
	; ࠧ�� 2   --+-
	MOV	A,DIG2
	ORI	B,ROW2
	RJMP	L000
L003:
	; ࠧ�� 3   ---+
	MOV	A,DIG3
	ORI	B,ROW3
L000:

	; �⪫�祭�� �⮡ࠦ���� ������� ᨬ�����
	COM	FlashMask
	SBRS	Cnt1sec,5
	AND	B,FlashMask
	COM	FlashMask

	; �८�ࠧ������ ����� ᨬ���� � ��� ᥣ����� ���
	LDI	ZH,HIGH(CharTable*2)	; r0 = CharTable[A]
	LDI	ZL,LOW(CharTable*2)
	ADD	ZL,A
	CLR	A
	ADC	ZH,A
	LPM
	COM	r0
	OUT	PORTB,r0
	OUT	PORTD,B

	; ��ࠡ�⪠ ����⨩ �� ������
	ANDI	ScanPos,3     ; ��ࠡ��뢠�� ⮫쪮 ������ 4-� ���饭��
	BRNE	L009
	CPI	KeyTimer,SPEED1
	BRNE	L012
	; �६� ���室�饥 - �맢��� ��ࠡ��稪� ����⨩ �� ������
	SBIS	PIND,0
	RCALL	Key0Pressed
	SBIS	PIND,1
	RCALL	Key1Pressed
	CLR	KeyTimer
	INC	Accel	      ; �᫨ ��諮 ����� 5 ����⨩ - �᪮�塞 �����
	LDI	B,AUTO_SPEEDUP_COUNT
	CP	Accel,B
;;	CPI	Accel,AUTO_SPEEDUP_COUNT
	BRNE	L012
	DEC	Accel         
	LDI	KeyTimer,SPEED1-SPEED2
L012:	SBIC	PIND,0	      ; �᫨ ����� ���� ���� ������ KeyTimer++
	SBIS	PIND,1	      ; �᫨ �� �����, � KeyTimer=0
	RJMP	L010
	LDI	KeyTimer,SPEED1
	CLR	Accel
	RJMP	L009
L010:	INC	KeyTimer
	CLR	AutoCancelTime
L009:

	CPI	BrightUpTimer,0	; �᫨ ०�� ��������� �મ��
	BREQ	L12G3B		; �믮��塞 �������⥫��� ����প� � 
	CLR	A		; �⪫�砥� ��������� �� ��室� �� ���뢠���
L12G3C:	NOP
	LDI	B,$FF
	DEC	A
	BRNE	L12G3C
	OUT	PORTB,B
L12G3B:


	; ��⠫쭠� ���� �㭪樨 ��뢠���� 1 ࠧ � ᥪ㭤�
	LDI	B,200
	CPSE	Cnt1sec,B
	RJMP	L005
	CLR	Cnt1sec

	; �஢�ઠ �६��� ��⮬���᪮�� ��室� �� ०��� ����஥�
	INC	AutoCancelTime
	LDI	A,INACTIVE_INTERVAL
	CP	A,AutoCancelTime
	BRNE	L015
	TST	Hour	; �᫨ �६� 0:00 - ������ �� �ந������
	BRNE	L13G3A	; ᤥ���� ��� �����஢�� ������ ��᫥ ��१���᪠
	TST	Minute
	BREQ	L015
L13G3A:	CLR	ParNum
L015:

	; 㢥��祭�� ���稪� �६��
	INC	Second		; 㢥��祭�� ᥪ㭤
	CPI	Second,60
	BRNE	L005
	CLR	Second

	INC	Minute		; 㢥��祭�� �����襣� ࠧ�鸞 �����
	MOV	A,Minute
	ANDI	A,$0F
	CPI	A,$0A
	BRNE	L005
	SUBI	Minute,-6
	CPI	Minute,$60	; 㢥��祭�� ���襣� ࠧ�鸞 �����
	BRNE	L005
	CLR	Minute

	CPI	Hour,$23	; �஢�ઠ �� ���室 �१ �������
	BRNE	L005A
	CLR	Hour

	MOV	Second,Correction	; �८�ࠧ������ Correction �� BCD
	ANDI	Second,$0F		; �ଠ� � ����� � ������ � Second
	MOV	A,Correction
	SWAP	A
	ANDI	A,$0F
	LDI	B,10
L011:	ADD	Second,A
	DEC	B
	BRNE	L011
	LDI	A,50
	SUB	Second,A

	RJMP	L005

L005A:	INC	Hour		; 㢥��祭�� �����襣� ࠧ�鸞 �ᮢ
	CPI	BrightUpTimer,0	
	BREQ	L13G3B		; 㬥�襭�� �६��� �� ��������� �મ��
	DEC	BrightUpTimer
L13G3B:	MOV	A,Hour
	ANDI	A,$0F
	CPI	A,$0A
	BRNE	L005
	SUBI	Hour,-6         ; 㢥��祭�� ���襣� ࠧ�鸞 �ᮢ
L005:	RETI



; �㭪�� ��뢠���� ��� ��ࠡ�⪨ ������ �� ������ 0
Key0Pressed:
	INC	ParNum		; ��ॡ�� ����㯭�� ��ࠬ�⭮� ����ன��
	CPI	ParNum,1
	BRNE	L013
	MOV	ParVal,Hour	; �����⮢�� � ���������� �ᮢ
	RJMP	L008
L013:
	CPI	ParNum,2
	BRNE	L014
	MOV	Hour,ParVal	; �����⮢�� � ���������� �����
	MOV	ParVal,Minute
	RJMP	L008
L014:
	CPI	ParNum,3
	BRNE	L016
	MOV	Minute,ParVal	; �����⮢�� � ���������� ���
	MOV	ParVal,Correction
	RJMP	L008
L016:	
	MOV	Correction,ParVal
	CLR	A		; ��࠭���� ��� � EEPROM
	OUT	EEAR,A
	OUT	EEDR,Correction
	SBI	EECR,2
	SBI	EECR,1
	CLR	Second
	CLR	ParNum

L008:	RET

; �㭪�� ��뢠���� ��� ��ࠡ�⪨ ������ �� ������ 1
Key1Pressed:
	CPI	ParNum,0
	BRNE	L12G3A		; ������ ����� � ०��� ��������
	CPI	BrightUpTimer,0	; ��४��祭�� �મ��
	LDI	BrightUpTimer,0
	BRNE	L12G3A
	LDI	BrightUpTimer,BRIGHT_TIME
L12G3A:	INC	ParVal		; 㢥��祭�� ParVal � BCD ���४樥�
	MOV	A,ParVal	; � ��࠭�祭�� �� 99
	ANDI	A,$0F
	CPI	A,$0A
	BRNE	L007
	SUBI	ParVal,-$06
	CPI	ParVal,$A0
	BRNE	L007
	CLR	ParVal
L007:
	CPI	ParNum,1	; ��࠭�祭�� ���ᨬ����� ���祭�� ��ࠬ��஢
	BRNE	L007A
	CPI	ParVal,$24	; �᫨ �ᮢ 24, ����塞
	BRNE	L007B
	CLR	ParVal
	RJMP	L007B
L007A:	CPI	ParNum,2
	BRNE	L007B
	CPI	ParVal,$60	; �᫨ ᥪ㭤 60, ����塞
	BRNE	L007B
	CLR	ParVal
	RJMP	L007B
L007B:
	RET



; �室 � �ணࠬ�� ************************************************************
Reset:
	; ���樠������ 㪠��⥫� �⥪� ��砫�� ���祭���
	LDI	A,LOW(RAMEND)
	OUT	SPL,A
	; ����ன�� ���ࠢ���� ࠡ��� ����� ���⮢ B � D
	LDI	A, ROW0 | ROW1 | ROW2 | ROW3
	OUT	DDRD,A
	LDI	A,$FF
	OUT	PORTB,A
	OUT	DDRB,A
	; ����ன�� ⠩��� � ��� ���뢠���
	LDI	A,$40
	OUT	TIMSK,A
	LDI	A,$0A
	OUT	TCCR1B,A
	LDI	A,HIGH(Fosc/8/800)
	OUT	OCR1AH,A
	LDI	A,LOW(Fosc/8/800)
	OUT	OCR1AL,A


	LDI	A,$37		; �஢�ઠ ��稭� ��१���᪠
	CP	ResetType0,A
	BRNE	HardwareReset
	LDI	A,$12
	CP	ResetType1,A
	BRNE	HardwareReset
	LDI	A,$F5
	CP	ResetType2,A
	BREQ	SoftwareReset
HardwareReset:
	LDI	A,$37
	MOV	ResetType0,A
	LDI	A,$12
	MOV	ResetType1,A
	LDI	A,$F5
	MOV	ResetType2,A
	CLR	Second		; ���㫥��� ��६�����
	CLR	Minute
	CLR	Hour
	CLR	ParVal
	CLR	BrightUpTimer
	CLR	A		; �⥭�� ��� �� EEPROM
	OUT	EEAR,A
	SBI	EECR,0
	IN	Correction,EEDR
	CLR	AutoCancelTime
	LDI	ParNum,1

SoftwareReset:

	SEI





; �몫�砥� ��������� �������� ��� 㬥��襭�� ⮪� ���ॡ�����
	LDI	A,$80
	OUT	ACSR,A
; ��ॢ���� ���ப���஫��� � ०�� Idle
; ���樠������ �����襭�, �� ��⠫�� ����⢨� ���� �믮������ � ���뢠���
LoopForever:
	LDI	A,$20
	OUT	MCUCR,A
	SLEEP
	RJMP	LoopForever

CharTable:
.DB	0b11010111,0b10000001,0b11001110,0b11001011,0b10011001,0b01011011,0b01011111,0b11000001,0b11011111,0b11011011,0b00001000
;       0         1           2           3          4          5          6          7           8         9          -

.EXIT
 