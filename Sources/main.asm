;*******************************************************************
;* This stationery serves as the framework for a user application. *
;* For a more comprehensive program that demonstrates the more     *
;* advanced functionality of this processor, please see the        *
;* demonstration applications, located in the examples             *
;* subdirectory of the "Freescale CodeWarrior for HC08" program    *
;* directory.                                                      *
;*******************************************************************

; Include derivative-specific definitions
            INCLUDE 'derivative.inc'
;
; export symbols
;
            XDEF _Startup
            ABSENTRY _Startup

;
; variable/data section
;
            ORG    RAMStart         ; Insert your data definition here
CNT:  dc.w  17
CN: ds.w 1
myH: ds.b 1
myX: ds.b 1
bPrvniNibble: ds.b 1
bDruhyNibble: ds.b 1
bTretiNibble: ds.b 1
bCtvrtyNibble: ds.b 1
currentDisplay: dc.b 0
currentNumber: dc.b 0
currentNumberSegments: dc.b 0
LeftDisplayAdr: equ 2
RightDisplayAdr: equ 6
DILSwitchAdr: equ 8
RTCClockSetting: equ %00011100 ; nastaveno na 16ms, cca 10x pomalejsi v realite
nula: equ $3F ; zacatek stavove tabulky
jedna: equ $06                      
dva: equ $5B
tri: equ $4F
ctyri: equ $66
pet:  equ $6D
sest: equ $7D
sedm: equ $07
osm: equ $7F
devet: equ $6F
aa: equ $77
bb: equ $7C
cc: equ $39
dd: equ $5E
ee: equ $79
ff: equ $71


;
; code section
;
            ORG    ROMStart


_Startup:
      LDHX   #RAMEnd+1        ; initialize the stack pointer
      TXS
      ;cli                     ; enable interrupts
      
      clra
      sta SOPT1 ; zastaveni watchdogu
      
      mov #%11111111, PTBDD; ; data direction output pro port B, Seg7 1
      mov #%11111111, PTDDD; ; data direction output pro port D, Seg7 2
      mov #%11111111, PTEDD; ; data direction output pro port E, DILSwitch
    
      mov #%00000000, PTBD; 
      mov #%00000000, PTDD; 
      mov #%00000000, PTED; 
      
      jsr loadNibbles
      
      jsr displayTest      
            
         
  	
  	lda #2
  	;sta RTCLKS ; TODO: pridat preddelickove bity RTCLKS; str 216
  	; clks na 0b00, rtcps na 0b1000
    
  	;mov #%00, RTCSC_RTCLKS0
  
      cli  ;povol preruseni
      ;sei	
      jsr rezimSetDef
	  
	  	
  	jmp mainLoop
; konec inicializacni casti
; blok doprednych deklaraci
displayTest:
        lda bTretiNibble
      sta currentNumber												 	
      jsr displayNumber	
      lda #0 ; zvol levy
      sta currentDisplay	        		   			            
	    jsr displayIt           	
	
	    lda bCtvrtyNibble
      sta currentNumber												 	
      jsr displayNumber
      lda #1 ; zvol pravy
      sta currentDisplay		        		   			            
  	jsr displayIt
  	rts

displayNumber:
      jsr displayNumberDef
      rts
; rezim set	        
rezimSetDef:
      mov #RTCClockSetting, RTCSC
    
      rts
      
; rezim Stop      
rezimStopDef:
      
      rts

; rezim Start
rezimStartDef:
      jsr rezimStart
    
      rts      
; konec bloku doprednych deklaraci
; odtud definice            



clockInterruptService:
      ; lda RTCSC      ; preruseni kazdou sekundu
      ;ora #$80
      ;sta RTCSC
      jsr loadNibbles
	
      mov #RTCClockSetting, RTCSC
      
      jsr rezimSet	
      rti

displayIt:
      lda #0	  
      cmp currentDisplay
      bne zobrazNaPravem           	
zobrazNaLevem:
      lda currentNumberSegments
      sta LeftDisplayAdr									
      jmp konecZobrazovani
zobrazNaPravem:           		
      lda currentNumberSegments
      sta RightDisplayAdr
konecZobrazovani:                          			
      rts                  

rezimCitani:
      brset 5, PTED, zvysCNT
      brclr 5, PTED, snizCNT

      

      rts

blikniAktivni:
      brclr 4, PTED, blikniLevy
blikniPravy:
      
      com PTDDD
      ;lda PTDD
      ;and PTDDD
     ; sta PTDD
      
      ;mov PTDD, PTDDD
      
      ;mov #%00000000, PTDD
      mov #%11111111, PTBDD ; kdyz blikam levy, obnovim zobrazeni na pravem
      jmp konecBlikani
blikniLevy:
      com PTBDD
      ;mov #%00000000, PTBD 
      mov #%11111111, PTDDD ; vice versa
konecBlikani:      
      rts      
rezimSet:
      ; volej z wait
      ; blikni aktivni
      jsr blikniAktivni
      rts
rezimStart:
      ; volej z wait
      ;pseudo brset 6, PTED, wait
      brclr 6, PTED, rezimSet
      
      
      rts

loadNibbles:
      ldhx CNT
      sthx myH
      ;; CNT je v myH a myX
      ;; ulozeni prvniho nibble
      lda myH
      and #%11110000
      lsra
      lsra
      lsra
      lsra
      sta bPrvniNibble
      ;; ulozeni druheho nibble
      lda myH
      and #%00001111
      sta bDruhyNibble
      ;; ulozeni tretiho nibble
      lda myX       
      and #%11110000
      lsra
      lsra
      lsra
      lsra
      sta bTretiNibble
      ;; ulozeni ctvrteho nibble                 
      lda myX
      and #%00001111
      sta bCtvrtyNibble
      
      rts

zvysCNT:
      ldhx CNT
      aix #1
      sthx CNT
      rts
snizCNT:
      ldhx CNT
      aix #-1
      sthx CNT  
      rts        

nactiDILSwitch:
      lda PTED ; v A je hodnota DILSwitche
      brset 7, PTED, rezimStart
      rts
        
mainLoop:
            ; Insert your code here
      NOP
      
      jsr loadNibbles
      jsr displayTest
      jsr nactiDILSwitch            
      wait
      
      ;feed_watchdog
      BRA    mainLoop
            
displayNumberDef:
      lda #0
      cmp currentNumber
      beq zobrazNula

      	
      lda #1
      cmp currentNumber
      beq zobrazJedna


      lda #2
      cmp currentNumber
      beq zobrazDva

      lda #3
      cmp currentNumber
      beq zobrazTri

      lda #4
      cmp currentNumber
      beq zobrazCtyri

      lda #5
      cmp currentNumber
      beq zobrazPet

      lda #6
      cmp currentNumber
      beq zobrazSest

      lda #7
      cmp currentNumber
      beq zobrazSedm

      lda #8
      cmp currentNumber
      beq zobrazOsm

      lda #9
      cmp currentNumber
      beq zobrazDevet

      lda #10
      cmp currentNumber
      beq zobrazA

      lda #11
      cmp currentNumber
      beq zobrazB

      lda #12
      cmp currentNumber
      beq zobrazC

      lda #13
      cmp currentNumber
      beq zobrazD

      lda #14
      cmp currentNumber
      beq zobrazE

      lda #15
      cmp currentNumber
      beq zobrazF

      rts
            
zobrazNula:
      lda #nula
      sta currentNumberSegments
      rts                        
zobrazJedna:
      lda #jedna
      sta currentNumberSegments
      rts 
zobrazDva:
      lda #dva
      sta currentNumberSegments
      rts 
zobrazTri:
      lda #tri
      sta currentNumberSegments
      rts 
zobrazCtyri:
      lda #ctyri
      sta currentNumberSegments
      rts 
zobrazPet:
      lda #pet
      sta currentNumberSegments
      rts 
zobrazSest:
      lda #sest
      sta currentNumberSegments
      rts 
zobrazSedm:
      lda #sedm
      sta currentNumberSegments
      rts 
zobrazOsm:
      lda #osm
      sta currentNumberSegments
      rts 
zobrazDevet:
      lda #devet
      sta currentNumberSegments
      rts 
zobrazA:
      lda #aa
      sta currentNumberSegments
      rts 
zobrazB:
      lda #bb
      sta currentNumberSegments
      rts 
zobrazC:
      lda #cc
      sta currentNumberSegments
      rts 
zobrazD:
      lda #dd
      sta currentNumberSegments
      rts 
zobrazE:
      lda #ee
      sta currentNumberSegments
      rts 
zobrazF:
      lda #ff
      sta currentNumberSegments
      rts    
            
displayNumberOnCurrentDisplay:
                            

cislo0:
      mov #%11000000, PTBD 
      rts


;-----------------------------------------------------
delay_fixed: ; 2 vnorene cykly, kazdy o danem pevnem poctu iteraci
      psha
      lda		#$8F
delay1:

      psha
      lda		#$60
delay2:

      nop                     ; doba provadeni = 1 BUS-cyklus
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop

      dbnza	delay2
      pula

      dbnza	delay1
      pula

      rts

;-----------------------------------------------------
delay_var ; 16-bit pocet iteraci je pred volanim vlozen do H:X
          ; (iterace se pocitaji od 0 az po (2^16)-1)
      pshx
      pshh
      ais #-2                   ; pomocna lokalni 16-bit promenna
      tsx
      clr 1,X
      clr ,X
      bra d1
d0:
      tsx
      inc 1,X
      bne d1
      inc ,X
d1:
      nop                       ; "zatez" smycky

      ldhx 3,SP
      cphx 1,SP
      bhi d0

      ais #4
      rts
                                        

spurious:   ; telo obsluhy pro neobsluhovana preruseni
      nop
      rti

;**************************************************************
;* V. tabulka vektoru preruseni                               *
;**************************************************************


      org   $FFC0
      dc.w  spurious         ;$FFC0
      dc.w  spurious         ;$FFC2
      dc.w  clockInterruptService         ;$FFC4
      dc.w  spurious         ;$FFC6
      dc.w  spurious         ;$FFC8
      dc.w  spurious         ;$FFCA
      dc.w  spurious         ;$FFCC
      dc.w  spurious         ;$FFCE
      dc.w  spurious         ;$FFD0
      dc.w  spurious         ;$FFD2
      dc.w  spurious         ;$FFD4
      dc.w  spurious         ;$FFD6
      dc.w  spurious         ;$FFD8
      dc.w  spurious         ;$FFDA
      dc.w  spurious         ;$FFDC
      dc.w  spurious         ;$FFDE
      dc.w  spurious         ;$FFE0
      dc.w  spurious         ;$FFE2
      dc.w  spurious         ;$FFE4
      dc.w  spurious         ;$FFE6
      dc.w  spurious         ;$FFE8
      dc.w  spurious         ;$FFEA
      dc.w  spurious         ;$FFEC
      dc.w  spurious         ;$FFEE
      dc.w  spurious         ;$FFF0
      dc.w  spurious         ;$FFF2
      dc.w  spurious         ;$FFF4
      dc.w  spurious         ;$FFF6
      dc.w  spurious         ;$FFF8
      dc.w  spurious         ;$FFFA
      dc.w  spurious         ;$FFFC
      dc.w  _Startup         ;$FFFE              
