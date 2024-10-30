$NOMOD51
#include "80c552.h"

;*********************************************************************************************************************************
;				ETIKETAK
;*********************************************************************************************************************************

;		Aldagaiak
		EGOERA				EQU	R7
		GERTAERA			EQU	R6
		TENPERATURA			EQU	0x20
		DENBORA				EQU	0x21
		PISU_MAX			EQU 	0x22
		
		KONT_1ms			EQU 	0x23
		KONT_250ms			EQU	0x24
		SEGUNDUAK			EQU	0x25
		MINUTUAK			EQU	0x26
		
		ATE_KONT			EQU	0x27.0
	
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
		TICK_TIMER			EQU 	0x27.1
		TICK_15s			EQU	0x27.2
		TICK_1min			EQU	0x27.3
		TICK_10min			EQU	0x27.4
		TICK_50min			EQU	0x27.5
		TICK_GAINK			EQU	0x27.6
		TICK_TENP_EGOKIA		EQU	0x27.7
		TICK_IRAKURRITA			EQU	0x28.0
		TICK_BOTOIA			EQU	0x28.1

;*********************************************************************************************************************************

ORG 0x00
	AJMP 	PROGRAMA_HASIERA

;*********************************************************************************************************************************
;				ETENAK
;*********************************************************************************************************************************

ORG 0x03	;	INT0 etena

	RETI
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

ORG 0BH		;	TIMER0 etena, 1ms-rako konfiguratuta

	PUSH	ACC
	PUSH	PSW
	MOV	TH0,	#0xF8		
	MOV	TL0,	#0x30
	SETB	TICK_TIMER
	INC	KONT_1ms	;	1ms kontatzen duen aldagaia inkrementatu
	POP	PSW
	POP	ACC
	RETI

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

ORG 0x53	;	ADC0 etena ---> ADCI=1 denean

	SETB	TICK_IRAKURRITA		;	ADC-ren balioa irakurri egin dela jakiteko
	ANL	ADCON,	#0xEF		;	Irakurketa amaitzean ADCI flag-a (ADCON.4 bit-a) software bidez ezabatu behar da
	RETI

;*********************************************************************************************************************************
;				PROGRAMA NAGUSIA
;*********************************************************************************************************************************

ORG 0x7B
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
		MOV	EGOERA,		#0x00
		MOV	GERTAERA,	#0x00
		MOV 	TENPERATURA,	#0x00
		MOV	DENBORA,	#0x3C	;	60 minitu gorde
		MOV	PISU_MAX,	#0xE6
		CLR 	ATE_KONT
		
;		Timerren FLAG-ak eta laguntzaileak
		MOV	KONT_1ms,	#0x00
		MOV	KONT_250ms,	#0x00
		MOV	SEGUNDUAK,	#0x00
		MOV	MINUTUAK,	#0x00
		
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
		MOV	PWMP,		#0x7F
		
;		Timer0
		ANL	TMOD,		#0xF1	;	TMOD = XXXX0001 --> Timer 0-ren 16 biteko modua aukeratu (Timer 1-ren konfigurazioa aldatu gabe)
		MOV	TH0,		#0xF8		
		MOV	TL0,		#0x30
		
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
		ORL	PCON,	#0x01	;	IDLE modua aktibatu
		CLR 	EX0		;	INT0 etena desgaitu
		CLR	EA		;	Etenak desgaitu
		CLR 	TICK_BOTOIA	;	FLAG-a desgaitu
		MOV	EGOERA,	#0x01	;	1. egoerara aldatu
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
		AJMP	EKINTZARIK_EZ_1	;	Atea irekita dagoenean, baina aurreko bueltan jada irekita bazegoen (displayak etengabe ez eguneratzeko)
		
	GERTAERA_SORGAILUA_1:
		JB	ATE_SNTS,	GS1_ATE_IREKIA	;	Atearen egoera konprobatu
		MOV	GERTAERA,	#0x01		;	Atea itxita dago
		RET
	
	GS1_ATE_IREKIA:						;	Atea irekita dago
		JNB	ATE_KONT,	GS1_LEHENENGO_ALDIA	;	Atea irekita dagoen lehenengo buelta den konprobatu
		MOV	GERTAERA,	#0x02			;	Aurreko bueltan atea jada irekita zegoen
		RET
	
	GS1_LEHENENGO_ALDIA:			;	Atea lehengo aldiz ireki da
		MOV	GERTAERA,	#0x00	;	Gertaerarik ez
		RET
		
	ATEA_IREKI:
		SETB	ATE_KONT		;	Atea lehenengo aldiz irekitzean flag-a altxatzen da
		MOV	EGOERA,		#0x01	;	1. egoera jarri
		ACALL	DISPLAYAK_EGUNERATU_PA	;	Displayetan PA bistaratu
		RET
		
	ATEA_ITXI:
		CLR	ATE_KONT		;	Ate irekiaren FLAG-a jaitsi
		MOV	EGOERA,		#0x02	;	2. egoera jarri
		ACALL	DISPLAYAK_AMATATU	;	Displayak amatatu
		ANL	ADCON,		#0xF8	;	Hiru ADDR-ak 0-ra jarri ADC0 aukeratzeko
		ACALL	ADC_IRAKURKETA_HASI	;	Pisu irakurketa hasi
		RET

	EKINTZARIK_EZ_1:
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
		AJMP	EKINTZARIK_EZ_2	;	Pisuaren irakurketa oraindik ez da amaitu
		
	GERTAERA_SORGAILUA_2:
		JB	ATE_SNTS,		GS2_ATE_IREKIA			;	Atearen egoera konprobatu
		JB	TICK_IRAKURRITA,	GS2_GAINKARGA_KONPROBATU	;	Pisuaren irakurketa amaitu den konprobatu
		MOV	GERTAERA,		#0x03				;	Oraindik ez da pisua irakurri
		RET
		
	GS2_ATE_IREKIA:
		MOV	GERTAERA,	#0x00	;	Atea ireki da
		RET
	
	GS2_GAINKARGA_KONPROBATU:
		ACALL	PISUA_IRAKURRI			;	Pisu irakurketaren emaitza konprobatu
		JB	TICK_GAINK,	GS2_GAINKARGA	;	Gainkarga konprobatu
		MOV	GERTAERA,	#0x02		;	Pisua egokia da
		RET		
	
	GS2_GAINKARGA:
		MOV	GERTAERA,	#0x01	;	Gainkarga dago
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
		MOV	EGOERA,		#0x03	;	3. egoera jarri
		ACALL	DISPLAYAK_AMATATU	;	Displayak amatatu
		SETB	BETE_MTR		;	Ur sarreraren balbula aktibatu
		RET

	EKINTZARIK_EZ_2:
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
		AJMP	BEROTU		;	Danborra guztiz beteta dago eta ura berotu daiteke
		AJMP	EKINTZARIK_EZ_3	;	Oraindik danborra ez dago beteta
		
	GERTAERA_SORGAILUA_3:
		JB	BETE_SNTS,	GS3_BETETA	;	Danborra beteta dagoen konprobatu
		MOV	GERTAERA,	#0x01		;	Oraindik ez dago beteta
		RET
		
	GS3_BETETA:
		MOV	GERTAERA,	#0x00	;	Guztiz beteta dago
		RET
		
	BEROTU:
		MOV	EGOERA,	#0x04		;	4. egoera jarri
		CLR	BETE_MTR		;	Ur sarreraren balbula itxi
		SETB	BEROG			;	Berogailua piztu
		ANL	ADCON, #0xF8		;	AADR 1 eta 2 0-ra jarri
		ORL	ADCON, #0x01		; 	AADR 0 1-era jarri ADC1 
		ACALL	ADC_IRAKURKETA_HASI	;	Tenperatura irakurtzen hasi
		RET

	EKINTZARIK_EZ_3:
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
		AJMP	EKINTZARIK_EZ_4		;	Oraindik ez da irakurketa amaitu
		
	GERTAERA_SORGAILUA_4:
		JB	TICK_IRAKURRITA,	GS4_TENPERATURA_KONPROBATU	;	Irakurketa amitu den konprobatu
		MOV	GERTAERA,		#0x02				;	Oraindik ez da irakurketa amaitu
		RET
		
	GS4_TENPERATURA_KONPROBATU:
		ACALL	TENP_IRAKURRI					;	Tenperatura irakurketaren emaitza konprobatu
		JB	TICK_TENP_EGOKIA,	GS4_TENPERATURA_EGOKIA	;	Tenperatura egokia den konprobatu
		MOV	GERTAERA,		#0x01			;	Tenperatura oraindik ez da nahikoa eta berriro irakurri behar da
		RET
		
	GS4_TENPERATURA_EGOKIA:
		MOV	GERTAERA,	#0x00	;	Tenperatura egokia da
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
		ANL	A,	#0x03
		INC	A
		MOVC	A,	@ A+PC
		RET
		DB	0x00	;	Ur hotza
		DB	0x66	;	40ºC
		DB	0x99	;	60ºC
		DB	0xCC	;	80ºC
				
	GARBITU:
		CLR	TICK_TENP_EGOKIA	;	Tenperatura egokiaren flag-a jaitsi
		CLR	BEROG			;	Berogailua itzali
		CLR 	EAD			;	ADCren etenak desgaitu
		MOV	EGOERA,		#0x05	;	5. egoera jarri
		SETB	ET0			;	Timer0-ren etenak gaitu
		SETB	TR0			;	Timer 0 piztu
		MOV	PWM0,		#0xE8	;	60rpm-ko abiaduran jarri motorra
		RET

	EKINTZARIK_EZ_4:
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
		AJMP	EKINTZARIK_EZ_5			;	Gertaerarik ez
		
	GERTAERA_SORGAILUA_5:
		JNB	TICK_TIMER,	GS5_AM
		ACALL	UNITATE_BIHURKETA
		ACALL	T_FLAG_KONPROBATU
		JB	TICK_50min,	GS5_50min	;	50 min igaro diren konprobatu
		JB	TICK_1min,	GS5_1min	;	1 min igaro den konprobatu
		JB	TICK_15s,	GS5_15s		;	15 s igaro diren konprobatu
		GS5_AM:
		MOV	GERTAERA,	#0x03		;	Gertaerarik ez
		RET
		
	GS5_50min:
		MOV	GERTAERA,	#0x02	;	50 min igaro dira
		RET
	
	GS5_1min:
		MOV	GERTAERA,	#0x01	;	1 min igaro da
		RET
	
	GS5_15s:
		MOV	GERTAERA,	#0x00	;	15 s igaro dira
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
		MOV	PWM0,	#0xFF		;	Motorra gelditu
		ACALL	DISPLAYAK_AMATATU	;	Dsiplayak amatatu		
		MOV	EGOERA,	#0x06		;	6. egoera jarri
		SETB	HUSTU_MTR		;	Husteko motorra piztu
		RET

	EKINTZARIK_EZ_5:
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
		AJMP	EKINTZARIK_EZ_6	;	Danborra oraindik ez dago hutsik
		
	GERTAERA_SORGAILUA_6:
		JB	HUSTU_SNTS,	GS6_HUTSIK	;	Hustk dagoen konprobatu
		MOV	GERTAERA,	#0x01		;	Oraindik ez dago hutsik
		RET
		
	GS6_HUTSIK:
		MOV	GERTAERA,	#0x00	;	Hutsik dago
		RET
	
	ZENTRIFUGATU:
		CLR	HUSTU_MTR	;	Husteko motorra amatatu
		MOV	EGOERA,	#0x07	;	7. egoera jarri
		SETB	ET0		;	Timer0-ren etenak gaitu
		SETB	EA		;	Etenak gaitu
		SETB	TR0		;	Timer0 piztu
		MOV	PWM0,	#0x1A	;	600 rpm-ko abiaduran jarri motorra
		RET

	EKINTZARIK_EZ_6:
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
		MOV	GERTAERA,	#0x02		;	Gertaerarik ez
		RET
		
	GS7_10min:
		MOV	GERTAERA,	#0x00	;	10 min igaro dira
		RET
		
	GS7_1min:
		MOV	GERTAERA,	#0x01	;	1 min igaro da
		RET
	
	AMAITU:
		MOV	EGOERA,		#0x08	;	8. egoera jarri
		CLR	TICK_10min		;	10 min flag-a jaitsi
		CLR	TR0			;	Timer0 amatatu
		CLR	ET0			;	Timer0-ren etenak desgaitu
		CLR	EA			;	Etenak desgaitu
		MOV	PWM0,		#0xFF	;	Motorra gelditu
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
		MOV	GERTAERA,	#0xx1		;	Oraindik ez da atea ireki
		RET
		
	GS8_ATE_IREKIA:
		MOV	GERTAERA,	#0x00	;	Atea ireki da
		RET	

	BUKATUTA:
		MOV	EGOERA,		#0x00	;	0. egoera jarri
		RET
		
;*********************************************************************************************************************************
;				EKINTZA KOMUNAK
;*********************************************************************************************************************************
		
	ADC_IRAKURKETA_HASI:
		CLR 	TICK_IRAKURRITA		;	Irakurketa berria hasiko denez, flag-a jaitsi
		ANL	ADCON,	#0xDF		;	ADEX 0-ra jarri software modua aukeratzeko (ADCON.5)
		SETB	EAD			;	ADCaren etenak gaitu
		SETB	EA			;	Etenak gaitu
		ORL	ADCON,	#0x08		;	ADCS 1-era jarri (ADCON.3) irakurketa hasteko
		RET
			
;*********************************************************************************************************************************
;													TIMERREN ERRUTINA LAGUNTZAILEAK
;*********************************************************************************************************************************

	UNITATE_BIHURKETA:
		MOV	A,	#0xFA				;	250 akumuladorean gorde
		CJNE	A,	KONT_1ms,	UB_AMAIERA	;	250 ms pasatu diren konprobatu (1ms*250)
		INC	KONT_250ms				;	250ms kontatzen duen aldagaia inkrementatu
		MOV	KONT_1ms,		#0x00		;	1ms kontatzen duen aldagaia 0-ra jarri
		MOV	A,	#0x04				;	4 akumuladorean gorde
		CJNE	A,	KONT_250ms,	UB_AMAIERA	;	1 s pasatu den konprobatu (250ms*4)
		INC	SEGUNDUAK				;	Segunduak inkrementatu
		MOV	KONT_250ms,		#0x00		;	250ms kontatzen duen aldagaia 0-ra jarri
		UB_AMAIERA:
		RET

	T_FLAG_KONPROBATU:
		ACALL	KONPROBATU_15s
		ACALL	KONPROBATU_1min
		ACALL	KONPROBATU_10min_ZENT
		ACALL	KONPROBATU_50min
		RET

	KONPROBATU_15s:
		MOV	A,	#0x0F				;	15 akumuladorean gorde
		CJNE	A,	SEGUNDUAK,	K15s_AMAIERA	;	15 segundu pasatu diren konprobatu
		SETB	TICK_15s				;	15 s igaro diren flag-a altxatu
		K15s_AMAIERA:
		RET

	KONPROBATU_1min:
		MOV	A,	#0x3C				;	60 akumuladorean gorde
		CJNE	A,	SEGUNDUAK,	K1min_AMAIERA	;	1 min pasatu den konprobatu (1s*60)
		SETB	TICK_1min				;	1 min igaron den falg-a altxatu
		INC	MINUTUAK				;	Minutuak inkrementatu
		MOV	SEGUNDUAK,	#0x00			;	Segunduak 0-ra jarri
		K1min_AMAIERA:
		RET
			
	KONPROBATU_50min:
		MOV	A,	#0x32				;	50 akumuladorean gorde
		CJNE	A,	MINUTUAK,	K50min_AMAIERA	;	50 min pasatu diren konprobatu
		SETB	TICK_50min				;	50 min pasatu diren flag-a altxatu
		K50min_AMAIERA:
		RET
	
	KONPROBATU_10min_ZENT:
		MOV	A,	#0x3C				;	10 akumuladorean gorde
		CJNE	A,	MINUTUAK,	K10min_AMAIERA	;	10 min pasatu diren konprobatu
		SETB	TICK_10min				;	10 min pasatu diren flag-a altxatu
		K10min_AMAIERA:
		RET
	
;*********************************************************************************************************************************
;				DISPLAYAK
;*********************************************************************************************************************************
	
	DISPLAYAK_AMATATU:
		ANL	DH,	#0x80	;	DH etiketak P0 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		ANL	DU,	#0x80	;	DU etiketak P2 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		RET
	
	DISPLAYAK_EGUNERATU_PA:
		ANL	DH,	#0x80	;	DH etiketak P0 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		ORL	DH,	#0x73	;	P = 0111 0011b = 73H
		ANL	DU,	#0x80	;	DU etiketak P2 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		ORL	DU,	#0x77	;	A = 0111 0111b = 77H
		RET
	
	DISPLAYAK_EGUNERATU_SP:
		ANL	DH,	#0x80	;	DH etiketak P0 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		ORL	DH,	#0x6D	;	S = 0110 1101b = 6DH
		ANL	DU,	#0x80	;	DU etiketak P2 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		ORL	DU,	#0x73	;	P = 0111 0011b = 73H
		RET
	
	DISPLAYAK_EGUNERATU_FF:
		ANL	DH,	#0x80	;	DH etiketak P0 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		ORL	DH,	#0x71	;	F = 0111 0001b = 71H
		ANL	DU,	#0x80	;	DU etiketak P2 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		ORL	DU,	#0x71	;	F = 0111 0001b = 71H
		RET
	
	DISPLAYAK_EGUNERATU_DENBORA:
		CLR 	TICK_1min
		MOV	A,	DENBORA
		SUBB	A,	MINUTUAK		;	Geratzen den denbora kalkulatu
		MOV	B,	#0x0A
		DIV	AB				;	Geratzen den denbora /10 egin hamarrekoak eta unitateak banatzeko. Zatiketaren emaitza (hamarrekoak) akumuladorean gordeko da, eta hondarra (unitateak) B erregistroan
		ACALL	DISPLAY_ZENBAKIA_ZEHAZTU
		ANL		DH,	#0x80		;	DH etiketak P0 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		ORL		DH,	A		;	Ezkerreko displayan hamarrekoen zifra bistaratu
		MOV		A,	B		;	Zatiketaren hondarra (unitateak) akumuladorean gorde
		ACALL	DISPLAY_ZENBAKIA_ZEHAZTU
		ANL		DU,	#0x80		;	DU etiketak P2 portua adierazten du, baina .7 bit-a ez denez displayetan erabiltzen, ez da bere balioa aldatu behar
		ORL		DU,	A		;	Unitateen zifran eskumako displayan bistaratu
		RET
		
	DISPLAY_ZENBAKIA_ZEHAZTU:
		INC	A
		MOVC	A,	@ A+PC
		RET
		DB	0x3F	;	0 = 0011 1111b
		DB	0x06	;	1 = 0000 0110b
		DB	0x5B	;	2 = 0101 1011b
		DB	0x9F	;	3 = 0100 1111b
		DB	0x66	;	4 = 0110 0110b
		DB	0x6D	;	5 = 0110 1101b
		DB	0x7D	;	6 = 0111 1101b
		DB	0x07	;	7 = 0000 0111b
		DB	0x7F	;	8 = 0111 1111b
		DB	0x6F	;	9 = 0110 1111b
		
END
