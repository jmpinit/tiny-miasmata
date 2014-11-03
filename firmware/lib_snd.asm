;***** Constants
.equ	SND_LEN	= 32

;***** SND SETUP
snd_setup:
	//SETUP PWM
	ldi		r16, (1<<COM0A0)|(1<<WGM01)|(0<<WGM00)
	out		TCCR0A, r16

	ldi		r16, (1<<CS01)|(1<<CS00)
	out		TCCR0B, r16
	
	;start with low-pitched tone
	;so our ears don't bleed if something goes wrong
	ldi		r16, 128
	out		OCR0A, r16

	//SETUP MUSIC
	;counter for interrupt
	ldi		r16, 128
	out		OCR1AH, r16
	ldi		r16, 0
	out		OCR1AL, r16
	ldi		r16, (1<<OCIE1A)
	out		TIMSK, r16
	ldi		r16, (1<<CS11)
	out		TCCR1B, r16

	;setup music pointer
	ldi		YH, high(music<<1)
	ldi		YL, low(music<<1)

	sei

	ret

;***** SND INTERRUPT
snd_interrupt:
	in		r8, SREG
	mov		r9, ZH		;save Z
	mov		r10, ZL

	movw	Z, Y		;load music pointer
	
	lpm		r7, Z		;load note
	out		OCR0A, r7	;play note

	ld		r7, Y+		;load bogus to do 16 bit increment of music

	;check for overflow
	cpi		YH, high((music+SND_LEN/2)<<1)
	brlt	snd_interrupt_no_over
	cpi		YL, low((music+SND_LEN/2)<<1)
	brlt	snd_interrupt_no_over

	ldi		YH, high(music<<1)
	ldi		YL, low(music<<1)

snd_interrupt_no_over:
	mov		ZH, r9		;restore Z
	mov		ZL, r10

	;clear the counter
	clr		r9
	out		TCNT1H, r9
	out		TCNT1L, r9
	
	out		SREG, r8	;restore SREG
	
	reti

music:
	.db		32, 48, 32, 48
	.db		32, 48, 32, 48


	.db		80, 48, 80, 48 
	.db		80, 48, 80, 48


	.db		128, 64, 56, 48
	.db		128, 64, 56, 48

	.db		128, 128, 255, 255
	.db		64, 64, 128, 128
