
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


        ld      bc,24           ; Prepare the FCB
        ld      de,FCB+13
        ld      hl,FCB+12
        ld      (hl),b
        ldir                    ; Initialize the second half with zero
;
; File name processing
	ld	hl,FCB+1
	ld	ix,BUFFER

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
	jr	z,OpenFile
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
	jr	z,OpenFile
	ld	(hl),a
	inc	ix
	inc	hl
	djnz	fnp2	
;
OpenFile:
; Control informations on diplay
      
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
	ld	c,_TERM0
	jp	DOS		

Fpo
; File was opened
	ld	a,2
	ld	de,BUFFER
	call	EXTPAR
	jr	c,ParEnd	; not parametr => StFlAddr=0
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
	ld	c,_STROUT
	call	DOS
	ld	c,_TERM0
	jp	DOS
parc2:
	ld	ix,Param2
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
; Control Print Parametr

	ld	a,(Param2+2)
	call	HEXOUT
	ld	a,(Param2+1)
	call	HEXOUT
	ld	a,(Param2)
	call	HEXOUT

	ld	e,"-"
	ld	c,_CONOUT
	call	DOS

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
; check maximal file size
;
; max size = 8 Mb (1000.0000.0000h) - Param2
; 
	ld	a,(Size+3)
	or	a
	jr	z,msz0
	ld	de,FileSzB	; File to big!
	jp 	termdos	
msz0:
	xor	a
	ld	hl,0
	ld	de,(Param2)
	sbc	hl,de
	ld	a,(Param2+2)
	ld	b,a
	ld	a,#80
	sbc	a,b
	ld	c,a
	jr	nc,msz1

	ld	de,ParOvz_S	; Start addres big
	jp 	termdos
msz1:
;	ld	b,a
;	ex	hl,de 
	ld	de,(Size)
	sbc	hl,de
	ld	a,(Size+2)
	ld	b,a
	ld	a,c
	sbc	a,b
	jr	nc,msz2
	ld	de,FileSzB	; File to big!
	jp 	termdos
msz2:
;;;;;;;;;;;;;;;;;;;;

	ld	a,(slot)
	call	TestROM
;	jp	c,termdos


;;;;;;;;;;;;;;;;;;;;

	ld	de,StPrg_S
	ld	c,_STROUT
	call	DOS
	
	ld	c,_CONIN
	call	DOS
	cp	"y"
	jr	z,Prg
	cp	"Y"
	jr	z,Prg
;;;;;;;;
	ret
;;;;;;;;
Prg:
	ld	de,ONE_NL_S
	ld	c,_STROUT
	call	DOS

;	ld	a,#01	; 1 primary slot
;	ld	h,#40	; 4000-7FFFh
;	call	ENASLT

	ld      c,_SDMA
	ld      de,BUFTOP
	call    DOS
; Portion of 2000h bytes

	ld	a,0
	ld	(lastbl),a

Mcprg:

; DEC Size

	ld	hl,(Size)
	ld	de,#2000
	sbc	hl,de
	ld	a,(Size+2)
	sbc	a,0

	jr	c,Lbl		; последний блок
;!!!!!!!!!!!!!!!!!!!!!!!!!
; sub Size(),2000h
	ld	(Size),hl
	ld	(Size+2),a
;	ld	(SizeBl),de
	ex	hl,de
	jr	NLbl
Lbl:	
	ld	a,(lastbl)
	xor	a
	jp	nz,PrgDone
	ld	a,1
	ld	(lastbl),a
	add	hl,de
	ld	a,h
	or	e
	jp	z,PrgDone
NLbl:
;hl - size block to Flash
	ld	(SizeBl),hl

;	in	a,(#A8)
;	ld	(SAVESL),A


	ld      c,_RBREAD
	ld	de,FCB
	call    DOS
	or	a
	jp	nz,FrErr
; Buffer redy
;	control print
;	ld	hl,0
;	ld	a,(Param2+2)
;	call	HEX
;	call	WRTVRM
;	inc	hl
;	ld	a,b
;	call	WRTVRM
;	ld	a,(Param2+1)
;	call	HEX
;	call	WRTVRM
;	inc	hl
;	ld	a,b
;	call	WRTVRM
;	inc	hl
;	ld	a,(Param2)
;	call	HEX
;	call	WRTVRM
;	inc	hl
;	ld	a,b
;	call	WRTVRM
;	inc	hl
;	ld	a,"-"
;	call	WRTVRM
;	inc	hl
;	ld	a,(BUFTOP)
;	call	HEX
;	call	WRTVRM
;	inc	hl
;	ld	a,b
;	call	WRTVRM	
;	inc	hl
;	ld	a," "
;	call	WRTVRM

	ld	e,#0D
	ld	c,_CONOUT
	call	DOS
	ld	a,(Param2+2)
	call	HEXOUT
	ld	a,(Param2+1)
	call	HEXOUT
	ld	a,(Param2)
	call	HEXOUT

	ld	e," "
	ld	c,_CONOUT
	call	DOS

	ld	a,(BUFTOP)
	call	HEXOUT




; Poehali!
	ld	a,(SLTFLC)	; Set Cartridge Slot
	ld	h,#40		; 4000-7FFFh
	call	ENASLT	
	di
	ld	hl,BUFTOP
	ld	DE,(SizeBl)
	ld	a,#20
	ld	(#4F80),a
nextbp:
; send 1st
	exx

; внимание затычка
;	jr	zat1
; address byte load
	ld	hl,Param2
	ld	de,#4F81
	ld	bc,3
	ldir

; send 1st
;;	ld	hl,sAAA_AA
;;	ld	de,#4F81
;;	ld	bc,4
;;	ldir
	ld	a,#AA
	ld	(#4AAA),a
; send 2nd
;	ld	hl,s555_55
;;	ld	de,#4F81
;;	ld	bc,4
;;	ldir
	ld	a,#55
	ld	(#4555),a
; send 3st
;	ld	hl,sAAA_A0
;;	ld	de,#4F81
;;	ld	bc,4
;;	ldir
	ld	a,#A0
	ld	(#4AAA),a

; Load byte
;;	ld	hl,Param2
;;	ld	de,#4F81
;;	ld	bc,3
;;	ldir

	exx
	ld	a,(hl)
	ld	(#4F84),a


; control result

	ld	c,a
pchk_l1:
	ld	a,(#4F84) 
	xor	c
	jp	p,pchk_r1 ; r bit7 = w bit7
	xor	c
	and	#20
	jr	z,pchk_l1 ; r bit5 = 1 (wait)
	ld	a,(#4F84)
	xor	c
	jp	p,pchk_r1 ; r bit7 = w bit7
	scf
	jp	PrgFalse

;	затычка	
zat1:

	ld	hl,Param2
	ld	de,#4F81
	ld	bc,3
	ldir
	exx
	ld	a,(#4F84)
	cp	a,(hl)
	jp	nz,PrgFalse
	
;  end bzzz
pchk_r1:

	exx
	ld	hl,(Param2)
	ld	de,1
	add	hl,de
	ld	(Param2),hl
	ld	a,(Param2+2)
	adc	a,0
	ld	(Param2+2),a
	exx

	inc	hl
	dec	de
	ld	a,e
	or	d
	jp	nz,nextbp
	ei
	jp	Mcprg


PrgDone:
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT
;	ld	a,(SAVESL)
;	out     (#A8),a
	ei
	ld	de,ONE_NL_S
	ld	c,_STROUT
	call	DOS
	ld	de,PRG_OK_S
	ld	c,_STROUT
	call	DOS
	ld	c,_TERM0
	jp	DOS
PrgFalse:
	ld	a,(hl)
	ld	(CByte),a
	ld	a,(#4F84)
	ld	(CByte+1),a
;	ld	a,(SAVESL)
;	out     (#A8),a
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT
	ei
	ld	de,ONE_NL_S
	ld	c,_STROUT
	call	DOS
	ld	a,(Param2+2)
	call	HEXOUT
	ld	a,(Param2+1)
	call	HEXOUT
	ld	a,(Param2)
	call	HEXOUT

	ld	e," "
	ld	c,_CONOUT
	call	DOS

	ld	a,(CByte)
	call	HEXOUT

	ld	e,"-"
	ld	c,_CONOUT
	call	DOS
	ld	a,(CByte+1)
	call	HEXOUT

	ld	de,ONE_NL_S
	ld	c,_STROUT
	call	DOS
	ld	de,PRG_ER_S
	ld	c,_STROUT
	call	DOS
	ld	c,_TERM0
	jp	DOS
FrErr:
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT
;	ld	a,(SAVESL)
;	out     (#A8),a
	ei	
	ld	de,ONE_NL_S
	ld	c,_STROUT
	call	DOS
	ld	de,FR_ER_S
	ld	c,_STROUT
	call	DOS
	ld	c,_TERM0
	jp	DOS



;---



;******************************
;***                        ***
;***   AUXILIARY ROUTINES   ***
;***                        ***
;******************************

;--- STRCMP: Compares two strings
;    Input: HL, DE = Strings
;    Output: Z if strings are equal

STRCMP:
	ld	a,(de)
	cp	(hl)
	ret	nz
	or	a
	ret	z
	inc	hl
	inc	de
	jr	STRCMP


;--- NAME: COMP
;      Compares HL and DE (16 bits unsigned)
;    INPUT:    HL, DE = numbers to compare
;    OUTPUT:    C, NZ if HL > DE
;               C,  Z if HL = DE
;              NC, NZ if HL < DE

COMP:	call	_COMP
	ccf
	ret

_COMP:	ld	a,h
	sub	d
	ret	nz
	ld	a,l
	sub	e
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


;--- Termination due to ESC or CTRL-C pressing
;    Connection is closed, or aborted if CTRL is pressed,
;    and program finishes

CLOSE_END:	ld	a,(CON_NUM)
	cp	#FF
	jr	z,TERMINATE
	push	af
	call	SET_UNAPI
	pop	bc

	ld	a,(#FBEB)	;Checks CTRL key status
	bit	1,a	;in order to decide whether

	ld	de,USERAB_S
CLOSE_END2:	push	de

	call	CALL_UNAPI

CLOSE_END3:	pop	de
	jp	PRINT_TERM


;--- Program terminations

	;* Print string at DE and terminate

PRINT_TERM:
	ld	c,_STROUT
	call	DOS
	jr	TERMINATE

	;* Invalid parameter

;INVPAR:	print	INVPAR_S

INVPAR:	ld	de,INVPAR_S
	ld	c,_STROUT
	call	DOS


	jr	TERMINATE

	;* Missing parameter

;MISSPAR:	print	MISSPAR_S
MISSPAR:	ld	de,MISSPAR_S
	ld	c,_STROUT
	call	DOS

	jr	TERMINATE

MISSHNM:        ld	de,MISSHNM_S
	ld	c,_STROUT
	call	DOS

	;* Generic termination routine

TERMINATE:
	ld	a,(TPASLOT1)
	ld	h,#40
	call	ENASLT

	ld	a,(TPASEG1)	;Restores TPA on page 1
	call	PUT_P1

	ld	a,(DOS2)	;Under DOS 2, the CTRL-C
	or	a	;control routine has to be cancelled first
	ld	de,0
	ld	c,_DEFAB
	call	nz,DOS

	ld	c,_TERM0
	jp	DOS


;--- Prints LF

LF:	ld	e,10
	ld	c,_CONOUT
	jp	DOS


;--- Segment switching routines for page 1,
;    these are overwritten with calls to
;    mapper support routines on DOS 2

PUT_P1:	out	(#FD),a
	ret
GET_P1:	in	a,(#FD)
	ret

TPASEG1:	db	2	;TPA segment on page 1


;--- IP_STRING: Converts an IP address to a string
;    Input: L.H.E.D = IP address
;           A = Termination character
;           IX = Address for the string

IP_STRING:
	push	af
	ld	a,l
	call	BYTE2ASC
	ld	(ix),"."
	inc	ix
	ld	a,h
	call	BYTE2ASC
	ld	(ix),"."
	inc	ix
	ld	a,e
	call	BYTE2ASC
	ld	(ix),"."
	inc	ix
	ld	a,d
	call	BYTE2ASC

	pop	af
	ld	(ix),a	;Termination character
	ret


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

NUMTOASC:	push	af,ix,de,hl
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

EXTNUM16:	call	EXTNUM
	ret	c
	jp	c,INVPAR	;Error if >65535

	ld	a,e
	or	a	;Error if the last char is not 0
	ret	z
	scf
	ret


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


;--- CHECK_KEY: Calls a DOS routine so the CTRL-C pressing
;    can be detected by DOS and the program can be aborted.
;    Also, returns A<>0 if a key has been pressed.

CHECK_KEY:	ld	e,#FF
	ld	c,_DIRIO
	jp	DOS


;--- BYTE2ASC: Converts the number A into a string without termination
;    Puts the string in (IX), and modifies IX so it points after the string
;    Modifies: C

BYTE2ASC:	cp	10
	jr	c,B2A_1D
	cp	100
	jr	c,B2A_2D
	cp	200
	jr	c,B2A_1XX
	jr	B2A_2XX

	;--- One digit

B2A_1D:	add	"0"
	ld	(ix),a
	inc	ix
	ret

	;--- Two digits

B2A_2D:	ld	c,"0"
B2A_2D2:	inc	c
	sub	10
	cp	10
	jr	nc,B2A_2D2

	ld	(ix),c
	inc	ix
	jr	B2A_1D

	;--- Between 100 and 199

B2A_1XX:	ld	(ix),"1"
	sub	100
B2A_XXX:	inc	ix
	cp	10
	jr	nc,B2A_2D	;If ti is 1XY with X>0
	ld	(ix),"0"	;If it is 10Y
	inc	ix
	jr	B2A_1D

	;--- Between 200 and 255

B2A_2XX:	ld	(ix),"2"
	sub	200
	jr	B2A_XXX


;--- GET_STRING: Returns the string associated to a number, or "Unknown".
;    Input:  DE = Pointer to a table of numbers and strings, with the format:
;                 db num,"String$"
;                 db num2,"String2$"
;                 ...
;                 db 0
;            B = Associated number
;    Output: DE = Pointer to the string

GET_STRING:	ld	a,(de)
	inc	de
	or	a	;String not found: return "Unknown"
	jr	nz,LOOP_GETS2

	ld	ix,UNKCODE_S
	ld	a,b
	call	BYTE2ASC
	ld	(ix),")"
	ld	(ix+1),"$"

	ld	de,STRUNK_S
	ret

LOOP_GETS2:	cp	b	;The number matches?
	ret	z

LOOP_GETS3:	ld	a,(de)	;No: pass to the next one
	inc	de
	cp	"$"
	jr	nz,LOOP_GETS3
	jr	GET_STRING

STRUNK_S:	db	"*** Unknown error ("
UNKCODE_S:	db	"000)$"

;--- Code to switch TCP/IP implementation on page 1, if necessary

SET_UNAPI:
UNAPI_SLOT:	ld	a,0
	ld	h,#40
	call	ENASLT
	ei
UNAPI_SEG:	ld	a,0
	jp	PUT_P1


CALL_UNAPI:	jp	0

;--- Extract parametr's on buffer
;	HL - buffer
;	IY N# Word
G_PA:
	XOR	A
	ld	(PA_ST),a	
	dec	hl
G_PA1:	
	inc	hl
	ld	a,(hl)
	cp	0	; end of file
	ret	z
	cp	#1A
	ret	z       ; end of file
	cp	#0D
	jr	z,G_PA1 ; end of string
	cp	#0A
	jr	z,G_PA1	;
	
	push	iy
	call	G_PA_N
	pop	iy
        jr	G_PA1

;--- Extract parametr on string
; IY - N# Word
; HL - buffer
G_PA_N:
	ld	a,(iy)    ; index on name parametr
	or	a         ; if = 0 to finish
	ret	z
	ld	e,a
	inc	iy
	ld	d,(iy)
	inc 	iy
	ld	a,(de)    ; len
	inc	de        ; de - (name parametr)
	ld	b,a
	push	hl
	call	STR_CP
	jr	z,G_PA_1	; Ok, go to extract
	pop	hl
	inc	iy
	inc	iy
	jr	G_PA_N       	; next search word of parametr
G_PA_1:				; Extract parametr to (parametr)
				; (hl) -> (de) util 0, #0D, #0A, #1A (EOF), ";"
	ld	a,(de)		; bit mask parametr
	ld	b,a
	ld	a,(PA_ST)
	or	b
	ld	(PA_ST),a
	ld	e,(iy)
	inc	iy
	ld	d,(iy)
	inc	iy
G_PA_3	ld	a,(hl)
	cp	0
	jr	z,G_PA_2	
	cp	#0D
	jr	z,G_PA_2
	cp	#1A
	jr	z,G_PA_2
	cp	";"
	jr	z,G_PA_2
	ld	(de),a
	inc	hl
	inc	de
	jr	G_PA_3

G_PA_2:	xor	a
	ld	(de),a		; 0 -> end of parametr
	scf
	pop	bc		; correction stack
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
;--- Console string out until 0 char
CONOUTS:
	ld	a,(de)
	cp	0
	ret	z
	push	de
	ld	e,a
	ld	c,_CONOUT
	call 	DOS
	pop	de
	inc	de
	jr	CONOUTS
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
WRTVRM:
	RST	#30
biossl: db	0
	dw	#004D
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
	db	"* USE DOS2 ",13,10,"$"


PRESENT_S:
	db	"Loading for Flesh ROM cartridge",13,10
	db	"Carnivore on absolute address",13,10,10,"$"

INFO_S:	db	"Usage: ABSPROG <filename.ext> <hexaddress> [<slot>]",13,10,10
	db	"       for example:",13,10
	db	"       ABSPROG SYSCSCC.ROM 00000 01",13,10, "$"

USERCLOS_S:	db	13,10,"*** Connection closed by user",13,10,"$"
USERAB_S:	db	13,10,"*** Connection aborted by user",13,10,"$"
INVPAR_S:	db	"*** Invalid parameter(s)",13,10,"$"
MISSPAR_S:	db	"*** Missing parameter(s)",13,10,"$"
MISSHNM_S:	db	"*** Missing hostname",13,10,"$"
PA_ST:	db	0	; bit mask status parametr's
			; 0 - server		1 - port
			; 2 - server password   3 - nick
			; 4 - user str

OpFile_S:
	db	"Open File: ","$"
F_NOT_F_S:
	db	"File not found",13,10,"$"
PAR_ER_S:
	db	"Error of start address",13,10,"$"
StPrg_S:
	db	"Start loading to Flash ?$"
PRG_OK_S:
	db	"Loading finish",13,10,"$"
PRG_ER_S:
	db	"Loading stop on ERROR!",13,10,"$"
FR_ER_S:
	db	"File read ERROR!",13,10,"$"	
ParOvz_S:
	db	"Start Address oversize",13,10,"$"
FileSzB:
	db	"File size to big for Flash room",13,10,"$"
ABCD:	db	"0123456789ABCDEF"
MfC_S:	db	"Manufacturer Code: $"
DVC_S:	db	"Device code: $"
EMB_S:	db	"Extended Memory Block: $"
EMBF_S:	db	"EMB Factory loced",13,10,"$"
EMBC_S:	db	"EMB Customer Locable",13,10,"$"
CRLF_S:	db	13,10,"$"
SltN_S:	db	"Slot - $"
M29W640:
        db      "Detect M29W640G$"
NOTD_S:	db	"FlashROM not detected",13,10,"$"

TWO_NL_S:	db	13,10
ONE_NL_S:	db	13,10,"$"


SLTFLC:	db	#01	

;--- File Control Block
FCB:	db	0
	db	"           "
	ds	28
FILENAME: db    "                                $"
Size:	db 0,0,0,0
SizeBl:	dw 0
Param2:	  db	0,0,0
CByte:	  db 0,0
SAVESL:	  db #FF
lastbl:	  db 0

Param1:	  db	0,0,0
slot:	db	1
cslt:	db	0
Det00:	db	0
Det02:	db	0
Det1C:	db	0
Det1E:	db	0
Det06:	db	0



NullA:	db 0,0,0
sAAA_AA: db #AA,#0A,#00, #AA
s555_55: db #55,#05,#00, #55
sAAA_A0: db #AA,#0A,#00, #A0



;

;--- Generic temporary buffer for data send/receive
;    and for parameter parsing
POINT:		ds	2
LBUFF:		ds      2
BUFFER:		ds	512
		db	"$"
BUFFER1:	ds	512
BUFTOP:
