$NOMOD51
#include "80c552.h"

;*********************************************************************************************************************************
;													ETIKETAK
;*********************************************************************************************************************************

;	Aldagaiak
	EGOERA				EQU	20H
	GERTAERA			EQU	21H
	TENPERATURA			EQU	22H
	DENBORA				EQU	23H
		
	MIN_UNIT			EQU 23H
	MIN_HAMAR			EQU	24H
	KONT_1ms			EQU 25H
	KONT_250ms			EQU	26H
	SEGUNDUAK			EQU	27H
	MINUTUAK			EQU	28H
		
	ATE_KONT			EQU	29H.0
	GAINK_KONT			EQU	29H.1
	
;	Sentsoreak
	ATE_SNTS			EQU	P1.1
	BETE_SNTS			EQU	P1.2
	HUSTU_SNTS			EQU	P1.3
		
;	Motoreak
	HUSTU_MTR			EQU	P1.0
	BETE_MTR			EQU	P3.3
	BEROG				EQU	P3.6
		
;	Hamarrekoen Displaya
	DH					EQU	P0
	DH_ZENB				EQU	2BH
	
;	Unitateen displaya
	DU					EQU	P2
	DU_ZENB				EQU	2CH
	
;	Etenen FLAG-ak (T0, T1, ADC0, ADC1 eta IDLE)
	TICK_15s			EQU	29H.2
	TICK_1min			EQU	29H.3
	TICK_10min			EQU	29H.4
	TICK_50min			EQU	29H.5
	TICK_GAINK			EQU	29H.6
	TICK_TENP_EGOKIA	EQU	29H.7
	TICK_IRAKURRITA		EQU	2AH.0
	TICK_BOTOIA			EQU	2AH.1

;*********************************************************************************************************************************

ORG 00H
	AJMP PROGRAMA_HASIERA

;*********************************************************************************************************************************
; 													ETENAK
;*********************************************************************************************************************************

ORG 03H		;	INT0 etena

	SETB	TICK_BOTOIA
	RETI
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

ORG	0BH		;	TIMER0 etena

	PUSH	ACC
	PUSH	B
	PUSH	PSW
	MOV		TH0,	#0F8H
	MOV		TL0,	#030H
	ACALL	UNITATE_BIHURKETA
	ACALL	T_FLAG_KONPROBATU
	POP		PSW
	POP		B
	POP		ACC
	RETI

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

ORG	1BH		;	TIMER1 etena
;	_______________________________________________________________________________________________________________________________
	//TODO
;	_______________________________________________________________________________________________________________________________

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

ORG	53H		;	ADC0 etena ---> ADCI=1 denean

	PUSH	ACC
	PUSH	B
	PUSH	PSW
	SETB	TICK_IRAKURRITA
	ANL		ADCON,	#0EFH
	MOV		A,	#02H
	CLR		C
	SUBB	A,	EGOERA
	JC		ADC_TENPERATURA
	ACALL	PISUA_IRAKURRI
	AJMP	ADC_AMAIERA
	ADC_TENPERATURA:
	ACALL	TENPERATURA_IRAKURRI
	ADC_AMAIERA:
	POP		PSW
	POP		B
	POP		ACC 
	RETI

;*********************************************************************************************************************************
; 													PROGRAMA NAGUSIA
;*********************************************************************************************************************************

ORG 7BH
	PROGRAMA_HASIERA:
		ACALL HASIERAKETAK
	
	LOOP:
		ACALL EGOERA_MAKINA
		AJMP LOOP
			
;*********************************************************************************************************************************
; 													HASIERAKETAK
;*********************************************************************************************************************************

	HASIERAKETAK:
;		Aldagaiak
		MOV	EGOERA,			#00H
		MOV	GERTAERA,		#00H
		MOV TENPERATURA,	#00H
		CLR ATE_KONT
		CLR	GAINK_KONT
		
;		Timerren FLAG-ak eta laguntzaileak
		MOV MIN_UNIT,		#00H
		MOV MIN_HAMAR,		#00H
		MOV	KONT_1ms,		#00H
		MOV	KONT_250ms,		#00H
		MOV	SEGUNDUAK,		#00H
		MOV	MINUTUAK,		#00H
		
;		Motoreak
		CLR	HUSTU_MTR
		CLR	BETE_MTR
		CLR	BEROG
		
;		Hamarrekoen Displaya
		MOV	DH,				#00H
		MOV	DH_ZENB,		#00H
	
;		Unitateen displaya
		MOV	DU,				#00H
		MOV	DU_ZENB,		#00H
		
;		Etenen FLAG-ak (T0, T1, ADC0, ADC1 eta IDLE)
		CLR	TICK_15s
		CLR	TICK_1min
		CLR	TICK_10min
		CLR	TICK_50min
		CLR	TICK_GAINK
		CLR	TICK_TENP_EGOKIA
		CLR	TICK_IRAKURRITA
		CLR	TICK_BOTOIA
		
;		PWM prescaler (%50)
		MOV		PWMP,		#0FH
		
;		Etenak eta FLAG-ak
		SETB EA		;	Etenak gaitu
		
		RET
		
;*********************************************************************************************************************************
; 													EGOERA MAKINA
;*********************************************************************************************************************************

	EGOERA_MAKINA:
		MOV	A,	EGOERA
		RL	A
		MOV	DPTR,	#EGOERA_TAULA
		JMP	@A+DPTR
	
	EGOERA_TAULA:
		AJMP	EGOERA_0	;	IDLE
		AJMP	EGOERA_1	;	Atea konprobatu
		AJMP	EGOERA_2	;	Pisua konprobatu
		AJMP	EGOERA_3	;	Betetzen
		AJMP	EGOERA_4	;	Berotzen
		AJMP	EGOERA_5	;	Garbitzen
		AJMP	EGOERA_6	;	Husten
		AJMP	EGOERA_7	;	Zentrifugatzen
		AJMP	EGOERA_8	;	Amaiera
	
	
;*********************************************************************************************************************************
;													EGOERA 0	(IDLE)
;*********************************************************************************************************************************

	EGOERA_0:
		MOV		IEN0,	#81H	;	Botoiaren etena gaitu
		ORL		PCON,	#01H	;	IDLE modua aktibatu
		CLR 	EX0				;	INT0 etena desgaitu
		CLR		EA				;	Etenak desgaitu
		CLR 	TICK_BOTOIA		;	FLAG-a desgaitu
		MOV		EGOERA,	#01H
		RET

;*********************************************************************************************************************************
;													EGOERA 1	(Atea konprobatu)
;*********************************************************************************************************************************

	EGOERA_1:
		ACALL	GERTAERA_SORGAILUA_1
		MOV		A,		GERTAERA
		RL		A
		MOV		DPTR,	#EKINTZA_TAULA_1
		JMP		@ A+DPTR
		
	EKINTZA_TAULA_1:
		AJMP	ATEA_IREKI
		AJMP	ATEA_ITXI
		RET
		
	GERTAERA_SORGAILUA_1:
		JB		ATE_SNTS,	GS1_ATE_IREKIA
;		Atea itxita dago
		MOV		GERTAERA,	#01H
		CLR		ATE_KONT
		RET
	
	GS1_ATE_IREKIA:
;		Atea irekita dago
		JNB		ATE_KONT,	GS1_LEHENENGO_ALDIA
;		Aurreko bueltan atea jada irekita zegoen
		MOV		GERTAERA,	#02H
		RET
	
	GS1_LEHENENGO_ALDIA:
;		Atea lehengo aldiz ireki da
		MOV		GERTAERA,	#00H
		RET
	
;*********************************************************************************************************************************
;													EGOERA 2	(Pisua konprobatu)
;*********************************************************************************************************************************

	EGOERA_2:
		ACALL	GERTAERA_SORGAILUA_2
		MOV		A,		GERTAERA
		RL		A
		MOV		DPTR,	#EKINTZA_TAULA_2
		JMP		@ A+DPTR

	EKINTZA_TAULA_2:
		AJMP	ATEA_IREKI
		AJMP	PISU_IRAKURKETA_HASI
		AJMP	GAINKARGA
		AJMP	BETE
		RET
		
	GERTAERA_SORGAILUA_2:
		JB	ATE_SNTS,			GS2_ATE_IREKIA
		JB	TICK_IRAKURRITA,	GS2_GAINKARGA_KONPROBATU
;		Oraindik ez da pisua irakurri
		MOV	GERTAERA,	#04H
		RET
		
	GS2_ATE_IREKIA:
		MOV	GERTAERA,	#00H
		RET
	
	GS2_GAINKARGA_KONPROBATU:
		JB	TICK_GAINK,	GS2_GAINKARGA
		MOV	GERTAERA,	#03H
		RET		
	
	GS2_GAINKARGA:
		JNB	GAINK_KONT,	GS2_LEHENENGO_ALDIA
		MOV GERTAERA,	#01H
		RET
		
	GS2_LEHENENGO_ALDIA:
		MOV	GERTAERA,	#02H
		RET
		
;*********************************************************************************************************************************
;													EGOERA 3	(Betetzen)
;*********************************************************************************************************************************

	EGOERA_3:
		ACALL	GERTAERA_SORGAILUA_3
		MOV		A,		GERTAERA
		RL		A
		MOV		DPTR,	#EKINTZA_TAULA_3
		JMP		@ A+DPTR
	
	EKINTZA_TAULA_3:
		AJMP	BEROTU
		RET
		
	GERTAERA_SORGAILUA_3:
		JB	BETE_SNTS,	GS3_BETETA
;		Oraindik ez da bete
		MOV	GERTAERA,	#01H
		RET
		
	GS3_BETETA:
		MOV	GERTAERA,	#00H
		RET
		
;*********************************************************************************************************************************
;													EGOERA 4	(Berotzen)
;*********************************************************************************************************************************

	EGOERA_4:
		ACALL	GERTAERA_SORGAILUA_4
		MOV		A,		GERTAERA
		RL		A
		MOV		DPTR,	#EKINTZA_TAULA_4
		JMP	@ A+DPTR
		
	EKINTZA_TAULA_4:
		AJMP	GARBITU
		AJMP	TENP_IRAKURKETA_HASI
		RET
		
	GERTAERA_SORGAILUA_4:
		JB	TICK_IRAKURRITA,	GS4_TENPERATURA_KONPROBATU
		MOV	GERTAERA,			#02H
		RET
		
	GS4_TENPERATURA_KONPROBATU:
		JB	TICK_TENP_EGOKIA,	GS4_TENPERATURA_EGOKIA
		MOV	GERTAERA,			#01H
		RET
		
	GS4_TENPERATURA_EGOKIA:
		MOV	GERTAERA,	#00H
		RET
		
;*********************************************************************************************************************************
;													EGOERA 5	(Garbitzen)
;*********************************************************************************************************************************

	EGOERA_5:
		ACALL	GERTAERA_SORGAILUA_5
		MOV		A,		GERTAERA
		RL		A
		MOV		DPTR,	#EKINTZA_TAULA_5
		JMP		@ A+DPTR
		
	EKINTZA_TAULA_5:
		AJMP	NORANZKOA_ALDATU
		AJMP	DISPLAYAK_EGUNERATU_DENBORA
		AJMP	HUSTU
		RET
		
	GERTAERA_SORGAILUA_5:
		JB	TICK_50min,	GS5_50min
		JB	TICK_1min,	GS5_1min
		JB	TICK_15s,	GS5_15s
		MOV	GERTAERA,	#03H
		RET
		
	GS5_50min:
		MOV	GERTAERA,	#02H
		RET
	
	GS5_1min:
		MOV	GERTAERA,	#01H
		RET
	
	GS5_15s:
		MOV	GERTAERA,	#00H
		RET
		
;*********************************************************************************************************************************
;													EGOERA 6	(Husten)
;*********************************************************************************************************************************

	EGOERA_6:
		ACALL	GERTAERA_SORGAILUA_6
		MOV		A,		GERTAERA
		RL		A
		MOV		DPTR,	#EKINTZA_TAULA_6
		JMP		@ A+DPTR
		
	EKINTZA_TAULA_6:
		AJMP	ZENTRIFUGATU
		RET
		
	GERTAERA_SORGAILUA_6:
		JB	BETE_SNTS,	GS6_HUTSIK
		MOV	GERTAERA,	#01H
		RET
		
	GS6_HUTSIK:
		MOV	GERTAERA,	#00H
		RET
		
;*********************************************************************************************************************************
;													EGOERA 7	(Zentrifugatzen)
;*********************************************************************************************************************************

	EGOERA_7:
		ACALL	GERTAERA_SORGAILUA_7
		MOV		A,		GERTAERA
		RL		A
		MOV		DPTR,	#EKINTZA_TAULA_7
		JMP		@ A+DPTR
		
	EKINTZA_TAULA_7:
		AJMP	AMAITU
		AJMP	DISPLAYAK_EGUNERATU_DENBORA
		RET
		
	GERTAERA_SORGAILUA_7:
		JB	TICK_10min,	GS7_10min
		JB	TICK_1min,	GS7_1min
		MOV	GERTAERA,	#02H
		RET
		
	GS7_10min:
		MOV	GERTAERA,	#00H
		RET
		
	GS7_1min:
		MOV	GERTAERA,	#01H
		RET
		
;*********************************************************************************************************************************
;													EGOERA 8	(Amaiera)
;*********************************************************************************************************************************
	
	EGOERA_8:
		ACALL	GERTAERA_SORGAILUA_8
		MOV		A,		GERTAERA
		RL		A
		MOV		DPTR,	#EKINTZA_TAULA_8
		JMP		@ A+DPTR
		
	EKINTZA_TAULA_8:
		AJMP	BUKATUTA
		RET
		
	GERTAERA_SORGAILUA_8:
		JB	ATE_SNTS,	GS8_ATE_IREKIA
		MOV	GERTAERA,	#01H
		RET
		
	GS8_ATE_IREKIA:
		MOV	GERTAERA,	#00H
		RET		
		
;*********************************************************************************************************************************
;													EKINTZAK
;*********************************************************************************************************************************
		
	ATEA_IREKI:
		SETB	ATE_KONT
		MOV		EGOERA,	#01H
		ACALL	DISPLAYAK_EGUNERATU_PA
		RET
		
	ATEA_ITXI:
		CLR		ATE_KONT
		MOV		EGOERA,	#02H
		ACALL	DISPLAYAK_AMATATU
		
		SETB	EAD
		ANL		ADCON,	#0F8H	;	Hiru ADDR-ak 0-ra jarri ADC0 aukeratzeko
		ANL		ADCON,	#0DFH	;	ADEX 0-ra jarri software modua aukeratzeko (ADCON.5)
		SETB	EAD
		SETB	EA
		ACALL	PISU_IRAKURKETA_HASI
		RET
		
	PISU_IRAKURKETA_HASI:
		CLR TICK_IRAKURRITA
		ORL		ADCON,	#08H	;	ADCS 1-era jarri (ADCON.3) irakurketa hasteko
		RET
		
	GAINKARGA:
		SETB	GAINK_KONT
		ACALL	DISPLAYAK_EGUNERATU_SP
		RET
		
	BETE:
		CLR		TICK_GAINK
		CLR		GAINK_KONT
		MOV		EGOERA,	#03H
		ACALL	DISPLAYAK_AMATATU
		SETB	P3.3
		RET
		
	BEROTU:
		MOV		EGOERA,	#04H
		CLR		P3.3
		SETB	P3.6
		ANL		ADCON, #0F9H	;AADR 1 eta 2 0-ra eta AADR 0 1-era jarri ADC1 aukeratzeko
		ANL		ADCON, #0DFH	;ADEX 0-ra jarri software modua aukeratzeko (ADCON.5)
		SETB	EAD
		SETB	EA
		ACALL	TENP_IRAKURKETA_HASI
		RET
		
	TENP_IRAKURKETA_HASI:
		CLR		TICK_IRAKURRITA
		ORL		ADCON, 		#08H	;	ADCS 1-era jarri (ADCON.3)
		RET
		
	GARBITU:
		CLR		TICK_TENP_EGOKIA
		CLR		P3.6
		CLR 	EAD
		MOV		EGOERA,		#05H
		MOV		DENBORA,	#32H
		MOV		TMOD,		#02H
		SETB	ET0
		SETB	TR0
		SETB	EA
		
		MOV		PWM0,		#0E8H
		RET
		
	NORANZKOA_ALDATU:
		CPL		P2.7
		CLR		TICK_15s
		RET
		
	HUSTU:	
		CLR		TICK_50min
		CLR		TICK_10min
		CLR		TICK_1min
		CLR		ET0
		CLR		TR0
		CLR		EA
		MOV		EGOERA,	#06H
		ACALL	DISPLAYAK_AMATATU
		SETB	P1.0
		RET
	
	ZENTRIFUGATU:
		MOV	EGOERA,	#07H
		SETB	ET0
		SETB	EA
		SETB	TR0
		MOV		PWM0,	#01AH
		//TODO
		RET
	
	AMAITU:
		MOV		EGOERA,	#08H
		CLR		TICK_10min
		CLR		TR0
		CLR		ET0
		CLR		EA
		MOV		PWM0,	#0FFH
		ACALL	DISPLAYAK_EGUNERATU_FF
		RET
	
	BUKATUTA:
		AJMP	PROGRAMA_HASIERA
	
;*********************************************************************************************************************************
;													DISPLAYAK
;*********************************************************************************************************************************
	
	DISPLAYAK_AMATATU:
		MOV	DH,	#00H
		MOV	DU,	#00H
		RET
	
	DISPLAYAK_EGUNERATU_PA:
		MOV	DH,	#73H	;	P = 0111 0011b = 73H
		MOV	DU,	#77H	;	A = 0111 0111b = 77H
		RET
	
	DISPLAYAK_EGUNERATU_SP:
		MOV	DH,	#6DH	;	S = 0110 1101b = 6DH
		MOV	DU,	#73H	;	P = 0111 0011b = 73H
		RET
	
	DISPLAYAK_EGUNERATU_FF:
		MOV	DH,	#71H	;	F = 0111 0001b = 71H
		MOV	DU,	#71H	;	F = 0111 0001b = 71H
		RET
	
	DISPLAYAK_EGUNERATU_DENBORA:
		CLR TICK_1min
		MOV	A,	DENBORA
		SUBB	A,	MINUTUAK
		MOV	B,	#0AH
		DIV	AB
		ACALL	DISPLAY_ZENBAKIA_ZEHAZTU
		MOV	DH,	A
		MOV	A,	B
		ACALL	DISPLAY_ZENBAKIA_ZEHAZTU
		MOV	DU,	A
		RET
		
	DISPLAY_ZENBAKIA_ZEHAZTU:
		INC	A
		MOVC	A,	@ A+PC
		RET
		DB	03FH	;	0 = 0011 1111b
		DB	06H		;	1 = 0000 0110b
		DB	05BH	;	2 = 0101 1011b
		DB	09FH	;	3 = 0100 1111b
		DB	066H	;	4 = 0110 0110b
		DB	06DH	;	5 = 0110 1101b
		DB	07DH	;	6 = 0111 1101b
		DB	07H		;	7 = 0000 0111b
		DB	07FH	;	8 = 0111 1111b
		DB	06FH	;	9 = 0110 1111b
		

;*********************************************************************************************************************************
;													ETENEN ERRUTINA LAGUNTZAILEAK
;*********************************************************************************************************************************

	UNITATE_BIHURKETA:
		INC	KONT_1ms
		MOV	A,	#0FAH
		CJNE	A,	KONT_1ms,	UB_AMAIERA
		INC	KONT_250ms
		MOV	KONT_1ms,	#00H
		MOV	A,	#04H
		CJNE	A,	KONT_250ms,	UB_AMAIERA
		INC	SEGUNDUAK
		MOV	KONT_250ms,	#00H
		UB_AMAIERA:
		RET

	T_FLAG_KONPROBATU:
		ACALL	KONPROBATU_15s
		ACALL	KONPROBATU_1min
		ACALL	KONPROBATU_10min
		ACALL	KONPROBATU_50min
		RET

	KONPROBATU_15s:
		MOV	A,	#0FH
		CJNE	A,	SEGUNDUAK,	K15s_AMAIERA
		SETB	TICK_15s
		K15s_AMAIERA:
		RET

	KONPROBATU_1min:
		MOV	A,	#03CH
		CJNE	A,	SEGUNDUAK,	K1min_AMAIERA
		SETB	TICK_1min
		INC	MINUTUAK
		MOV	SEGUNDUAK,	#00H
		K1min_AMAIERA:
		RET
	
	KONPROBATU_10min:
		MOV	A,	#0AH
		CJNE	A,	MINUTUAK,	K10min_AMAIERA
		SETB	TICK_10min
		K10min_AMAIERA:
		RET
			
	KONPROBATU_50min:
		MOV	A,	#032H
		CJNE	A,	MINUTUAK,	K50min_AMAIERA
		SETB	TICK_50min
		K50min_AMAIERA:
		RET
			
			
	PISUA_IRAKURRI:
		MOV		A,	#0E6H
		CLR		C
		SUBB	A,	ADCH
		JC		GAINKARGA_DAGO
		CLR		TICK_GAINK
		RET
	
	GAINKARGA_DAGO:
		SETB	TICK_GAINK
		RET
		
	
	TENPERATURA_IRAKURRI:
		ACALL	TENPERATURA_HAUTATU
		SUBB	A,	ADCH
		JC		TENPERATURA_EGOKIA
		CLR		TICK_TENP_EGOKIA
		RET
		
	TENPERATURA_EGOKIA:
		SETB	TICK_TENP_EGOKIA
		RET
		
	TENPERATURA_HAUTATU:
		MOV		A,	#00H
		MOV		A,	P3
		ANL		A,	#03H
		INC	A
		MOVC	A,	@ A+PC
		RET
		DB	00H		;	Ur hotza
		DB	066H	;	40ºC
		DB	099H	;	60ºC
		DB	0CDH	;	80ºC
		
END