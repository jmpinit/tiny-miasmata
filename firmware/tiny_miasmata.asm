 .include "tn2313def.inc"

;***** Constants
//GAME PARAMETERS
.equ	JUMP_HEIGHT	= 12

;player sprite directions
.equ	DIR_RIGHT	= 0
.equ	DIR_LEFT	= 8

//BUTTONS
;d-pad
.equ	B_RIGHT		= 0
.equ	B_LEFT		= 1
.equ	B_DOWN		= 2
.equ	B_UP		= 3

.equ	B_START		= 4
.equ	B_SELECT	= 5

.equ	B_B			= 6
.equ	B_A			= 7

//RAM ADDRESSES
.equ	RAMSTART	= 96
.equ	TILEMEM		= 96			;30 bytes for current screen of tiles
.equ	SCORE		= TILEMEM+30	;up to 256 kills

;***** Macros
.MACRO CALL_DELAY
	ldi		r16, @0
	rcall	delay
.ENDMACRO

.MACRO PRINT
	ldi		r16, @0
	ldi		r17, @1
	ldi		r18, @2-65
	rcall	gpx_char
.ENDMACRO

;***** Registers
;map
.def	sec_x		= r22	;sector x
.def	sec_y		= r23	;sector y

;player
.def	ply_x		= r24	;player x position
.def	ply_y		= r25	;player y position
.def	ply_jmp_clk	= r15	;jump timer and indicator
.def	ply_dir		= r14	;player direction (sprite offset)

;enemy
.def	en_x		= r4
.def	en_y		= r5
.def	en_jmp_clk	= r6

;***** Pin definitions

//LCD
.equ	PIN_SCLK	= PB7
.equ	PIN_SDIN	= PB6
.equ	PIN_DC		= PB5
.equ	PIN_RES		= PB4
.equ	PIN_SCE		= PB3

//NES
.equ	PIN_LATCH	= PD4
.equ	PIN_PULSE	= PD3
.equ	PIN_DATA	= PD2

//Speaker
.equ	PIN_SPEAKER	= PB2

.cseg
.org 0
	rjmp	reset
.org OC1Aaddr
	rjmp	snd_interrupt

.include "lib_lcd.asm"
.include "lib_nes.asm"
.include "lib_gpx.asm"
.include "lib_snd.asm"
.include "lib_map.asm"

.include "util_game.asm"

;***** Program Execution Starts Here

reset:
	//SETUP STACK
	ldi		r16, low(RAMEND)
	out		SPL, r16

	//SETUP PIN DIRECTIONS
	;LCD pins
	ldi		r16, (1<<PIN_DC)|(1<<PIN_SCE)|(1<<PIN_SDIN)|(1<<PIN_SCLK)|(1<<PIN_RES)
	out		DDRB, r16

	;NES controller pins
	sbi		DDRD, PIN_LATCH
	sbi		DDRD, PIN_PULSE

	;speaker pins
	sbi		DDRB, PIN_SPEAKER

	//SETUP SOUND SYSTEM
	rcall	snd_setup
	
	//SETUP LCD
	rcall	lcd_setup
	
	//SETUP GAME
	;map 
	ldi		sec_x, 0
	ldi		sec_y, 0

	;player
	ldi		ply_x, 32
	ldi		ply_y, 8
	ldi		r16, DIR_RIGHT
	mov		ply_dir, r16

	;enemy
	ldi		r16, 255
	mov		en_x, r16
	ldi		r16, 8
	mov		en_y, r16

	rcall	lcd_clear
	rcall	refresh

game_loop:
	;check if the enemy is on the screen
	sbrc	en_y, 6
	rjmp	ply_think

	.include	"enemy.asm"
	.include	"player.asm"
	

//.include	"font.dat"
.include	"map.dat"

tiles:
	tile_empty:
		.db		$00, $00, $00, $00, $00, $00, $00, $00	//0
	tile_adminium:
		.db		$7E, $83, $85, $89, $91, $A1, $C1, $7E	//1
	tile_rock:
		.db		$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF	//2
	tile_dirt:
		.db		$55, $AA, $55, $AA, $55, $AA, $55, $AA	//3
	tile_wood:
		.db		$FF, $C6, $FF, $0C, $FF, $63, $31, $FF	//4
	tile_sand:
		.db		$92, $49, $24, $92, $92, $49, $24, $92	//5
	tile_torch:
		.db		$00, $00, $0C, $7A, $7A, $0C, $00, $00	//6

/*
Copyright (c) 2011 Owen Trueblood

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
