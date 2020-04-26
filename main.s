.include "defs.s"
.include "colorPallete.s"

.struct Sprite
	ypos   .byte
	id     .byte
	attrib .byte
	xpos   .byte
.endStruct

.struct MetaSprite
	sp1 .tag Sprite
	sp2 .tag Sprite
	sp3 .tag Sprite
	sp4 .tag Sprite
.endStruct

virusSprite: .tag MetaSprite

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

bgPaletteInit:
	lda #$3f
	sta PPUADDR
	
	lda #$00
	sta PPUADDR
	
	lda #$6
	sta PPUDATA

	lda #$3f
	sta BG_PALLETE_ADDR_HI
	sta PPUADDR
	
	lda #$01
	sta BG_PALLETE_ADDR_LOW
	sta PPUADDR
	
	ldx #$0
	ldy #$0

	jmp bgPalette

nextBgPallete:
	clc
	ldy #$0
	cpx #$18
	beq ppu

	lda BG_PALLETE_ADDR_HI
	sta PPUADDR

	lda BG_PALLETE_ADDR_LOW
	adc #$04
	sta PPUADDR
	sta BG_PALLETE_ADDR_LOW

bgPalette:
	lda colorPallete, x
	sta PPUDATA
	inx
	iny
	cpy #$3
	beq nextBgPallete
	bne bgPalette
	ldy #$0

; start ppu
ppu:
	lda #%10010000
	sta PPUCTRL
	lda #%00011000
	sta PPUMASK

initString:
	lda #$01
	sta CHAR_COUNTER
	
	ldy #00
	lda stringTest, y
	sta CHAR_MAX_LENGTH
	
	lda #$00
	sta IS_RENDER_DONE

initVirusSprite:
	lda #$00000000
	sta virusSprite+MetaSprite::sp1+Sprite::attrib
	lda #$01
	sta virusSprite+MetaSprite::sp1+Sprite::id
	lda #$50
	sta virusSprite+MetaSprite::sp1+Sprite::ypos
	sta virusSprite+MetaSprite::sp1+Sprite::xpos

initVirusPos:
	lda #$77
	sta VIRUS1_POS_Y
	sta VIRUS1_POS_X
	lda #$0
	sta VIRUS1_POS_Y_POLARITY

initToken:
	lda #$0
	sta TOKEN

infinite:
	lda #$0
	cmp TOKEN
	beq onUpdate
	jmp infinite

onUpdate:
	lda #$01
	sta TOKEN

checkVirusPos:
	ldx VIRUS1_POS_Y

	cpx #$D7
	beq virusPolarityUp
	
	clc
	
	cpx #55
	beq virusPolarityDown

	clc

	ldx VIRUS1_POS_Y_POLARITY
	cpx #$00
	beq virusDown
	bne virusUp

virusPolarityUp:
	lda #$01
	sta VIRUS1_POS_Y_POLARITY
	jmp virusUp

virusPolarityDown:
	lda #$00
	sta VIRUS1_POS_Y_POLARITY
	jmp virusDown

virusDown:
	ldx VIRUS1_POS_Y
	inx
	inx
	stx VIRUS1_POS_Y
	jmp infinite

virusUp:
	ldx VIRUS1_POS_Y
	dex
	dex
	stx VIRUS1_POS_Y
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
	cpy #$03
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
	lda #$20
	sta PPUADDR
	lda #$C1
	sta PPUADDR

	lda #$20
	sta PPUDATA

	lda #$20
	sta PPUADDR
	lda #$DE
	sta PPUADDR

	lda #$22
	sta PPUDATA

	lda #$20
	sta PPUADDR
	lda #$C2
	sta PPUADDR

	ldx #00

bottomBoxRender:
	lda #$21
	sta PPUDATA

	inx
	cpx #$1C
	bne bottomBoxRender

initStringRender:
	lda #$01
	cmp IS_RENDER_DONE
	beq scroll

	lda #$20
	sta PPUADDR
	lda #$63
	sta PPUADDR

	ldx #$01

stringRender:
	lda CHAR_MAX_LENGTH
	cmp CHAR_COUNTER
	beq endRender

	lda stringTest, x
	sta PPUDATA

	txa
	inx
	cmp CHAR_COUNTER
	bne stringRender

	stx CHAR_COUNTER
	jmp scroll

endRender:
	lda #$01
	sta IS_RENDER_DONE

scroll:
	; X Axis Scroll
	lda #$0
	sta PPUSCROLL

	; Y Axis Scroll
	lda #$0
	sta PPUSCROLL

spriteRender:
	lda #$00
	sta OAMADDR_LOW
	lda #$02
	sta OAMADDR_HI

;	lda virusSprite+MetaSprite::sp1+Sprite::ypos
;	sta $0200
;	lda virusSprite+MetaSprite::sp1+Sprite::id
;	sta $0201
;	lda virusSprite+MetaSprite::sp1+Sprite::attrib
;	sta $0202
;	lda virusSprite+MetaSprite::sp1+Sprite::xpos
;	sta $0203

	lda VIRUS1_POS_Y
	sta OAMDATA
	lda #$01
	sta OAMDATA
	lda #$0
	sta OAMDATA
	lda VIRUS1_POS_X
	sta OAMDATA

	lda VIRUS1_POS_Y
	sta OAMDATA
	lda #$01
	sta OAMDATA
	lda #%01000000
	sta OAMDATA
	lda VIRUS1_POS_X
	adc #$07
	sta OAMDATA

	lda VIRUS1_POS_Y
	adc #$08
	sta OAMDATA
	lda #$01
	sta OAMDATA
	lda #%10000000
	sta OAMDATA
	lda VIRUS1_POS_X
	sta OAMDATA

	lda VIRUS1_POS_Y
	adc #$08
	sta OAMDATA
	lda #$01
	sta OAMDATA
	lda #%11000000
	sta OAMDATA
	lda VIRUS1_POS_X
	adc #$08
	sta OAMDATA

	lda #$0
	sta TOKEN

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
.include "sprite.s"

.segment "CHR0b"
.include "charset.s"