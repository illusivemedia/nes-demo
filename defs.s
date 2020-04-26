;;; PPU registers.
PPUCTRL		= $2000
PPUMASK		= $2001
PPUSTATUS	= $2002
OAMADDR_HI  = $4014
OAMADDR_LOW = $2003
OAMDATA		= $2004
PPUSCROLL	= $2005
PPUADDR		= $2006
PPUDATA		= $2007

;;; Other IO registers.
OAMDMA		= $4014
APUSTATUS	= $4015
JOYPAD1		= $4016
JOYPAD2		= $4017

ATTRIB_TABLE_1 = $23C0

GRAY_0  = $0
GRAY_1  = $10
WHITE_1 = $20
BLUE_0  = $01
BLUE_1  = $11
BLUE_2  = $21
BLUE_3  = $31
RED_0   = $06
BLACK_0 = $D

CHAR_COUNTER = $01
CHAR_MAX_LENGTH = $02
IS_RENDER_DONE = $03

BOX_ADDR_HI = $04
BOX_ADDR_LOW = $05

BOX_PREV_ADDR_HI = $06
BOX_PREV_ADDR_LOW = $07 

TOKEN = $08

BG_PALLETE_ADDR_HI = $0A
BG_PALLETE_ADDR_LOW = $0B

VIRUS1_POS_Y = $0C
VIRUS1_POS_X = $0D
VIRUS1_POS_Y_POLARITY = $0E