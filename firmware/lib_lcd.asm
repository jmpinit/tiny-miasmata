.MACRO SET_POINT
	ldi		r16, $80|@0			;set column
	rcall	lcd_write_cmd
	ldi		r16, $40|(@1&$07)	;set row
	rcall	lcd_write_cmd
.ENDMACRO

;***** LCD SETUP - reset LCD
;DESTROYS: r0, r1, r16, r17
lcd_setup:
	cbi		PORTB, PIN_RES
	CALL_DELAY 1
	sbi		PORTB, PIN_RES
	CALL_DELAY 1

	;values from 3310 datasheet
	ldi		r16, 0x21
	rcall	lcd_write_cmd

	ldi		r16, 0xD0
	rcall	lcd_write_cmd

	ldi		r16, 0x04
	rcall	lcd_write_cmd

	ldi		r16, 0x13
	rcall	lcd_write_cmd

	ldi		r16, 0x20
	rcall	lcd_write_cmd

	ldi		r16, 0x0C
	rcall	lcd_write_cmd

	ret

;***** SPI WRITE
;INPUT: r16 data byte
;DESTROYS: r16, r17
spi_write:
	cbi		PORTB, PIN_SCLK	;lower clock
	ldi		r17, 8
spi_write0:
	sbrc	r16, 7			;write bit to pin
	sbi		PORTB, PIN_SDIN
	sbrs	r16, 7
	cbi		PORTB, PIN_SDIN

	sbi		PORTB, PIN_SCLK	;clock out bit
	cbi		PORTB, PIN_SCLK

	lsl		r16				;shift data out	

	dec		r17				;do for all bits
	brne	spi_write0

	ret

;***** LCD WRITE CMD
;INPUT: r16 data byte
;DESTROYS: r16, r17
lcd_write_cmd:
	cbi		PORTB, PIN_DC	;set LCD in command mode
	cbi		PORTB, PIN_SCE	;enable LCD

	rcall	spi_write		;send data

	sbi		PORTB, PIN_SCE	;disable LCD

	ret

;***** LCD WRITE DATA
;INPUT: r16 data byte
;DESTROYS: r16, r17
lcd_write_data:
	sbi		PORTB, PIN_DC	;set LCD in data mode
	cbi		PORTB, PIN_SCE	;enable LCD

	rcall	spi_write		;send data

	sbi		PORTB, PIN_SCE	;disable LCD

	ret

;***** LCD CLEAR
;DESTROYS: r16, r17, r18
lcd_clear:
	SET_POINT	0, 0

	ldi		r18, 252
lcd_clear0:
	ldi		r16, $00
	rcall	lcd_write_data

	dec		r18
	brne	lcd_clear0

	ldi		r18, 252
lcd_clear1:
	ldi		r16, $00
	rcall	lcd_write_data

	dec		r18
	brne	lcd_clear1

	ret

/*
Copyright (c) 2011 Owen Trueblood

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
