;*****************************
;***                       ***
;***   MACROS, CONSTANTS   ***
;***                       ***
;*****************************

	;--- Macro for printing a $-finished string

print	macro	
	ld	de,\1
	ld	c,_STROUT
	call	DOS
	endm


	;--- System variables and routines

DOS:	equ	#0005	;DOS function calls entry point
ENASLT:	equ	#0024

TPASLOT1:	equ	#F342
ARG:	equ	#F847
EXTBIO:	equ	#FFCA

;CSCCR:	equ	#4F80

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


CHECKSL:
	;--- Checks if there are command line parameters.
	;    If not, prints information and finishes.

	ld	a,1
	ld	de,BUFFER
	call	EXTPAR
	jr	nc,HAYPARS

;TERMINFO:	print	INFO_S
TERMINFO:
	ld	de,INFO_S
termdos:
	ld	c,_STROUT
	call	DOS

	ld	c,_TERM0
	jp	DOS

HAYPARS:	;
	; 2-st parametr #slot
	ld	a,2
	ld	de,BUFF1
	call	EXTPAR
	jr	c,AutoSlot	
	ld	hl,BUFF1
	ld	a,(hl)
	sub	"0"
	jr	nc,HyPs1
errslt:	ld	de,ERRSlt_S
	jp	termdos
HyPs1:	cp	4
	jr	nc,errslt
	ld	b,a
	inc	hl
	ld	a,(hl)
	or	a
	jr	z,HyPs2
	sub	"0"
	jr	c,errslt
	cp	4
	jr	nc,errslt
	rlc	a
	rlc	a
	or	#80
	or	b
	ld	b,a
	inc	hl
	ld	a,(hl)
	or	a
	jr	nz,errslt
HyPs2:	or	b
	jr	SlotOk

AutoSlot:
	ld	a,1
SlotOk:	ld	(slot),a	; slot #1 
;	call	HEXOUT
	;
	; "ALL" or address block erase	

	ld	hl,BUFFER
	ld	de,ALL_S
	call	STR_CP
	jp	z,AllErase
	
	; processing block address parametr

	ld	hl,BUFFER
	ld	b,0
parc1:	ld	a,(hl)
	or	a
	jr	z,parc2
	inc	hl
	inc	b
	ld	a,b
	cp	7
	jr	c,parc1
ParEr:
	ld	de,PAR_ER_S
	jp	termdos
parc2:
	ld	ix,Param1
parc3	dec	hl
	ld	a,(hl)
	sub	#30
	cp	10
	jr	c,parc4
	sub	7
	cp	16
	jr	NC,ParEr
parc4	ld	c,a
	ld	(ix),a
	dec	b	
	jr	z,ParEnd	
	dec	hl
	ld	a,(hl)
	sub	#30
	cp	10
	jr	c,parc5
	sub	7
	cp	16
	jr	NC,ParEr
parc5	rlc	a
	rlc	a
	rlc	a
	rlc	a
	or	c
	ld	(ix),a
	inc	ix
	djnz	parc3	

ParEnd:
	; Block Erase

	ld	a,(slot)
	call	TestROM
;	jp	c,termdos

	print	BlkErs_S
	ld	a,(Param1+2)
	call	HEXOUT
	ld	a,(Param1+1)
	call	HEXOUT
	ld	a,(Param1)
	call	HEXOUT
	print 	Cont_S
	ld	c,_CONIN
	call	DOS
	cp	"y"
	jr	z,ErB0
	cp	"Y"
	jr	z,ErB0
	print	CRLF_S	
	ld	de,EMGO_S
	jp	termdos
	;
ErB0:
	print	CRLF_S
	print	ProcE_S
	ld	a,(slot)
	call	TestBlk
	jr	z,ErB1
	print	ProtBl_S
ErB1:	ld	a,(slot)
	call	BlkErase
	jr	c,ErrFin
	jr	OkFin

AllErase:

	ld	a,(slot)
	call	TestROM
	print	AllErs_S
	ld	c,_CONIN
	call	DOS
	cp	"y"
	jr	z,AllEr0
	cp	"Y"
	jr	z,AllEr0
	print	CRLF_S	
	ld	de,EMGO_S
	jp	termdos
AllEr0:	ld	a,(slot)
	call	ChipErase
	jr	c,ErrFin
	jr	OkFin

ErrFin:
	ld	de,ErsErr
	jp	termdos
OkFin:	ld	de,ErsOk
	jp	termdos


;*********************************************
;input a - Slot Number
;*********************************************	
ChipErase:
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
	ld	a,#80
	ld	(#4AAA),a	; Erase Mode
	ld	a,#AA
	ld	(#4AAA),a
	ld	a,#55
	ld	(#4555),a
	ld	a,#10		; Command Erase Block
	ld	(#4AAA),a

	ld	a,#FF
    	ld	de,#4000
    	call	CHECK
;    	jp  c,Done      ; Jump if Erase fail
	push	af
	ei
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT          ; Select Main-RAM at bank 4000h~7FFFh
	pop	af
	ret

;*********************************************
;input a - Slot Number, Param1[2..0] - address 
;*********************************************	
BlkErase:
	ld	(cslt),a
	ld	h,#40
	call	ENASLT
	ld	a,#95		; enable write  to bank (current #85)
	ld	(R1Mult),a  

	di
	ld	a,(Param1+2)
	ld	(AddrM2),a
	ld	a,(Param1+1)
	ld	(AddrM1),a
	ld	a,(Param1)
	ld	(AddrM0),a
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
;    	jp  c,Done      ; Jump if Erase fail
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
    	ld	de,ErsErr
    	scf
CHK_R1:	pop bc
	ret

;*********************************************
;input a - Slot Number, Param1[2..0] - address 
;*********************************************	
TestBlk:
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

	ld	a,(Param1+2)
	ld	(AddrM2),a
	ld	a,(Param1+1)
	ld	(AddrM1),a
	ld	a,#04
	ld	(AddrM0),a
	ld	a,(DatM0)
	or	a
	push	af
	ld	a,#F0
	ld	(#4000),a	; Autoselect Mode OFF
	ei
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT          ; Select Main-RAM at bank 4000h~7FFFh
	pop	af
	ret

;*********************************
;input a - Slot Number
;*********************************
TestROM:
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

;--- String compare
; HL - 1st string
; DE - 2nd string
; B  - length
; output NZ - false, Z - true
STR_CP:
	ld	a,(de)
	or	a
	ret	z
	cp	(hl)
	ret	nz
	inc	hl
	inc	de
	djnz	STR_CP
	ret



;***************************
;***                     ***
;***   DATA, VARIABLES   ***
;***                     ***
;***************************



;--- Variables

CON_NUM:	db	#FF	;Connection handle
INPUT_MODE:	db	0	;0 for line mode, #FF for character mode
GETCHAR_FUN:	db	_CONIN	;_CONIN for echo ON, _INNOE for echo OFF
DOS2:		db	0	;0 for DOS 1, #FF for DOS 2

;--- Text strings
USEDOS2_S:
	db	"* USE DOS2 "
CRLF_S:	db	13,10,"$"
SltN_S:	db	"Slot - $"
M29W640:
        db      "Detect M29W640G$"
NOTD_S:	db	"FlashROM not detected",13,10,"$"

PRESENT_S:
	db	"Erase flashrom for",13,10
	db	"Carnivore SCC Cartridge",13,10,10,"$"

INFO_S:	db	"Usage: Erase <hexaddress> [<slot>]",13,10,10
	db	"       for example:",13,10
	db	"$"
MfC_S:	db	"Manufacturer Code: $"
DVC_S:	db	"Device code: $"
EMB_S:	db	"Extended Memory Block: $"
EMBF_S:	db	"EMB Factory loced",13,10,"$"
EMBC_S:	db	"EMB Customer Locable",13,10,"$"
ABCD:	db	"0123456789ABCDEF"
ALL_S:	db	"ALL",0
ERRSlt_S:
	db	"Error slot number",13,10,"$"
PAR_ER_S:
	db	"Error block rease address",13,10,"$"
BlkErs_S:
	db	"Block Erase from: $"
AllErs_S:
	db	"Chip Erase. Attention! will be destroyed cartridge boot block!",13,10
Cont_S:	db	" Continue ? (y/n)$"
EMGO_S:	db	"Emergency evacuation",13,10,"$"
ProcE_S: db	"Wait process is executed...$"
ProtBl_S:
	db	"Block protected $"
ErsErr:	db	"Error erase",13,10,"$"
ErsOk:	db	"Erase complete",13,10,"$"


;sAAA_AA: db #AA,#0A,#00, #AA
;s555_55: db #55,#05,#00, #55
;sAAA_90: db #AA,#0A,#00, #90

Param1:	  db	0,0,0
slot:	db	1
cslt:	db	0
Det00:	db	0
Det02:	db	0
Det1C:	db	0
Det1E:	db	0
Det06:	db	0
;Det04:	ds	134
BUFFER:		ds	512
		db	"$"
BUFF1:	ds	16
