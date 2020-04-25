.include "defs.s"
.include "colorPallete.s"

.code

;;; ----------------------------------------------------------------------------
;;; Reset handler
.segment "CODE"
.proc reset
	sei			; Disable interrupts
	cld			; Clear decimal mode
	ldx #$ff
	txs			; Initialize SP = $FF
	inx
	stx PPUCTRL		; PPUCTRL = 0
	stx PPUMASK		; PPUMASK = 0
	stx APUSTATUS		; APUSTATUS = 0
	stx $4010
	lda #$0

	;; PPU warmup, wait two frames, plus a third later.
	;; http://forums.nesdev.com/viewtopic.php?f=2&t=3958
:	bit PPUSTATUS
	bpl :-
:	bit PPUSTATUS
	bpl :-

	;; Zero ram.
	txa
:	sta $000, x
	sta $100, x
	sta $200, x
	sta $300, x
	sta $400, x
	sta $500, x
	sta $600, x
	sta $700, x
	inx
	bne :-

	;; Final wait for PPU warmup.
:	bit PPUSTATUS
	bpl :-

paletteInit:
	lda #$3f
	sta PPUADDR
	
	lda #$00
	sta PPUADDR
	
	ldx #$0

	lda RED_0
	sta PPUDATA

	lda #$3f
	sta PPUADDR
	
	lda #$01
	sta PPUADDR

bgPalette1:
	lda colorPallete, x
	sta PPUDATA
	inx
	cpx #$C
	bne bgPalette1
	
	ldx #$0

spritePalette:
	inx
	stx $2007
	cpx #$10
	bne spritePalette
	ldx #$00
	clc

; start ppu
ppu:
	lda #%10010000
	sta PPUCTRL
	lda #%00011000
	sta PPUMASK

initString:
	lda #$00
	sta CHAR_COUNTER
	
	ldy #00
	lda stringTest, y
	sta CHAR_MAX_LENGTH
	
	lda #$00
	sta IS_RENDER_DONE

infinite:
	jmp infinite
.endproc

stringTest:
	.byte 16
	.byte CHAR_B
	.byte CHAR_E
	.byte CHAR_W
	.byte CHAR_A
	.byte CHAR_R
	.byte CHAR_E
	.byte SPACE
	.byte CHAR_O
	.byte CHAR_F
	.byte SPACE
	.byte CHAR_C
	.byte CHAR_O
	.byte CHAR_V
	.byte CHAR_I
	.byte CHAR_D

colorPallete:
	.include "colorPallete.s"

;;; ----------------------------------------------------------------------------
;;; NMI (vertical blank) handler

.proc nmi

initTopboxRender:
	lda #$20
	sta PPUADDR
	lda #$41
	sta PPUADDR
	lda #$1C
	sta PPUDATA
	ldx #$00

topBoxRender:
	lda #$1B
	sta PPUDATA
	inx
	cpx #$1C
	bne topBoxRender
	lda #$1E
	sta PPUDATA

	lda #$20
	sta BOX_PREV_ADDR_HI
	lda #$41
	sta BOX_PREV_ADDR_LOW	
	ldy #$00

midBoxRender:
	cpy #$0A
	beq initBottomBoxRender

	lda BOX_PREV_ADDR_LOW
	adc #$20
	
	sta BOX_PREV_ADDR_LOW
	sta BOX_ADDR_LOW
	
	lda BOX_PREV_ADDR_HI
	adc #$00
	
	sta BOX_PREV_ADDR_HI
	sta BOX_ADDR_HI
	
	lda BOX_PREV_ADDR_HI
	sta PPUADDR

	lda BOX_PREV_ADDR_LOW
	sta PPUADDR

	lda #$1D
	sta PPUDATA

	lda BOX_ADDR_LOW
	adc #$1D
	sta BOX_ADDR_LOW
	
	lda BOX_ADDR_HI
	adc #$00
	sta BOX_ADDR_HI

	lda BOX_ADDR_HI
	sta PPUADDR

	lda BOX_ADDR_LOW
	sta PPUADDR

	lda #$1F
	sta PPUDATA

	iny
	jmp midBoxRender

initBottomBoxRender:
	lda #$21
	sta PPUADDR
	lda #$A1
	sta PPUADDR

	lda #$20
	sta PPUDATA

	lda #$21
	sta PPUADDR

	lda #$BE
	sta PPUADDR

	lda #$22
	sta PPUDATA

	lda #$21
	sta PPUADDR
	lda #$A2
	sta PPUADDR

	ldx #00

bottomBoxRender:
	lda #$21
	sta PPUDATA

	inx
	cpx #$1C
	bne bottomBoxRender

scroll:
	; X Axis Scroll
	lda #$0
	sta PPUSCROLL

	; Y Axis Scroll
	lda #$0
	sta PPUSCROLL

	rti

.endproc

;;; ----------------------------------------------------------------------------
;;; IRQ handler

.proc irq
	rti
.endproc



;;; ----------------------------------------------------------------------------
;;; Vector table

.segment "VECTOR"
.addr nmi
.addr reset
.addr irq


;;; ----------------------------------------------------------------------------
;;; CHR data

.segment "CHR0a"

; Sample Box Sprite
.byte 255
.byte 129
.byte 129
.byte 129
.byte 129
.byte 129
.byte 129
.byte 255
.byte 255
.byte 255
.byte 255
.byte 255
.byte 255
.byte 255
.byte 255
.byte 255

.byte 7

.byte 31

.byte 63

.byte 119

.byte 127

.byte 253

.byte 239

.byte 255

.byte 7

.byte 28

.byte 32

.byte 72

.byte 64

.byte 130

.byte 144

.byte 128

.segment "CHR0b"
.include "charset.s"