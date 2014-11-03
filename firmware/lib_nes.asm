;***** NES READ
;DESTROYS: r16, r17, r18
;OUTPUT: r16 data
nes_read:
	//ask for data
	sbi		PORTD, PIN_LATCH
	rcall	nes_delay
	cbi		PORTD, PIN_LATCH

	//read buttons
	clr		r18
	ldi		r17, 7

nes_read0:
	//get button state
	sbis	PIND, PIN_DATA
	ori		r18, $01
	lsl		r18

	rcall	nes_delay

	//ask for next button
	sbi		PORTD, PIN_PULSE
	rcall	nes_delay
	cbi		PORTD, PIN_PULSE

	dec		r17
	brne	nes_read0

	//get last button
	sbis	PIND, PIN_DATA
	ori		r18, $01

	mov		r16, r18

	ret

;***** NES DELAY - 6 us delay
;DESTROYS: r16
nes_delay:
	ldi		r16, 14		;1 cycle
nes_delay0:
	dec		r16			;1 cycle
	brne	nes_delay0	;1 if false, 2 if true

	ret					;4 cycles
