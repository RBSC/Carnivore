; Bios Call
ENASLT	equ	#0024
CHPUT	equ	#00A2
CLS	equ	#00C3
POSIT	equ	#00C6
CHGET	equ	#009F

; Card configuration registers
CardMDR equ	#4F80

R_Base	equ	#C010
L_STR	equ	16

	org	#4000
	db	"AB"	; ROM Identeficator
	dw	boot	; Start INIT
	dw	0	; STATEMENT
	dw	0	; DEVICE
	dw	0	; TEXT
	db	0,0,0,0,0,0
	db	"CSCCFRC"

boot:
; ESC button exit
	ld	a,(#FBEC)
	and	%00000010	; F5 No start cartridge
	ret	z
; set slot
	call	SltDet
	ld	h,#80
	call	ENASLT		; Set slot 8000-BFFF the same on 4000-3FFF

; Set Cart, Register
	ld	hl,B2ON
	ld	de,CardMDR+#0C	; set Bank2
	ld	bc,6
	ldir
; Test autostart
	ld	d,#FF
	ld	a,2
	ld	(CardMDR+#0E),a ; set 2nd bank to autostart map
	ld	hl,#8000
TA_00:	ld	a,(hl)
	or	a
	jr	z,TA_01
	inc	hl
	ld	a,(hl)
	ld	d,a
	cp	#FF
	jp	z,Menu	; deselected autostart
; autostart finded
	ld	a,1
	ld	(CardMDR+#0E),a ; set 2nd bank to directory map		
	call 	c_dir
	jr	z,Menu		; empty record, go menu
	ld	a,(#FBEC)
	and	%00001101	; ESC,F4 No autostart
	cp	%00001101
	jr	nz,Menu
	jp	RUN_CT		; not empty record go start
TA_01:	inc	hl		; next auto
	inc	hl
	ld	a,h
	cp	#A0		; out 8kb
	jp	c,TA_00		; next 
				; not found go menu
Menu:
; Main Menu
; Search records (64b) max - 256
	ld	c,d
	exx
	ld	a,1
	ld	(CardMDR+#0E),a ; set 2nd bank to directory map


	exx
	ld	d,0
	exx
Pagep:	
	call	CLS
	ld	hl,StMSG_S	; Start MEssage
	call	print	
	exx
	ld	a,c
	exx
	call	hexout


	ld	e,0	; str = 0
	exx
	ld	a,d	
	exx
	ld	d,a

; ptint page ( 16 record )



; calc dir enter point
sPrr1:	call 	c_dir
	jr	nz,prStr	; valid dir enter
nRec:	inc	d
	jp	z,dRec	; done, last record
	jr	sPrr1
prStr:
;----str---------------------
; (ix , d) - record num , e - str num
; *(h,l, a b)

;posit cursor
	ld	h,1
	ld	a,e
	add	a,7
	ld	l,a
	call	POSIT
	

; Number record

	ld	a,d
	call	hexout

; space
	ld	a,' '
	call	CHPUT
; set hl-point
	push 	ix
	pop	hl
	inc	hl
	inc	hl
	inc	hl
	inc	hl
; T-symbol
	ld	a,(hl)
	call	CHPUT
	inc	hl
; space
	ld	a,' '
	call	CHPUT
; print name
	ld	b,32-6
sPr:	ld	a,(hl)
	call	CHPUT
	inc	hl
	djnz	sPr

;--------------------------

	inc	d
	jr	z,dRec	; last dir
	inc	e
	ld	a,e	; last str
	cp	L_STR
	jp	c,sPrr1


dRec:
	ld	e,0	; cursor 0
	exx	
	ld	a,d
	exx
	ld	d,a	; restore dir enter to top page
CH00:
;posit cursor
	ld	h,3
	ld	a,e
	add	a,7
	ld	l,a
	call	POSIT
	ld	a,"*"
	call	CHPUT
	call	POSIT


CH01:	
	call	CHGET
	cp	27	; ESC
	jp	z,Exit
	cp	30	; UP
	jp	z,C_UP
	cp	31	; down
	jp	z,C_DOWN
	cp	29	; LEFT
	jp	z,P_B
	cp	28	; RIGTH
	jp	z,P_F
	cp	32	; SPACE
	jp	z,RUN_CT ; Run selected record
	cp	"R"	;
	jp	z,RUN_CR ; Run on reset
	cp	"G"
	jp	z,RUN_CJ ; Run on go to
	cp	"A"
	jp	z,AUTO_R ; set selected record to autorun
	cp	"D"
	jp	z,DAUTO_R ; deselect autorun (disable)
	cp	"?"
	jp	z,Help
	cp	"h"
	jp	z,Help
	jr	CH01
C_UP:
; cursor up (previous str select)
	ld	a,e
	or	a
	jr	z,CH01 ; 1-st str
	ld	a," "
	call	CHPUT	; CLS Cursor
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
	ld	a," "	
	call	CHPUT	; CLS Cursor
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
	exx
	ld	a,d
	exx
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
	exx
	ld	d,a
	exx
	jp	Pagep
P_B:
; Page Back
	exx
	ld	a,d
	exx
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
	exx
	ld	d,a
	exx
	jp	Pagep
PB02:	ld	d,0
	jp	PB03
RUN_CT:
; Start and autostart
; ix - point dir entry
	ld	a,(ix+#3E)
	bit	0,a
	jr	nz,RUN_CR
	bit	1,a
	ret	z
	jr	RUN_CJ	

RUN_CR:
; Configurate 	cart register and restart
; ix - point dir entry
; 
	ld	a,%00101110
	ld	(CardMDR),a
	ld	a,(ix+2)
	ld	(CardMDR+#05),a	; set start block
	push	ix
	pop	hl
	ld	bc,#23
	add	hl,bc	; config data
	ld	de,CardMDR+#06
	ld	bc,26
	ldir

	jp	0	;reset operations
RUN_CJ:
; Configurate 	cart register and start ROM
; ix - point dir entry
	ld	a,%00101110
	ld	(CardMDR),a
	ld	a,(ix+2)
	ld	(CardMDR+#05),a	; set start block
	push	ix
	pop	hl
	ld	bc,#23
	add	hl,bc	; config data
	ld	de,CardMDR+#06
	ld	bc,26
	ldir
	ld	hl,RJP
	ld	de,R_Base
	ld	bc,RJPE-RJP
	ldir
	ld	a,(ix+#3E)
	bit	2,a
	jp	z,R_Base
	ld	a,#80
	ld	(R_Base+5),a
	jp	R_Base

RJP:	ld	a,(#4000)
	ld	hl,(#4002)
	jp	(hl)
RJPE:	nop
DAUTO_R
; deselect (disable) autostart
	ld	a,2
	ld	(CardMDR+#0E),a ; set 2nd bank to autostart map
; seek to active autostart
	ld	hl,#8000
DSA_01	ld	a,(hl)
	cp	#FF
	jr	nz,DSA_02 ; next
 	inc	hl
	ld	a,(hl)	
	cp	#FF	; deselect ?
	jp	z,ATR_05; no business
; deactivate	
	dec	hl
	call	ATR_B_Erase
	ld	a,#FF
	jp	ATR_04	
DSA_02:
	inc	hl
	inc	hl
	ld	a,h
	cp	#A0		; out of range ?
	jp	c,DSA_01
; erase autostart map
	call	ATR_M_Erase
	ld	hl,#8000
	ld	a,#FF
	jp	ATR_04	
AUTO_R:
; set current recod (d) to autostart
	ld	a,2
	ld	(CardMDR+#0E),a ; set 2nd bank to autostart map
; seek to active autostart
	ld	hl,#8000
ATR_01	ld	a,(hl)
	cp	#FF
	jr	nz,ATR_02 ; next
 	inc	hl
	ld	a,(hl)	
	cp	d	; the same record ?
	jp	z,ATR_05; no business
	cp	#FF	; not autostart record
	jr	z,ATR_00 ; save autostart

; deactivate
	dec	hl
	call	ATR_B_Erase
; save new autostart
	inc	hl
	inc	hl
	inc	hl
ATR_00:	call	ATR_B_Prog
ATR_05:	ld	a,d
ATR_04:	exx
	ld	c,a
	exx
	ld	a,1
	ld	(CardMDR+#0E),a ; set 2nd bank to directory map
; print new autostart
	ld	hl,23*256+05
	call	POSIT
	exx
	ld	a,c
	exx
	call	hexout	
	jp	CH00
ATR_02:
	inc	hl
	inc	hl
	ld	a,h
	cp	#A0		; out of range ?
	jp	c,ATR_01	
; erase autostart map
	call	ATR_M_Erase
	ld	hl,#8001
	jp	ATR_05

ATR_B_Erase:
	di
	push	de
	push	hl
	ld	hl,RABE
	ld	de,R_Base
	ld	bc,RABEE-RABE
	ldir
	pop	hl
	pop	de
	jp	R_Base
RABE:
	ld	a,#AA
	ld	(#8AAA),a
	ld	a,#55
	ld	(#8555),a
	ld	a,#A0
	ld	(#8AAA),a
	xor	a
	ld	(hl),a
	ld	b,a
RABE2:	ld	a,(hl)
	xor	b
	bit	7,a
	jr	z,RABE1
	xor	b
	and	#20
	jr	z,RABE2
RABE1:	ret
RABEE
	
ATR_B_Prog:
	di
	push	de
	push	hl
	ld	hl,RABT
	ld	de,R_Base
	ld	bc,RABTE-RABT
	ldir
	pop	hl
	pop	de
	jp	R_Base
RABT:
	ld	a,#AA
	ld	(#8AAA),a
	ld	a,#55
	ld	(#8555),a
	ld	a,#A0
	ld	(#8AAA),a
	ld	a,d
	ld	(hl),a
	ld	b,a
RABT2:	ld	a,(hl)
	xor	b
	bit	7,a
	jr	z,RABT1
	xor	b
	and	#20
	jr	z,RABT2
RABT1:	ret

RABTE
ATR_M_Erase:
	di
	push	de
	push	hl
	ld	hl,RAME
	ld	de,R_Base
	ld	bc,RAMEE-RAME
	ldir
	pop	hl
	pop	de
	jp	R_Base
RAME:
	ld	a,#AA
	ld	(#8AAA),a
	ld	a,#55
	ld	(#8555),a
	ld	a,#80
	ld	(#8AAA),a
	ld	a,#AA
	ld	(#8AAA),a
	ld	a,#55
	ld	(#8555),a
	ld	a,#30
	ld	(#8000),a
RAME2:	ld	a,(#8000)
	xor	#FF
	bit	7,a
	jr	z,RAME1
	xor	#FF
	and	#20
	jr	z,RAME2
RAME1:	ret
	
RAMEE

Help:
; Print help informations page
	call	CLS
	ld	hl,helpmsg
	call	print
	LD	HL,#0101
	call    POSIT
	call	CHGET
	call	CHPUT
	jp	Pagep

Exit:	jp	CLS
;-------------------------------------------------------------------------

; Print	String
; Inp reg HL - point start String
; (hl) = 0 -> end
print:
	ld	a,(hl)
	or	a
	ret	z
	call	CHPUT
	inc	hl
	jr	print

;	slot detect
;	Out reg A = present value slot on 4000-7FFF
SltDet:
	di
	in	a,(#A8)
	ld	b,a		; save primary slot
	and	%00111111
	ld	c,a
	ld	a,b
	and	%00001100
	rlc	a
	rlc	a
	rlc	a
	rlc	a
	or	c
	out	(#A8),a		; set page3 to slot from page1
	ld	a,(#FFFF)
	xor	#FF
	ld	c,a		; save secondary slot
	xor	%11000000
	ld	d,a		; test page3
	ld	(#FFFF),a
	ld	a,(#FFFF)
	cp	d		; Z - (#FFFF)= RAM
	jr	z,notExpS
	xor	#FF
	cp	c		; Z - (#FFFF)= constant		
	jr	z,notExpS	
	cp	d		; rd = neg(wr) - Slot register
	jr	nz,notExpS		
	ld	a,c
	ld	(#FFFF),a	; restore value Expand slot
	and	%00001100
	or	%10000000       ; record detect secondary
	jr	sldet1	
notExpS:
	ld	a,c
	xor	#FF
	ld	(#FFFF),a 	; restore value memory byte
	xor	a
sldet1:	ld	c,a
	ld	a,b
	rrc	a
	rrc	a
	and	%00000011       ; record detect primary
	or	c		; A - out value
	ld	c,a
	ld	a,b
	out	(#A8),a
	ld	a,c
	ret
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
	cp	#FF	; emptry ?
	ret	z	; RET Z=1
	ld	a,(ix+1)
	or	a	; delete ?
	ret

hexout:	push	af
	rrc     a
	rrc     a
	rrc     a
	rrc     a
	and 	#0F
	add	a,48
	cp	58
	jr	c,he1
	add	a,7
he1:	call	CHPUT
	pop	af
	and 	#0F
	add	a,48
	cp	58
	jr	c,he2
	add	a,7
he2:	call	CHPUT
	ret
	
StMSG_S:
;	db	3
	db	"Multicartridge Carnivore SCC Menu v1.0",#0A,#0D
	db	"  press '?' for help",#0A,#0A,#0D
	db	" Autostart selected - "
	db	0
helpmsg:
	db	" Help page",#0A,#0A,#0D
	db	"Use cursor button for menu navigation",#0A,#0D
	db	"(UP),(DOWN) - posit to string record",#0A,#0D
	db	"(LEFT),(RIGHT) - page select",#0A,#0D
	db	"(SPACE) - start selected record",#0A,#0D	
	db	"(ESC) - exit to continue booting system",#0A,#0D
	db	"(SHIFT)+(R) - start record after restart",#0A,#0D
	db	"(SHIFT)+(G) - start record immediately",#0A,#0D
	db	"(SHIFT)+(A) - select record to autostart",#0A,#0D
	db	"(SHIFT)+(D) - unselect autostart",#0A,#0D
	db	"press at boot:" ,#0A,#0D
	db	"(TAB) - disable autostart",#0A,#0D
	db	"(F5)  - disable boot catridge",#0A,#0D
	db	"press anykey for return"		
	db	0

B2ON:	db	#F0,#70,#01,#15,#7F,#80







		