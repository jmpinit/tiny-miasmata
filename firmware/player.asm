ply_think:
	//JUMP CHECK
	mov		r16, ply_jmp_clk
	cpi		r16, 0				;if ply is jumping
	brne	ply_try_fly		;then don't fall, try to fly!

	//TILE COLLISION CHECK BELOW
	mov		r16, ply_x
	mov		r17, ply_y
	rcall	check_ground
	cpi		r16, 0			;if tile below is not empty
	brne	ply_collide		;then don't fall

	//GRAVITY
	;clear player
	mov		r16, ply_x
	mov		r17, ply_y
	rcall	sprite_clear

	;move down
	inc		ply_y

	;draw player
	rcall	ply_draw

	;check if ply fell off screen
	cpi		ply_y, 48
	brge	offscreen_bottom

	rjmp	ply_control
ply_try_fly:
	//TILE COLLISION CHECK ABOVE
	mov		r16, ply_y
	andi	r16, $07
	cpi		r16, 0
	brne	ply_fly

	mov		r16, ply_x
	mov		r17, ply_y
	rcall	check_ceiling
	cpi		r16, 0			;if tile above is not empty
	brne	ply_kill_jmp	;then stop jumping
	
ply_fly:
	//JUMP MOVEMENT
	;clear player
	mov		r16, ply_x
	mov		r17, ply_y
	rcall	sprite_clear

	dec		ply_y			;move up
	dec		ply_jmp_clk		;count down time to stop jump

	;draw player
	rcall	ply_draw

	rjmp	ply_control
ply_kill_jmp:
	clr		ply_jmp_clk
	rjmp	ply_control
ply_collide:
	;quantize y position (make sure we stand on top of ground)
	andi	ply_y, ~$03		;makes y position a multiple of 8
ply_control:
	ldi		r16, 63			;set game speed
	rcall	delay_frame

	//CONTROL
	rcall	nes_read
	cpi		r16, 0
	breq	jump_pad0	;button was not pressed

	;decode button press
	sbrc	r16, B_B
	rjmp	ply_attack

	sbrc	r16, B_A
	rjmp	ply_try_jmp

	sbrc	r16, B_RIGHT
	rjmp	ply_try_go_right
	
	sbrc	r16, B_LEFT
	rjmp	ply_try_go_left

	sbrc	r16, B_SELECT
	rcall	redraw

	sbrc	r16, B_START
	rjmp	offscreen_right	

jump_pad0:
	rjmp	game_loop

offscreen_left:
	dec		sec_x			;move one section to the left
	ldi		ply_x, 76		;put player on correct side
	rcall	refresh			;redraw everything
	rjmp	game_loop

offscreen_right:
	inc		sec_x			;move one section to the right
	clr		ply_x			;put player on correct side
	rcall	refresh			;redraw everything
	rjmp	game_loop

offscreen_top:
	dec		sec_y			;move one section up
	ldi		ply_y, 48		;put player on correct side
	rcall	refresh			;redraw everything
	rjmp	game_loop

offscreen_bottom:
	inc		sec_y			;move one section down
	clr		ply_y			;put player on correct side
	rcall	refresh			;redraw everything
	rjmp	game_loop

ply_try_go_left:
	;check for possibility of collision
	mov		r16, ply_x
	andi	r16, $07
	cpi		r16, 0
	brne	ply_go_left

	;check for collision
	mov		r16, ply_x
	mov		r17, ply_y
	rcall	check_left
	cpi		r16, 0
	brne	jump_pad0
ply_go_left:
	;change sprite direction
	ldi		r16, DIR_LEFT
	mov		ply_dir, r16

	;clear player
	mov		r16, ply_x
	mov		r17, ply_y
	rcall	sprite_clear

	dec		ply_x			;move position left
	breq	offscreen_left	;check if ply is in-bounds

	;draw player
	rcall	ply_draw

	rjmp	jump_pad0

ply_try_go_right:
	;check for possibility of collision
	mov		r16, ply_x
	andi	r16, $07
	cpi		r16, 0
	brne	ply_go_right

	;check for collision
	mov		r16, ply_x
	mov		r17, ply_y
	rcall	check_right
	cpi		r16, 0
	brne	jump_pad0
ply_go_right:
	;change sprite direction
	ldi		r16, DIR_RIGHT
	mov		ply_dir, r16

	;clear player
	mov		r16, ply_x
	mov		r17, ply_y
	rcall	sprite_clear

	inc		ply_x			;move position right

	;draw player
	rcall	ply_draw

	cpi		ply_x, 80		;check if ply is in-bounds
	brge	offscreen_right
	rjmp	game_loop

ply_try_jmp:
	//CHECK FOR GROUND
	mov		r16, ply_x
	mov		r17, ply_y
	rcall	check_ground

	cpi		r16, 0	;if tile below is not empty
	brne	ply_jmp	;then we can jump

	rjmp	game_loop

ply_jmp:
	ldi		r16, JUMP_HEIGHT
	mov		ply_jmp_clk, r16
	rjmp	game_loop

ply_attack:
	;did we kill anything?
	mov		r16, en_x	;location of enemy
	mov		r17, en_y
	rcall	tile_pos

	mov		r18, r16	;save it
	mov		r19, r17

	mov		r16, ply_x	;our location
	mov		r17, ply_y
	rcall	tile_pos

	;correct for attack direction
	tst		ply_dir
	breq	ply_attack_right

	dec		r16
	rjmp	ply_attack_check
ply_attack_right:
	inc		r16
ply_attack_check:
	cp		r16, r18
	brne	ply_attack_fail
	cp		r17, r19
	brne	ply_attack_fail
ply_attack_kill:
	ldi		r16, $FF
	mov		en_x, r16
	mov		en_y, r16
ply_attack_fail:
	;attack imagery
	mov		r16, ply_x
	mov		r17, ply_y
	
	;sound effect!
	mov		ZH, r18
	eor		r18, ZL
	out		OCR0A, r18

	;random garbage! wooo!
	in		ZL, TCNT1L
	in		ZH, TCNT1H
	clr		ZH

	ldi		r18, 8

	;detect direction
	tst		ply_dir
	breq	ply_draw_attack_right

ply_draw_attack_left:
	sub		r16, r18
	
	mov		r1, r16
	mov		r2, r17
	rcall	tile_pos
	in		r18, TCNT1L
	lsr		r18
	lsr		r18
	lsr		r18
	lsr		r18
	lsr		r18
	rcall	map_set_tile
	mov		r16, r1
	mov		r17, r2

	rjmp	ply_draw_attack_end
ply_draw_attack_right:
	add		r16, r18

	mov		r1, r16
	mov		r2, r17
	rcall	tile_pos
	in		r18, TCNT1L
	lsr		r18
	lsr		r18
	lsr		r18
	lsr		r18
	lsr		r18
	rcall	map_set_tile
	mov		r16, r1
	mov		r17, r2
ply_draw_attack_end:
	rcall	gpx_sprite
	rjmp	jump_pad0

sprite_player:
	//.db		$FF, $81, $81, $81, $81, $81, $81, $FF	;test square
	.db		$00, $00, $E8, $1E, $1D, $EA, $00, $00	;facing right
	.db		$00, $00, $EA, $1D, $1E, $E8, $00, $00	;facing left
