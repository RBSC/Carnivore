	;--- Macro for printing a $-finished string

print	macro	
	ld	de,\1
	ld	c,_STROUT
	call	DOS
	endm


	;--- System variables and routines

DOS:	equ	#0005	;DOS function calls entry point
ENASLT:	equ	#0024	; BIOS Enable Slot
WRTSLT:	equ	#0014	; BIOS Write to Slot

TPASLOT1:	equ	#F342
TPASLOT2:	equ	#F343
CSRY	equ	#F3DC
CSRX	equ	#F3DD
ARG:	equ	#F847
EXTBIO:	equ	#FFCA
MNROM:   equ    #FCC1  ; Main-ROM Slot number & Secondary slot flags table

CardMDR: equ	#4F80
AddrM0: equ	#4F80+1
AddrM1: equ	#4F80+2
AddrM2: equ	#4F80+3
DatM0: equ	#4F80+4

AddrFR: equ	#4F80+5

R1Mask: equ	#4F80+6
R1Addr: equ	#4F80+7
R1Reg:  equ	#4F80+8
R1Mult: equ	#4F80+9
B1MaskR: equ	#4F80+10
B1AdrD:	equ	#4F80+11

R2Mask: equ	#4F80+12
R2Addr: equ	#4F80+13
R2Reg:  equ	#4F80+14
R2Mult: equ	#4F80+15
B2MaskR: equ	#4F80+16
B2AdrD:	equ	#4F80+17

R3Mask: equ	#4F80+18
R3Addr: equ	#4F80+19
R3Reg:  equ	#4F80+20
R3Mult: equ	#4F80+21
B3MaskR: equ	#4F80+22
B3AdrD:	equ	#4F80+23

R4Mask: equ	#4F80+24
R4Addr: equ	#4F80+25
R4Reg:  equ	#4F80+26
R4Mult: equ	#4F80+27
B4MaskR: equ	#4F80+28
B4AdrD:	equ	#4F80+29

CardMod: equ	#4F80+30

CardMDR2: equ   #4F80+31
ConfFl:	equ	#4F80+32
ADESCR:	equ	#4010

L_STR:	equ	16 	; 


	;--- DOS function calls

_TERM0:	equ	#00	;Program terminate
_CONIN:	equ	#01	;Console input with echo
_CONOUT:	equ	#02	;Console output
_DIRIO:	equ	#06	;Direct console I/O
_INNOE:	equ	#08	;Console input without echo
_STROUT:	equ	#09	;String output
_BUFIN:	equ	#0A	;Buffered line input
_CONST:	equ	#0B	;Console status
_FOPEN: equ	#0F	;Open file
_FCLOSE	equ	#10	;Close file
_SDMA:	equ	#1A	;Set DMA address
_RBREAD:	equ	#27	;Random block read
_TERM:	equ	#62	;Terminate with error code
_DEFAB:	equ	#63	;Define abort exit routine
_DOSVER:	equ	#6F	;Get DOS version


;************************
;***                  ***
;***   MAIN PROGRAM   ***
;***                  ***
;************************

	org	#100	;Needed for programs executing under MSX-DOS

	;------------------------
	;---  Initialization  ---
	;------------------------

	;--- Checks the DOS version and establishes variable DOS2

	ld	c,_DOSVER
	call	DOS
	or	a
	jr	nz,NODOS2
	ld	a,b
	cp	2
	jr	c,NODOS2

	ld	a,#FF
	ld	(DOS2),a	;#FF for DOS 2, 0 for DOS 1
	print	USEDOS2_S

NODOS2:	;



	;--- Prints the presentation

	print	PRESENT_S

	call	FindSlot
	jp	c,Exit
; 
	ld	a,1
	ld	de,BUFFER
	call	EXTPAR
	jr	c,MainM		; No parametr
	ld	ix,BUFFER		;
	call	FnameP
	jp	ADD_OF		; continue loadin ROM-image

; Main menu
MainM:
	print	MAIN_S
Ma01:	ld	c,_INNOE
	call	DOS	
	cp	"0"
	jp	z,Exit
	cp	27
	jp	z,Exit
	cp	"8"
	jp	z,UTIL
	cp	"1"
	jp	z,ADDimage
	cp	"2"
	jp	z,ListRec
	jr	Ma01
;---

ADDimage:
; ADD ROM image
	print	ADD_RI_S
	ld	de,Bi_FNAM
	ld	c,_BUFIN
	call	DOS
	ld	a,(Bi_FNAM+1)
	or	a		; Empty input
	jp	z,MainM	
	ld	c,a
	ld	b,0
	ld	hl,Bi_FNAM+2
	add	hl,bc
	ld	(hl),0
	ld	ix,Bi_FNAM+2
	call	FnameP
ADD_OF:
;Open file
	ld	de,OpFile_S
	ld	c,_STROUT
	call	DOS

	ld	a,(FCB)
	or 	a
	jr	z,opf1	; not print device letter
	add	a,#40	; 1 => "A:"
	ld	e,a
	ld	c,_CONOUT
	call	DOS
	ld	e,":"
	ld	c,_CONOUT
	call	DOS
opf1:	ld	b,8
	ld	hl,FCB+1
opf2:	push	bc
	push	hl
	ld	e,(hl)
	ld	c,_CONOUT
	call	DOS
	pop	hl
	inc	hl
	pop	bc
	djnz	opf2	
	ld	e,"."
	ld	c,_CONOUT
	call	DOS
	ld	b,3
	ld	hl,FCB+9
opf3:	push	bc
	push	hl
	ld	e,(hl)
	ld	c,_CONOUT
	CALL	DOS
	pop	hl
	inc	hl
	pop	bc
	djnz	opf3
	ld	de,ONE_NL_S
	ld	c,_STROUT
	call	DOS

; file open
	ld	de,FCB
	ld	c,_FOPEN
	call	DOS		; Open file
	ld      hl,1
	ld      (FCB+14),hl     ; Record size = 1 byte
	or	a
	jr	z,Fpo

	ld	de,F_NOT_F_S
	ld	c,_STROUT
	call	DOS
	jp	MainM		
	
Fpo:
; File was opened
	ld      c,_SDMA
	ld      de,BUFTOP
	call    DOS
; Get File Size
	ld	hl,FCB+#10
	ld	bc,4
	ld	de,Size
	ldir
;
	ld	a,(Size+3)
	call	HEXOUT
	ld	a,(Size+2)
	call	HEXOUT
	ld	a,(Size+1)
	call	HEXOUT
	ld	a,(Size)
	call	HEXOUT

	ld	de,ONE_NL_S
	ld	c,_STROUT
	call	DOS	
; File size <= 32 κα ?
;	ld	a,(Size+3)
;	or	a
;	jr	nz,Fptl
;	ld	a,(Size+2)
;	or	a
;	jr	nz,Fptl
;	ld	a,(Size+1)
;	cp	#80
;	jr	nc,Fptl
; ROM Image is small, no use mapper
; bla bla bla :)
FMROM:
	print	MROMD_S
	ld	hl,(Size)
	exx
	ld	hl,(Size+2)
	ld	bc,0
	exx

	ld	a,%00000100
	ld	de,ssr08
	ld	bc,#2001	; >8Kb
	or	a
	sbc	hl,bc
	exx
	sbc	hl,bc
	exx
	jr	c,FMRM01

	ld	a,%00000101
	ld	de,ssr16
	ld	bc,#4001-#2001 ;(#2000)  ; >16kB
	sbc	hl,bc
	exx
	sbc	hl,bc
	exx
	jr	c,FMRM01

	ld	a,%00000110
	ld	de,ssr32
	ld	bc,#8001-#4001 ;(#4000); >32kb
	sbc	hl,bc
	exx
	sbc	hl,bc
	exx
	jr	c,FMRM01

	ld	a,%00001110
	ld	de,ssr48
	ld	bc,#C001-#8001 ;(#4000) ; >48kB
	sbc	hl,bc
	exx
	sbc	hl,bc
	exx
	jr	c,FMRM01

	ld	a,%00000111
	ld	de,ssr64
	ld	bc,#4000 ;#10001-#C001 ; >64kB
	sbc	hl,bc
	exx
	sbc	hl,bc
	exx
	jr	c,FMRM01

	xor	a
	ld	de,ssrMAP


FMRM01:				; fix size
	ld	(SRSize),a
	ld	c,_STROUT
	call	DOS
	print	CRLF_S

; Analise ROM-Image

; load first 8000h byte for analise	
Fptl:
	ld	hl,#8000
	ld      c,_RBREAD
	ld	de,FCB
	call    DOS
	ld	a,l
	or	h
	jp	z,FrErr

; descriptor analise
;ROMABCD - % 0, 0, CD2, AB2, CD1, AB1, CD0, AB0	
;ROMJT0	 - CD, AB, 0,0,TEXT ,DEVACE, STAT, INIT
;ROMJT1
;ROMJT2
;ROMJI0	- high byte INIT jmp-address
;ROMJI1
;ROMJI2
	ld	bc,6
	ld	hl,ROMABCD
	ld	de,ROMABCD+1
	ld	(hl),b
	ldir			; clear descr tab


	ld	ix,BUFTOP	; test #0000
	call	fptl00
	ld	(ROMJT0),a
	and	#0F
	jr	z,fpt01
	ld	a,e
	ld	(ROMJI0),a
fpt01:
	ld	a,(SRSize)
	and	#0F		
	jr	z,fpt07		; MAPPER
	cp	6
	jr	c,fpt03		; <= 16 kB 
fpt07:
	ld	ix,BUFTOP+#4000	; test #4000
	call	fptl00
	ld	(ROMJT1),a
	and	#0F
	jr	z,fpt02
	ld	a,e
	ld	(ROMJI1),a
fpt02:
	ld	a,(SRSize)
	and	#0F
	jr	z,fpt08		; MAPPER
	cp	7
	jr	c,fpt03		; <= 16 kB 
fpt08:
	ld      c,_SDMA
	ld      de,BUFFER
	call    DOS

	ld	hl,#0010
	ld      c,_RBREAD
	ld	de,FCB
	call    DOS
	ld	a,l
	or	h
	jp	z,FrErr

	ld	ix,BUFFER	; test #8000
	call	fptl00
	ld	(ROMJT2),a
	and	#0F
	jr	z,fpt03
	ld	a,e
	ld	(ROMJI2),a

fpt03:

	ld      c,_SDMA
	ld      de,BUFTOP
	call    DOS
	


	jp	FPT10

fptl00:
	ld	h,(ix+1)
	ld	l,(ix)
	ld	bc,"A"+"B"*#100
	xor	a
	push	hl
	sbc	hl,bc
	pop	hl
	jr	nz,fptl01
	set	6,a
fptl01: ld	bc,"C"+"D"*#100
	or	a
	sbc	hl,bc
	jr	nz,fptl02
	set	7,a
fptl02:	ld	e,a	
	ld	d,0
	or	a
	jr	z,fptl03	; no AB,CD descriptor

	ld	b,4
	push	ix
	pop	hl
	inc	hl	;+1
fptl05:
	inc	hl	;+2
	ld	a,(hl)
	inc	hl
	or	(hl)	;+3
	jr	z,fptl04
	scf
fptl04:	rr	d
	djnz	fptl05
	rrc	d
	rrc	d
	rrc	d
	rrc	d
fptl03:
	ld	a,d
	or	e
	ld	d,a
	ld	e,(ix+3)
	bit	0,d
	jr	nz,fptl06
	ld	e,(ix+5)
	bit	1,d
	jr	nz,fptl06
	ld	e,(ix+7)
	bit	2,d
	jr	nz,fptl06
	ld	e,(ix+9)
fptl06:
;			ld	e,a
;			ld	a,d
	ret
FPT10:

; file close
	ld	de,FCB
	ld	c,_FCLOSE
	call	DOS
; print test ROM descriptor table
	print	CRLF_S
	ld	a,(ROMJT0)
	call	HEXOUT
	ld	e," "
	ld	c,_CONOUT
	call	DOS
	ld	a,(ROMJT1)
	call	HEXOUT
	ld	e," "
	ld	c,_CONOUT
	call	DOS
	ld	a,(ROMJT2)
	call	HEXOUT
	print	CRLF_S
	ld	a,(ROMJI0)
	call	HEXOUT
	ld	e," "
	ld	c,_CONOUT
	call	DOS
	ld	a,(ROMJI1)
	call	HEXOUT
	ld	e," "
	ld	c,_CONOUT
	call	DOS
	ld	a,(ROMJI2)
	call	HEXOUT
	print	CRLF_S


; Map / miniROm select
	ld	a,(SRSize)
	and	#0F
	jr	z,FPT01		; MAPPER ROM
	cp	7
	jr	c,FPT02		; MINI ROM
	print	MRSQ_S
FPT03:	ld	c,_INNOE	; 32 < ROM =< 64
	call	DOS
	cp	"n"
	jr	z,FPT01		;no minirom (mapper)
	jr	FPT03	
	cp	"y"		; yes minirom
	jp	nz,FPT03
FPT02:
; Mini ROM set

	ld	b,5
	jp	DTME1

FPT01:
	xor	a
	ld	(SRSize),a	

; Mapper types Singature
; Konami:
;    LD    (#6000),a
;    LD    (#8000),a
;    LD    (#a000),a
; 
;    Konami SCC:
;    LD    (#5000),a
;    LD    (#7000),a
;    LD    (#9000),a
;    LD    (#b000),a
; 
;    ASCII8:
;    LD    (#6000),a
;    LD    (#6800),a
;    LD    (#7000),a
;    LD    (#7800),a
; 
;    ASCII16:
;    LD    (#6000),a
;    LD    (#7000),a
;
;    32 00 XX
; 
;    For Konami games is easy since they always use the same register addresses.
; 
;    But ASC8 and ASC16 is more difficult because each game uses its own addresses and instructions to access them.
;    I.e.:
;    LD    HL,#68FF 2A FF 68
;    LD    (HL),A   77
;
;    BIT E 76543210
; 	   !!!!!!!. 5000h
;          !!!!!!.- 6000h
;          !!!!!.-- 6800h
;	   !!!!.--- 7000h
;	   !!!.---- 7800h
;          !!.----- 8000h
;          !.------ 9000h
;	   .------- A000h
;    BIT D 76543210
;	          . B000h
DTMAP:
	print	Analis_S
	ld	de,0
	ld	ix,BUFTOP
	ld	bc,#8000
DTM01:	ld	a,(ix)
	cp	#2A
	jr	nz,DTM03
	ld	a,(ix+1)
	cp	#FF
	jr	nz,DTM02
	ld	a,(ix+3)
	cp	#77
	jr	nz,DTM02
	ld	a,(ix+2)
	cp	#60
	jr	z,DTM60	
	cp	#68
	jr	z,DTM68
	cp	#70
	jr	z,DTM70
	cp	#78
	jr	z,DTM78
	jr	DTM02
DTM03:	cp	#32
	jr	nz,DTM02
	ld	a,(ix+1)
	cp	#00
	jr	nz,DTM02
	ld	a,(ix+2)
	cp	#50
	jr	z,DTM50
	cp	#60
	jr	z,DTM60
	cp	#68
	jr	z,DTM68
	cp	#70
	jr	z,DTM70
	cp	#78
	jr	z,DTM78
	cp	#80
	jr	z,DTM80
	cp	#90
	jr	z,DTM90
	cp	#A0
	jr	z,DTMA0
	cp	#B0
	jr	z,DTMB0
	
DTM02:	inc	ix
	dec	bc
	ld	a,b
	or	c
	jr	nz,DTM01
	jr	DTME
DTM50:
	set	0,E
	jr	DTM02
DTM60:
	set	1,E
	jr	DTM02
DTM68:
	set	2,E
	jr	DTM02
DTM70:
	set	3,E
	jr	DTM02
DTM78:
	set	4,E
	jr	DTM02
DTM80:
	set	5,E
	jr	DTM02
DTM90:
	set	6,E
	jr	DTM02
DTMA0:
	set	7,E
	jr	DTM02

DTMB0:
	set	0,D
	jr	DTM02
	

DTME:
	ld	(BMAP),de	;save detect bit mask
	ld	a,0

	ld	a,(BMAP+1)
	call	HEXOUT
	ld	a,(BMAP)
	call	HEXOUT	

	ld	e," "
	ld	c,_CONOUT
	call	DOS
;    BIT E 76543210
; 	   !!!!!!!. 5000h
;          !!!!!!.- 6000h
;          !!!!!.-- 6800h
;	   !!!!.--- 7000h
;	   !!!.---- 7800h
;          !!.----- 8000h
;          !.------ 9000h
;	   .------- A000h
;    BIT D 76543210
;	          . B000h
	ld	a,(BMAP+1)
	cp	%00000001		;
	ld	a,(BMAP)
	jr	z,DTME2		;konami5
	ld	b,4		;AsCII 16
	cp	%00001010	;6000h 7000h
	jr	z,DTME1		
	ld	b,1		;konami (4)
	cp	%10100010	;6000h 8000h A000h
	jr	z,DTME1
	ld	b,3		;ASCII 8
	cp	%00011110	;6000h,6800h,7000h,8700h
	jr	z,DTME1
DTME3:				;Mapper not detected

	ld	b,0
	jr	DTME1
DTME2:
	cp	%01001001	;5000h,7000h,9000h	
	ld	b,2		;Konami 5 (SCC)
	jr	z,DTME1
	cp	%01001000	;5000h,7000h
	jr	nz,DTME3
DTME1:
	ld	a,b
	ld	(DMAP),a	; save detect Maper type
	print	ONE_NL_S
	ld	a,(DMAP)
	ld	b,a
	call	TTAB
	inc	hl
	ex	hl,de
	ld	c,_STROUT	; pring selected MAP
	call	DOS
	print	ONE_NL_S

	ld	a,(SRSize)
	and	#0F
	jp	nz,DE_F1	; not confirm the type mapper

	ld	a,(DMAP)
	or	a
	jr	z,MTC
	print	CTC_S		; (y/n)?
DTME4:	ld	c,_INNOE
	call	DOS
	cp	"y"
	jp	z,DE_F1
	cp	"n"
	jr	nz,DTME4
MTC:				; Manual select MAP type
	print	CoTC_S
	ld	a,1
MTC2:	ld	(DMAPt),a	; prtint all tab MAP
	ld	b,a
	call	TTAB
	ld	a,(hl)
	or	a
	jr	z,MTC1	
	push	hl
	ld	a,(DMAPt)
	ld	e,a
	ld	d,0
	ld	hl,BUFFER
	ld	b,2
	ld	c," "
	ld	a,%00001000	; print 2 decimal digit number
	call	NUMTOASC
	print	BUFFER
	ld	e," "
	ld	c,_CONOUT
	CALL	DOS
	POP	hl
	inc	hl
	ex	hl,de
	ld	c,_STROUT
	call	DOS
	print	ONE_NL_S
	ld	a,(DMAPt)
	inc	a
	jr	MTC2
MTC1:
	print	Num_S

MTC3:		
	ld	de,Binpsl	; input 2 digit number
	ld	c,_BUFIN
	call	DOS
	ld	b,0
	ld	a,(Binpsl+1)
	cp	1
	jr	z,MTC4
	cp	2
	jr	z,MTC5	
	jr	MTC
MTC4:	ld	a,(Binpsl+2)
	sub	a,"0"
	jr	MTC6
MTC5:	ld	a,(Binpsl+2)
	sub	a,"0"
	inc	a
	xor	a
	ld	b,a
MTC7:	dec	b
	jr	z,MTC8
	add	a,10
	jr	MTC7
MTC8:	ld	b,a
	ld	a,(Binpsl+3)
	sub	a,"0"
	add	b

MTC6:
; chech inp
	ld	hl,DMAPt
	cp	(hl)
	jp	nc,MTC
	or	a
	jp	z,MTC
	ld	b,a
	jp	DTME1

DE_F1:
; Save MAP config to Record form
	ld	a,(DMAP)
	ld	b,a
	call	TTAB
	ld	a,(hl)
	ld	(Record+04),a	; type descriptos symbol
	ld	bc,35		;TAB register map
	add	hl,bc
	ld	de,Record+#23	;Record register map
	ld	bc,29		;(6 * 4) + 5
	ldir

	ld	a,(SRSize)
	ld	(Record+#3D),a

; Correction start metod

; ROMJT0
	ld	ix,ROMJT0
	and	#0F
	jp	z,Csm01		; mapper ROM
;Mini ROM-image
;;	
	cp	5		; =< 8Kb
	jr	nc,Csm04

	ld	a,#84		; set size 8kB no Ch.reg
	ld	(Record+#26),a	; Bank 1
	ld	a,#8C		; set Bank off
	ld	(Record+#2C),a	; Bank 1
	ld	(Record+#32),a	; Bank 2
	ld	(Record+#38),a	; Bank 3
Csm08:	ld	a,(ix)
	cp	#41
	ld	a,#40
	jr	nz,Csm06	; start on reset
	ld	a,(ix+3)
	and	#C0
	ld	(Record+#28),a	; set Bank Addr	
	cp	#40
	jr	z,Csmj4	; start on #4000
	cp	#80	
	jr	z,Csmj8	; start Jmp(8002)
Csm06:
	ld	a,(ix+3)
	and	#C0
	ld	(Record+#28),a	; set Bank Addr	

	ld	a,01		; start reset
Csm05:	ld	(Record+#3E),a		
	jp	Csm70
Csmj4:	ld	a,2
	jr	Csm05
Csmj8:	ld	a,6
	jr	Csm05

;;
Csm04:	cp	6		; =< 16 kB
	jr	nc,Csm07

	ld	a,#85		; set size 16kB noCh.reg
	ld	(Record+#26),a	; Bank 1
	ld	a,#8D		; set Bank off
	ld	(Record+#2C),a	; Bank 1
	ld	(Record+#32),a	; Bank 2
	ld	(Record+#38),a	; Bank 3
	jp	Csm08

Csm07:	cp	7		; =< 32 kb
	jr	nc,Csm09
	ld	a,#85		; set size 16kB noCh.reg
	ld	(Record+#26),a	; Bank 1
	ld	a,#85		; set size 16kB noCh.reg
	ld	(Record+#2C),a	; Bank 1
	ld	a,#8d		; set Bank off
	ld	(Record+#32),a	; Bank 2
	ld	(Record+#38),a	; Bank 3
	ld	a,(ix)
	ld	b,a
;	cp	#41
	or	a
;	jr	z, Csm071
	jr	nz,Csm071
	ld	a,(ix+1)
	cp	#41
	jr	nz,Csm06
	ld	a,(ix+4)
	and	#C0
	cp	#80
	jr	nz,Csm06
	jr	Csmj8		; start Jmp(8002)	
Csm071:	ld	a,(ix+3)	
	and	#C0
	cp	#40		; #4000
	jr	nz,Csm072
	ld	a,b
	cp	#41
	jp	nz,Csm06	;R
	ld	a,2
	jp	Csm05		; start Jmp(4002)
	cp	#00		; #0000 subrom
	jr	nz,Csm072
	ld	(Record+#28),a	; Bank1 #0000 
	ld	a,#40
	ld	(Record+#2E),a	; Bank2 #4000
	jp	Csm06		; start on reset 	
Csm072:	cp	#80
	jp	nz,Csm06		; start on reset
	ld	(Record+#28),a	; Bank1 #0000 
	ld	a,#C0
	ld	(Record+#2E),a	; Bank2 #4000
	ld	a,6
	jp	Csm05		; start Jmp(8002)

Csm09:
	cp	7		; 64 kB ROM
	jr	nz,Csm10
	ld	a,#87		; set size 64kB noCh.reg
	ld	(Record+#26),a	; Bank 1
	ld	a,#8D		; set Bank off
	ld	(Record+#2C),a	; Bank 1
	ld	(Record+#32),a	; Bank 2
	ld	(Record+#38),a	; Bank 3
	ld	a,0
	ld	(Record+#28),a	; Bank 0 Address=0
	ld	a,(ix)
	or	a
	jp	nz,Csm06	; start on Reset
	ld	a,(ix+1)
	or	a
	jr	z,Csm11
	cp	#41
	jp	nz,Csm06
	ld	a,2		; start jmp(4002)
	jp	Csm05				
Csm11:	ld	a,(ix+2)
	cp	#41
	jp	nz,Csm06
	ld	a,6		; staer jmp(8002)
	jp	Csm05		


Csm10:
;                               ; %00001110 48 kB
	ld	a,#85		; set size 16kB noCh.reg
	ld	(Record+#26),a	; Bank 1
	ld	a,#85		; set size 16kB noCh.reg
	ld	(Record+#2C),a	; Bank 1
	ld	a,#85		; set size 16kB noCh.reg
	ld	(Record+#32),a	; Bank 2
	ld	a,#8D		; set Bank off
	ld	(Record+#38),a	; Bank 3
	ld	a,2
	ld	(Record+#2B),a
	ld	a,(ix)
	or	a			
	jr	z,Csm12
	cp	41
	jr	nz,Csm13
	ld	a,2		; start jmp(4002)
	jp	Csm05
Csm13:	ld	a,(ix+3)
	and	#C0
	jp	nz,Csm06	; start on Reset
	xor	a		; 0 address
	ld	(Record+#28),a
	ld	a,#40
	ld	(Record+#2E),a
	ld	a,#80
	ld	(Record+#34),a
	jp	Csm06		; start on Reset
Csm12:	ld	a,(ix+1)
	or	a
	jr	z,Csm14
	ld	a,(ix+4)
	and	#C0
	cp	#40
	jr	nz,Csm15
	xor	a		; 0 address
	ld	(Record+#28),a
	ld	a,#40
	ld	(Record+#2E),a
	ld	a,#80
	ld	(Record+#34),a
	ld	a,(ix+1)
	cp	#41
	jp	nz,Csm06
	ld	a,2		; start jmp(4002)
	jp	Csm05
Csm15:	jp	Csm06

Csm14:	ld	a,(ix+2)
	or	a
	jp	nz,Csm06
	xor	a		; 0 address
	ld	(Record+#28),a
	ld	a,#80
	ld	(Record+#2E),a
	ld	a,(ix+2)
	cp	#41	
	jp	nz,Csm06
	ld	a,6		; start jmp(8002)
	jp	Csm05

Csm01:

; Mapper ROM IMAGE start Bank #4000

; 
	ld	a,(ix+1)	;ROMJT1 (#8000)
	or	a
	jr	nz,Csm02	
Csm03:	ld	a,01		; Copmlex start
	ld	(Record+#3E),a	; need Reset
	jp	Csm80
Csm02:
	ld	a,(ix)		;ROMJT0 (#4000)
	cp	#41
	jr	nz,Csm03	; Reset
	ld	a,02		; Start to jump (#4002)	
	ld	(Record+#3E),a
Csm70:


Csm80:
; test print Size-start metod
	print	Strm_S
	ld	a,(Record+#3D)
	call	HEXOUT
	ld	e,"-"
	ld	c,_CONOUT
	call	DOS
	ld	a,(Record+#3E)
	call	HEXOUT
	print	CRLF_S


; Search free space in flash


	ld	a,(Record+#3D)
	and	#0F
	jp	z,SFM80		; mapper ROM
	cp	7
	jp	nc,SFM80	; no multi ROM
; search exist multi rom record
	call	SFMR
	jr	nc,SFM01
;no find
	ld	a,(TPASLOT1)	; reset 1 page
	ld	h,#40
	call	ENASLT

	print	NFNR_S
	jr	SFM80
SFM01:
;find
	ld	e,a
	push	de

	ld	a,(TPASLOT1)	; reset 1 page
	ld	h,#40
	call	ENASLT


	print	FNRE_S
	pop	de

	push	de
	ld	a,d		; print N Record
	call	HEXOUT
	ld	e,"-"
	ld	c,_CONOUT
	call	DOS
	ld	a,(ix+2)	; print N FlashBlock
	call	HEXOUT
	ld	e,"-"
	ld	c,_CONOUT
	call	DOS
	pop	de

	push	de
	ld	a,e		; print N Bank
	call	HEXOUT
	print	CRLF_S
	pop	de

;	pop	af	;?

	ld	a,(Record+#3D)
	and	#0F
	cp	6
	ld	a,e
	jr	c,SFM70
	rlc	a
SFM70:	
	ld	(Record+#25),a	;R1Reg
	inc	a
	ld	(Record+#2B),a	;R2Reg
	inc	a
	ld	(Record+#31),a	;R3Reg
	inc	a
	ld	(Record+#37),a	;R4Reg

	ld	a,e
	rlc	a
	rlc	a
	rlc	a
	rlc	a
	ld	b,a
	ld	a,(Record+#3D)
	and	#0F
	or	b
	ld	(Record+#3D),a

	ld	d,1
	ld	e,(ix+2)
	ld	a,d
	ld	(multi),a

	jp	DEFMR1

SFM80:
	xor	a
	ld	(multi),a

; compile BAT table ( 8MB/64kB = 128 )
	call	CBAT
	print	QQ
	call	PRBAT
; Size  - size file 4 byte
; 
; calc blocks len
;
	ld	a,(Size+3)
	or	a
	jp	nz,DEFOver
	ld	a,(Size+2)
	cp	128
	jp	nc,DEFOver
	ld	d,a
	ld	bc,(Size)
	ld	a,b
	or	c
	jr	z,DEF01
	inc	d	 	; add block
DEF01:				; d- block len
; search empty space
	ld	bc,3		; blocks 0,1,2 occupied by the system

DEF03:	ld	e,c
	push	de		; save first empty BAT pointer and len

DEF05:	ld	hl,BAT
	add	hl,bc		; set BAT poiner
	ld	a,(hl)
	or	a		; empty ?
	jr	nz,DEF02	; not empty
	dec	d
	jr	z,DEF04		; successfully found
	inc	c		;
	bit	7,c		; >127 ?
	jr	z,DEF05		; next BAT
	pop	de		; outside BAT table
	jr	DEFOver
DEF02:	pop	de
	inc	c
	bit	7,c		; >127 ?
	jr	nz,DEFOver	; outside BAT table
	jr	DEF03		; next BAT

DEFOver:
	print	FileOver_S
	jp	MainM

DEF04:	pop 	de		; E - find start block D -Len
;
;	save	start block and length
DEFMR1:
	ld	(Record+02),de	; Record+02 - start block
				; Record+03 - len
	ld	a,#FF
	ld	(Record+01),a	; set "not erase" byte


; Control print
	print	FFFS_S
	ld	a,(Record+02)
	call	HEXOUT
	ld	e," "
	ld	c,_CONOUT
	call	DOS
	ld	a,(Record+03)
	call	HEXOUT

	print	ONE_NL_S


;
; search free DIR record

DEF09:	call	FrDIR
	jr	nz,DEF06
; Directory overfull
	print	DirOver_S
DEF07:	ld	c,_INNOE
	call	DOS
	cp	"y"
	jr	z,DEF08
	cp	"n"
	jp	z,MainM
	jr	DEF07
DEF08:	call	CmprDIR
	jr	DEF09

DEF06:	
	ld	(Record),a	; save DIR number
; control print
	print	FDE_S
	ld	a,(Record)
	call	HEXOUT
	print	ONE_NL_S

; Filename -> Record name
	ld	a," "
	ld	bc,30-1
	ld	de,Record+06
	ld	hl,Record+05
	ld	(hl),a
	ldir			; clear Record name
	ld	hl,FCB+1
	ld	de,Record+05
	ld	bc,8+3
	ldir			; transfer filename

; print Record name
DEF13:
	print	NR_I_S
	ld	b,30
	ld	hl,Record+05
DEF12:
	push	hl
	push	bc
	ld	e,(hl)
	ld	c,_CONOUT
	call	DOS
	pop	bc
	pop	hl
	inc	hl
	djnz	DEF12
	print	ONE_NL_S
	print	NR_L_S
	ld	a,30
	ld	(BUFFER),a
	ld	c,_BUFIN
	ld	de,BUFFER
	call	DOS
	ld	a,(BUFFER+1)	
	or	a
	jr	z,DEF10
	ld	a," "
	ld	bc,30-1
	ld	de,Record+06
	ld	hl,Record+05
	ld	(hl),a
	ldir			; clear Record name
	ld	a,(BUFFER+1)
	ld	b,0
	ld	c,a
	ld	hl,BUFFER+2
	ld	de,Record+05
	ldir
	jr	DEF13
DEF10:
	print	LOAD_S

	ld	c,_INNOE
	call	DOS
	cp	"y"
	jr	z,DEF11
	cp	"n"
	jp	z,MainM
	jr	DEF10
DEF11:
	print	ONE_NL_S
	call	LoadImage
	jp	MainM


;-----------------------------------------------------------------------------
LoadImage:
; Erase block's and load ROM-image

; Reopen file image

        ld      bc,24           ; Prepare the FCB
        ld      de,FCB+13
        ld      hl,FCB+12
        ld      (hl),b
        ldir                    ; Initialize the second half with zero
	ld	de,FCB
	ld	c,_FOPEN
	call	DOS		; Open file
	ld      hl,1
	ld      (FCB+14),hl     ; Record size = 1 byte
	or	a
	jr	z,LIF01		; file open
	print	F_NOT_F_S
	ret
LIF01:	ld      c,_SDMA		;
	ld      de,BUFTOP
	call    DOS

	ld	a,(multi)
	or	a
	jp	nz,LIFM1		; no erase!

; 1st operation - erase
	print	FLEB_S
	xor	a
	ld	(EBlock0),a
	ld	a,(Record+02)	; start bloc
	ld	(EBlock),a
	ld	a,(Record+03)	; len b
	or	a
	jp	z,LIF04
	ld	b,a
LIF03:	push	bc
	call	FBerase
	jr	nc,LIF02
	pop	bc			
	print 	FLEBE_S
	jp	LIF04
LIF02:
	ld	a,(EBlock)
	call	HEXOUT
	ld	e," "
	ld	c,_CONOUT
	call	DOS
	pop	bc
	ld	hl,EBlock
	inc	(hl)
	djnz	LIF03

; 2st operation - loading ROM-image to flash
LIFM1:
        ld      a,(ERMSlt)
        ld      h,#40
        call    ENASLT
	ld	a,#14			; #14 #84
	ld	(R2Mult),a		; set 8kB Bank
	ld	a,(Record+02)		; start bloc (absolute block 64kB)
	ld	(EBlock),a
	ld	(AddrFR),a
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT

; set inblock shift
	ld	a,(multi)
	jr	z,LIFM2
	ld	a,(Record+#3D)
	ld	e,a
	and	#0F
	cp	4	; 8 kB
	ld	c,1
	jr	z,LIFM3
	cp	5	; 16 kB
	ld	c,2
	jr	z,LIFM3
	ld	c,4	; 32 kB

LIFM3:
	ld	a,e
	rr	a
	rr	a
	rr	a
	rr	a
	and	#0F
	ld	b,a
	or	a
	ld	a,0
	jr	z,LIFM2
LIFM4:	add	a,c
	dec	b
	jr	nz,LIFM4

LIFM2:	ld	(PreBnk),a



	print	LFRI_S
;calc loading cycles
; Size 3 = 0 ( or oversize )
; Size 2 (x 64 kB ) - cycles for (Eblock) 
; Size 1,0 / 2000h - cycles for FBProg portions

;Size / #2000 
	ld	h,0
	ld	a,(Size+2)
	ld	l,a
	xor	a
	ld	a,(Size+1)
	rl	a
	rl	l
	rl	h	; 00008000
	rl	a
	rl	l
	rl	h	; 00004000
	rl	a
	rl	l
	rl	h	; 00002000
	ld	b,a
	ld	a,(Size)
	or	b
	jr	z,Fpr03
	inc	hl	; rounding up
Fpr03:	ld	(C8k),hl	; save Counter 8kB blocks

Fpr02:	

;load portion from file
	ld	c,_RBREAD
	ld	de,FCB
	ld	hl,#2000
	call	DOS
	ld	a,h
	or	l
	jp	z,Ld_Fail
;program portion
	ld	hl,BUFTOP
	ld	de,#8000
	ld	bc,#2000
 
;      	ld      a,(ERMSlt)
;	ld	e,#94		; sent bank2 to 8kb
;	call	WRTSLT

	call	FBProg2
	jr	c,PR_Fail
	ld	e,"."
	ld	c,_CONOUT
	call	DOS
	ld	a,(PreBnk)
	inc	a		; next PreBnk 
	and	7
	ld	(PreBnk),a	
	jr	nz,FPr01
	ld	hl,EBlock
	inc	(hl)	
FPr01:	ld	bc,(C8k)
	dec	bc
	ld	(C8k),bc
	ld	a,c
	or	b
	jr	nz,Fpr02	


; finish loading ROMimage
; save directory record

        ld      a,(ERMSlt)
        ld      h,#40
        call    ENASLT
	ld	a,#15
	ld	(R2Mult),a		; set 16kB Bank write
	xor	A
	ld	(EBlock),a
	ld	(AddrFR),a
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT
; 
	ld	a,1	
	ld	(PreBnk),a

        ld      a,(ERMSlt)
        ld      h,#80
        call    ENASLT
;
	ld	a,(Record)
	ld	d,a
	call	c_dir		; calc address directory record
	push	ix
	pop	de		; set flash destination
	ld	hl,Record	; set source
	ld	bc,#40		; lenght record
	call	FBProg		; save
	jr	c,PR_Fail
	print	Prg_Su_S
LIF04:
; file close
	ld	de,FCB
	ld	c,_FCLOSE
	call	DOS
	ret
PR_Fail:
	print	FL_erd_S
	jr	LIF04
Ld_Fail:
	print	ONE_NL_S
	print	FR_ER_S
	jr	LIF04

FBProg:
; Block (0..2000h) programm to flash
; hl - buffer sourse
; de = flash destination
; bc - Length
; (Eblock),(Eblock0) - start address in flash
; output CF - flag Programm fail
	exx
        ld      a,(ERMSlt)
        ld      h,#40
        call    ENASLT  
	ld	a,(PreBnk)
	ld	(R2Reg),a
	ld	a,(EBlock)
	ld	(AddrFR),a
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT
        ld      a,(ERMSlt)
        ld      h,#80
        call    ENASLT 
	ld	hl,#8AAA
	ld	de,#8555
	exx
	di
Loop1:
	exx
	ld	(hl),#AA	; (AAA)<-AA
	ld	a,#55		
	ld	(de),a		; (555)<-55
	ld	(hl),#A0	; (AAA)<-A0
	exx
	ld	a,(hl)
	ld	(de),a		; byte programm

	call	CHECK		; check
	jp	c,PrEr
	inc	hl
	inc	de
	dec	bc
	ld	a,b
	or	c
	jr	nz,Loop1
	jr	PrEr

FBProg2:
; Block (0..2000h) programm to flash
; hl - buffer sourse
; de = #8000
; bc - Length
; (Eblock)x64kB, (PreBnk)x8kB(16kB) - start address in flash
; output CF - flag Programm fail
	exx
        ld      a,(ERMSlt)
        ld      h,#40
        call    ENASLT  
	ld	a,(PreBnk)
	ld	(R2Reg),a
	ld	a,(EBlock)
	ld	(AddrFR),a
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT
        ld      a,(ERMSlt)
        ld      h,#80
        call    ENASLT 
	ld	hl,#8AAA
;	ld	de,#8555
	exx
	ld	de,#8000
	di
Loop2:
	exx
	ld	(hl),#50	; double byte programm
	exx
	ld	a,(hl)
	ld	(de),a		; 1st byte programm
	inc	hl
	inc	de
	ld	a,(hl)		; 2nd byte programm
	ld	(de),a
	call	CHECK		; check
	jp	c,PrEr
	inc	hl
	inc	de
	dec	bc
	dec	bc
	ld	a,b
	or	c
	jr	nz,Loop2
PrEr:
;    	save flag CF - fail
	exx
	push	af
	ei
        ld      a,(TPASLOT2)
        ld      h,#80
        call    ENASLT          ; Select Main-RAM at bank 4000h~7FFFh
	pop	af
	exx
	ret

FBerase:
; Flash block erase 
; Eblock, Eblock0 - block address
	ld	a,(ERMSlt)
	ld	h,#40		; Set 1 page
	call	ENASLT
	di
	xor	a
	ld	(AddrM0),a
	ld	a,(EBlock0)
	ld	(AddrM1),a
	ld	a,(EBlock)	; block addres
	ld	(AddrM2),a
	ld	a,#AA
	ld	(#4AAA),a
	ld	a,#55
	ld	(#4555),a
	ld	a,#80
	ld	(#4AAA),a	; Erase Mode
	ld	a,#AA
	ld	(#4AAA),a
	ld	a,#55
	ld	(#4555),a
	ld	a,#30		; Command Erase Block
	ld	(DatM0),a

	ld	a,#FF
    	ld	de,DatM0
    	call	CHECK
;    	save flag CF - erase fail
	push	af
	ei
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT          ; Select Main-RAM at bank 4000h~7FFFh
	pop	af
	ret
;**********************
CHECK:
    	push	bc
    	ld	c,a
CHK_L1: ld	a,(de)
    	xor	c
    	jp	p,CHK_R1    ; Jump if readed bit 7 = written bit 7
    	xor	c
    	and	#20
    	jr	z,CHK_L1    ; Jump if readed bit 5 = 1
    	ld	a,(de)
    	xor	c
    	jp	p,CHK_R1    ; Jump if readed bit 7 = written bit 7
    	scf
CHK_R1:	pop bc
	ret	


FrDIR:
; Search free DIR record
; output A - DIR number

; Set flash configuration
	ld	a,(ERMSlt)
	ld	h,#40		; Set 1 page
	call	ENASLT

	ld	hl,B2ON
	ld	de,CardMDR+#0C	; set Bank2
	ld	bc,6
	ldir
 
	ld	a,(ERMSlt)	; set 2 page
	ld	h,#80
	call	ENASLT
	ld	a,1
	ld	(CardMDR+#0E),a ; set 2nd bank to directory map

	ld	d,0
FRD02:	call	c_dir
	ld	a,(ix)
	cp	#FF
	jr	z,FRD01		; found empty
	inc	d
	jr	nz,FRD02	; next DIR	;
	xor	a
	jr	FRD03		; not found Zero
FRD01:	ld	a,d
	or	a		; not zero
FRD03:	push	af
	ld	a,(TPASLOT1)	; reset 1 page
	ld	h,#40
	call	ENASLT
	ld	a,(TPASLOT2)	; reset 2 page
	ld	h,#80
	call	ENASLT
	pop	af
	ret
SFMR:
; Search Free multi-Rom Flesh-Block
; out	d - record num ix-record
;	a - bank number
;	Flag C- non find nc-find

	ld	a,(ERMSlt)
	ld	h,#40		; Set 1 page
	call	ENASLT

	ld	hl,B2ON
	ld	de,CardMDR+#0C	; set Bank2
	ld	bc,6
	ldir
	ld	a,1
	ld	(CardMDR+#0E),a ; set 2nd bank to directory map

	ld	a,(ERMSlt)	; set 2 page
	ld	h,#80
	call	ENASLT



	ld	d,1
sfr06:	call	c_dir		; output ix - dir point
	jr	nz,sfr01	; valid dir
sfr02:	inc	d
	jp	z,sfr00		; finish directory
	jr	sfr06	
sfr01:	ld	a,(ix+#3D)
	and	#0F
	ld	b,a
	ld	a,(Record+#3D)
	and	#0F
	cp	b
	jr	nz,sfr02
;

	push	de

; print control
;	push	bc
;	push	ix	
;	ld	e,"m"
;	ld	c,_CONOUT
;	call	DOS
;	pop	ix
;	pop	bc

; bank1 to 8kB #6000-7FFF
	ld	a,#04
	ld	(R1Mult),a
	ld	a,#07
	ld	(B1MaskR),a
	ld	a,#60
	ld	(B1AdrD),a
; test free room
	ld	a,(ix+02)	; N Flesh Block
	ld	(AddrFR),a 
	ld	a,b		; size descriptor
	cp	4	; 8 kB
	ld	c,1
	jr	z,sfr10
	cp	5	; 16 kB
	ld	c,2
	jr	z,sfr10
	ld	c,4	; 32 kB
sfr10:
	ld	a,0	; start N place

	ex	af,af'
	ld	e,0	; start n-bank


sfr15:	ld	a,e	
	add	a,c
	ld	d,a	; stop n-bank

srf13:	ld	a,e
	ld	(R1Reg),a 

	ld	hl,#6000
sfr12:	ld	a,(hl)
	inc	a	; FF+1 = 0
	jr	nz,sfr14 ; not clear
	inc	hl
	ld	a,h
	cp	#80
	jr	nz,sfr12 ; next byte
sfr11:			; All byte = FF
	inc	e	;next 8k
	ld	a,e
	cp	d	
	jr	nz,srf13 ; next 8k Bank
; clear space finded
	xor	a
	ld	(AddrFR),a ; set system flesh block
	ld	(R1Reg),a 
	ld	a,#15
	ld	(R1Mult),a
	ld	a,#40
	ld	(B1AdrD),a
	ex	af,af'
	or	a	; clear flag C
	pop	de	
	ret

; non clear block
sfr14:
	ex	af,af'
	inc	a	; next Flashblock place
	ex	af,af'
;	push	de
;	push	bc
;	push	hl
;	dec	a
;	call	HEXOUT
;	ld	e,"<"
;	ld	c,_CONOUT
;	call	DOS
;	pop	hl
;	push	hl
;	ld	a,h
;	call	HEXOUT
;	pop	hl
;	push	hl
;	ld	a,l
;	call	HEXOUT
;	ld	e," "
;	ld	c,_CONOUT
;	call	DOS
;	pop	hl
;	pop	bc
;	pop	de

	ld	e,d	; new start bank = d (top prev)
	ld	a,d
	or	a
	cp	8
	jr	c,sfr15	; next block
	xor	a
	ld	(AddrFR),a ; set system flesh block
	ld	(R1Reg),a 
	ex	af,af'
	pop	de
	jp	sfr02	; next record

sfr00:	; out of directory ( not find )
	xor	a
	ld	(AddrFR),a ; set system flesh block
	ld	(R1Reg),a 
	ld	a,#15
	ld	(R1Mult),a
	ld	a,#40
	ld	(B1AdrD),a
	scf
	ret	
CBAT: 
; compile BAT table ( 8MB/64kB = 128 )

	ld      bc,127	        ; Prepare the BAT
        ld      de,BAT+1
        ld      hl,BAT
        ld      (hl),b
        ldir                    ; Initialize with zero
	

; Set flash configuration
	ld	a,(ERMSlt)
	ld	h,#40		; Set 1 page
	call	ENASLT

;	di
	ld	hl,B2ON
	ld	de,CardMDR+#0C	; set Bank2
	ld	bc,6
	ldir
 
	ld	a,(ERMSlt)	; set 2 page
	ld	h,#80
	call	ENASLT
	xor	a


	ld	a,1
	ld	(CardMDR+#0E),a ; set 2nd bank to directory map

	ld	d,1		; start dir enter
CBT06:	call	c_dir		; output ix - dir point
	jr	nz,CBT01	; valid dir
CBT02:	inc	d
	jr	z,CBT03		; finish dir
	jr	CBT06	
CBT01:	
	ld	a,(ix+02)	; start block
	ld	c,a
	ld	b,0
	ld	hl,BAT
	add	hl,bc		; calc BAT pointer hl
	ld	b,(ix+03)	; len Blocks
CBT04:	xor	a
	cp	b
	jr	z,CBT02		; len 0 - system block
	cp	(hl)
	ld	a,d
	jr	z,CBT05		; empty Block <- DIR number
	ld	a,(hl)		; not empty <- FF (multi ROM)
	or	#80
CBT05:	ld	(hl),a		; save BAT element
	inc	hl
	dec	b		; next BAT
	jr	nz,CBT04
		
	jr	CBT02		; next DIR	

CBT03:				; finish CBAT
	ld	a,(TPASLOT1)	; reset 1 page
	ld	h,#40
	call	ENASLT
	ld	a,(TPASLOT2)	; reset 2 page
	ld	h,#80
	call	ENASLT
	ret
B2ON:	db	#F0,#70,#01,#15,#7F,#80
c_dir:
; input d - dir idex num
; outut	ix - dir point enter
 	ld	b,0
	or	a 
	ld	a,d
	rl	a
	rl	b
	rl	a
	rl	b
	rl	a
	rl	b
	rl	a
	rl	b
	rl	a
	rl	b
	rl	a
	rl	b
	ld	c,a
	ld	ix,#8000
	add	ix,bc	; 8000h + b*64
; test empty/delete
	ld	a,(ix)
	cp	#FF	; empty ?
	ret	z	; RET Z=1
	ld	a,(ix+1)
	or	a	; delete ?
	ret
;-------------------------------
TTAB:
;	ld	b,(DMAP)
	inc	b
	ld	hl,CARTTAB
	ld	de,64
TTAB1:	dec	b
	ret	z
	add	hl,de
	jr	TTAB1




FrErr:
; file close
	ld	de,FCB
	ld	c,_FCLOSE
	call	DOS
; print error
	ld	de,FR_ER_S
	ld	c,_STROUT
	call	DOS
; return main	
	jp	MainM		

Exit:	ld	de,EXIT_S
	jp	termdos



;-----------------------------------------------------------------------------

FnameP:
; File Name prepearing
; input	ix - buffer file name
; outut - FCB	
	ld	b,8+3
	ld	HL,FCB
	ld	(hl),0
fnp3:	inc	hl
	ld	(hl)," "
	djnz	fnp3	

        ld      bc,24           ; Prepare the FCB
        ld      de,FCB+13
        ld      hl,FCB+12
        ld      (hl),b
        ldir                    ; Initialize the second half with zero
;
; File name processing
	ld	hl,FCB+1
;	ld	ix,BUFFER

	ld	b,8
	ld	a,(ix+1)
	cp	":"
	jr	nz,fnp0
;       device name
	ld	a,(ix)
	and	a,%11011111
	sub	#40
	ld	(FCB),a
	inc	ix
	inc	ix
;	file name
fnp0:	ld	a,(ix)
	or	a
	ret	z
	cp	"."
	jr	z,fnp1
	ld	(hl),a
	inc	ix
	inc	hl
	djnz	fnp0
	ld	a,(ix)
	cp	"."
	jr	z,fnp1
	dec	ix
;	file ext
fnp1:
	ld	hl,FCB+9
	ld	b,3
fnp2:	ld	a,(ix+1)
	or 	a
	ret	z
	ld	(hl),a
	inc	ix
	inc	hl
	djnz	fnp2	

	ret

FindSlot:
; Auto-detection 
	ld	ix,TRMSlt	; Tabl Find Slt cart
        ld      b,3             ; B=Primary Slot
BCLM:
        ld      c,0             ; C=Secondary Slot
BCLMI:
        push    bc
        call    AutoSeek
        pop     bc
        inc     c
	bit	7,a	
	jr      z,BCLM2		; not extend slot	
        ld      a,c
        cp      4
        jr      nz,BCLMI        ; Jump if Secondary Slot < 4
BCLM2:  dec     b
        jp      p,BCLM          ; Jump if Primary Slot < 0
	ld	a,#FF
	ld	(ix),a		; finish autodetect
; slot analise
	ld	ix,TRMSlt
	ld	a,(ix)
	or	a
	jr	z,BCLNS		; No Detect
; print slot table
	ld	(ERMSlt),a	; save first detect slot
	print Findcrt_S
BCLT1:	ld	a,(ix)
	cp	#FF
	jr	z,BCLTE
	and	3
	add	a,"0"
	ld	c,_CONOUT
	ld	e,a
	call	DOS		; print praimary slot number
	ld	a,(ix)
	bit	7,a
	jr	z,BCLT2		; no extended
	rrc	a
	rrc	a
	and	3
	add	a,"0"
	ld	e,a
	ld	c,_CONOUT
	call	DOS		; print extended slot number
BCLT2:	ld	e," "
	ld	c,_CONOUT
	call	DOS	
	inc	ix
	jr	BCLT1

BCLTE:
	print FindcrI_S
	jp	BCLNE
BCLNS:
;
	print	NSFin_S
BCLNE:
; input slot number
	ld	de,Binpsl
	ld	c,_BUFIN
	call	DOS
	ld	a,(Binpsl+1)
	or	a
	jr	z,BCTSF		; no input slot
	ld	a,(Binpsl+2)
	sub	a,"0"
	and	3
	ld	(ERMSlt),a
	ld	a,(Binpsl+1)
	cp	2
	jr	nz,BCTSF	; no extended
	ld	a,(Binpsl+3)
	sub	a,"0"
	and	3
	rlc	a
	rlc	a
	ld	hl,ERMSlt
	or	(hl)
	or	#80
	ld	(hl),a	

BCTSF:
; test flash
;*********************************
	ld	a,(ERMSlt)
;TestROM:
	ld	(cslt),a
	ld	h,#40
	call	ENASLT
	ld	a,#95		; enable write  to bank (current #85)
	ld	(R1Mult),a  

	di
	ld	a,#AA
	ld	(#4AAA),a
	ld	a,#55
	ld	(#4555),a
	ld	a,#90
	ld	(#4AAA),a	; Autoselect Mode ON

	ld	a,(#4000)
	ld	(Det00),a	; Manufacturer Code 
	ld	a,(#4002)
	ld	(Det02),a	; Device Code C1
	ld	a,(#401C)
	ld	(Det1C),a	; Device Code C2
	ld	a,(#401E)
	ld	(Det1E),a	; Device Code C3
	ld	a,(#4006)
	ld	(Det06),a	; Extended Memory Block Verify Code

	ld	a,#F0
	ld	(#4000),a	; Autoselect Mode OFF
	ei
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT          ; Select Main-RAM at bank 4000h~7FFFh

	
; Print result
	
	print 	SltN_S
	ld	a,(cslt)
	ld	b,a
	cp	#80
	jp	nc,Trp01	; exp slot number
	and	3
	jr	Trp02
Trp01:	rrc	a
	rrc	a
	and	%11000000
	ld	c,a
	ld	a,b
	and	%00001100
	or	c
	rrc	a
	rrc	a
Trp02:	call	HEXOUT	
	print	CRLF_S

	print	MfC_S
	ld	a,(Det00)
	call	HEXOUT
	print	CRLF_S

	print	DVC_S
	ld	a,(Det02)
	call	HEXOUT
	ld	e," "
	ld	c,_CONOUT
	call	DOS	
	ld	a,(Det1C)
	call	HEXOUT
	ld	e," "
	ld	c,_CONOUT
	call	DOS
	ld	a,(Det1E)
	call	HEXOUT
	print	CRLF_S

	print	EMB_S
	ld	a,(Det06)
	call	HEXOUT
	print	CRLF_S

	ld	a,(Det00)
	cp	#20
	jr	nz,Trp03	
	ld	a,(Det02)
	cp	#7E
	jr	nz,Trp03
	print	M29W640
	ld	e,"x"
	ld	a,(Det1C)
	cp	#0C
	jr	z,Trp05
	cp	#10
	jr	z,Trp08
	jr	Trp04
Trp05:	ld	a,(Det1E)
	cp	#01
	jr	z,Trp06
	cp	#00
	jr	z,Trp07
	jr	Trp04
Trp08:	ld	a,(Det1E)
	cp	#01
	jr	z,Trp09
	cp	#00
	jr	z,Trp10
	jr	Trp04
Trp06:	ld	e,"H"
	jr	Trp04
Trp07:	ld	e,"L"
	jr	Trp04
Trp09:	ld	e,"T"
	jr	Trp04
Trp10:	ld	e,"B"
Trp04:	ld	c,_CONOUT
	call	DOS
	print	CRLF_S

	ld	a,(Det06)
	cp	80
	jp	c,Trp11		
	print	EMBF_S
	xor	a
	ret
Trp11:
	print	EMBC_S	
	xor	a
	ret	
Trp03:
	print	NOTD_S
	scf
	ret

;---- Out to conlose HEX byte
; A - byte
HEXOUT:
	push	af
	rrc	a
	rrc	a
	rrc	a
	rrc	a
	and	#0F
	ld	b,0
	ld	c,a
	ld	hl,ABCD
	add	hl,bc
	ld	e,(hl)
	ld	c,_CONOUT
	call	DOS
	pop	af
	and	#0F
	ld	b,0
	ld	c,a
	ld	hl,ABCD
	add	hl,bc
	ld	e,(hl)
	ld	c,_CONOUT
	call	DOS
	ret
HEX:
;--- HEX
; input  a- Byte
; output a - H hex symbol
;        b - L hex symbol
	ld	c,a
	and 	#0F
	add	a,48
	cp	58
	jr	c,he2
	add	a,7
he2:	ld	b,a
	ld	a,c
	rrc     a
	rrc     a
	rrc     a
	rrc     a
	and 	#0F
	add	a,48
	cp	58
	ret	c
	add	a,7	
   	ret




NO_FND:
;;;;;;;;;;;;;;;;;;;;;
AutoSeek:
; return reg A - slot
;	    
;	     

	ld	a,b
	xor	3		; Reverse the bits to reverse the search order (0 to 3)
	ld	hl,MNROM
	ld	d,0
	ld	e,a
	add	hl,de
	bit	7,(hl)
	jr	z,primSlt	; Jump if slot is not expanded
	or	(hl)		; Set flag for secondary slot
	sla	c
	sla	c
	or	c		; Add secondary slot value to format FxxxSSPP
primSlt:
	ld	(ERMSlt),a
; ---
;	ld	b,a		; Keep actual slot value
;
;	bit	7,a
;	jr	nz,SecSlt	; Jump if Secondary Slot
;	and	3		; Keep primary slot bits
;SecSlt:
;	ld	c,a
;
;	ld	a,b		; Restore actual slot value
; ---
	ld	h,#40
	call	ENASLT		; Select a Slot in Bank 1 (4000h ~ 7FFFh)

	ld	hl,ADESCR
	ld	de,DESCR
	ld	b,7
ASt00	ld	a,(de)
	cp	(hl)
	ret	nz
	djnz	ASt00
	ld	a,(ERMSlt)
	ld	(ix),a
	inc	ix
	ret
;**********************************************************************
;* Menu Utilites
;********************************************************************** 
UTIL:
	print	UTIL_S
UT01:	ld	c,_INNOE
	call	DOS
	cp	"1"
	jp	z,D_Compr
	cp	"2"
	jp	z,DIRINI
	cp	"3"
	jp	z,BootINI
	cp	27
	jp	z,MainM
	cp	"0"
	jp	z,MainM
	jr	UT01	
D_Compr:
	print	DirComr_S
DCMPR1:	ld	c,_INNOE
	call	DOS
	cp	"y"
	jr	z,DCMPR2
	cp	"n"
	jp	z,MainM
	jr	DCMPR1
DCMPR2:	call	CmprDIR
	jr	UTIL
CmprDIR:
; Compress directory 
; Set flash configuration
	ld	a,(ERMSlt)
	ld	h,#40		; Set 1 page
	call	ENASLT

	ld	hl,B2ON
	ld	de,CardMDR+#0C	; set Bank2
	ld	bc,6
	ldir
 
	ld	a,(ERMSlt)	; set 2 page
	ld	h,#80
	call	ENASLT
	ld	a,1
	ld	(CardMDR+#0E),a ; set 2nd bank to directory map

        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT
; copy valid record 1st 8kB
	xor	a
	ld	(Dpoint+2),a		; start number record
	ld	hl,#8000
	ld	(Dpoint),hl

CVDR:
;
; clear buffer #FF
	ld	bc,#2000-1
	ld	hl,BUFTOP
	ld	de,BUFTOP+1
	ld	a,#FF
	ld	(hl),a
	ldir
; copy valid dir record -  to BUFFTOP
	ld	de,BUFTOP
	ld	hl,(Dpoint)
CVDR2:	ld	a,(hl)	
	inc	hl
	cp	#FF		; b1 empty ?
	jr	z,CVDR1		; empty
	ld	a,(hl)
	cp	#FF		; b2 erase ?
	jr	nz,CVDR1	; erase
	ld	bc,#3F		; not empty not erase -> copy		
	ld	a,(Dpoint+2)	;
	ld	(de),a		; 1st byte = new number record
	inc	a
	ld	(Dpoint+2),a	; increment number
	inc	de	
	ldir			; copy other bytes from old record
	ld	(Dpoint),hl	; save sourse pointer		
	bit	7,a		; if numper >= 80 (half table)
	jr	nz,CVDR4 	; next 8Kb 
CVDR3:	ld	a,h
	cp	#C0	 	; out or range directory #C000 address
	jr	c,CVDR2		; go to next record
	jr	CVDR4  		; finish copy
CVDR1:	ld	bc,#3F		; skipping record
	add	hl,bc		; hl = hl + #3F
	ld	(Dpoint),hl	; save sourse pointer	
	jr	CVDR3		; go to test tabl ending
CVDR4:
; save 1-st 8k directory



;  clear (1/2)
	xor	a
	ld	(EBlock),a
	ld	a,#40
	ld	(EBlock0),a
	call	FBerase
;  programm (1/2)
	xor	a
	ld	(EBlock),a
	inc	a
	ld	(PreBnk),a
	ld	hl,BUFTOP
	ld	de,#8000
	ld	bc,#2000
	call	FBProg
; clear buffer #FF
	ld	bc,#2000-1
	ld	hl,BUFTOP
	ld	de,BUFTOP+1
	ld	a,#FF
	ld	(hl),a
	ldir
; Set flash configuration
	ld	a,(ERMSlt)
	ld	h,#40		; Set 1 page
	call	ENASLT

	ld	hl,B2ON
	ld	de,CardMDR+#0C	; set Bank2
	ld	bc,6
	ldir
 
	ld	a,(ERMSlt)	; set 2 page
	ld	h,#80
	call	ENASLT
	ld	a,1
	ld	(CardMDR+#0E),a ; set 2nd bank to directory map

        ld      a,(TPASLOT1)
        ld      h,#40

; 2-nd 8kB block directory
	ld	a,(Dpoint+2)
	bit	7,a
	jr	z,CVDR20	; no 2-nd Block

;  copy valid record 2-nd 8kB
; de - new TOPBUFF
; hl - continue directory >= A000	
	ld	de,BUFTOP
	ld	hl,(Dpoint)
	ld	a,h
	cp	#C0
	jr	nc,CVDR20
CVDR12:	ld	a,(hl)	
	inc	hl
	cp	#FF
	jr	z,CVDR11
	ld	a,(hl)
	cp	#FF
	jr	nz,CVDR11
	ld	bc,#3F
	ld	a,(Dpoint+2)
	ld	(de),a
	inc	a
	ld	(Dpoint+2),a
	inc	de
	ldir
CVDR13:	ld	(Dpoint),hl	
	ld	a,h
	cp	#C0	 	; out or range directory
	jr	c,CVDR12
	jr	CVDR20    		; finish copy
CVDR11:	ld	bc,#3F
	add	hl,bc

	jr	CVDR13

CVDR20:

;  clear (2/2)
	xor	a
	ld	(EBlock),a
	ld	a,#60
	ld	(EBlock0),a
	call	FBerase
;  programm (2/2)
	ld	hl,BUFTOP
	ld	de,#A000
	ld	bc,#2000
	call	FBProg
;  clear autostart
	xor	a
	ld	(EBlock),a
	ld	a,#80
	ld	(EBlock0),a
	call	FBerase

	ret

;**********************************************************
; Listing records for choose operations
;
;
;
ListRec:
; set 2 page - directory
	call	SET2PD
	xor	a
	ld	(strp),a	; record num for 1st str
Pagep:
	print	CLS_S
; print header message
	print	CRD_S
	
	ld	e,0		; current str
	ld	a,(strp)
	ld	d,a
; calc dir enter point
sPrr1:	call 	c_dir		; input d, output ix
	jr	nz,prStr	; valid dir enter
nRec:	inc	d
	jp	z,dRec	; done, last record
	jr	sPrr1
prStr:
; print str
	push	de

; posit str
;CSRY	equ	#F3DC
;CSRX	equ	#F3DD
	ld	h,1
	ld	a,e
	add	a,6
	ld	l,a
	ld	(CSRY),hl
; print
	ld	(strI),ix
	ld	a,d
	call	HEXOUT		
	ld	e," "		
	ld	c,_CONOUT
	call	DOS

;	ld	a,(strI+1)
;	call	HEXOUT		
;	ld	a,(strI)
;	call	HEXOUT		
;	ld	e," "		
;	ld	c,_CONOUT
;	call	DOS
;
;
;	ld	hl,(strI)
;	ld	a,(hl)
;	call	HEXOUT		; print hex number
;	ld	e," "		; space symbol
;	ld	c,_CONOUT
;	call	DOS

	ld	hl,(strI)	; t-symbol
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	(strI),hl
	ld	e,(hl)
	ld	c,_CONOUT
	call	DOS	
	ld	e," "		; space symbol
	ld	c,_CONOUT
	call	DOS
	ld	hl,(strI)
	inc	hl
	ld	de,BUFFER
	ld	bc,26
	ldir			; extract record name
	ld	a,"$"
	ld	(de),a
	print	BUFFER

	pop	de

	inc	d
	jr	z,dRec	; last dir
	inc	e
	ld	a,e	; last str
	cp	L_STR
	jp	c,sPrr1
dRec:
	ld	e,0
	ld	a,(strp)
	ld	d,a
CH00:
; cursor processing
	ld	h,3
	ld	a,e
	add	a,6
	ld	l,a
	ld	(CSRY),hl
	push	de
	push	hl
	ld	e,"*"
	ld	c,_CONOUT
	call	DOS
	pop	hl	
	pop	de
	ld	(CSRY),hl
CH01:
; key processing
	push	de
	ld	c,_INNOE
	call	DOS
	pop	de
	cp	27	; ESC
	jp	z,LST_EX
	cp	30	; UP
	jp	z,C_UP
	cp	31	; down
	jp	z,C_DOWN
	cp	29	; LEFT
	jp	z,P_B
	cp	28	; RIGTH
	jp	z,P_F
	cp	"D"
	jp	z,R_DEL ; record delete
	cp	"E"
	jp	z,R_EDIT ; record editor
	jr	CH01

C_UP:
; cursor up (previous str select)
	ld	a,e
	or	a
	jr	z,CH01 ; 1-st str
	push	de
	ld	e," "
	ld	c,_CONOUT
	call	DOS
	pop	de
C_U00:	dec	e
C_U01:	dec	d
	ld	a,#FF
	cp	d
	jp	z,C_D00
	call	c_dir
	jr	z,C_U01
	jp	CH00

C_DOWN:
; cursor down (next str select)
	ld	a,e
	cp	L_STR-1
	jr	nc,CH01	; last str
	push	de
	ld	e," "
	ld	c,_CONOUT
	call	DOS
	pop	de
C_D00:	inc	e
C_D01:	inc	d
	ld	a,#FF
	cp	d
	jp	z,C_U00
	call	c_dir
	jr	z,C_D01
	jp	CH00
P_F:
; Page Forward
	ld	a,(strp)
	ld	d,a	; extract 1st page
; next N str
	ld	e,L_STR
PF01:	inc	d
	ld	a,#FF
	cp	d
	jp	z,Pagep	; out of dir
	call	c_dir
	jr	z,PF01	; empty/delete
	dec	e
	jr	nz,PF01
;  save new start d
	ld	a,d
	ld	(strp),a
	jp	Pagep
P_B:
; Page Back
	ld	a,(strp)
	ld	d,a	; extract 1st page
; previos N str
	ld	e,L_STR
PB01	dec	d
	ld	a,#FF
	cp	d
	jr	z,PB02	; out of dir
	call	c_dir
	jr	z,PB01
	dec	e
	jr	nz,PB01
;  save new start d
PB03:	ld	a,d
	ld	(strp),a
	jp	Pagep
PB02:	ld	d,0
	jp	PB03

; Record delete
R_DEL:
	push	de
	ld	hl,256+23
	ld	(CSRY),hl	
	ld	a,d
	call	HEXOUT

	print	RDELQ_S

	ld	c,_INNOE
	call	DOS
	cp	"y"
	pop	de
	jp	nz,Pagep	; no delete

	call	c_dir
	push	ix
	pop	de
	inc	de		; dest byte record+1
	ld	bc,1		; 1 byte programming
	ld	hl,ZiroB	; source byte=0
	xor	a
	ld	(EBlock),a	; Block = 0 system (x 64kB)
	inc	a
	ld	(PreBnk),a	; Bank=1 (x 16kB)
	call	FBProg		; exeCute
	push	de

	call	SET2PD

	pop	de
	jp	Pagep

LST_EX:
; Exit Record list
	ld	a,(TPASLOT2)
	ld	h,#80
	call	ENASLT	; reset slot 2 (added by Alexey)
	print	CLS_S
	jp	MainM



SET2PD:
	ld	a,(ERMSlt)
	ld	h,#40		; Set 1 page
	call	ENASLT

	ld	hl,B2ON
	ld	de,CardMDR+#0C	; set Bank2
	ld	bc,6
	ldir
 
	ld	a,(ERMSlt)	; set 2 page
	ld	h,#80
	call	ENASLT
	ld	a,1
	ld	(CardMDR+#0E),a ; set 2nd bank to directory map

        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT
	ret

;*********************************************************************
R_EDIT
;*********************************************************************
	push	de
; copy record data to buffer
	ld	(BUFFER),de
	call	c_dir
	push	ix
	pop	hl
	ld	de,BUFFER+2
	ld	bc,#40
	ldir
	pop	de
	push	de
	call	Redit
	jp	z,E_RD0
; get free directory element
E_RD3:	call	FrDIR
	jr	nz,E_RD1
	print	DirOver_S
E_RD2:	ld	c,_INNOE
	call	DOS
	cp	"n"
	jp	z,E_RD0
	cp	"Y"
	jr	nz,E_RD2
	call	CmprDIR
	jr	E_RD3
E_RD1:
; save new record
	ld	(BUFFER+2),a	; new record number

        ld      a,(ERMSlt)
        ld      h,#40
        call    ENASLT
	ld	a,#15
	ld	(R2Mult),a		; set 16kB Bank write
	xor	A
	ld	(EBlock),a
	ld	(AddrFR),a
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT
; 
	ld	a,1	
	ld	(PreBnk),a

        ld      a,(ERMSlt)
        ld      h,#80
        call    ENASLT

	push	ix
	pop	hl
	ld	(BUFFER+2+#40),hl	;save old record address

	ld	a,(BUFFER+2)
	ld	d,a
	call	c_dir
	push	ix
	pop	de
	ld	hl,BUFFER+2
	ld	bc,#40
	call	FBProg
	jr	nc,E_RD4
	print	FL_erd_S
	jr	E_RD0
E_RD4:	
	print	QDOR_S
E_RD5:	ld	c,_INNOE
	call	DOS
	cp	"n"
	jr	z,E_RD0
	cp	"y"
	jr	nz,E_RD5
; delete old record
	ld	de,(BUFFER)
	call	c_dir
	push	ix
	pop	de
	inc	de
	ld	bc,1
	ld	hl,ZiroB
	xor	a
	ld	(EBlock),a
	inc	a
	ld	(PreBnk),a
	call	FBProg
	
E_RD0:
;	ld	hl,(BUFFER+2+#40)
;	push	hl
;	pop	ix
	call	SET2PD
	pop	de
	jp	Pagep




Redit:
	push	de
; drawing edit screen
	print	CLS_S	
	print	RPE_S
	pop	de
	ld	a,d
	call	HEXOUT
	ld	e,1
rdt01:
	call	c_emdi		; iy calc edit element addres	
	ld	a,(iy)		
	ld	(CSRY),a	; set y coordinate cursor
	ld	a,(iy+1)
	ld	(CSRX),a	; set x coordinate cursor
	ld	l,(iy+2)
	ld	h,(iy+3)	; get buffer adress data element
	ld	a,(iy+4)	; get type element
	or	a		; 0 - empty
	jp	z,rdt04	;done
	cp	1		; record name element
	jr	z,rdt02	
	cp	2		; record descriptor element
	jr	z,rdt03
	cp	3		; text print
	jr	z,rdt06
				; other element (hexbyte print)
	ld	a,(hl)
	call	HEXOUT
	jr	rdt04
rdt02:				; record name to display
	ld	b,30
rdt05:	ld	e,(hl)
	push	bc
	push	hl
	ld	c,_CONOUT	
	call	DOS
	pop	hl
	pop	bc
	inc	hl
	djnz	rdt05
	jr	rdt04
rdt03:				; descriptor
	ld	a,(hl)
	push	hl
	call	HEXOUT
	ld	e,"-"
	ld	c,_CONOUT	
	call	DOS
	pop	hl
	ld	e,(hl)	
	ld	c,_CONOUT	
	call	DOS
	jr	rdt04
rdt06:				; text element
	ex	hl,de
	ld	c,_STROUT
	call	DOS

rdt04:	ld	a,(iy+5)	; next element
	ld	e,a
	or	a
	jp	nz,rdt01

; edit cycle

; 1 level menu
rdt08:	call	CLSM
	ld	hl,#0103
	ld	(CSRY),hl
	print	M_CTS
	ld	hl,#0103
rdt09:	ld	(CSRY),hl
rdt10:	push	hl
	ld	c,_INNOE
	call	DOS
	pop	hl
	cp	30	;UP
	jr	z,rdt11
	cp	31	;DOWN
	jr	z,rdt12
	cp	27	;ESC
	jr	z,rdt13
	cp	" "	;SPACE
	jr	z,rdt14
	cp	#0D
	jr	z,rdt14
;	push	hl
;	call	HEXOUT
;	pop	hl
	jr	rdt10

rdt11:;UP
	ld	a,l
	cp	4
	jr	c,rdt10
	dec	l
	jr	rdt09
rdt12:;DOWN
	ld	a,l
	cp	7
	jr	nc,rdt10
	inc	l
	jr	rdt09
rdt13:;ESC
	call	CLSM
	ld	hl,#0105
	ld	(CSRY),hl
	print	EWS_S
	ld	c,_INNOE
	call	DOS
	cp	"y"
	ret	z
	jp	rdt08
		
rdt14:;GO
	ld	a,l
	cp	3	; rename
	jr	z,rdt16
	cp	4	; preset
	JP	Z,rdt20
	cp	5	; edit
	jp	z,rdte01
	cp	6
	jr	z,rdt15 ; save and exit
	cp	7
	jr	z,rdt13 ; quit ws save
	jp	rdt10

rdt15:;Save end exit (save late)
	call	CLSM
	ld	hl,#0105
	ld	(CSRY),hl
	print	SAE_S
	ld	c,_INNOE
	call	DOS
	cp	"y"
	jp	nz,rdt08
	cp	#FF	; set C,nZ
	ret		
rdt16:;Rename record
	call	CLSM
	ld	hl,#0105
	ld	(CSRY),hl
	print	ENNR_S
; prepare buffer
	ld	a,30
	ld	b,0
	ld	c,a
	ld	de,BUFFER+2+#40	
	ld	(de),a
;	inc	de
;	ld	(de),a
;	inc	de
;	ld	hl,BUFFER+2+5
;	ldir
	ld	de,BUFFER+2+#40	
	ld	c,_BUFIN
	call	DOS
	ld	a,(BUFFER+2+#40+1)
	or	a
	ld	c,a
	ld	b,0
	jp	z,rdt08	; empty buffer? exit
; clear name
	ld	e,30
	ld	a," "
	ld	hl,BUFFER+2+5
rdt18	ld	(hl),a
	inc	hl
	dec	e
	jr	nz,rdt18
; copy name
	ld	hl,BUFFER+2+#40+2
	ld	de,BUFFER+2+5
	ldir
	jp	Redit	
rdt20:
; preset type cartrige
	print	CLS_S	
	print	PTC_S
	ld	hl,#0303
	ld	de,CARTTAB+1
rdt21:	ld	(CSRY),hl
	call	PRDE		; print 5 type
	ex	hl,de
	ld	bc,#40
	add	hl,bc
	ex	hl,de
	inc	l
	ld	a,l
	cp	3+6
	jr	c,rdt21	

	ld	de,PTCUL_S
	ld	(CSRY),hl
	call	PRDE		; print user type load
	inc	l

	ld	de,PTCE_S	; quit element
	ld	(CSRY),hl
	call	PRDE

	ld	hl,#0103
rdt24:	ld	(CSRY),hl	
rdt27:	push	hl
	ld	c,_INNOE
	call	DOS
	pop	hl

	cp	30	;UP
	jr	z,rdt22
	cp	31	;DOWN
	jr	z,rdt23
	cp	27	;ESC
	jp	z,Redit
	cp	" "	;SPACE
	jr	z,rdt25
	cp	#0D
	jr	z,rdt25
	jr	rdt27
rdt22:;UP
	ld	a,l
	cp	4
	jr	c,rdt27
	dec	l
	jr	rdt24
rdt23:;DWON
	ld	a,l
	cp	4+6
	jr	nc,rdt27
	inc	l
	jr	rdt24	
rdt25:;GO
	ld	a,l
	cp	3
	ld	hl,CARTTAB
	jr	z,rdt30
	cp	4
	ld	hl,CRTT1
	jr	z,rdt30
	cp	5
	ld	hl,CRTT2
	jr	z,rdt30
	cp	6
	ld	hl,CRTT3
	jr	z,rdt30
	cp	7
	ld	hl,CRTT4
	jr	z,rdt30
	cp	8
	ld	hl,CRTT5
	jr	z,rdt30
	cp	9		; load from file

	jp	Redit
rdt30:;copy set
	ld	a,(hl)
	ld	(BUFFER+2+4),a
	ld	bc,35
	add	hl,bc
	ld	de,BUFFER+2+#23
	ld	bc,#40-#23
	ldir 
; select start metod
	print	CLS_S	
	print	SSM_S
	ld	hl,#0303
	ld	(CSRY),hl	
	ld	de,ssm01
	call	PRDE
	inc	hl	
	ld	(CSRY),hl	
	ld	de,ssm02
	call	PRDE
	inc	hl
	ld	(CSRY),hl	
	ld	de,ssm03
	call	PRDE
	ld	hl,#0103
	ld	de,#0200
	call	SELM
	ld	b,1	; start on reset
	cp	1
	jr	z,rdt31
	ld	b,0	; no start
	cp	2
	jr	z,rdt31
	ld	b,2	; start #4000
rdt31:	ld	a,b
	ld	(BUFFER+2+#3E),a
; select adress ROM start
	bit	1,a
	jr	z,rdt36	; no start address
	ld	hl,#0106
	ld	de,SSA_S
	call	PRDE
	ld	hl,#0307
	ld	de,ssa01
	call	PRDE
	inc	l
	ld	de,ssa02
	call	PRDE
	inc	l
	ld	de,ssa03
	call	PRDE
	ld	hl,#0108
	ld	de,#0201
	call	SELM
	cp	0
	jr	z,rdt37
	cp	2
	jr	z,rdt38
	jr	rdt36	
rdt37:
	ld	hl,BUFFER+2+#3E
	set	2,(HL)
	jr	rdt36	
rdt38:
	ld	hl,BUFFER+2+#3E
	set	3,(HL)
rdt36:
	ld	a,(BUFFER+2+#3D) ; mini multirom status
; select size ROM-Image
	and	#07
	jr	z,rdt40		; Mapper RON, not select size

	ld	hl,#010A
	ld	de,SSR_S
	call	PRDE
	ld	hl,#030B
	ld	de,ssr64
	call	PRDE
	inc	l
	ld	de,ssr48
	call	PRDE
	inc	l
	ld	de,ssr32
	call	PRDE
	inc	l
	ld	de,ssr16
	call	PRDE
	inc	l
	ld	de,ssr08
	call	PRDE
	ld	hl,#010B
	ld	de,#0400
	call	SELM
	ld	b,#0E
	cp	1
	jr	z,rdt39
	ld	b,6
	cp	2
	jr	z,rdt39
	ld	b,5
	cp	3
	jr	z,rdt39
	ld	b,4
	cp	4
	jr	z,rdt39
	ld	b,7
rdt39:	ld	a,(BUFFER+2+#3D)
	and	#F0
	or	b
	ld	(BUFFER+2+#3D),a	
rdt40:
; select place ROM-Image 0000h/4000h/8000h/
	and	7
	jr	z,rdt60	; mapper ROM, not selected place

	ld	hl,#0111
	ld	de,SRL_S
	call	PRDE
	ld	hl,#0312
	ld	de,ssa01
	call	PRDE
	inc	l
	ld	de,ssa02
	call	PRDE
	inc	l
	ld	de,ssa03
	call	PRDE

	ld	hl,#0113
	ld	de,#0201
	call	SELM
; 0 - #0000, 1-#4000 2 -#8000
	cp	27
	jr	z,rdt50
	ld	b,#00
	or	a
	jr	z,rdt48
	ld	b,#80
	cp	2
	jr	z,rdt48
	ld	b,#40
rdt48:	ld	a,b
	ld	(BUFFER+2+#28),a
			

; select place in FleshBlock
rdt50:	ld	hl,#0115
	ld	de,SFL_S
	call	PRDE
	ld	a,1
	ld	de,BUFFER+2+#40	
	ld	(de),a
	ld	c,_BUFIN
	call	DOS
	ld	a,(BUFFER+2+#40+1)
	or	a
	jr	z,rdt60
	ld	a,(BUFFER+2+#40+2)
	sub	"0"
	jr	c,rdt50
	cp	8
	jr	nc,rdt50
	or	a
	rr	a
	rr	a
	rr	a
	rr	a
	ld	b,a
	ld	a,(BUFFER+2+#3D)
	and	a,%10001111
	or	b
	ld	(BUFFER+2+#3D),a
rdt60:
	ld	a,(BUFFER+2+#3D)
; tuning cardregister
	ld	b,a
	and	7
	jr	z,rdt80	; no tuning
; set bank size
	ld	c,a
	ld	hl,(BUFFER+2+#26)	; R1Mult	
	ld	a,7
	and	(hl)
	or	c
	ld	(hl),a
	bit	3,b
	jr	z,rdt61	; not 48kb	
; 2 bank, only for 48 kb
	ld	a,#05
	ld	(BUFFER+2+#2C),a	; set on 2-bank 16kb
	ld	a,2
	ld	(BUFFER+2+#2B),a	; (0,1) = (0)B1/32, (2)B2/16
	ld	a,(BUFFER+2+#28)
	add	a,#80
	ld	(BUFFER+2+#2E),a	; set addr 2-bank
rdt61:	

rdt80:
	jp	Redit


;select menu
; input D - max element E-start element
; h - horizontal posit	l-start verlical posit
; output a-number menu or 27(no select exit)
SELM:	
selm0:	ld	(CSRY),hl
	push	hl
	push	de
	ld	c,_INNOE
	call	DOS
	pop	de
	pop	hl
	cp	30	;UP
	jr	z,selmU
	cp	31	;DOWN
	jr	z,selmD
	cp	27	;ESC
	ret	z
	cp	" "	;SPACE
	jr	z,selmG
	cp	#0D	;Enter
	jr	z,selmG
	jr	selm0
selmU:	ld	a,e
	or	a
	jr	z,selm0
	dec	e
	dec	l
	jr	selm0
selmD:	ld	a,e
	cp	d
	jr	nc,selm0
	inc	e
	inc	l
	jr	selm0
selmG:	
	push	hl
	push	de
	ld	e,"*"
	ld	c,_CONOUT
	call	DOS
	pop	de
	pop	hl
	ld	a,e
	ret
PRDE:
	push	hl
	push	de
	ld	(CSRY),hl	
	ld	c,_STROUT
	call	DOS
	pop	de
	pop	hl
	ret
CLSM:
; clear menu area	
	ld	hl,#0102
CLSM0:	ld	a,l
	cp	10
	ret	nc
	ld	(CSRY),hl
	push	hl
	print	CLStr_S
	pop	hl	
	inc	l
	jr	CLSM0
c_emdi:
	push	de
	ld	bc,14	; size edit menu element
	ld	iy,Temdi
cemdi1:	dec	e
	jr	z,cemdi2
	add	iy,bc	
	jr	cemdi1
cemdi2:	pop	de
	ret
;
; card register editor
;
rdte01:
	call	CLSM
	ld	hl,#0105
	ld	de,GHME	; general help
	ld	(CSRY),hl	
	ld	c,_STROUT
	call	DOS	

	ld	e,1	;(first element)

rdte04:	call	c_emdi
; clear context help area
rdte04a:
	call	CCHA
; print context help
	ld	hl,#0100+22
	ld	d,(iy+13)
	ld	e,(iy+12)
	ld	(CSRY),hl	
	ld	c,_STROUT
	call	DOS	
; key processing	
rdte05:
	ld	l,(iy)
	ld	h,(iy+1)
	ld	(CSRY),hl	
	ld	c,_INNOE
	call	DOS
	ld	e,(iy+6)
	cp	30	;UP
	jp	z,rdte06
	ld	e,(iy+7)
	cp	31	;DOWN
	jp	z,rdte06
	ld	e,(iy+8)
	cp	29	;LEFT
	jp	z,rdte06
	ld	e,(iy+9)
	cp	28	;RIGHT
	jp	z,rdte06
	cp	27	;ESC
	jp	z,rdte80
	cp	" "	;SPACE
	jp	z,rdte10 ; extend element edit
	cp	#0D
	jp	z,rdte10
; check byte protect
	ld	b,a
	ld	a,(protect)
	or	a
	jr	z,rdte09
	ld	a,(iy+10)
	or	a
	jr	nz,rdte11
rdte09:	ld	a,b
; process hex input
	ld	e,a
	call	HEXA	
	jr	c,rdte05	;not hex symbol
	rl	a
	rl	a
	rl	a
	rl	a
	ld	(BUFFER+2+#40),a
	ld	c,_CONOUT
	call	DOS
; process second hex digit
rdte07:	ld	c,_INNOE
	call	DOS
	cp	27	; ESC
	jr	z,rdte08
	cp	8	; BS
	jr	z,rdte08
	call	HEXA
	jr	c,rdte07
	ld	b,a
	ld	a,(BUFFER+2+#40)
	or	b	
	ld	h,(iy+3)
	ld	l,(iy+2)
	ld	(hl),a	; save new data
rdte08:
	ld	h,(iy+3)
	ld	l,(iy+2)
	ld	a,(hl)
	push	hl
	ld	h,(iy+1)
	ld	l,(iy+0)
	ld	(CSRY),hl
	call	HEXOUT	; print new data
	pop	hl
	ld	e,(iy+9)	; next element (right)
	ld	a,(iy+4)
	cp	2
	jr	nz,rdte06	; no type cartride
	ld	a,(hl)
	cp	20		; special symbol ?
	jr	nc,rdte0A	
	ld	a," "		
rdte0A:	ld	e,a
	ld	hl,CSRX
	inc	(hL)
	ld	c,_CONOUT
	call	DOS	
	ld	e,(iy+9)	; next element (right)
rdte06:
	ld	a,e
	or	a
	jp	z,rdte05	; no move
	jp	rdte04		; move to new element (e)

rdte11:
; clear context help area
	call	CCHA
; print context help
	ld	hl,#0100+22
	ld	de,Hprot
	call	PRDE	
	jp	rdte05
;


; Extend edit data
rdte10:
	call	CLSM	; clear "help" area

	ld	a,(iy+4)
	cp	2	
; type cartridge symbol
	jr	nz,rdte12
	ld	hl,#0105
	ld	de,EnSm_S
	call	PRDE
	ld	de,BUFFER+2+#40
	ld	a,1
	ld	(de),a
	ld	c,_BUFIN
	push	de
	call	DOS
	pop	de
	inc	de
	ld	a,(de)
	or 	a
	jp	z,rdte13	;no enter
	inc	de
	ld	a,(de)
	ld	l,(iy+2)
	ld	h,(iy+3)
	ld	(hl),a
	push	hl
	call	CLSM
	pop	hl
	ld	a,(hl)
	jp	rdte08
rdte12:
	cp	5	; bitmap for RxMULT
	jr	c,rdte121 ; no bitmap
; print pointer tab
	ld	hl,#0102
	ld	(CSRY),hl	
	print	BTbp_S
	ld	hl,#0C09
	ld	(CSRY),hl
	ld	e,"-"
	ld	c,_CONOUT
	call	DOS
	ld	a,(iy+4)
	ld	e,1		; N help element
	cp	5	
	jr	z,rdte122
	ld	e,9
	cp	6
	jr	z,rdte122
	ld	e,17
	cp	7
	jr	z,rdte122
	ld	e,25
	cp	8
	jr	z,rdte122

	jr	rdte121
rdte122:
	push	iy
; print bithelp
rdte123:call	c_bht
	ld	l,(iy)
	ld	h,(iy+1)
	ld	e,(iy+2)
	ld	d,(iy+3)
	call	PRDE
	ld	a,(iy+4)	
	ld	e,a
	or	a
	jr	nz,rdte123
	pop	iy	
rdte121:

; get edit data
	ld	l,(iy+2)
	ld	h,(iy+3)
	ld	a,(hl)
	ld	(BUFFER+2+#40),a
	ld	c,a

	ld	hl,#0409	; set cursor to 7n bit
	ld	d,%01111111
	ld	e,%10000000	; c- edit byte

rdte20:
; print bit map
	push	hl
	push	de

	ld	hl,#0109
	ld	(CSRY),hl
	push	bc
	call	HEXOUT
	ld	e,"-"
	ld	c,_CONOUT
	call	DOS
	pop	bc

	push	bc
	ld	b,8
rdte14:	ld	a,%00011000	; "0"(#30) RRA		
	rl	c
	rl	a
	ld	e,a
	push	bc
	ld	c,_CONOUT
	call	DOS
	pop	bc
	djnz	rdte14
	pop	bc

	pop	de
	pop	hl


				
rdte15:	ld	(CSRY),hl
	push	bc
	push	hl
	push	de
	ld	c,_INNOE
	call	DOS
	pop	de
	pop	hl
	pop	bc

	cp	29	; LEFT
	jr	z,rdte16
	cp	28	; RIGHT
	jr	z,rdte17
	cp	"0"
	jr	z,rdte18
	cp	"1"
	jr	z,rdte19
	cp	" "	; SPACE
	jr	z,rdte21
	cp	#0D	; ENTER
	jr	z,rdte22	
	cp	27	; ESC
	jr	z,rdte23
	jr	rdte15

rdte16:	ld	a,h
	cp	4+1	; left limit
	jr	c,rdte15
	dec	h
	rlc	d
	rlc	e
	jr	rdte15

rdte17:	ld	a,h
	cp	4+7	; right limit
	jr	nc,rdte15
	inc	h
	rrc	d
	rrc	e
	jr	rdte15
rdte18:			; "0"
	ld	a,c
	and	d
	ld	c,a
	jp	rdte20
rdte19:			; "1"
	ld	a,c
	or	e	
	ld	c,a
	jp	rdte20
rdte21:			; "0/1" 
	ld	a,c
	xor	e
	ld	c,a
	jp	rdte20
rdte22:			; Ok
	ld	l,(iy+2)
	ld	h,(iy+3)
	ld	(hl),c	; set data save
rdte23:
	call	CLSM
	ld	l,(iy+2)
	ld	h,(iy+3)
	ld	a,(hl)
	jp	rdte08
rdte13:	call	CLSM
	jp	rdte04a
rdte80:

	call	CCHA
	
	jp	Redit
CCHA:
	ld	hl,#0100+21
CCHA02:	ld	a,l
	cp	25
	ret	nc
	ld	(CSRY),hl
	push	hl
	print	CLStr_S
	pop	hl	
	inc	l
	jr	CCHA02
c_bht:
	ld	iy,BHtab
	ld	bc,5
c_bht1:	dec	e
	ret	z
	add	iy,bc
	jr	c_bht1



HEXA:
; HEX symbol (A) to halfbyte (A)
	cp	"0"
	ret	c	; < "0"
	cp	"9"+1
	jr	nc,hexa1	; > "9"
	sub	"0"
	ret
hexa1:	and	%11011111	;(inv #20) abc -> ABC
	cp	"A"
	ret	c	; < "A"
	cp	"F"+1
	jr	c,hexa2
	scf
	ret
hexa2:	sub	"A"-#A
	ret
	
; Erase directory + add 00 Record (empty SCC)
DIRINI:
;
; warning message 
	print	DIRINI_S
UT02:	ld	c,_INNOE
	call	DOS
	cp	"y"
	jr	z,UT03
	cp	"n"
	jp	z,UTIL
	jr	UT02

UT03:			; continue
; erase directory area
	xor	a
	ld	(EBlock),a
	ld	a,#40		; 1st 1/2 Directory
	ld	(EBlock0),a
	call	FBerase	
	ld	a,#60		; 2nd 1/2 Directory
	ld	(EBlock0),a
	call	FBerase		
	ld	a,#80		; Autostart table
	ld	(EBlock0),a
	call	FBerase

	call	SET2PD

; load 00 - record "empty SCC"
	ld	a,(ERMSlt)
	ld	e,#15
	ld	hl,R2Mult
	call	WRTSLT		; set 16 kB Bank1
	xor	a
	ld	(EBlock),a	; Block = 0 system (x 64kB)
	inc	a
	ld	(PreBnk),a	; Bank=1 (x 16kB)
	ld	hl,MAP_E_SCC
	ld	de,#8000
	ld	bc,#40
	call	FBProg

	print DIRINC_S

	jp	UTIL

BootINI:
	print	Boot_I_S
Boot01:	ld	c,_INNOE
	call	DOS
	cp	"y"
	jr	z,Boot02
	cp	"n"
	jp	UTIL
	jr	Boot01
Boot02:
; open file
	ld	hl,BootFNam
	ld	de,FCB
	ld	bc,1+8+3
	ldir			; set file name
        ld      bc,24           ; Prepare the FCB
        ld      de,FCB+13
        ld      hl,FCB+12
        ld      (hl),b
        ldir                    ; Initialize the second half with zero
	ld	de,FCB
	ld	c,_FOPEN
	call	DOS		; Open file
	ld      hl,1
	ld      (FCB+14),hl     ; Record size = 1 byte
	or	a
	jr	z,Boot03		; file open
	print	F_NOT_F_S
	jp	UTIL
Boot03:	ld      c,_SDMA		;
	ld      de,BUFTOP
	call    DOS		; set DMA
; Get File Size
	ld	hl,FCB+#10
	ld	bc,4
	ld	de,Size
	ldir
; Check size
	ld	bc,(Size+2)
	ld	a,(Size+1)	
	dec	a
	and	%11000000	 ; 2000h 0010 0000
	or	b
	or	c
	jr	z,Boot04
	print	FSizE_S		; File size >= 15kb
	jp	UTIL
Boot04:
; Load first 8kb
	ld	c,_RBREAD
	ld	de,FCB
	ld	hl,#2000
	call	DOS
	ld	a,h
	or	l	
	jr	nz,Boot05
	print	FR_ER_S
	jp	UTIL
		
Boot05:
;Erase Boot Block		
	xor	a
	ld	(EBlock),a
	ld	a,#00		; 1st 1/2 Boot Block
	ld	(EBlock0),a
	call	FBerase	
	ld	a,#20		; 2nd 1/2 Boot Block
	ld	(EBlock0),a
	call	FBerase	
;Program 1st Boot
	call	SET2PD
	ld	a,(ERMSlt)
	ld	e,#15
	ld	hl,R2Mult
	call	WRTSLT		; set 16 kB Bank1
	ld	a,0
	ld	(PreBnk),a	; 0-page #0000 (Boot)
	ld	hl,BUFTOP
	ld	de,#8000
	ld	bc,#2000
	call	FBProg
	jr	c,Boot07
; Load second 8kb
	ld	c,_RBREAD
	ld	de,FCB
	ld	hl,#2000
	call	DOS
	ld	a,h
	or	l
	jr	z,Boot06	; No second 8kB, finish
; Program 2-nd Boot Block
	ld	hl,BUFTOP
	ld	de,#A000
	ld	bc,#2000	
	call	FBProg
	jr	nc,Boot06
Boot07:
	print	FL_er_S
	jp	UTIL
Boot06:
	print	Boot_C_S
	jp	UTIL

;-------------------------------------------------------------------------
;--- NAME: EXTPAR
;      Extracts a parameter from the command line
;    INPUT:   A  = Parameter to extract (the first one is 1)
;             DE = Buffer to put the extracted parameter
;    OUTPUT:  A  = Total number of parameters in the command line
;             CY = 1 -> The specified parameter does not exist
;                       B undefined, buffer unmodified
;             CY = 0 -> B = Parameter length, not including the tailing 0
;                       Parameter extracted to DE, finished with a 0 byte
;                       DE preserved

EXTPAR:	or	a	;Terminates with error if A = 0
	scf
	ret	z

	ld	b,a
	ld	a,(#80)	;Terminates with error if
	or	a	;there are no parameters
	scf
	ret	z
	ld	a,b

	push	af,hl
	ld	a,(#80)
	ld	c,a	;Adds 0 at the end
	ld	b,0	;(required under DOS 1)
	ld	hl,#81
	add	hl,bc
	ld	(hl),0
	pop	hl
	pop	af

	push	hl,de,ix
	ld	ix,0	;IXl: Number of parameter
	ld	ixh,a	;IXh: Parameter to be extracted
	ld	hl,#81

	;* Scans the command line and counts parameters

PASASPC:	ld	a,(hl)	;Skips spaces until a parameter
	or	a	;is found
	jr	z,ENDPNUM
	cp	" "
	inc	hl
	jr	z,PASASPC

	inc	ix	;Increases number of parameters
PASAPAR:	ld	a,(hl)	;Walks through the parameter
	or	a
	jr	z,ENDPNUM
	cp	" "
	inc	hl
	jr	z,PASASPC
	jr	PASAPAR

	;* Here we know already how many parameters are available

ENDPNUM:	ld	a,ixl	;Error if the parameter to extract
	cp	ixh	;is greater than the total number of
	jr	c,EXTPERR	;parameters available

	ld	hl,#81
	ld	b,1	;B = current parameter
PASAP2:	ld	a,(hl)	;Skips spaces until the next
	cp	" "	;parameter is found
	inc	hl
	jr	z,PASAP2

	ld	a,ixh	;If it is the parameter we are
	cp	b	;searching for, we extract it,
	jr	z,PUTINDE0	;else...

	inc	B
PASAP3:	ld	a,(hl)	;...we skip it and return to PASAP2
	cp	" "
	inc	hl
	jr	nz,PASAP3
	jr	PASAP2

	;* Parameter is located, now copy it to the user buffer

PUTINDE0:	ld	b,0
	dec	hl
PUTINDE:	inc	b
	ld	a,(hl)
	cp	" "
	jr	z,ENDPUT
	or	a
	jr	z,ENDPUT
	ld	(de),a	;Paramete is copied to (DE)
	inc	de
	inc	hl
	jr	PUTINDE

ENDPUT:	xor	a
	ld	(de),a
	dec	b

	ld	a,ixl
	or	a
	jr	FINEXTP
EXTPERR:	scf
FINEXTP:	pop	ix
		pop     de
		pop	hl
	ret


termdos:
	ld	c,_STROUT
	call	DOS

	ld	c,_TERM0
	jp	DOS



;--- NAME: NUMTOASC
;      Converts a 16 bit number into an ASCII string
;    INPUT:      DE = Number to convert
;                HL = Buffer to put the generated ASCII string
;                B  = Total number of characters of the string
;                     not including any termination character
;                C  = Padding character
;                     The generated string is right justified,
;                     and the remaining space at the left is padded
;                     with the character indicated in C.
;                     If the generated string length is greater than
;                     the value specified in B, this value is ignored
;                     and the string length is the one needed for
;                     all the digits of the number.
;                     To compute length, termination character "$" or 00
;                     is not counted.
;                 A = &B ZPRFFTTT
;                     TTT = Format of the generated string number:
;                            0: decimal
;                            1: hexadecimal
;                            2: hexadecimal, starting with "&H"
;                            3: hexadecimal, starting with "#"
;                            4: hexadecimal, finished with "H"
;                            5: binary
;                            6: binary, starting with "&B"
;                            7: binary, finishing with "B"
;                     R   = Range of the input number:
;                            0: 0..65535 (unsigned integer)
;                            1: -32768..32767 (twos complement integer)
;                               If the output format is binary,
;                               the number is assumed to be a 8 bit integer
;                               in the range 0.255 (unsigned).
;                               That is, bit R and register D are ignored.
;                     FF  = How the string must finish:
;                            0: No special finish
;                            1: Add a "$" character at the end
;                            2: Add a 00 character at the end
;                            3: Set to 1 the bit 7 of the last character
;                     P   = "+" sign:
;                            0: Do not add a "+" sign to positive numbers
;                            1: Add a "+" sign to positive numbers
;                     Z   = Left zeros:
;                            0: Remove left zeros
;                            1: Do not remove left zeros
;    OUTPUT:    String generated in (HL)
;               B = Length of the string, not including the padding
;               C = Length of the string, including the padding
;                   Tailing "$" or 00 are not counted for the length
;               All other registers are preserved

NUMTOASC:
	push	af,ix,de,hl
	ld	ix,WorkNTOA
	push	af,af
	and	%00000111
	ld	(ix+0),a	;Type
	pop	af
	and	%00011000
	rrca
	rrca
	rrca
	ld	(ix+1),a	;Finishing
	pop	af
	and	%11100000
	rlca
	rlca
	rlca
	ld	(ix+6),a	;Flags: Z(zero), P(+ sign), R(range)
	ld	(ix+2),b	;Number of final characters
	ld	(ix+3),c	;Padding character
	xor	a
	ld	(ix+4),a	;Total length
	ld	(ix+5),a	;Number length
	ld	a,10
	ld	(ix+7),a	;Divisor = 10
	ld	(ix+13),l	;User buffer
	ld	(ix+14),h
	ld	hl,BufNTOA
	ld	(ix+10),l	;Internal buffer
	ld	(ix+11),h

ChkTipo:	ld	a,(ix+0)	;Set divisor to 2 or 16,
	or	a	;or leave it to 10
	jr	z,ChkBoH
	cp	5
	jp	nc,EsBin
EsHexa:	ld	a,16
	jr	GTipo
EsBin:	ld	a,2
	ld	d,0
	res	0,(ix+6)	;If binary, range is 0-255
GTipo:	ld	(ix+7),a

ChkBoH:	ld	a,(ix+0)	;Checks if a final "H" or "B"
	cp	7	;is desired
	jp	z,PonB
	cp	4
	jr	nz,ChkTip2
PonH:	ld	a,"H"
	jr	PonHoB
PonB:	ld	a,"B"
PonHoB:	ld	(hl),a
	inc	hl
	inc	(ix+4)
	inc	(ix+5)

ChkTip2:	ld	a,d	;If the number is 0, never add sign
	or	e
	jr	z,NoSgn
	bit	0,(ix+6)	;Checks range
	jr	z,SgnPos
ChkSgn:	bit	7,d
	jr	z,SgnPos
SgnNeg:	push	hl	;Negates number
	ld	hl,0	;Sign=0:no sign; 1:+; 2:-
	xor	a
	sbc	hl,de
	ex	de,hl
	pop	hl
	ld	a,2
	jr	FinSgn
SgnPos:	bit	1,(ix+6)
	jr	z,NoSgn
	ld	a,1
	jr	FinSgn
NoSgn:	xor	a
FinSgn:	ld	(ix+12),a

ChkDoH:	ld	b,4
	xor	a
	cp	(ix+0)
	jp	z,EsDec
	ld	a,4
	cp	(ix+0)
	jp	nc,EsHexa2
EsBin2:	ld	b,8
	jr	EsHexa2
EsDec:	ld	b,5

EsHexa2:	push	de
Divide:	push	bc,hl	;DE/(IX+7)=DE, remaining A
	ld	a,d
	ld	c,e
	ld	d,0
	ld	e,(ix+7)
	ld	hl,0
	ld	b,16
BucDiv:	rl	c
	rla
	adc	hl,hl
	sbc	hl,de
	jr	nc,$+3
	add	hl,de
	ccf
	djnz	BucDiv
	rl	c
	rla
	ld	d,a
	ld	e,c
	ld	a,l
	pop	hl
	pop	bc

ChkRest9:	cp	10	;Converts the remaining
	jp	nc,EsMay9	;to a character
EsMen9:	add	a,"0"
	jr	PonEnBuf
EsMay9:	sub	10
	add	a,"A"

PonEnBuf:	ld	(hl),a	;Puts character in the buffer
	inc	hl
	inc	(ix+4)
	inc	(ix+5)
	djnz	Divide
	pop	de

ChkECros:	bit	2,(ix+6)	;Cchecks if zeros must be removed
	jr	nz,ChkAmp
	dec	hl
	ld	b,(ix+5)
	dec	b	;B=num. of digits to check
Chk1Cro:	ld	a,(hl)
	cp	"0"
	jr	nz,FinECeros
	dec	hl
	dec	(ix+4)
	dec	(ix+5)
	djnz	Chk1Cro
FinECeros:	inc	hl

ChkAmp:	ld	a,(ix+0)	;Puts "#", "&H" or "&B" if necessary
	cp	2
	jr	z,PonAmpH
	cp	3
	jr	z,PonAlm
	cp	6
	jr	nz,PonSgn
PonAmpB:	ld	a,"B"
	jr	PonAmpHB
PonAlm:	ld	a,"#"
	ld	(hl),a
	inc	hl
	inc	(ix+4)
	inc	(ix+5)
	jr	PonSgn
PonAmpH:	ld	a,"H"
PonAmpHB:	ld	(hl),a
	inc	hl
	ld	a,"&"
	ld	(hl),a
	inc	hl
	inc	(ix+4)
	inc	(ix+4)
	inc	(ix+5)
	inc	(ix+5)

PonSgn:	ld	a,(ix+12)	;Puts sign
	or	a
	jr	z,ChkLon
SgnTipo:	cp	1
	jr	nz,PonNeg
PonPos:	ld	a,"+"
	jr	PonPoN
	jr	ChkLon
PonNeg:	ld	a,"-"
PonPoN	ld	(hl),a
	inc	hl
	inc	(ix+4)
	inc	(ix+5)

ChkLon:	ld	a,(ix+2)	;Puts padding if necessary
	cp	(ix+4)
	jp	c,Invert
	jr	z,Invert
PonCars:	sub	(ix+4)
	ld	b,a
	ld	a,(ix+3)
Pon1Car:	ld	(hl),a
	inc	hl
	inc	(ix+4)
	djnz	Pon1Car

Invert:	ld	l,(ix+10)
	ld	h,(ix+11)
	xor	a	;Inverts the string
	push	hl
	ld	(ix+8),a
	ld	a,(ix+4)
	dec	a
	ld	e,a
	ld	d,0
	add	hl,de
	ex	de,hl
	pop	hl	;HL=initial buffer, DE=final buffer
	ld	a,(ix+4)
	srl	a
	ld	b,a
BucInv:	push	bc
	ld	a,(de)
	ld	b,(hl)
	ex	de,hl
	ld	(de),a
	ld	(hl),b
	ex	de,hl
	inc	hl
	dec	de
	pop	bc
	ld	a,b	;*** This part was missing on the
	or	a	;*** original routine
	jr	z,ToBufUs	;***
	djnz	BucInv
ToBufUs:
	ld	l,(ix+10)
	ld	h,(ix+11)
	ld	e,(ix+13)
	ld	d,(ix+14)
	ld	c,(ix+4)
	ld	b,0
	ldir
	ex	de,hl

ChkFin1:	ld	a,(ix+1)	;Checks if "$" or 00 finishing is desired
	and	%00000111
	or	a
	jr	z,Fin
	cp	1
	jr	z,PonDolar
	cp	2
	jr	z,PonChr0

PonBit7:	dec	hl
	ld	a,(hl)
	or	%10000000
	ld	(hl),a
	jr	Fin

PonChr0:	xor	a
	jr	PonDo0
PonDolar:	ld	a,"$"
PonDo0:	ld	(hl),a
	inc	(ix+4)

Fin:	ld	b,(ix+5)
	ld	c,(ix+4)
	pop	hl
	pop     de
	pop	ix
	pop	af
	ret

WorkNTOA:	defs	16
BufNTOA:	ds	10


;--- EXTNUM16
;      Extracts a 16-bit number from a zero-finished ASCII string
;    Input:  HL = ASCII string address
;    Output: BC = Extracted number
;            Cy = 1 if error (invalid string)
;
;EXTNUM16:	call	EXTNUM
;	ret	c
;	jp	c,INVPAR	;Error if >65535
;
;	ld	a,e
;	or	a	;Error if the last char is not 0
;	ret	z
;	scf
;	ret


;--- NAME: EXTNUM
;      Extracts a 5 digits number from an ASCII string
;    INPUT:      HL = ASCII string address
;    OUTPUT:     CY-BC = 17 bits extracted number
;                D  = number of digits of the number
;                     The number is considered to be completely extracted
;                     when a non-numeric character is found,
;                     or when already five characters have been processed.
;                E  = first non-numeric character found (or 6th digit)
;                A  = error:
;                     0 => No error
;                     1 => The number has more than five digits.
;                          CY-BC contains then the number composed with
;                          only the first five digits.
;    All other registers are preserved.

EXTNUM:	push	hl,ix
	ld	ix,ACA
	res	0,(ix)
	set	1,(ix)
	ld	bc,0
	ld	de,0
BUSNUM:	ld	a,(hl)	;Jumps to FINEXT if no numeric character
	ld	e,a	;IXh = last read character
	cp	"0"
	jr	c,FINEXT
	cp	"9"+1
	jr	nc,FINEXT
	ld	a,d
	cp	5
	jr	z,FINEXT
	call	POR10

SUMA:	push	hl	;BC = BC + A 
	push	bc
	pop	hl
	ld	bc,0
	ld	a,e
	sub	"0"
	ld	c,a
	add	hl,bc
	call	c,BIT17
	push	hl
	pop	bc
	pop	hl

	inc	d
	inc	hl
	jr	BUSNUM

BIT17:	set	0,(ix)
	ret
ACA:	db	0	;b0: num>65535. b1: more than 5 digits

FINEXT:	ld	a,e
	cp	"0"
	call	c,NODESB
	cp	"9"+1
	call	nc,NODESB
	ld	a,(ix)
	pop	ix
	pop	hl
	srl	a
	ret

NODESB:	res	1,(ix)
	ret

POR10:	push	de,hl	;BC = BC * 10 
	push	bc
	push	bc
	pop	hl
	pop	de
	ld	b,3
ROTA:	sla	l
	rl	h
	djnz	ROTA
	call	c,BIT17
	add	hl,de
	call	c,BIT17
	add	hl,de
	call	c,BIT17
	push	hl
	pop	bc
	pop	hl
	pop	de
	ret
PRBAT:
	print	ONE_NL_S
	ld	bc,#0810
	ld	hl,BAT
PRB1:	ld	a,(hl)
	push	hl
	push	bc
	call	HEXOUT
	pop	bc
	pop	hl
	inc	hl
	dec	c
	jr	nz,PRB1
	push	hl
	push	bc
	print	ONE_NL_S
	pop	bc
	pop	hl
	ld	c,16		
	dec	b
	jr	nz,PRB1
	ret


	
PRESENT_S:
	db	3
	db	"FlashROM Manager for",13,10
	db	"Carnivore SCC Cartridge",13,10,10,"$"
NSFin_S:
	db	"No find cartridge. Enter slot number-$"
Findcrt_S:
	db	"Find Cartrigde in slots:",13,10,"$"
FindcrI_S:
	db	13,10,"Press Enter for first find slot or enter slot number-$"
DESCR:	db	"CSCCFRC"
USEDOS2_S:
	db	"* USE DOS2 "
CRLF_S:	db	13,10,"$"
SltN_S:	db	13,10,"Slot - $"
M29W640:
        db      "Detect M29W640G$"
NOTD_S:	db	13,10,"FlashROM not detected",13,10
	db	"This cartridge is not open or is defective.",13,10
	db	" Try holding down (F5) the reset ",13,10 
	db	"$"
MfC_S:	db	"Manufacturer Code: $"
DVC_S:	db	"Device code: $"
EMB_S:	db	"Extended Memory Block: $"
EMBF_S:	db	"EMB Factory loced",13,10,"$"
EMBC_S:	db	"EMB Customer Locable",13,10,"$"
ABCD:	db	"0123456789ABCDEF"
EXIT_S:	db	"Terminate programm",13,10,"$"

MAIN_S:	db	13,10
	db	" 1 - Add ROM-image to flash",13,10
	db	" 2 - Navigate ROM-image Records",13,10
	db	" 8 - Service utilites",13,10
	db	" 0 - Exit",13,10,"$"
UTIL_S:
	db	13,10
	db	" 1 - Compress Directory",13,10
	db	" 2 - Directory initialization (Erase All)",13,10
	db	" 3 - Restore boot block Flesh cartridge",13,10
	db	" 0 - Return Main Menu",13,10,"$"
DirComr_S:
	db	"Directory is compressed, continue (y/n)?$"
DIRINI_S:
	db	"Directory is initialized, all the records will be erased (y/n)?$"
DIRINC_S:
	db	13,10,"Initialization directory complete",13,10,"$"
Boot_I_S:
	db	"Loading system Boot Block (y/n)?$"
Boot_C_S:
	db	13,10,"Restore boot block complete",13,10,"$"
ADD_RI_S:
	db	13,10,"Input filename ROM-image for loading $"
OpFile_S:
	db	"Open File: ","$"
F_NOT_F_S:
	db	"File not found",13,10,"$"
FSizE_S:
	db	"File size error",13,10,"$"
FR_ER_S:
	db	"File read ERROR!",13,10,"$"
Analis_S:	db 	13,10,"ROM Image analise -$"
MROMD_S:	db	"ROM size is set to $" 

CTC_S:	db	"Confirm the type of cartridge (y/n)",13,10,"$"
CoTC_S:	db	"Select the type of cartridge:",13,10,"$"
Num_S:	db	"Numer -$"
FileOver_S:
	db	"File oversize or not enough space in the flashROM",13,10,"$"
MRSQ_S:	db	"Size  32kB < ROM <= 64 kB. No Mapper MiniROM ?(y/n)",13,10,"$"
Strm_S:	db	"MMROM-CSRM: $"
NFNR_S:	db	"Not found record Multirom with a free block",#0D,#0A
	db	"It will use the new FleshBlock 64kB",#0A,#0D,"$"
FNRE_S:	db	"Use Record-FBlock-NBank for MiniROM",#0D,#0A
	db	" (Multi) - $"
DirOver_S:
	db	"No free directory entries",13,10
DirCmpr: db	"Compress the directory?",13,10,"$"
FFFS_S:	db	"Find free space at:$"
FDE_S:	db	"Find free Directory entry at:$"
NR_I_S:	db	"Name Record: $"
NR_L_S: db	"Press Enter or input new Name",13,10,"$"
FLEB_S:	db	"Erase flash block - $"
FLEBE_S: db	"Error erase flesh",13,10,"$"
LFRI_S:	db	"Loading ROM-image to flash",13,10,"$"
Prg_Su_S:
	db	13,10,"Complete loading",13,10,"$"
FL_er_S:
	db	13,10,"Error flash programming",13,10,"$"
FL_erd_S:
	db	13,10,"Error directory programming",13,10,"$"
CRD_S:	db	"Choose record for (E)dit or (D)elete, use cursor Keys$"
RDELQ_S:
	db	"-record delete ?(y/n)$" 
RPE_S:	db	"Edit parametr record - $"

LOAD_S:	db	"ROM-image is ready to be loaded, continue?(y/n)$"
QQ:	db	"CBAT:$"
TWO_NL_S:	db	13,10
ONE_NL_S:	db	13,10,"$"
CLS_S:		db	27,"E$"
CLStr_S:	db	27,"K$"
INVPAR_S:	db	"*** Invalid parameter(s)",13,10,"$"
QDOR_S	db	#0D,#0A,"Delete old record ? (y/n)$"

MAP_E_SCC:
	db	#00,#FF,00,00,"s"
	db	"Empty Konami-5 SSC            "
	db	#F8,#50,#00,#8C,#3F,#40	
	db	#F8,#70,#01,#8C,#3F,#60		
	db      #F8,#90,#02,#8C,#3F,#80		
	db	#F8,#B0,#03,#8C,#3F,#A0	
	db	#FF,#B2,#00,#00,#FF

CARTTAB: ; (N x 64 byte) 
	db	0					;1
	db	"Not type detect                  $"	;34
	db	#F8,#50,#00,#84,#3F,#40			;6
	db	#F8,#70,#01,#84,#3F,#60			;6	
	db      #F8,#90,#02,#84,#3F,#80			;6	
	db	#F8,#B0,#03,#84,#3F,#A0			;6
	db	#FF,#BC,#00,#02,#FF			;5

CRTT1:	db	"k"
	db	"Konami (Konami 4)                $"
	db	#E8,#50,#00,#04,#3F,#40			
	db	#E8,#60,#01,#84,#3F,#60				
	db      #E8,#80,#02,#84,#3F,#80				
	db	#E8,#A0,#03,#84,#3F,#A0			
	db	#FF,#AC,#00,#02,#FF
CRTT2:	db	"K"
	db	"Konami SCC (Konami 5)            $"
	db	#F8,#50,#00,#84,#3F,#40			
	db	#F8,#70,#01,#84,#3F,#60				
	db      #F8,#90,#02,#84,#3F,#80				
	db	#F8,#B0,#03,#84,#3F,#A0			
	db	#FF,#BC,#00,#02,#FF
CRTT3:	db	"a"
	db	"ASCII 8                          $"
	db	#F8,#60,#00,#84,#3F,#40			
	db	#F8,#68,#01,#84,#3F,#60				
	db      #F8,#70,#02,#84,#3F,#80				
	db	#F8,#78,#03,#84,#3F,#A0			
	db	#FF,#AC,#00,#02,#FF
CRTT4:	db	"A"
	db	"ASCII 16                         $"		
	db	#F8,#60,#00,#85,#7F,#40			
	db	#F8,#70,#01,#85,#7F,#80				
	db      #F8,#70,#02,#08,#3F,#80				
	db	#F8,#78,#03,#08,#3F,#A0			
	db	#FF,#8C,#00,#01,#FF
CRTT5:	db	"A"
	db	"Mini-ROM                         $"		
	db	#F8,#60,#00,#16,#7F,#40			
	db	#F8,#70,#01,#08,#7F,#80				
	db      #F8,#70,#02,#08,#3F,#C0				
	db	#F8,#78,#03,#08,#3F,#A0			
	db	#FF,#8C,#07,#01,#FF
	
	db	0
Temdi:
;1 N elem
	db	13,1	; 0,1 - Y,X screen location 
	dw	BUFFER+2; 2,3 - Data source
	db	4	; 4   - type Data (4)-HEX byte
	db	2	; 5   - next element for print menu
	db	0,8	; 6,7,8,9 - next element for edit
	db	0,2	; UP,DOWN,LEFT,RIGHT (0)-stop
	db	1	; 10  - protection bype
	db	0	; 11  - reserv
	dw	HRecN	; 12,13 - context help message

;2 "delete" code
	db	13,4
	dw	BUFFER+3
	db	4
	db	3
	db	0,8
	db	1,3
	db	1
	db	0
	dw	HPSV

;3 start block
	db	13,8
	dw	BUFFER+4
	db	4
	db	4
	db	0,8	
	db	2,4
	db	1
	db	0
	dw	HSTB
;4 len block
	db	13,11
	dw	BUFFER+5
	db	4
	db	5
	db	0,9
	db	3,5
	db	1
	db	0
	dw	HLNB
;5 type descriptor
	db	13,16
	dw	BUFFER+6
	db	2
	db	6
	db	0,10
	db	4,8
	db	0
	db	0
	dw	HTDS
;6 record name
	db	11,1
	dw	BUFFER+7
	db	1
	db	7
	db	0,0
	db	0,0
	db	0
	db	0
	dw	HEMPT
;7 1 bank name
	db	15,1
	dw	BM_S1
	db	3
	db	8
	db	0,0
	db	0,0
	db	0
	db	0
	dw	HEMPT
;8 R1Mask
	db	15,8
	dw	BUFFER+2+#23
	db	4
	db	9
	db	3,15
	db	5,9
	db	0
	db	0
	dw	HRMask
;9 R1Addr
	db	15,11
	dw	BUFFER+2+#24
	db	4
	db	10
	db	4,16
	db	8,10
	db	0
	db	0
	dw	HRAddr
;10 R1Reg
	db	15,14
	dw	BUFFER+2+#25
	db	4
	db	11
	db	5,17
	db	9,11
	db	0
	db	0
	dw	HRReg
;11 R1Mult
	db	15,17
	dw	BUFFER+2+#26
	db	5
	db	12
	db	5,18
	db	10,12
	db	0
	db	0
	dw	HRMult
;12 B1MaskR
	db	15,20
	dw	BUFFER+2+#27
	db	4
	db	13
	db	5,19
	db	11,13
	db	0
	db	0
	dw	HBMaskR
;13 B1AdrD
	db	15,23
	dw	BUFFER+2+#28
	db	4
	db	14
	db	5,20
	db	12,15
	db	0
	db	0
	dw	HBAdrD
;14 2 bank name
	db	16,1
	dw	BM_S2
	db	3
	db	15
	db	0,0
	db	0,0
	db	0
	db	0
	dw	HEMPT
;15 R2Mask
	db	16,8
	dw	BUFFER+2+#29
	db	4
	db	16
	db	8,22
	db	13,16
	db	0
	db	0
	dw	HRMask
;16 R2Addr
	db	16,11
	dw	BUFFER+2+#2A
	db	4
	db	17
	db	9,23
	db	15,17
	db	0
	db	0
	dw	HRAddr
;17 R2Reg
	db	16,14
	dw	BUFFER+2+#2B
	db	4
	db	18
	db	10,24
	db	16,18
	db	0
	db	0
	dw	HRReg
;18 R2Mult
	db	16,17
	dw	BUFFER+2+#2C
	db	5
	db	19
	db	11,25
	db	17,19
	db	0
	db	0
	dw	HRMult
;19 B2MaskR
	db	16,20
	dw	BUFFER+2+#2D
	db	4
	db	20
	db	12,26
	db	18,20
	db	0
	db	0
	dw	HBMaskR
;20 B2AdrD
	db	16,23
	dw	BUFFER+2+#2E
	db	4
	db	21
	db	13,27
	db	19,22
	db	0
	db	0
	dw	HBAdrD

;21 3 bank name
	db	17,1
	dw	BM_S3
	db	3
	db	22
	db	0,0
	db	0,0
	db	0
	db	0
	dw	HEMPT
;22 R3Mask
	db	17,8
	dw	BUFFER+2+#2F
	db	4
	db	23
	db	15,29
	db	20,23
	db	0
	db	0
	dw	HRMask
;23 R3Addr
	db	17,11
	dw	BUFFER+2+#30
	db	4
	db	24
	db	16,30
	db	22,24
	db	0
	db	0
	dw	HRAddr
;24 R3Reg
	db	17,14
	dw	BUFFER+2+#31
	db	4
	db	25
	db	17,31
	db	23,25
	db	0
	db	0
	dw	HRReg
;25 R3Mult
	db	17,17
	dw	BUFFER+2+#32
	db	5
	db	26
	db	18,32
	db	24,25
	db	0
	db	0
	dw	HRMult
;26 B3MaskR
	db	17,20
	dw	BUFFER+2+#33
	db	4
	db	27
	db	19,33
	db	25,26
	db	0
	db	0
	dw	HBMaskR
;27 B3AdrD
	db	17,23
	dw	BUFFER+2+#34
	db	4
	db	28
	db	20,34
	db	26,28
	db	0
	db	0
	dw	HBAdrD

;28 4 bank name
	db	18,1
	dw	BM_S4
	db	3
	db	29
	db	0,0
	db	0,0
	db	0
	db	0
	dw	HEMPT
;29 R4Mask
	db	18,8
	dw	BUFFER+2+#35
	db	4
	db	30
	db	22,35
	db	27,30
	db	0
	db	0
	dw	HRMask
;30 R4Addr
	db	18,11
	dw	BUFFER+2+#36
	db	4
	db	31
	db	23,36
	db	29,31
	db	0
	db	0
	dw	HRAddr
;31 R4Reg
	db	18,14
	dw	BUFFER+2+#37
	db	4
	db	32
	db	24,37
	db	30,32
	db	0
	db	0
	dw	HRReg
;32 R4Mult
	db	18,17
	dw	BUFFER+2+#38
	db	5
	db	33
	db	25,38
	db	31,33
	db	0
	db	0
	dw	HRMult
;33 B4MaskR
	db	18,20
	dw	BUFFER+2+#39
	db	4
	db	34
	db	19,39
	db	32,34
	db	0
	db	0
	dw	HBMaskR
;34 B4AdrD
	db	18,23
	dw	BUFFER+2+#3A
	db	4
	db	35
	db	20,39
	db	33,35
	db	0
	db	0
	dw	HBAdrD

;35 Reserv
	db	20,8
	dw	BUFFER+2+#3B
	db	4
	db	36
	db	29,0
	db	34,36
	db	1
	db	0
	dw	HRez
;36 CardMDR
	db	20,11
	dw	BUFFER+2+#3C
	db	6
	db	37
	db	30,0
	db	35,37
	db	0
	db	0
	dw	HCardMDR
;37 miniROM options
	db	20,14
	dw	BUFFER+2+#3D
	db	7
	db	38
	db	31,0
	db	36,38
	db	0
	db	0
	dw	HMRTB
;38 Start/Reset options
	db	20,17
	dw	BUFFER+2+#3E
	db	8
	db	39
	db	32,0
	db	37,39
	db	0
	db	0
	dw	HSOB
;39 Reserv
	db	20,20
	dw	BUFFER+2+#3F
	db	4
	db	0
	db	33,0
	db	38,0
	db	1
	db	0
	dw	HRez


BHtab:
;1 7bit help RMult
	db	2,13
	dw	H7hMult
	db	2
;2 6bit help RMult
	db	3,13
	dw	H6hMult
	db	3
;3 5bit help RMult
	db	4,13
	dw	H5hMult
	db	4
;4 4bit help RMult
	db	5,13
	dw	H4hMult
	db	5
;5 3bit help RMult
	db	6,13
	dw	H3hMult
	db	6
;6 2bit help RMult
	db	7,13
	dw	H2hMult
	db	7
;7 1bit help RMult
	db	8,13
	dw	H1hMult
	db	8
;8 0bit help RMult
	db	9,13
	dw	H0hMult
	db	0
;9  7Bit help CardMDR
	db	2,13
	dw	H7CMDR
	db	10
;10 6Bit help CardMDR
	db	3,13
	dw	H6CMDR
	db	11
;11 5Bit help CardMDR
	db	4,13
	dw	H5CMDR
	db	12
;12 4Bit help CardMDR
	db	5,13
	dw	H4CMDR
	db	13
;13 3Bit help CardMDR
	db	6,13
	dw	H3CMDR
	db	14
;14 2Bit help CardMDR
	db	7,13
	dw	H2CMDR
	db	15
;15 1Bit help CardMDR
	db	8,13
	dw	H1CMDR
	db	16
;16 0Bit help CardMDR
	db	9,13
	dw	H0CMDR
	db	0
;17-25 Bit Help CardMDR register
	db	2,13
	dw	H7MMRD
	db	18
	db	3,13
	dw	H6MMRD
	db	19
	db	4,13
	dw	H5MMRD
	db	20
	db	5,13
	dw	H4MMRD
	db	21
	db	6,13
	dw	H3MMRD
	db	22
	db	7,13
	dw	H2MMRD
	db	23
	db	8,13
	dw	H1MMRD
	db	24
	db	9,13
	dw	H0MMRD
	db	0
;25-28 Bit Help StartRom options register
	db	6,13
	dw	H3SRo
	db	26
	db	7,13
	dw	H2SRo
	db	27
	db	8,13
	dw	H1SRo
	db	28
	db	9,13
	dw	H0SRo
	db	0




H7hMult	db	" Enable Bank Number register$"
H6hMult	db	" Mirror over Bank Number$"
H5hMult	db	" Extend RAM source Bank$"
H4hMult	db	" Enable write Bank$"
H3hMult	db	" Disable Bank$"
H2hMult	db	"] 111-64kB 110-32kB$"
H1hMult	db	"] 101-16kB 100-08kB$"
H0hMult	db	"] another 0xx-disable$"

H7CMDR	db	" Disable Card.Contr.Register$"
H6CMDR	db	"] 00-#0F80 01-#4F80 10-#8F80$"
H5CMDR	db	"] 11-#CF80 base C.C.Register$"
H4CMDR	db	" Enable SCC music chip$"
H3CMDR	db	" Enable delayed reconfig.$"
H2CMDR	db	" reconf.p.: 0-Reset, 1-#4000$"
H1CMDR	db	" reserve            adr.read$"
H0CMDR	db	" reserve$"

H7MMRD	db	" reserve$"
H6MMRD	db	"] N=posit.in 64kB FleshBlock$"
H5MMRD	db	"] 000-0, 001-1, 010-2, 011-3$"
H4MMRD	db	"] 100-4, 101-5, 110-6, 111-7$"
H3MMRD	db	" 1- 48kB size ROM, 0- Other$"
H2MMRD	db	"] Size ROM 000-Not MiniROM$"
H1MMRD	db	"] 111-64kB 110-32/48kB$" 
H0MMRD	db	"] 101-16kB 100-8kB$"

H3SRo	db	"Jmp adr. 1-(#0002) 0-see 2b.$"
H2SRo	db	"Jmp adr. 0-(#4002) 1-(#8002)$"
H1SRo	db	"0- no Start ROM, 1-Start Jmp$"
H0SRo	db	"0- no Reset, 1- Reset MSX$"



BM_S1	db	"1-Bank$"
BM_S2	db	"2-Bank$"
BM_S3	db	"3-Bank$"
BM_S4	db	"4-Bank$"
GHME:	db	" Use cursor to navigate register table",#0D,#0A
	db	" Enter new values HEX Byte",#0D,#0A
	db	" or press SPACE for extanded (bitedit)",#0D,#0A
	db	" ESC - quit$"
HEMPT	db	"$"
Hprot	db	" Protect element !",#0D,#0A
	db	" Set SU mode to access$"
HRecN	db	"ACT - Record active flag",#0D,#0A
	db	" #FF - empty record, #XX - record number$"
HPSV:	db	"PSV - Record delete byte (#FF - not delete)$"
HSTB:	db	"STB - Start block in Flash for ROM-image$"
HLNB:	db	"LNB - Length ROM-image (N-blocks 64kB)$"
HTDS:	db	"Type cartridge descryptor Symbol$"
HRMask	db	"RxMask BitMask for register Bank number",#0D,#0A
	db	"bit=1 - bit address from RAddr register",#0D,#0A
	db	"bit=0 - this bit does not affect$"
HRAddr	db	"The high byte address Bank number register$"
HRReg	db	"The initial value of the bank number$"
HRMult	db	"Multi-control Bank register",#0D,#0A
	db	"press SPACE for extend editing bit mask$"
HBMaskR	db	"Bitmask for to limit the value of the bank number$"
HBAdrD	db	"The high byte Bank address in CPU memory area$" 
HRez	db	"Reserve bytes not used$"
HCardMDR
	db	"Main control register CSCC cartridge",#0D,#0A
	db	"press SPACE for extend editing bit mask$"
HMRTB	db	"Mini and Multi ROM control register",#0D,#0A
	db	"press SPACE for extend editing bit mask$"
HSOB	db	"Start ROM-image options register",#0D,#0A
	db	"press SPACE for extend editing bit mask$"


M_CTS:
M_CT01:	db	"  Rename Record",#0D,#0A
M_CT02:	db	"  Preset cardtridge configuration",#0D,#0A
M_CT03:	db	"  Edit configuration register",#0D,#0A
M_CT04:	db	"  Save record and exit",#0D,#0A
M_CT05:	db	"  Quit Editor without saving (ESC)",#0D,#0A,"$"
EWS_S:	db	" Quit without saving?(y/n)$"
ENNR_S:	db	" Enter new name record",#0D,#0A,"$"
SAE_S:	db	" Save and exit(y/n)$"
PTC_S:	db	" Select preset register configuration:$"
PTCUL_S:
	db	"Load preset register from file.CPC$"
PTCE_S:
	db	"Quit (ESC)$"
SSM_S:	db	"Select start ROM metod :$"
ssm01:	db	"Jump to ROM INIT$"
ssm02:	db	"Reset system$"
ssm03:	db	"No start$"
SSA_S:	db	"Select start ROM page:$"
ssa01:	db	"#0000$"
ssa02:	db	"#4000$"
ssa03:	db	"#8000$"
SSR_S:	db	"Select ROM Size:$"
ssrMAP:	db	"> 64 kB, use mapper detect$"
ssr64:	db	"64 kB$"
ssr48:	db	"48 kB$"
ssr32:	db	"32 kB$"
ssr16:	db	"16 kB$"
ssr08	db	"8  kB or less$"
SRL_S:	db	"Select ROM location:$"
SFL_S:	db	"Enter location in FlashBlock(0-7):$"
EnSm_S:	db	"Enter Symbol - $"

BTbp_S:	db	"   *--------",#0D,#0A
	db	"   !*-------",#0D,#0A
	db	"   !!*------",#0D,#0A
	db	"   !!!*-----",#0D,#0A
	db	"   !!!!*----",#0D,#0A
	db	"   !!!!!*---",#0D,#0A
	db	"   !!!!!!*--$"	
;	db	"FF-76543210-"

;variable
protect:
	db	1
DOS2:	db	0
ERMSlt	db	1
TRMSlt	db	#FF,#FF,#FF,#FF,#FF,#FF,#FF,#FF,#FF
Binpsl	db	2,0,"1",0
slot:	db	1
cslt:	db	0
Det00:	db	0
Det02:	db	0
Det1C:	db	0
Det1E:	db	0
Det06:	db	0
;Det04:	ds	134
DMAP:	db	0
DMAPt:	db	1
BMAP:	ds	2
Dpoint:	db	0,0,0
StartBL: ds	2
C8k:	dw	0
PreBnk:	db	0
EBlock0: db	0
EBlock:	db	0
strp:	db	0
strI:	dw	#8000
BootFNam:
	db	0,"BOOTCSCCBIN"
Bi_FNAM db	14,0,"D:FileName.ROM",0
;--- File Control Block
FCB:	db	0
	db	"           "
	ds	28
FILENAME: db    "                                $"
Size:	db 0,0,0,0
BAT:	; BAT table ( 8MB/64kB = 128 )
	ds	128	
Record:	ds	#40
SRSize:	db	0
multi	db	0
ROMABCD:	db	0
ROMJT0:	db	0
ROMJT1:	db	0
ROMJT2:	db	0
ROMJI0:	db	0
ROMJI1:	db	0
ROMJI2:	db	0

ZiroB:	db	0
BUFFER:	ds	256
BUFTOP:
