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
	ld	a,(Size+3)
	or	a
	jr	nz,Fptl
	ld	a,(Size+2)
	or	a
	jr	nz,Fptl
	ld	a,(Size+1)
	cp	#80
	jr	nc,Fptl
; ROM Image is small, no use mapper
; bla bla bla :)


; load first 8000h byte for analise	
Fptl:
	ld	hl,#8000
	ld      c,_RBREAD
	ld	de,FCB
	call    DOS
	or	a
	jp	nz,FrErr
; file close
	ld	de,FCB
	ld	c,_FCLOSE
	call	DOS
; Analise ROM-Image

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
DTME3:	ld	b,0
	jr	DTME1
DTME2:
	cp	%01001001	;5000h,7000h,9000h	
	ld	b,2		;Konami 5 (SCC)
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
; Correction start metod




; Search free space in flash


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

        ld      a,(ERMSlt)
        ld      h,#40
        call    ENASLT
	ld	a,#14
	ld	(R2Mult),a		; set 8kB Bank
	ld	a,(Record+02)		; start bloc (absolute block 64kB)
	ld	(EBlock),a
	ld	(AddrFR),a
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT

; set inblock shift
	xor	a
	ld	(PreBnk),a

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

CmprDIR:
; Compress directory 

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
	call	CLNFCB
	print	UTIL_S
UT01:	ld	c,_INNOE
	call	DOS


	cp	"2"
	jp	z,DIRINI
	cp	"3"
	jp	z,BootINI
	cp	27
	jp	z,MainM
	cp	"0"
	jp	z,MainM
	jr	UT01	

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
; load 00 - record "empty SCC"
	ld	a,(ERMSlt)
	ld	e,#15
	ld	hl,R2Mult
	call	WRTSLT		; set 16 kB Bank1
	ld	a,1
	ld	(PreBnk),a	; 1-page #4000 (Directory)
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
ToBufUs:	ld	l,(ix+10)
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


CLNFCB:	push 	hl
	push	bc
	ld	hl,FCB
	xor	a
	ld	(hl),a
	inc	hl
	ld	a,32
	ld	bc,11
CLNFCB1:ld	(hl),a
	inc	hl
	dec	c
	jr	nz,CLNFCB1
	pop	bc
	pop	hl
	ret

	
PRESENT_S:
	db	3
	db	"FlashROM Manager for Carnivore SCC Cartridge v1.00",13,10
	db	"(C) 2015-2016 RBSC. All rights reserved.",13,10,13,10,"$"
NSFin_S:
	db	"Carnivore cartridge is not found. Enter slot number - $"
Findcrt_S:
	db	"Found Carnivore cartrigde in slot(s):",13,10,"$"
FindcrI_S:
	db	13,10,"Press Enter to use the found slot or enter slot number - $"
DESCR:	db	"CSCCFRC"
USEDOS2_S:
	db	"*** Please use DOS2! *** "
CRLF_S:	db	13,10,"$"
SltN_S:	db	13,10,"Slot - $"
M29W640:
        db      "Detected: M29W640G$"
NOTD_S:	db	13,10,"Flash chip type is not detected!",13,10
	db	"This cartridge is not open for writing or is defective!",13,10
	db	"Try holding down (F5) during reboot...",13,10 
	db	"$"
MfC_S:	db	"Manufacturer's code: $"
DVC_S:	db	"Device's code: $"
EMB_S:	db	"Extended Memory Block: $"
EMBF_S:	db	"EMB Factory Locked",13,10,"$"
EMBC_S:	db	"EMB Customer Locable",13,10,"$"
ABCD:	db	"0123456789ABCDEF"
EXIT_S:	db	10,13,"Thanks for using the RBSC's product!",13,10,"$"

MAIN_S:	db	13,10
	db	"Main Menu",13,10
	db	" 1 - Flash new ROM image",13,10
	db	" 2 - Remove flashed ROM image",13,10
	db	" 8 - Cartridge's service utilites",13,10
	db	" 0 - Exit",13,10,"$"

UTIL_S:	db	13,10
	db	"Service Menu",13,10
	db	" 1 - Compress directory",13,10
	db	" 2 - Directory initialization (erase all records)",13,10
	db	" 3 - Flash new Boot Block into the cartridge",13,10
	db	" 0 - Return to the main menu",13,10,"$"
DIRINI_S:
	db	10,13,"Directory is initialized, erase all records? (y/n) - $"
DIRINC_S:
	db	13,10,"Initialization of directory is complete!",13,10,"$"
Boot_I_S:
	db	10,13,"Are you sure you want to flash new Boot Block? (y/n) - $"
Boot_C_S:
	db	13,10,"Restoring of Boot Block is complete!",13,10,"$"
ADD_RI_S:
	db	13,10,"Input ROM image's file name for flashing: $"
OpFile_S:
	db	10,13,"Opening file: ","$"
F_NOT_F_S:
	db	"File not found!",13,10,"$"
FSizE_S:
	db	"File size error!",13,10,"$"
FR_ER_S:
	db	"File read error!",13,10,"$"
Analis_S:	db 	13,10,"Detecting ROM's mapper - $"
CTC_S:	db	"Do you confirm the type of mapper? (y/n) - ",13,10,"$"
CoTC_S:	db	"Select the type of mapper - ",13,10,"$"
Num_S:	db	10,13,"Selection - $"
FileOver_S:
	db	"File is too large or there's not enough space in the flash chip!",13,10,"$"
DirOver_S:
	db	"No more free directory entries!",13,10
	db	"Compress the directory? (y/n) - ",13,10,"$"
FFFS_S:	db	"Found free space at: $"
FDE_S:	db	"Found free directory entry at: $"
NR_I_S:	db	"Name of the directory record: $"
NR_L_S: db	"Press Enter or input a new name of the directory record:",13,10,"$"
FLEB_S:	db	"Erasing flash block - $"
FLEBE_S: db	"Error erasing flash block!",13,10,"$"
LFRI_S:	db	10,13,"Flashing ROM image, please wait...",13,10,"$"
Prg_Su_S:
	db	13,10,"The ROM image was flashed successfully!",13,10,"$"
FL_er_S:
	db	13,10,"Flashing operation failed!",13,10,"$"
FL_erd_S:
	db	13,10,"Writing of directory entry failed!",13,10,"$"


LOAD_S:	db	"The ROM image is ready to be flashed, proceed? (y/n) - $"
QQ:	db	"CBAT:$"
TWO_NL_S:	db	13,10
ONE_NL_S:	db	13,10,"$"
INVPAR_S:	db	"*** Invalid parameter(s)",13,10,"$"

MAP_E_SCC:
	db	#00,#FF,00,00,"s"
	db	"Empty Konami-5 SCC cartridge     $"
	db	#F8,#50,#00,#8C,#3F,#40	
	db	#F8,#70,#01,#8C,#3F,#60		
	db      #F8,#90,#02,#8C,#3F,#80		
	db	#F8,#B0,#03,#8C,#3F,#A0	
	db	#FF,#B2,#00,#00,#FF

CARTTAB: ; (N x 64 byte) 
	db	0					;1
	db	"Undefined cartridge type         $"	;34
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
	
	db	0

;variable
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
StartBL: ds	2
C8k:	dw	0
PreBnk:	db	0
EBlock0: db	0
EBlock:	db	0
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
	
BUFFER:	ds	256
BUFTOP:
