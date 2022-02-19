$NOMOD51
#include "80c552.h"

;*********************************************************************************************************************************
;				ETIKETAK
;*********************************************************************************************************************************

;		Aldagaiak
		EGOERA				EQU	20H
		GERTAERA			EQU	21H
		TENPERATURA			EQU	22H
		DENBORA				EQU	23H
		PISU_MAX			EQU 	24H
		
		KONT_1ms			EQU 	25H
		KONT_250ms			EQU	26H
		SEGUNDUAK			EQU	27H
		MINUTUAK			EQU	28H
		
		ATE_KONT			EQU	29H.0
	
;		Sentsoreak
		ATE_SNTS			EQU	P1.1
		BETE_SNTS			EQU	P1.2
		HUSTU_SNTS			EQU	P1.3
		
;		Motoreak
		HUSTU_MTR			EQU	P1.0
		BETE_MTR			EQU	P3.3
		BEROG				EQU	P3.6
		
;		Hamarrekoen Displaya
		DH				EQU	P0
	
;		Unitateen displaya
		DU				EQU	P2
	
;		Etenen FLAG-ak (Timer, ADC eta IDLE)
		TICK_TIMER			EQU 	29H.1
		TICK_15s			EQU	29H.2
		TICK_1min			EQU	29H.3
		TICK_10min			EQU	29H.4
		TICK_50min			EQU	29H.5
		TICK_GAINK			EQU	29H.6
		TICK_TENP_EGOKIA		EQU	29H.7
		TICK_IRAKURRITA			EQU	2AH.0
		TICK_BOTOIA			EQU	2AH.1

;*********************************************************************************************************************************

ORG 00H
	AJMP 	PROGRAMA_HASIERA

;*********************************************************************************************************************************
;				ETENAK
;*********************************************************************************************************************************

ORG 03H		;	INT0 etena

	SETB	TICK_BOTOIA
	RETI
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

ORG 0BH		;	TIMER0 etena, 1ms-rako konfiguratuta

	PUSH	ACC
	PUSH	B
	PUSH	PSW
	MOV	TH0,	#0F8H		
	MOV	TL0,	#030H
	SETB	TICK_TIMER
	INC	KONT_1ms	;	1ms kontatzen duen aldagaia inkrementatu
	POP	PSW
	POP	B
	POP	ACC
	RETI

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

ORG	53H		;	ADC0 etena ---> ADCI=1 denean

	PUSH	ACC
	PUSH	B
	PUSH	PSW
	SETB	TICK_IRAKURRITA		;	ADC-ren balioa irakurri egin dela jakiteko
	ANL	ADCON,	#0EFH		;	Irakurketa amaitzean ADCI flag-a (ADCON.4 bit-a) software bidez ezabatu behar da
	POP	PSW
	POP	B
	POP	ACC 
	RETI

;*********************************************************************************************************************************
;				PROGRAMA NAGUSIA
;*********************************************************************************************************************************

ORG 7BH
	PROGRAMA_HASIERA:
		ACALL 	HASIERAKETAK	;	Programan erabiliko diren aldagai eta erregistro guztiak hasieratu
		
	LOOP:				;	Begizta nagusia, programa etengabe egongo da honen barruan bueltaka
		ACALL 	EGOERA_MAKINA
		AJMP 	LOOP
			
;*********************************************************************************************************************************
;				HASIERAKETAK
;*********************************************************************************************************************************

	HASIERAKETAK:
;		Aldagaiak
		MOV	EGOERA,		#00H
		MOV	GERTAERA,	#00H
		MOV 	TENPERATURA,	#00H
		MOV	DENBORA,	#3CH	;	60 minitu gorde
		MOV	PISU_MAX,	#0E6H
		CLR 	ATE_KONT
		
;		Timerren FLAG-ak eta laguntzaileak
		MOV	KONT_1ms,	#00H
		MOV	KONT_250ms,	#00H
		MOV	SEGUNDUAK,	#00H
		MOV	MINUTUAK,	#00H
		
;		Motoreak
		CLR	HUSTU_MTR
		CLR	BETE_MTR
		CLR	BEROG
		
;		Displayak amatatuta hasieratu
		ACALL	DISPLAYAK_AMATATU
		
;		Etenen FLAG-ak (T0, T1, ADC0, ADC1 eta IDLE)
		CLR	TICK_TIMER
		CLR	TICK_15s
		CLR	TICK_1min
		CLR	TICK_10min
		CLR	TICK_50min
		CLR	TICK_GAINK
		CLR	TICK_TENP_EGOKIA
		CLR	TICK_IRAKURRITA
		CLR	TICK_BOTOIA
		
;		PWM prescaler (%50)
		MOV	PWMP,		#7FH
		
;		Timer0
		MOV	TMOD,		#01H	;	Timer modua aukeratu (1)
		MOV	TH0,		#0F8H		
		MOV	TL0,		#030H
		
;		Etenak eta FLAG-ak
		SETB 	EA			;	Etenak gaitu	
		RET
		
;*********************************************************************************************************************************
; 				EGOERA MAKINA
;*********************************************************************************************************************************

	EGOERA_MAKINA:
		MOV	A,	EGOERA		;	Egoera akumuladorean gorde
		RL	A			;	Bider 2 egin, AJMP instrukzio bakoitzak 2 byte okupatzen duelako
		MOV	DPTR,	#EGOERA_TAULA	;	Egoera taularen memoria helbidea DPTR erregistroan gorde
		JMP	@ A+DPTR		;	Egoera taularen helbideari dagokion egoeraren balioa (bider 2) gehitu, eta horra salto egin
	
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
;				EGOERA 0	(IDLE)
;*********************************************************************************************************************************

	EGOERA_0:
		SETB	EX0		;	Botoiaren etena gaitu
		ORL	PCON,	#01H	;	IDLE modua aktibatu
		CLR 	EX0		;	INT0 etena desgaitu
		CLR	EA		;	Etenak desgaitu
		CLR 	TICK_BOTOIA	;	FLAG-a desgaitu
		MOV	EGOERA,	#01H	;	1. egoerara aldatu
		RET

;*********************************************************************************************************************************
;				EGOERA 1	(Atea konprobatu)
;*********************************************************************************************************************************

	EGOERA_1:
		ACALL	GERTAERA_SORGAILUA_1		;	Gertaera sorgailua deitu, gertaeraren arabera ekintza bat aukeratu ahal izateko
		MOV	A,	GERTAERA		;	Gertaera akumuladorean gorde
		RL	A				;	Bider 2 egin, AJMP instrukzio bakoitzak 2 byte okupatzen duelako
		MOV	DPTR,	#EKINTZA_TAULA_1	;	Gertaera taularen memoria helbidea DPTR erregistroan gorde
		JMP	@ A+DPTR			;	Gertaera taularen helbideari dagokion egoeraren balioa (bider 2) gehitu, eta horra salto egin
				
	EKINTZA_TAULA_1:		;	Egoerari dagozkion ekintza guztiak zerrendatzen ditu (gertaeraren arabaera aukeratzen da zein egin)
		AJMP	ATEA_IREKI	;	Lehenengo aldiz atea irekitzen denean
		AJMP	ATEA_ITXI	;	Atea ixten denean
		RET			;	Atea irekita dagoenean, baina aurreko bueltan jada irekita bazegoen (displayak etengabe ez eguneratzeko)
		
	GERTAERA_SORGAILUA_1:
		JB	ATE_SNTS,	GS1_ATE_IREKIA	;	Atearen egoera konprobatu
		MOV	GERTAERA,	#01H		;	Atea itxita dago
		RET
	
	GS1_ATE_IREKIA:						;	Atea irekita dago
		JNB	ATE_KONT,	GS1_LEHENENGO_ALDIA	;	Atea irekita dagoen lehenengo buelta den konprobatu
		MOV	GERTAERA,	#02H			;	Aurreko bueltan atea jada irekita zegoen
		RET
	
	GS1_LEHENENGO_ALDIA:			;	Atea lehengo aldiz ireki da
		MOV	GERTAERA,	#00H	;	Gertaerarik ez
		RET
		
	ATEA_IREKI:
		SETB	ATE_KONT		;	Atea lehenengo aldiz irekitzean flag-a altxatzen da
		MOV	EGOERA,		#01H	;	1. egoera jarri
		ACALL	DISPLAYAK_EGUNERATU_PA	;	Displayetan PA bistaratu
		RET
		
	ATEA_ITXI:
		CLR	ATE_KONT		;	Ate irekiaren FLAG-a jaitsi
		MOV	EGOERA,		#02H	;	2. egoera jarri
		ACALL	DISPLAYAK_AMATATU	;	Displayak amatatu
		ANL	ADCON,		#0F8H	;	Hiru ADDR-ak 0-ra jarri ADC0 aukeratzeko
		ACALL	ADC_IRAKURKETA_HASI	;	Pisu irakurketa hasi
		RET
	
;*********************************************************************************************************************************
;				EGOERA 2	(Pisua konprobatu)
;*********************************************************************************************************************************

	EGOERA_2:
		ACALL	GERTAERA_SORGAILUA_2		;	Gertaera sorgailua deitu, gertaeraren arabera ekintza bat aukeratu ahal izateko
		MOV	A,	GERTAERA		;	Gertaera akumuladorean gorde
		RL	A				;	Bider 2 egin, AJMP instrukzio bakoitzak 2 byte okupatzen duelako
		MOV	DPTR,	#EKINTZA_TAULA_2	;	Gertaera taularen memoria helbidea DPTR erregistroan gorde
		JMP	@ A+DPTR			;	Gertaera taularen helbideari dagokion egoeraren balioa (bider 2) gehitu, eta horra salto egin

	EKINTZA_TAULA_2:
		AJMP	ATEA_IREKI	;	Atea irekitzen denean
		AJMP	GAINKARGA	;	Gainkarga dago
		AJMP	BETE		;	Pisua egokia da eta danborra urez bete daiteke
		RET			;	Pisuaren irakurketa oraindik ez da amaitu
		
	GERTAERA_SORGAILUA_2:
		JB	ATE_SNTS,		GS2_ATE_IREKIA			;	Atearen egoera konprobatu
		JB	TICK_IRAKURRITA,	GS2_GAINKARGA_KONPROBATU	;	Pisuaren irakurketa amaitu den konprobatu
		MOV	GERTAERA,		#03H				;	Oraindik ez da pisua irakurri
		RET
		
	GS2_ATE_IREKIA:
		MOV	GERTAERA,	#00H	;	Atea ireki da
		RET
	
	GS2_GAINKARGA_KONPROBATU:
		ACALL	PISUA_IRAKURRI			;	Pisu irakurketaren emaitza konprobatu
		JB	TICK_GAINK,	GS2_GAINKARGA	;	Gainkarga konprobatu
		MOV	GERTAERA,	#02H		;	Pisua egokia da
		RET		
	
	GS2_GAINKARGA:
		MOV	GERTAERA,	#01H	;	Gainkarga dago
		RET
		
	PISUA_IRAKURRI:
		MOV	A,	PISU_MAX	;	4,5V-ren (gainkargaren tentsio minimoa) balio hexadezimala akumuladorean gorde
		CLR	C			;	Carry-a ezabatu
		SUBB	A,	ADCH		;	Gainkargaren balioa eta irakurketaren balioa kendu
		JC	GAINKARGA_DAGO		;	Carry-a aktibatu bada, gainkarga dago (ADCH-k irakurritako balioa ezarritako balioa baino handiagoa da)
		CLR	TICK_GAINK		;	Gainkargaren flag-a jaitsi
		RET
	
	GAINKARGA_DAGO:
		SETB	TICK_GAINK	;	Gainkargaren flag-a altxatu
		RET
		
	GAINKARGA:
		ACALL	DISPLAYAK_EGUNERATU_SP	;	Displayetan SP bistaratu
		RET
		
	BETE:
		CLR	EAD			;	ADCren etenak desgaitu
		CLR	EA			;	Etenak desgaitu
		CLR	TICK_GAINK		;	Gainkargaren flag-a jaitsi
		MOV	EGOERA,		#03H	;	3. egoera jarri
		ACALL	DISPLAYAK_AMATATU	;	Displayak amatatu
		SETB	BETE_MTR		;	Ur sarreraren balbula aktibatu
		RET
		
;*********************************************************************************************************************************
;				EGOERA 3	(Betetzen)
;*********************************************************************************************************************************

	EGOERA_3:
		ACALL	GERTAERA_SORGAILUA_3		;	Gertaera sorgailua deitu, gertaeraren arabera ekintza bat aukeratu ahal izateko
		MOV	A,	GERTAERA		;	Gertaera akumuladorean gorde
		RL	A				;	Bider 2 egin, AJMP instrukzio bakoitzak 2 byte okupatzen duelako
		MOV	DPTR,	#EKINTZA_TAULA_3	;	Gertaera taularen memoria helbidea DPTR erregistroan gorde
		JMP	@ A+DPTR			;	Gertaera taularen helbideari dagokion egoeraren balioa (bider 2) gehitu, eta horra salto egin
	
	EKINTZA_TAULA_3:
		AJMP	BEROTU	;	Danborra guztiz beteta dago eta ura berotu daiteke
		RET		;	Oraindik danborra ez dago beteta
		
	GERTAERA_SORGAILUA_3:
		JB	BETE_SNTS,	GS3_BETETA	;	Danborra beteta dagoen konprobatu
		MOV	GERTAERA,	#01H		;	Oraindik ez dago beteta
		RET
		
	GS3_BETETA:
		MOV	GERTAERA,	#00H	;	Guztiz beteta dago
		RET
		
	BEROTU:
		MOV	EGOERA,	#04H		;	4. egoera jarri
		CLR	BETE_MTR		;	Ur sarreraren balbula itxi
		SETB	BEROG			;	Berogailua piztu
		ANL	ADCON, #0F8H		;	AADR 1 eta 2 0-ra jarri
		ORL	ADCON, #01H		; 	AADR 0 1-era jarri ADC1 
		ACALL	ADC_IRAKURKETA_HASI	;	Tenperatura irakurtzen hasi
		RET
		
;*********************************************************************************************************************************
;				EGOERA 4	(Berotzen)
;*********************************************************************************************************************************

	EGOERA_4:
		ACALL	GERTAERA_SORGAILUA_4		;	Gertaera sorgailua deitu, gertaeraren arabera ekintza bat aukeratu ahal izateko
		MOV	A,	GERTAERA		;	Gertaera akumuladorean gorde
		RL	A				;	Bider 2 egin, AJMP instrukzio bakoitzak 2 byte okupatzen duelako
		MOV	DPTR,	#EKINTZA_TAULA_4	;	Gertaera taularen memoria helbidea DPTR erregistroan gorde
		JMP	@ A+DPTR			;	Gertaera taularen helbideari dagokion egoeraren balioa (bider 2) gehitu, eta horra salto egin
		
	EKINTZA_TAULA_4:
		AJMP	GARBITU			;	Urak tenperatura egokia du eta garbiketa hasi daiteke
		AJMP	ADC_IRAKURKETA_HASI	;	Aurreko irakurketan tenperatura oraindik ez zen nahikoa eta berriro irakurriko da
		RET				;	Oraindik ez da irakurketa amaitu
		
	GERTAERA_SORGAILUA_4:
		JB	TICK_IRAKURRITA,	GS4_TENPERATURA_KONPROBATU	;	Irakurketa amitu den konprobatu
		MOV	GERTAERA,		#02H				;	Oraindik ez da irakurketa amaitu
		RET
		
	GS4_TENPERATURA_KONPROBATU:
		ACALL	TENP_IRAKURRI					;	Tenperatura irakurketaren emaitza konprobatu
		JB	TICK_TENP_EGOKIA,	GS4_TENPERATURA_EGOKIA	;	Tenperatura egokia den konprobatu
		MOV	GERTAERA,		#01H			;	Tenperatura oraindik ez da nahikoa eta berriro irakurri behar da
		RET
		
	GS4_TENPERATURA_EGOKIA:
		MOV	GERTAERA,	#00H	;	Tenperatura egokia da
		RET
		
	TENP_IRAKURRI:
		ACALL	TENPERATURA_HAUTATU		;	Hautatutako tenperatura zehaztu
		CJNE	A, ADCH, TENPERATURA_EZ_EGOKIA	;	ADCH-ren balioa begiratu, eta oraindik egokia ez bada salto egin
		SETB	TICK_TENP_EGOKIA		;	Tenperatura egokiaren flag-a jaitsi
		RET
		
	TENPERATURA_EZ_EGOKIA:
		CLR	TICK_TENP_EGOKIA	;	Tenperatura egokiaren flag-a altxatu
		RET
		
	TENPERATURA_HAUTATU:
		MOV	A,	P3
		ANL	A,	#03H
		INC	A
		MOVC	A,	@ A+PC
		RET
		DB	00H	;	Ur hotza
		DB	066H	;	40ºC
		DB	099H	;	60ºC
		DB	0CCH	;	80ºC
				
	GARBITU:
		CLR	TICK_TENP_EGOKIA	;	Tenperatura egokiaren flag-a jaitsi
		CLR	BEROG			;	Berogailua itzali
		CLR 	EAD			;	ADCren etenak desgaitu
		MOV	EGOERA,		#05H	;	5. egoera jarri
		SETB	ET0			;	Timer0-ren etenak gaitu
		SETB	TR0			;	Timer 0 piztu
		MOV	PWM0,		#0E8H	;	60rpm-ko abiaduran jarri motorra
		RET
		
;*********************************************************************************************************************************
;				EGOERA 5	(Garbitzen)
;*********************************************************************************************************************************

	EGOERA_5:
		ACALL	GERTAERA_SORGAILUA_5		;	Gertaera sorgailua deitu, gertaeraren arabera ekintza bat aukeratu ahal izateko
		MOV	A,	GERTAERA		;	Gertaera akumuladorean gorde
		RL	A				;	Bider 2 egin, AJMP instrukzio bakoitzak 2 byte okupatzen duelako
		MOV	DPTR,	#EKINTZA_TAULA_5	;	Gertaera taularen memoria helbidea DPTR erregistroan gorde
		JMP	@ A+DPTR			;	Gertaera taularen helbideari dagokion egoeraren balioa (bider 2) gehitu, eta horra salto egin
		
	EKINTZA_TAULA_5:
		AJMP	NORANZKOA_ALDATU		;	15 s igaro dira eta motorraren errotazio noraznkoa aldatuko da
		AJMP	DISPLAYAK_EGUNERATU_DENBORA	;	1 min igaro da eta displayetan geeratzen den denbora eguneratu behar da
		AJMP	HUSTU				;	50 min igaro dira eta danborra hustuko da
		RET					;	Gertaerarik ez
		
	GERTAERA_SORGAILUA_5:
		JNB	TICK_TIMER,	GS5_AM
		ACALL	UNITATE_BIHURKETA
		ACALL	T_FLAG_KONPROBATU
		JB	TICK_50min,	GS5_50min	;	50 min igaro diren konprobatu
		JB	TICK_1min,	GS5_1min	;	1 min igaro den konprobatu
		JB	TICK_15s,	GS5_15s		;	15 s igaro diren konprobatu
		GS5_AM:
		MOV	GERTAERA,	#03H		;	Gertaerarik ez
		RET
		
	GS5_50min:
		MOV	GERTAERA,	#02H	;	50 min igaro dira
		RET
	
	GS5_1min:
		MOV	GERTAERA,	#01H	;	1 min igaro da
		RET
	
	GS5_15s:
		MOV	GERTAERA,	#00H	;	15 s igaro dira
		RET
		
	NORANZKOA_ALDATU:
		CPL	P2.7		;	Osagarria kalkulatu, motorraren errotazio noranzkoa aldatzeko
		CLR	TICK_15s	;	15 s flg-a jaitsi
		RET
		
	HUSTU:	
		CLR	TR0			;	Timer0 amatatu
		CLR	ET0			;	Timer0-ren etenak desgaitu
		CLR	EA			;	Etenak desgaitu
		CLR	TICK_50min		;	50 min flag-a jaitsi
		CLR	TICK_10min		;	10 min flag-a jaitsi
		CLR	TICK_1min		;	1 min flag-a jaitsi
		CLR	TICK_TIMER		;	Timerraren flag-a desgaitu
		MOV	PWM0,	#0FFH		;	Motorra gelditu
		ACALL	DISPLAYAK_AMATATU	;	Dsiplayak amatatu		
		MOV	EGOERA,	#06H		;	6. egoera jarri
		SETB	HUSTU_MTR		;	Husteko motorra piztu
		RET
		
;*********************************************************************************************************************************
;				EGOERA 6	(Husten)
;*********************************************************************************************************************************

	EGOERA_6:
		ACALL	GERTAERA_SORGAILUA_6		;	Gertaera sorgailua deitu, gertaeraren arabera ekintza bat aukeratu ahal izateko
		MOV	A,	GERTAERA		;	Gertaera akumuladorean gorde
		RL	A				;	Bider 2 egin, AJMP instrukzio bakoitzak 2 byte okupatzen duelako
		MOV	DPTR,	#EKINTZA_TAULA_6	;	Gertaera taularen memoria helbidea DPTR erregistroan gorde
		JMP	@ A+DPTR			;	Gertaera taularen helbideari dagokion egoeraren balioa (bider 2) gehitu, eta horra salto egin
		
	EKINTZA_TAULA_6:
		AJMP	ZENTRIFUGATU	;	Danborra guztiz husu da eta zentrifugatzen hasiko da
		RET			;	Danborra oraindik ez dago hutsik
		
	GERTAERA_SORGAILUA_6:
		JB	HUSTU_SNTS,	GS6_HUTSIK	;	Hustk dagoen konprobatu
		MOV	GERTAERA,	#01H		;	Oraindik ez dago hutsik
		RET
		
	GS6_HUTSIK:
		MOV	GERTAERA,	#00H	;	Hutsik dago
		RET
	
	ZENTRIFUGATU:
		CLR	HUSTU_MTR	;	Husteko motorra amatatu
		MOV	EGOERA,	#07H	;	7. egoera jarri
		SETB	ET0		;	Timer0-ren etenak gaitu
		SETB	EA		;	Etenak gaitu
		SETB	TR0		;	Timer0 piztu
		MOV	PWM0,	#01AH	;	600 rpm-ko abiaduran jarri motorra
		RET
		
;*********************************************************************************************************************************
;				EGOERA 7	(Zentrifugatzen)
;*********************************************************************************************************************************

	EGOERA_7:
		ACALL	GERTAERA_SORGAILUA_7		;	Gertaera sorgailua deitu, gertaeraren arabera ekintza bat aukeratu ahal izateko
		MOV	A,	GERTAERA		;	Gertaera akumuladorean gorde
		RL	A				;	Bider 2 egin, AJMP instrukzio bakoitzak 2 byte okupatzen duelako
		MOV	DPTR,	#EKINTZA_TAULA_7	;	Gertaera taularen memoria helbidea DPTR erregistroan gorde
		JMP	@ A+DPTR			;	Gertaera taularen helbideari dagokion egoeraren balioa (bider 2) gehitu, eta horra salto egin
		
	EKINTZA_TAULA_7:
		AJMP	AMAITU				;	10 min igaro dira eta zentrifugatua amaitu da
		AJMP	DISPLAYAK_EGUNERATU_DENBORA	;	1 min igaro da eta displayetan denbora eguneratu behar da
		RET					;	Gertaerarik ez
		
	GERTAERA_SORGAILUA_7:
		JNB	TICK_TIMER, GS7_AM
		ACALL	UNITATE_BIHURKETA
		ACALL	T_FLAG_KONPROBATU
		JB	TICK_10min,	GS7_10min	;	10 min igaro diren konprobatu
		JB	TICK_1min,	GS7_1min	;	1 min igaro den konprobatu
		GS7_AM:
		MOV	GERTAERA,	#02H		;	Gertaerarik ez
		RET
		
	GS7_10min:
		MOV	GERTAERA,	#00H	;	10 min igaro dira
		RET
		
	GS7_1min:
		MOV	GERTAERA,	#01H	;	1 min igaro da
		RET
	
	AMAITU:
		MOV	EGOERA,		#08H	;	8. egoera jarri
		CLR	TICK_10min		;	10 min flag-a jaitsi
		CLR	TR0			;	Timer0 amatatu
		CLR	ET0			;	Timer0-ren etenak desgaitu
		CLR	EA			;	Etenak desgaitu
		MOV	PWM0,		#0FFH	;	Motorra gelditu
		ACALL	DISPLAYAK_EGUNERATU_FF	;	Displayetan FF bistaratu
		RET
		
;*********************************************************************************************************************************
;				EGOERA 8	(Amaiera)
;*********************************************************************************************************************************
	
	EGOERA_8:
		ACALL	GERTAERA_SORGAILUA_8		;	Gertaera sorgailua deitu, gertaeraren arabera ekintza bat aukeratu ahal izateko
		MOV	A,	GERTAERA		;	Gertaera akumuladorean gorde
		RL	A				;	Bider 2 egin, AJMP instrukzio bakoitzak 2 byte okupatzen duelako
		MOV	DPTR,	#EKINTZA_TAULA_8	;	Gertaera taularen memoria helbidea DPTR erregistroan gorde
		JMP	@ A+DPTR			;	Gertaera taularen helbideari dagokion egoeraren balioa (bider 2) gehitu, eta horra salto egin
		
	EKINTZA_TAULA_8:
		AJMP	BUKATUTA	;	Atea ireki da arropa ateratzeko
		RET			;	Oraindik ez da atea ireki
		
	GERTAERA_SORGAILUA_8:
		JB	ATE_SNTS,	GS8_ATE_IREKIA	;	Atea ireki den konprobatu
		MOV	GERTAERA,	#01H		;	Oraindik ez da atea ireki
		RET
		
	GS8_ATE_IREKIA:
		MOV	GERTAERA,	#00H	;	Atea ireki da
		RET	

	BUKATUTA:
		MOV	EGOERA,		#00H	;	0. egoera jarri
		RET
		
;*********************************************************************************************************************************
;				EKINTZA KOMUNAK
;*********************************************************************************************************************************
		
	ADC_IRAKURKETA_HASI:
		CLR 	TICK_IRAKURRITA		;	Irakurketa berria hasiko denez, flag-a jaitsi
		ANL	ADCON,	#0DFH		;	ADEX 0-ra jarri software modua aukeratzeko (ADCON.5)
		SETB	EAD			;	ADCaren etenak gaitu
		SETB	EA			;	Etenak gaitu
		ORL	ADCON,	#08H		;	ADCS 1-era jarri (ADCON.3) irakurketa hasteko
		RET
			
;*********************************************************************************************************************************
;													TIMERREN ERRUTINA LAGUNTZAILEAK
;*********************************************************************************************************************************

	UNITATE_BIHURKETA:
		MOV	A,	#0FAH				;	250 akumuladorean gorde
		CJNE	A,	KONT_1ms,	UB_AMAIERA	;	250 ms pasatu diren konprobatu (1ms*250)
		INC	KONT_250ms				;	250ms kontatzen duen aldagaia inkrementatu
		MOV	KONT_1ms,		#00H		;	1ms kontatzen duen aldagaia 0-ra jarri
		MOV	A,	#04H				;	4 akumuladorean gorde
		CJNE	A,	KONT_250ms,	UB_AMAIERA	;	1 s pasatu den konprobatu (250ms*4)
		INC	SEGUNDUAK				;	Segunduak inkrementatu
		MOV	KONT_250ms,		#00H		;	250ms kontatzen duen aldagaia 0-ra jarri
		UB_AMAIERA:
		RET

	T_FLAG_KONPROBATU:
		ACALL	KONPROBATU_15s
		ACALL	KONPROBATU_1min
		ACALL	KONPROBATU_10min_ZENT
		ACALL	KONPROBATU_50min
		RET

	KONPROBATU_15s:
		MOV	A,	#0FH				;	15 akumuladorean gorde
		CJNE	A,	SEGUNDUAK,	K15s_AMAIERA	;	15 segundu pasatu diren konprobatu
		SETB	TICK_15s				;	15 s igaro diren flag-a altxatu
		K15s_AMAIERA:
		RET

	KONPROBATU_1min:
		MOV	A,	#03CH				;	60 akumuladorean gorde
		CJNE	A,	SEGUNDUAK,	K1min_AMAIERA	;	1 min pasatu den konprobatu (1s*60)
		SETB	TICK_1min				;	1 min igaron den falg-a altxatu
		INC	MINUTUAK				;	Minutuak inkrementatu
		MOV	SEGUNDUAK,	#00H			;	Segunduak 0-ra jarri
		K1min_AMAIERA:
		RET
			
	KONPROBATU_50min:
		MOV	A,	#032H				;	50 akumuladorean gorde
		CJNE	A,	MINUTUAK,	K50min_AMAIERA	;	50 min pasatu diren konprobatu
		SETB	TICK_50min				;	50 min pasatu diren flag-a altxatu
		K50min_AMAIERA:
		RET
	
	KONPROBATU_10min_ZENT:
		MOV	A,	#3CH				;	10 akumuladorean gorde
		CJNE	A,	MINUTUAK,	K10min_AMAIERA	;	10 min pasatu diren konprobatu
		SETB	TICK_10min				;	10 min pasatu diren flag-a altxatu
		K10min_AMAIERA:
		RET
	
;*********************************************************************************************************************************
;				DISPLAYAK
;*********************************************************************************************************************************
	
	DISPLAYAK_AMATATU:
		ANL	DH,	#80H	;	DH etiketak P0 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		ANL	DU,	#80H	;	DU etiketak P2 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		RET
	
	DISPLAYAK_EGUNERATU_PA:
		ANL	DH,	#80H	;	DH etiketak P0 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		ORL	DH,	#73H	;	P = 0111 0011b = 73H
		ANL	DU,	#80H	;	DU etiketak P2 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		ORL	DU,	#77H	;	A = 0111 0111b = 77H
		RET
	
	DISPLAYAK_EGUNERATU_SP:
		ANL	DH,	#80H	;	DH etiketak P0 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		ORL	DH,	#6DH	;	S = 0110 1101b = 6DH
		ANL	DU,	#80H	;	DU etiketak P2 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		ORL	DU,	#73H	;	P = 0111 0011b = 73H
		RET
	
	DISPLAYAK_EGUNERATU_FF:
		ANL	DH,	#80H	;	DH etiketak P0 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		ORL	DH,	#71H	;	F = 0111 0001b = 71H
		ANL	DU,	#80H	;	DU etiketak P2 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		ORL	DU,	#71H	;	F = 0111 0001b = 71H
		RET
	
	DISPLAYAK_EGUNERATU_DENBORA:
		CLR 	TICK_1min
		MOV	A,	DENBORA
		SUBB	A,	MINUTUAK		;	Geratzen den denbora kalkulatu
		MOV	B,	#0AH
		DIV	AB				;	Geratzen den denbora /10 egin hamarrekoak eta unitateak banatzeko. Zatiketaren emaitza (hamarrekoak) akumuladorean gordeko da, eta hondarra (unitateak) B erregistroan
		ACALL	DISPLAY_ZENBAKIA_ZEHAZTU
		ANL		DH,	#80H		;	DH etiketak P0 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		ORL		DH,	A		;	Ezkerreko displayan hamarrekoen zifra bistaratu
		MOV		A,	B		;	Zatiketaren hondarra (unitateak) akumuladorean gorde
		ACALL	DISPLAY_ZENBAKIA_ZEHAZTU
		ANL		DU,	#80H		;	DU etiketak P2 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		ORL		DU,	A		;	Unitateen zifran eskumako displayan bistaratu
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
		
END
