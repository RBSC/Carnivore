;	.z80
	org	#100
	ld	a,1
	ld	de,buff
	call 	EXTPAR
	ret	c
;
	ld	hl,buff
	ld	ix,SINIT
	ld	b,0
parc1:	ld	a,(hl)
	or	a
	jr	z,parc2
	inc	hl
	inc	b
	ld	a,b
	cp	4
	jr	c,parc1
ParEr:
	scf
	ret
parc2:

parc3:	dec	hl
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
;parametr2
	ld	bc,#2007	; Prepare the DIR
	ld	de,buff+2
	ld	hl,buff+1
	ld	(hl),b
	ldir

	ld	a,2		;get file name from parametr#2
	ld	de,buff+1
	call 	EXTPAR
	jp	c,setreg
	ld	de,buff

	ld	a,0		; set drive "default"
	ld	hl,buff
	ld	(hl),a
pa2_1:	inc	hl
	ld	a,(hl)
	or	a
	jr	nz,pa2_1
	ld	(hl)," "	; 0 to " "
	ld	hl,buff+9
	ld	(hl),"C"        ; set ext filename
	inc	hl
	ld	(hl),"R"
	inc	hl
	ld	(hl),"F"
	inc	hl
	ld	(hl),a

	ld	bc,24	; Prepare the FCB
	ld	de,buff+13
	ld	hl,buff+12
	ld	(hl),b
	ldir
	
	ld	c,#0F
	ld	de,buff
	call	5	; open file	
	ld	hl,1
	ld	(buff+14),hl ;recod size = 1 byte
	or	a
	ld	de,DosErr
	jp	nz,Done
		
	ld	c,#1A
	ld	de,CRF
	call	5	; set DMA

	ld	c,#27
	ld	de,buff
	ld	hl,CRFe-CRF
	call	5
	or	a
	ld	de,DosErr
	jp	nz,Done

setreg:
	ld	a,1
	ld	h,#40
	call	#24
	ld	hl,SINIT
	ld	de,#4F85
	ld	bc,SINITE-SINIT
	ldir
	ld	hl,RRES
	ld	de,#8000
	ld	bc,RRSSE-RRES
	ldir
	jp	#8000
RRES:
	ld	a,(#FCC1)
	ld	h,0
	call	#24
	ld	a,(#FCC1)
	ld	h,#40
	call	#24
	call	#6F
	rst	0
RRSSE:	nop
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
Done:	ld	c,#09
	call	5
	rst	0


DosErr:	db	"Illegal type cartridge parametr or file error",#0D,#0A,"$"
SINIT:	DB 	#05
CRF:	DB 	#F8, #50, #00, #84, #3F, #40
	DB	#F8, #70, #01, #84, #3F, #60
	DB	#F8, #90, #02, #84, #3F, #80
	DB	#F8, #B0, #03, #84, #3F, #A0
	db	#00, #B2
CRFe:
SINITE:	db 0
buff:	db    0,0,0,0,0
	
