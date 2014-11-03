;***** DELAY - long delay
;INPUT: r16 is time to delay
;DESTROYS: r0, r1, r16
delay:
	clr		r0
	clr		r1
delay0: 
	dec		r0
	brne	delay0
	dec		r1
	brne	delay0
	dec		r16
	brne	delay0
	ret

;***** DELAY FRAME - short delay
;INPUT: r16 is time to delay
;DESTROYS: r0, r16
delay_frame:
	clr		r0
delay_frame0: 
	dec		r0
	brne	delay_frame0
	dec		r16
	brne	delay_frame0
	ret

;***** REFRESH - reloads map and redraws all game elements
;DESTROYS: r0, r1, r2, r16, r17, r18, r19, X, Z
refresh:
	//load map
	ldi		ZH, high(SECTION_DATA<<1)
	ldi		ZL, low(SECTION_DATA<<1)
	mov		r16, sec_x
	mov		r17, sec_y
	rcall	map_sector
redraw:
	//draw map
	rcall	gpx_render

	//draw player
	rcall	ply_draw

	ret

;***** SPRITE CLEAR - clear the screen where the sprite is
;DESTROYS: r0, r1, r2, r16, r17, r18, r19, X, Z
sprite_clear:
	ldi		ZH, high(tiles<<1)
	ldi		ZL, low(tiles<<1)
	rcall	gpx_sprite

	ret

;***** PLY DRAW - draw the player to the screen
;DESTROYS: r0, r1, r2, r16, r17, r18, r19, X, Z
ply_draw:
	ldi		ZH, high(sprite_player<<1)
	ldi		ZL, low(sprite_player<<1)
	
	;face the right direction
	add		ZL, ply_dir
	brcc	ply_draw_skip
	inc		ZH
ply_draw_skip:
	mov		r16, ply_x
	mov		r17, ply_y
	rcall	gpx_sprite

	ret

;***** ENEMY DRAW
;INPUT: r18 contains image #
enemy_draw:
	ldi		ZH, high(sprite_player<<1)
	ldi		ZL, low(sprite_player<<1)
	mov		r16, en_x
	mov		r17, en_y
	rcall	gpx_sprite

	ret

;***** DONE VERT - a convenient way to exit from the vertical check functions
done_vert:
	mov		r16, r3
	ret

;***** CHECK GROUND - returns tile below
;INPUT: r16 is x pos, r17 is y pos
;OUTPUT: r16 tile below
;DESTROYS: r16, r17, r18, r19, X
check_ground:
	mov		r0, r16		;save hires location
	rcall	tile_pos	;find tile location
	mov		r1, r16		;save x tile pos

	inc		r17			;check the one below
	mov		r2, r17		;save y tile pos
	rcall	map_get_tile
	mov		r3, r16		;save tile

	;check if we are between two tiles
	mov		r16, r0		;load hires x
	andi	r16, $07	;mod 8
	tst		r16
	breq	done_vert

	;we are between two tiles - check the other tile
	inc		r1
	mov		r16, r1
	mov		r17, r2
	rcall	map_get_tile
	or		r16, r3		;add new tile to result

	ret

;***** CHECK CEILING - returns tile above
;INPUT: r16 is x pos, r17 is y pos
;OUTPUT: r16 tile above
;DESTROYS: r16, r17, r18, r19, X
check_ceiling:
	mov		r0, r16		;save hires location
	rcall	tile_pos	;find tile location
	mov		r1, r16		;save x tile pos

	dec		r17			;check the one above
	mov		r2, r17		;save y tile pos
	rcall	map_get_tile
	mov		r3, r16		;save tile

	;check if we are between two tiles
	mov		r16, r0		;load hires x
	andi	r16, $07	;mod 8
	tst		r16
	breq	done_vert

	;we are between two tiles - check the other tile
	inc		r1
	mov		r16, r1
	mov		r17, r2
	rcall	map_get_tile
	or		r16, r3		;add new tile to result

	ret

;***** DONE VERT - a convenient way to exit from the horizontal check functions
done_horiz:
	mov		r16, r3
	ret

;***** CHECK LEFT - returns tile to the left
;INPUT: r16 is x pos, r17 is y pos
;OUTPUT: r16 tile to the left
;DESTROYS: r16, r17, r18, r19, X
check_left:
	mov		r0, r17		;save hires location
	rcall	tile_pos	;find tile location
	mov		r2, r17		;save y tile pos

	dec		r16			;check the one to the left
	mov		r1, r16		;save x tile pos
	rcall	map_get_tile
	mov		r3, r16		;save tile

	;check if we are between two tiles
	mov		r16, r0		;load hires y
	andi	r16, $07	;mod 8
	tst		r16
	breq	done_horiz

	;we are between two tiles - check the other tile
	inc		r2
	mov		r16, r1
	mov		r17, r2
	rcall	map_get_tile
	or		r16, r3		;add new tile to result

	ret

;***** CHECK RIGHT - returns tile to the right
;INPUT: r16 is x pos, r17 is y pos
;OUTPUT: r16 tile to the right
;DESTROYS: r16, r17, r18, r19, X
check_right:
	mov		r0, r17		;save hires location
	rcall	tile_pos	;find tile location
	mov		r2, r17		;save y tile pos

	inc		r16			;check the one to the right
	mov		r1, r16		;save x tile pos
	rcall	map_get_tile
	mov		r3, r16		;save tile

	;check if we are between two tiles
	mov		r16, r0		;load hires y
	andi	r16, $07	;mod 8
	tst		r16
	breq	done_horiz

	;we are between two tiles - check the other tile
	inc		r2
	mov		r16, r1
	mov		r17, r2
	rcall	map_get_tile
	or		r16, r3		;add new tile to result

	ret

;***** TILE POS - returns the tile that contains the given location
;DESTROYS: r16, r17
;OUTPUT: r16 tile x, r17 tile y
tile_pos:
	lsr		r16			;divide x by 8
	lsr		r16
	lsr		r16

	lsr		r17			;divide y by 8
	lsr		r17
	lsr		r17

	ret
