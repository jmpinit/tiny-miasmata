enemy_think:
	//JUMP CHECK
	mov		r16, en_jmp_clk
	cpi		r16, 0			;if enemy is jumping
	brne	enemy_try_fly	;then don't fall, try to fly!

	//TILE COLLISION CHECK BELOW
	mov		r16, en_x
	mov		r17, en_y
	rcall	check_ground
	cpi		r16, 0			;if tile below is not empty
	brne	enemy_collide	;then don't fall

	//GRAVITY
	;clear enemy
	mov		r16, en_x
	mov		r17, en_y
	rcall	sprite_clear

	;move down
	inc		en_y

	;draw enemy
	rcall	enemy_draw

	rjmp	enemy_ai

enemy_try_fly:
	//TILE COLLISION CHECK ABOVE
	mov		r16, en_y
	andi	r16, $07
	cpi		r16, 0
	brne	enemy_fly

	mov		r16, en_x
	mov		r17, en_y
	rcall	check_ceiling
	cpi		r16, 0			;if tile above is not empty
	brne	enemy_kill_jmp	;then stop jumping
enemy_fly:
	//JUMP MOVEMENT
	;clear enemy
	mov		r16, en_x
	mov		r17, en_y
	rcall	sprite_clear

	dec		en_y			;move up
	dec		en_jmp_clk		;count down time to stop jump

	;draw enemy
	rcall	enemy_draw

	rjmp	enemy_ai
enemy_kill_jmp:
	clr		en_jmp_clk
	rjmp	enemy_ai
enemy_collide:
	mov		r16, en_y
	andi	r16, ~$03
enemy_ai:
	;did we kill anything?
	clr		r20

	mov		r16, ply_x	;location of enemy
	mov		r17, ply_y
	mov		r18, en_x	;our location
	mov		r19, en_y

	//X DIRECTION CHECK
	cp		r16, r18
	brge	enemy_attack_check_x0
	
	;player to the left
	sub		r18, r16
	mov		r16, r18
	rjmp	enemy_attack_check_x1
enemy_attack_check_x0:
	sub		r16, r18
enemy_attack_check_x1:
	cpi		r16, 8
	brge	enemy_attack_fail

	//Y DIRECTION CHECK
	cp		r17, r19
	brge	enemy_attack_check_y0
	
	;player to the left
	sub		r19, r17
	mov		r17, r19
	rjmp	enemy_attack_check_y1
enemy_attack_check_y0:
	sub		r17, r19
enemy_attack_check_y1:
	cpi		r17, 8
	brge	enemy_attack_fail

enemy_kill:
	in		ZL, TCNT1L	;random garbage! wooo!
	in		ZH, TCNT1H
	lpm		r16, Z+
	rcall	lcd_write_data

	;sound effect
	mov		ZH, r18
	eor		r18, ZL
	out		OCR0A, r18

	rjmp	enemy_kill
enemy_attack_fail:
	//MOVEMENT AI
	;decide whether to move
	in		r16, TCNT1L
	in		r17, TCNT1H
	
	andi	r16, $07
	tst		r16
	brne	enemy_done

	cp		en_x, ply_x
	brlt	enemy_try_go_right

//	rjmp	enemy_done

enemy_try_go_left:
	;check for possibility of collision
	mov		r16, en_x
	andi	r16, $07
	cpi		r16, 0
	brne	enemy_go_left

	;check for collision
	mov		r16, en_x
	mov		r17, en_y
	rcall	check_left
	cpi		r16, 0
	brne	enemy_done
enemy_go_left:
	;clear enemy
	mov		r16, en_x
	mov		r17, en_y
	rcall	sprite_clear

	dec		en_x			;move position left

	;draw enemy
	rcall	enemy_draw

	rjmp	enemy_done
enemy_try_go_right:
	;check for possibility of collision
	mov		r16, en_x
	andi	r16, $07
	cpi		r16, 0
	brne	enemy_go_right

	;check for collision
	mov		r16, en_x
	mov		r17, en_y
	rcall	check_right
	cpi		r16, 0
	brne	enemy_done
enemy_go_right:
	;clear enemy
	mov		r16, en_x
	mov		r17, en_y
	rcall	sprite_clear

	inc		en_x			;move position left

	;draw enemy
	rcall	enemy_draw

	rjmp	enemy_done
enemy_try_jmp:
	//CHECK FOR GROUND
	mov		r16, en_x
	mov		r17, en_y
	rcall	check_ground

	cpi		r16, 0		;if tile below is not empty
	brne	enemy_jmp	;then we can jump

	rjmp	enemy_done
enemy_jmp:
	ldi		r16, JUMP_HEIGHT
	mov		en_jmp_clk, r16
	//rjmp	enemy_done
enemy_done:
