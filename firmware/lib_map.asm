;***** MAP GET TILE - returns tile at location
;INPUT: r16 is x, r17 is y
;DESTROYS: r16, r17, r18, r19, X
map_get_tile:
	;return empty if out of bounds
	cpi		r16, 10
	brge	map_get_tile_out
	cpi		r17, 6
	brge	map_get_tile_out

	clr		r18

	cpi		r17, 0
	breq	map_get_tile_skip
	ldi		r19, 5
map_get_tile_mult:
	add		r18, r19
	dec		r17
	brne	map_get_tile_mult
map_get_tile_skip:
	mov		r17, r16
	lsr		r16			;divide by 2
	add		r18, r16	;add to offset

	ldi		XH, high(TILEMEM)	;get pointer to right byte
	ldi		XL, low(TILEMEM)
	add		XL, r18
	brcc	map_get_tile_skip2
	inc		XH
map_get_tile_skip2:
	ld		r16, X

	lsr		r17			;figure out which nibble
	brcs	map_get_tile_high
map_get_tile_low:
	andi	r16, $0F
	ret
map_get_tile_high:
	swap	r16
	andi	r16, $0F
	ret

map_get_tile_out:
	clr		r16
	ret

;***** MAP SET TILE - sets tile at location
;INPUT: r16 is x, r17 is y, r18 is tile
;DESTROYS: r16, r17, r18, r19, X
map_set_tile:
	;return if out of bounds
	cpi		r16, 10
	brge	map_set_tile_out
	cpi		r17, 6
	brge	map_set_tile_out

	clr		r0
	
	cpi		r17, 0
	breq	map_set_tile_skip
	ldi		r19, 5
map_set_tile_mult:
	add		r0, r19
	dec		r17
	brne	map_set_tile_mult
map_set_tile_skip:
	mov		r17, r16
	lsr		r16		;divide by 2
	add		r0, r16	;add to offset

	ldi		XH, high(TILEMEM)	;get pointer to right byte
	ldi		XL, low(TILEMEM)
	add		XL, r0
	brcc	map_set_tile_skip2
	inc		XH
map_set_tile_skip2:
	ld		r16, X

	lsr		r17			;figure out which nibble
	brcs	map_set_tile_high
map_set_tile_low:
	andi	r18, $0F
	or		r16, r18
	st		X, r18
	ret
map_set_tile_high:
	andi	r18, $0F
	swap	r18
	or		r16, r18
	st		X, r18
	ret
map_set_tile_out:
	ret

;***** MAP DECODE - look up tile using group table
;INPUT: r16 is tile index, r17 is header
;OUTPUT: r16 contains tile type
;DESTROYS: r0, r16, r17, r18, Z
.def groupH		= r18
.def groupL		= r17
.def position	= r0
map_decode:
	ldi		ZH, high(GROUP_TABLE<<1)
	ldi		ZL, low(GROUP_TABLE<<1)
	
	lsl		r17
	add		ZL, r17
	brcc	map_decode_skip
	inc		ZH
map_decode_skip:
	lpm		groupL, Z+	;get the group
	lpm		groupH, Z

	mov		r0, groupH
	andi	groupH, $0F
	lsl		groupH
	lsl		groupH
	lsl		groupH
	mov		en_x, groupH
	mov		groupH, r0
	swap	groupH
	andi	groupH, $0F
	lsl		groupH
	lsl		groupH
	lsl		groupH
	mov		en_y, groupH
	
	clr		position
	inc		r16
map_decode_loop:
	lsr		groupH		;16 bit shift
	ror		groupL
	brcc	map_decode_empty
	dec		r16
map_decode_empty:
	inc		position
	cpi		r16, 0
	brne	map_decode_loop

	dec		position
	mov		r16, position

	ret

;***** MAP SECTOR - loads the specified sector
;INPUT: r16 is x, r17 is y, Z points to section data
;DESTROYS: r0, r16, r17, r18, r19, X, Z
map_sector:
	clr		r18
	cpi		r17, 0
	breq	map_sector_skip

	;multiply y by MAP_WIDTH
	ldi		r19, MAP_WIDTH
map_sector_mult:
	add		r18, r19
	dec		r17
	brne	map_sector_mult
map_sector_skip:
	;add x
	add		r18, r16

	;multiply by 16 to get offset
	lsl		r18
	lsl		r18
	lsl		r18
	lsl		r18

	;add offset to Z
	add		ZL, r18
	brcc	map_sector_no_ov
	inc		ZH
map_sector_no_ov:
	rcall	map_load
	ret

;***** MAP LOAD
;INPUT: Z points to section data
.def	header		= r1
.def	temp		= r16
.def	chunk_count = r19
.def	chunk		= r20
.def	tilepair	= r21
map_load:
	lpm		header, Z+

	ldi		XH, high(TILEMEM)
	ldi		XL, low(TILEMEM)

	ldi		chunk_count, 15
map_load_loop:
	lpm		chunk, Z+
	mov		r2, ZH
	mov		r3, ZL
	
	//part 1 and 2
	mov		r16, chunk
	andi	r16, $03

	mov		r17, header
	rcall	map_decode
	mov		tilepair, r16

	mov		r16, chunk
	andi	r16, $0C
	lsr		r16
	lsr		r16
	mov		r17, header
	rcall	map_decode

	swap	r16
	or		tilepair, r16
	st		X+, tilepair

	//part 3 and 4
	swap	chunk

	mov		r16, chunk
	andi	r16, $03
	mov		r17, header
	rcall	map_decode
	mov		tilepair, r16

	mov		r16, chunk
	andi	r16, $0C
	lsr		r16
	lsr		r16
	mov		r17, header
	rcall	map_decode

	swap	r16
	or		tilepair, r16
	st		X+, tilepair

	mov		ZH, r2
	mov		ZL, r3

	dec		chunk_count
	brne	map_load_loop

	ret
