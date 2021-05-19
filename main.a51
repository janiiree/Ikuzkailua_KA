$NOMOD51
#include "80c552.h"

;*********************************************************************************************************************************
;													ETIKETAK
;*********************************************************************************************************************************

;	Aldagaiak
	EGOERA				EQU	20H
	GERTAERA			EQU	21H
	TENPERATURA			EQU	22H
		
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
	D1					EQU	P0
	D1_ZENB				EQU	2BH
	
;	Unitateen displaya
	D2					EQU	P2
	D2_ZENB				EQU	2CH
	
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

;	_______________________________________________________________________________________________________________________________
	//TODO
;	_______________________________________________________________________________________________________________________________

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

ORG	1BH		;	TIMER1 etena
;	_______________________________________________________________________________________________________________________________
	//TODO
;	_______________________________________________________________________________________________________________________________

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

ORG	53H		;	ADC0 etena ---> ADCI=1 denean
;	_______________________________________________________________________________________________________________________________
	//TODO
;	_______________________________________________________________________________________________________________________________

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
		MOV	D1,				#00H
		MOV	D1_ZENB,		#00H
	
;		Unitateen displaya
		MOV	D2,				#00H
		MOV	D2_ZENB,		#00H
		
;		Etenen FLAG-ak (T0, T1, ADC0, ADC1 eta IDLE)
		CLR	TICK_15s
		CLR	TICK_1min
		CLR	TICK_10min
		CLR	TICK_50min
		CLR	TICK_GAINK
		CLR	TICK_TENP_EGOKIA
		CLR	TICK_IRAKURRITA
		CLR	TICK_BOTOIA
		
;		PWM
		MOV	PWMP,			#10h	;	Prescaler
		
;		Etenak eta FLAG-ak
;?????	SETB IT0	;	IT0 = TCON.0 = 0x88.0 (activado por transición)
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
		SETB	EX0				;	Botoiaren etena gaitu
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
		SETB	ATE_KONT
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
		ORL		ADCON, #08H		;ADCS 1-era jarri (ADCON.3)
		RET
		
	GARBITU:
		CLR	TICK_TENP_EGOKIA
		CLR	P3.6
		CLR EAD
		MOV	EGOERA,	#05H
		SETB	TR0
		SETB	EA
		//	FALTA LO DEL PWM	---->	PREGUNTAR
		RET
		
	NORANZKOA_ALDATU:
		//TODO
		RET
		
		
	HUSTU:	
		MOV		EGOERA,	#06H
		CLR		TR0
		CLR		EA
		SETB	P1.0
		RET
	
	ZENTRIFUGATU:
		MOV	EGOERA,	#07H
		//TODO
		RET
	
	AMAITU:
		MOV	EGOERA,	#08H
		//TODO
		RET
	
	BUKATUTA:
		MOV	EGOERA,	#00H
		ACALL	DISPLAYAK_EGUNERATU_PA
		RET
	
	
	
	
	
	DISPLAYAK_AMATATU:
	
	DISPLAYAK_EGUNERATU_PA:
	
	DISPLAYAK_EGUNERATU_SP:
	
	DISPLAYAK_EGUNERATU_DENBORA:






END