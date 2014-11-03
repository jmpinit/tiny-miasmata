//CONSTANTS
.equ	WIDTH	= 8	;how wide sprites are in pixels

gpx_exit:
	ret

;***** GPX SPRITE - display sprite at given x and y pos on screen
;INPUT: r16 is x, r17 is y, Z points to sprite
;DESTROYS: r0, r1, r2, r16, r17, r18, r19, X, Z
gpx_sprite:
	//BOUND CHECK
	;don't draw anything if outside bounds
	cpi		r16, 84
	brge	gpx_exit
	cpi		r17, 48
	brge	gpx_exit

	;save x and y
	mov		r0, r16
	mov		r1, r17

	//DRAW MATH
	;calculate mod
	andi	r17, $07
	breq	gpx_sprite_drw	;if remainder is zero

	mov		r2, r17			;mod 8 of r17 (shift count)

	//SETUP LCD TOP
	;set lcd column
	mov		r16, r0			;restore x
	ori		r16, $80		;format x for lcd
	rcall	lcd_write_cmd
	
	;set lcd row
	lsr		r1				;divide y pos to get the LCD row
	lsr		r1
	lsr		r1
	mov		r16, r1
	andi	r16, $07		;format row for lcd
	ori		r16, $40
	rcall	lcd_write_cmd

	;get lcd ready to draw
	sbi		PORTB, PIN_DC	;set LCD in data mode
	cbi		PORTB, PIN_SCE	;enable LCD
	
	movw	X, Z			;save sprite address
	
	//DRAW SPRITE TOP
	mov		r19, r0			;r19 keeps track of x draw position
	ldi		r18, 8			;byte count
gpx_sprite_slice_top:
	mov		r17, r2			;shift count
	lpm		r16, Z+			;get sprite byte to display
gpx_sprite_shift_top:
	lsl		r16				;shift sprite byte
	dec		r17				;do it (mod 8 of y) times
	brne	gpx_sprite_shift_top
	
	cpi		r19, 84			;ensure we're still in bounds
	brge	gpx_sprite_next_top

	rcall	spi_write		;send sprite byte to lcd

gpx_sprite_next_top:
	inc		r19				;move forward
	dec		r18				;do it for all 8 top parts
	brne	gpx_sprite_slice_top

	//SETUP LCD BOTTOM
	movw	Z, X

	;set lcd column
	mov		r16, r0			;restore x
	ori		r16, $80		;format x for lcd
	rcall	lcd_write_cmd
	
	;set lcd row
	mov		r16, r1			;restore y
	inc		r16				;move to sprite's bottom row
	andi	r16, $07		;format row for lcd
	ori		r16, $40
	rcall	lcd_write_cmd
	
	//DRAW MATH BOTTOM
	ldi		r16, 8
	mov		r17, r2
	sub		r16, r17
	mov		r2, r16			;r2 = 8 - remainder

	//DRAW SPRITE BOTTOM
	;get lcd ready to draw
	sbi		PORTB, PIN_DC	;set LCD in data mode
	cbi		PORTB, PIN_SCE	;enable LCD
	
	mov		r19, r0			;r19 keeps track of x draw position
	ldi		r18, WIDTH		;byte count
gpx_sprite_slice_bottom:
	mov		r17, r2			;shift count
	lpm		r16, Z+			;get sprite byte to display
gpx_sprite_shift_bottom:
	lsr		r16				;shift sprite byte
	dec		r17				;do it (8 - remainder) times
	brne	gpx_sprite_shift_bottom
	
	cpi		r19, 84			;ensure we're still in bounds
	brge	gpx_sprite_next_bottom

	rcall	spi_write		;send sprite byte to lcd

gpx_sprite_next_bottom:
	inc		r19				;move forward
	dec		r18				;draw all 8 bottom parts
	brne	gpx_sprite_slice_bottom

	sbi		PORTB, PIN_SCE	;disable LCD

	ret

gpx_sprite_drw:
	//SETUP LCD
	;set lcd column
	mov		r16, r0
	ori		r16, $80
	rcall	lcd_write_cmd

	//set lcd row
	mov		r16, r1
	lsr		r16
	lsr		r16
	lsr		r16

	andi	r16, $07
	ori		r16, $40
	rcall	lcd_write_cmd

	//get lcd ready to draw
	sbi		PORTB, PIN_DC	;set LCD in data mode
	cbi		PORTB, PIN_SCE	;enable LCD

	ldi		r16, WIDTH
	mov		r0, r16
gpx_sprite_drw_loop:
	lpm		r16, Z+

	cpi		r18, 84
	brge	gpx_sprite_drw_next

	rcall	spi_write
gpx_sprite_drw_next:
	inc		r18
	dec		r0
	brne	gpx_sprite_drw_loop
	
	sbi		PORTB, PIN_SCE	;disable LCD

	ret

;***** GPX CHAR - display a character at given row and column (10x6)
;INPUT: r16 is column, r17 is row, r18 is letter value
/*gpx_char:
	//SET UP LCD LOCATION

	mov		r19, r17

	;set lcd column
	ori		r16, $80
	rcall	lcd_write_cmd
	
	;set lcd row
	mov		r16, r19
	andi	r16, $07
	ori		r16, $40
	rcall	lcd_write_cmd

	//DECODE CHARACTER

	;multiply by 5
	ldi		r16, 5
	clr		r17				;character * 5 (sprite offset)
gpx_char_decode:
	add		r17, r18
	dec		r16
	brne	gpx_char_decode
	
	;get pointer to font
	ldi		ZH, high(font<<1)
	ldi		ZL, low(font<<1)

	add		ZL, r17			;add offset to pointer
	brcc	gpx_char_skip0
	inc		ZH
gpx_char_skip0:
	
	//DRAW CHARACTER

	;get lcd ready to draw
	sbi		PORTB, PIN_DC	;set LCD in data mode
	cbi		PORTB, PIN_SCE	;enable LCD

	lpm		r16, Z+
	rcall	spi_write
	lpm		r16, Z+
	rcall	spi_write
	lpm		r16, Z+
	rcall	spi_write
	lpm		r16, Z+
	rcall	spi_write
	lpm		r16, Z+
	rcall	spi_write

	sbi		PORTB, PIN_SCE	;disable LCD

	ret*/

;***** GPX TILE - draws a single tile at current position
;INPUT: r16 is the tile type 
;DESTROYS: r16, Z
gpx_draw_tile:
	lsl		r16				;multiply by 8 to get offset
	lsl		r16
	lsl		r16

	ldi		ZH, high(tiles<<1)
	ldi		ZL, low(tiles<<1)

	add		ZL, r16
	brcc	gpx_draw_tile_skip	;get index
	inc		ZH

gpx_draw_tile_skip:
	lpm		r16, Z+
	rcall	spi_write
	lpm		r16, Z+
	rcall	spi_write
	lpm		r16, Z+
	rcall	spi_write
	lpm		r16, Z+
	rcall	spi_write
	lpm		r16, Z+
	rcall	spi_write
	lpm		r16, Z+
	rcall	spi_write
	lpm		r16, Z+
	rcall	spi_write
	lpm		r16, Z+
	rcall	spi_write

	ret

;***** GPX RENDER - draws the tilemap to the screen
;DESTROYS: r16, r17, r18, r19, X, Z
gpx_render:
	SET_POINT 0, 0

	ldi		XH, high(TILEMEM)
	ldi		XL, low(TILEMEM)

	;get lcd ready to draw
	sbi		PORTB, PIN_DC	;set LCD in data mode
	cbi		PORTB, PIN_SCE	;enable LCD

	ldi		r19, 6
gpx_render_row:
	ldi		r18, 5
gpx_render_loop:
	ld		r16, X
	andi	r16, 0x0F
	rcall	gpx_draw_tile

	ld		r16, X+
	andi	r16, 0xF0
	swap	r16
	rcall	gpx_draw_tile

	dec		r18
	brne	gpx_render_loop

	clr		r16
	rcall	spi_write
	clr		r16
	rcall	spi_write
	clr		r16
	rcall	spi_write
	clr		r16
	rcall	spi_write

	dec		r19
	brne	gpx_render_row

	sbi		PORTB, PIN_SCE	;disable LCD

	ret
