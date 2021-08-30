; Archivo: Lab 5
; Dispositivo: PIC16F887
; Autor: José Santizo 
; Compilador: pic-as (v2.32), MPLAB X v5.50
    
; Programa: Multiples displays en un solo puerto
; Hardware: Displays de 7 segmentos, transistores y LEDs en puerto A
    
; Creado: 24 de Agosto, 2021
; Última modificación: 24 de agosto de 2021

PROCESSOR 16F887
#include <xc.inc>

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

;---------------Macros-------------------------  
 REINICIAR_TMR0 MACRO
    BANKSEL	PORTD
    MOVLW	61		; Timer 0 reinicia cada 20 ms
    MOVWF	TMR0		; Mover este valor al timer 0
    BCF		T0IF		; Limpiar la bandera del Timer 0
    ENDM
 
;-----------Valores globales------------------
UP	EQU 0			; Literal up = bit 0
DOWN	EQU 5			; Literal down = bit 5
;-----------Variables a utilizar---------------
PSECT udata_bank0	    ; common memory
    PORT:	    DS 1	    ; 1 byte
    CONT_UNI:	    DS 1
    CONT_DECE:	    DS 1
    CONT_CEN:	    DS 1
    VAR:	    DS 1
    VAR2:	    DS 1
    VAR3:	    DS 1
    UNI:	    DS 1
    DECE:	    DS 2
    CEN:	    DS 1
    BANDERAS:	    DS 1
    DISPLAY_VAR:    DS 2
    DISPLAY_VAR1:   DS 2
    DISPLAY_VAR2:   DS 2
    DISP_SELECTOR:  DS 1
    
PSECT udata_shr	    ; common memory
    W_TEMP:	    DS 1	    ; 1 byte
    STATUS_TEMP:    DS 1	    ; 1 byte
    
PSECT resVect, class=CODE, abs, delta=2
 ;------------vector reset-----------------
 ORG 00h			    ; posición 0000h para el reset
 resetVec:  
    PAGESEL MAIN
    goto MAIN

 PSECT intVect, class=CODE, abs, delta=2
 ;------------vector interrupciones-----------------
 ORG 04h			    ; posición 0000h para interrupciones
 
 PUSH:
    MOVWF	W_TEMP
    SWAPF	STATUS, W
    MOVWF	STATUS_TEMP
 
 ISR:
    BTFSC	T0IF
    CALL	INT_TMR0
    
    BTFSC	RBIF		    ; Chequear si la bandera RBIF está en 0
    CALL	INT_IOCB	    ; Subrutina INT_IOCB

 POP:
    SWAPF	STATUS_TEMP, W
    MOVWF	STATUS
    SWAPF	W_TEMP, F
    SWAPF	W_TEMP, W
    RETFIE
   
 ;------------Sub rutinas de interrupción--------------
 INT_IOCB:
    BANKSEL	PORTA		    ; Selección del puerto A
    BTFSS	PORTB, UP	    ; Chequear si el pin 0 del puerto B está en 0
    CALL	INCREMENTO
    
    BTFSS	PORTB, DOWN	    ; Chequear si el pin 5 del puerto B está en 0
    CALL	DECREMENTO		   
    BCF		RBIF		    ; Limpiar la bandera RBIF
    
    CALL	CHECK_DISPLAYS
    
    RETURN

 DECREMENTO:
    ;CONTADOR PUERTO A
    DECF	PORT		    ; Incrementar contador PORT
    MOVF	PORT, W		    ; W = PORT
    MOVWF	PORTA		    ; PORTA = W = PORT
    
    ;DISPLAYS DE 7 SEGMENTOS
    DECF	CONT_UNI	    ; CONT_UNI - 1
    RETURN 
 
 INCREMENTO:
    ;CONTADOR PUERTO A
    INCF	PORT		    ; Incrementar contador PORT
    MOVF	PORT, W		    ; W = PORT
    MOVWF	PORTA		    ; PORTA = W = PORT
    
    ;DISPLAYS DE 7 SEGMENTOS
    INCF	CONT_UNI	    ; CONT_UNI + 1
    RETURN
 
 CHECK_DISPLAYS:
    ;CHEQUEO SUMA
    MOVF	CONT_UNI, W	    ; W = CONT_UNI 
    SUBLW	10		    ; 10 - CONT_UNI
    BTFSC	STATUS, 2	    ; IF (10-CONT_UNI = 0)
    CALL	INCREMENTO_DEC	    ; ENTONCES CALL INCREMENTO_DEC
    
    MOVF	CONT_DECE, W	    ; W = CONT_DECE
    SUBLW	10		    ; 10 - CONT_DECE
    BTFSC	STATUS, 2	    ; IF (10-CONT_DECE = 0)
    CALL	INCREMENTO_CEN	    ; ENTONCES CALL INCREMENTO_CEN
    
    MOVF	CONT_CEN, W	    ; W = CONT_DECE
    SUBLW	10		    ; 10 - CONT_DECE
    BTFSC	STATUS, 2	    ; IF (10-CONT_DECE = 0)
    CLRF	CONT_CEN
    
    ;CHEQUEO RESTA
    MOVF	CONT_UNI, W	    ; W = CONT_UNI 
    SUBLW	-1		    ; -1 - CONT_UNI
    BTFSC	STATUS, 2	    ; IF (-1-CONT_UNI = 0)
    CALL	DECREMENTO_UNI	    ; ENTONCES CALL INCREMENTO_DEC
    
    MOVF	CONT_DECE, W	    ; W = CONT_DECE
    SUBLW	-1		    ; 10 - CONT_DECE
    BTFSC	STATUS, 2	    ; IF (10-CONT_DECE = 0)
    CALL	DECREMENTO_DEC	    ; ENTONCES CALL INCREMENTO_CEN
    
    MOVF	CONT_CEN, W	    ; W = CONT_CEN
    SUBLW	-1		    ; 10 - CONT_CEN
    BTFSC	STATUS, 2	    ; IF (10-CONT_CEN = 0)
    CALL	DECREMENTO_CEN
    
    ;CHEQUEAR 256
    MOVF	PORT, W
    SUBLW	0
    BTFSC	STATUS, 2
    CALL	RESET_PORT
    
    ;255 SI CONTADOR BINARIO ES 255
    MOVF	PORT, W
    SUBLW	255
    BTFSC	STATUS, 2
    CALL	SET_PORT
    
    ;TRADUCCIÓN A DISPLAY DE 7 SEGMENTOS
    MOVWF	CONT_UNI, W
    CALL	TABLA
    MOVWF	UNI
    
    MOVWF	CONT_DECE, W
    CALL	TABLA
    MOVWF	DECE
    
    MOVWF	CONT_CEN, W
    CALL	TABLA
    MOVWF	CEN
    RETURN
 
 SET_PORT:
    MOVLW	5
    MOVWF	CONT_UNI
    
    MOVLW	5
    MOVWF	CONT_DECE
    
    MOVLW	2
    MOVWF	CONT_CEN
    RETURN
    
 RESET_PORT:
    CLRF	CONT_UNI
    CLRF	CONT_DECE
    CLRF	CONT_CEN
    RETURN
    
 INCREMENTO_DEC:
    INCF	CONT_DECE
    CLRF	CONT_UNI
    RETURN
    
 INCREMENTO_CEN:
    INCF	CONT_CEN
    CLRF	CONT_DECE
    RETURN 
 
 DECREMENTO_UNI:
    MOVLW	9
    MOVWF	CONT_UNI
    DECF	CONT_DECE
    RETURN   
    
 DECREMENTO_DEC:
    MOVLW	9
    MOVWF	CONT_DECE
    DECF	CONT_CEN
    RETURN
    
 DECREMENTO_CEN:
    MOVLW	9
    MOVWF	CONT_CEN
    RETURN    
    
 INT_TMR0:
    REINICIAR_TMR0
    
    ; SE SELECCIONA EL DISPLAY AL QUE SE DESEA ESCRIBIR
    MOVF	DISP_SELECTOR,W
    MOVWF	PORTD
    
    ;REVISAR SI SE ESCRIBE EN EL DISPLAY DE UNIDADES (001)
    MOVF	DISP_SELECTOR, W
    SUBLW	1			;Chequear si DISP_SELECTOR = 001
    BTFSC	STATUS, 2
    CALL	DISPLAY_UNI		
    
    ;REVISAR SI SE ESCRIBE EN EL DISPLAY DE DECENAS (010)
    MOVF	DISP_SELECTOR, W
    SUBLW	2			;Chequear si DISP_SELECTOR = 010
    BTFSC	STATUS, 2
    CALL	DISPLAY_DECE		
    
    ;REVISAR SI SE ESCRIBE EN EL DISPLAY DE CENTENAS (100)
    MOVF	DISP_SELECTOR, W
    SUBLW	4			;Chequear si DISP_SELECTOR = 100
    BTFSC	STATUS, 2
    CALL	DISPLAY_CEN		
    
    ;MOVER EL 1 EN DISP_SELECTOR 1 POSICIÓN A LA IZQUIERDA
    BCF		STATUS, 0		;Se limpia el bit de carry
    RLF		DISP_SELECTOR, 1	;1 en DISP_SELECTOR se corre una posición a al izquierda
    
    ;REINICIAR DISP_SELECTOR SI EL VALOR SUPERÓ EL NÚMERO DE DISPLAYS
    MOVF	DISP_SELECTOR, W
    SUBLW	8
    BTFSC	STATUS, 2
    CALL	RESET_DISP_SELECTOR
    
    RETURN
    
 DISPLAY_UNI:
    MOVF	UNI, W			;W = UNI
    MOVWF	PORTC			;PORTC = W
    RETURN
    
 DISPLAY_DECE:
    MOVF	DECE, W			;W = DECE
    MOVWF	PORTC			;PORTC = W
    RETURN
    
 DISPLAY_CEN:
    MOVF	CEN, W			;W = CEN
    MOVWF	PORTC			;PORTC = W
    RETURN

 RESET_DISP_SELECTOR:
    CLRF	DISP_SELECTOR
    INCF	DISP_SELECTOR, 1
    RETURN
    
 
 
 ;---------------Código principal----------------   
    
 PSECT CODE, DELTA=2, ABS
 ORG 100H		    ;Posición para el codigo
 ;------------------Tablas-----------------------
 
 TABLA:
    CLRF	PCLATH
    BSF		PCLATH, 0   ;PCLATH = 01    PCL = 02
    ANDLW	0x0f
    ADDWF	PCL	    ;PC = PCLATH + PCL + W
    RETLW	00111111B   ;0
    RETLW	00000110B   ;1
    RETLW	01011011B   ;2
    RETLW	01001111B   ;3
    RETLW	01100110B   ;4
    RETLW	01101101B   ;5
    RETLW	01111101B   ;6
    RETLW	00000111B   ;7
    RETLW	01111111B   ;8
    RETLW	01101111B   ;9
    RETLW	01110111B   ;A
    RETLW	01111100B   ;B
    RETLW	00111001B   ;C
    RETLW	01011110B   ;D
    RETLW	01111001B   ;E
    RETLW	01110001B   ;F
 ;-----------Configuración----------------
 MAIN:
    CALL	RESET_DISP_SELECTOR ;DISP_SELECTOR = 001
    CALL	CONFIG_IO	    ;Configuraciones de entradas y salidas
    CALL	CONFIG_RELOJ	    ;Configuración del oscilador
    CALL	CONFIG_TMR0	    ;Configuración del Timer 0
    CALL	CONFIG_INT_ENABLE   ;Configuración de interrupciones	
    CALL	CONFIG_IOCB	    ;Configuración de resistencias pull up internas en puerto B
    BANKSEL	PORTA
    
 LOOP:
   
    GOTO	LOOP
 
 ;-------------SUBRUTINAS------------------  
 CONFIG_IOCB:
    BANKSEL	TRISA		    ;Selección del banco trisA
    BSF		IOCB, UP	    ;Limpiar las resistencias pull up en puerto 0 y 5
    BSF		IOCB, DOWN
    
    BANKSEL	PORTA		    ;SELECCIONAR PUERTO A
    MOVF	PORTB, W	    ;TERMINA CONDICIÓN MISMATCH AL LEER
    BCF		RBIF
    RETURN
    
 CONFIG_INT_ENABLE:
    BSF		GIE		    ;Configuración de las interrupciones
    BSF		RBIE
    BCF		RBIF
    RETURN   
    
 CONFIG_TMR0:
    BANKSEL	TRISA
    BCF		T0CS		    ;Reloj interno
    BCF		PSA		    ;PRESCALER
    BSF		PS2 
    BSF		PS1
    BSF		PS0		    ;Prescaler = 110 = 256
    BANKSEL	PORTA
    REINICIAR_TMR0
    BSF		GIE		    ;Configuración de las interrupciones
    BSF		T0IE
    BCF		T0IF
    RETURN
 
 CONFIG_RELOJ:
    BANKSEL	OSCCON
    BSF		IRCF2		    ;IRCF = 110 = 4 MHz
    BSF		IRCF1
    BSF		IRCF0
    BSF		SCS		    ;Reloj interno
    RETURN
 
 CONFIG_IO:
    BANKSEL	ANSEL
    CLRF	ANSEL		    ;PINES DIGITALES
    CLRF	ANSELH
    
    BANKSEL	TRISA
    CLRF	TRISA
    CLRF	TRISC		    ;PORT C COMO SALIDA
    CLRF	TRISD
    
    BSF		TRISB, UP	    ;PINES 0 Y 7 DE PORTB COMO ENTRADA
    BSF		TRISB, DOWN
    
    BCF		OPTION_REG, 7	    ;HABILITAR PULL UPS
    BSF		WPUB, UP
    BSF		WPUB, DOWN
 
    BANKSEL	PORTA
    CLRF	PORTA
    CLRF	PORTC
    CLRF	PORTD
    RETURN

    
END


