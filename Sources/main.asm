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
CNT:  dc.w  10
CN: ds.w 1
compareCNT: ds.w 1
myH: ds.b 1
myX: ds.b 1
CNTNbPrvniNibble: ds.b 1
CNTNbDruhyNibble: ds.b 1
CNTNbTretiNibble: ds.b 1
CNTNbCtvrtyNibble: ds.b 1
currentNibble: dc.b 0
currentNibbleValue: dc.b 0
currentDisplay: dc.b 0
currentNumber: dc.b 0
currentNumberSegments: dc.b 0
currentMode: dc.b 0
pocetBliknuti: dc.b 4
tempByte: ds.b 1
tempChangingH: ds.b 1
tempChangingX: ds.b 1
fastestChanging: ds.b 1
inicializacePravy: dc.b 1
LeftDisplayAdr: equ 2
RightDisplayAdr: equ 6
DILSwitchAdr: equ 8
RTCClockSetting: equ %00011100 ; 1100 nastaveno na 16ms, cca 10x pomalejsi v realite
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
        
            
      jmp mainLoop
; konec inicializacni casti
; blok doprednych deklaraci
displayTest:
        lda CNTNbTretiNibble
      sta currentNumber                                                                         
      jsr displayNumber 
      lda #0 ; zvol levy
      sta currentDisplay                                                      
          jsr displayIt             
      
          lda CNTNbCtvrtyNibble
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
      ;jsr loadNibbles
      
      mov #RTCClockSetting, RTCSC
      lda currentMode
      cmp #3   ; citani
	  beq modJeCitani
      cmp #5
      beq modBlikaniTrikrat
      cmp #0
      beq middleSkokNeblikej
      jsr blikniAktivni 
middleSkokNeblikej:      
      jmp neblikej
modBlikaniTrikrat:
      com PTBD
      com PTDD
	  jmp neblikej
modJeCitani:	        
		brset 5, PTED, zvyseniCNT
      brclr 5, PTED, snizeniCNT

zvyseniCNT:
      jsr zvysCNT
      jmp dontknowCNT
snizeniCNT:
      jsr snizCNT
dontknowCNT:
       lda currentMode
      cmp #5
      beq middleSkokNeblikej
      ldhx CNT
      sthx myH
      ; mam myH horni, myX dolni
      ldhx compareCNT
      sthx tempChangingH
      ; stare hodnoty CNT v tempChangingH, tempChangingX
      lda myH
      eor tempChangingH
      sta myH
      lda myX
      eor tempChangingX
      sta myX
      ldhx myH ; do HX uloz XOR verzi
      sthx compareCNT ; zazalohuj
      ; cmp myH, if > F, 4.n, mensi je 3. n
      ; cmp myX, if > F, 2.n, mensi je 1. n
      lda #0
      cmp myH
      beq testLowerX ; zadna zmena v H, jdeme do X
      lda myH
      cmp #$0F
      blo aktivniTretiNibble
aktivniCtvrtyNibble:                  
      lda #3
      sta fastestChanging
      jmp konecTestovaniCitani
aktivniTretiNibble:
      lda #2
      sta fastestChanging
      jmp konecTestovaniCitani
testLowerX:
      lda myX
      cmp #$0F
      blo aktivniPrvniNibble
aktivniDruhyNibble:
      lda #1
      sta fastestChanging
      jmp konecTestovaniCitani
aktivniPrvniNibble:
      lda #0
      sta fastestChanging 
konecTestovaniCitani: 
      ; nyni zobraz na displeji
      jsr loadNibbles
      lda fastestChanging ; nacteni nibble indexu 
      sta currentNumber   ; do currentNumber
      jsr displayNumberDef; zjisteni segmentu
      lda currentNumberSegments  ; nacteni segmentu
      sta LeftDisplayAdr   ; ulozeni na levy displej                                                   
	
      lda fastestChanging
      cmp #0 ; pokud prvni
      beq ulozPrvniN
      cmp #1
      beq ulozDruhyN
      cmp #2
      beq ulozTretiN
      cmp #3
      beq ulozCtvrtyN
      jmp ulozPrvniN ; osetreni
ulozPrvniN:
      lda CNTNbCtvrtyNibble
      jmp zobrazHodnotuNibble
ulozDruhyN:
      lda CNTNbTretiNibble
      jmp zobrazHodnotuNibble
ulozTretiN:
      lda CNTNbDruhyNibble
      jmp zobrazHodnotuNibble
ulozCtvrtyN:      
      lda CNTNbPrvniNibble
zobrazHodnotuNibble:
      sta currentNumber   ; do currentNumber
      jsr displayNumberDef; zjisteni segmentu
      lda currentNumberSegments  ; nacteni segmentu
      sta RightDisplayAdr   ; ulozeni na pravy displej                                                      
      ;wait
      ;lda currentMode
      ;cmp #3   ; citani
      ;beq neblikej
      
neblikej:      
      rti

displayIt:
      ;lda #0        
      ;cmp currentDisplay
      brset 4, PTED, zobrazNaPravem            
zobrazNaLevem:
      lda currentNumberSegments
      sta LeftDisplayAdr                                                      
      jmp konecZobrazovani
zobrazNaPravem:                     
      lda currentNumberSegments
      sta RightDisplayAdr
konecZobrazovani:                                           
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
      sta CNTNbPrvniNibble
      ;; ulozeni druheho nibble
      lda myH
      and #%00001111
      sta CNTNbDruhyNibble
      ;; ulozeni tretiho nibble
      lda myX       
      and #%11110000
      lsra
      lsra
      lsra
      lsra
      sta CNTNbTretiNibble
      ;; ulozeni ctvrteho nibble                 
      lda myX
      and #%00001111
      sta CNTNbCtvrtyNibble
      
      rts

blikniAktivni:
      brclr 4, PTED, blikniLevy
blikniPravy:      
      com PTDDD
      mov #%11111111, PTBDD ; kdyz blikam levy, obnovim zobrazeni na pravem
      jmp konecBlikani
blikniLevy:
      com PTBDD
      mov #%11111111, PTDDD ; vice versa
konecBlikani:      
      rts 
          
      
zmenHodnotuAktivnihoDispleje:      
      ; nacti hodnotu poslednich 4 bitu
      lda PTED
      and #%00001111
      brclr 4, PTED, pracujemeSNibblem
;pracujeme s cislem      
      sta currentNibbleValue        
      jmp konecPrace
pracujemeSNibblem:      
      sta currentNibble

konecPrace:
      sta currentNumber
      jsr displayNumber
      jsr displayIt
      
      ; uloz hodnotu      
      ldhx CNT
      sthx myH
      lda currentNibble
      cmp #3
      beq ulozeniPrvniNibble
      cmp #2
      beq ulozeniDruhyNibble
      cmp #1
      beq ulozeniTretiNibble
      cmp #0
      beq ulozeniCtvrtyNibble
      jmp ulozeniKonec
ulozeniPrvniNibble:
      lda myX
      and #%11110000
      ora currentNibbleValue
      sta myX
      jmp ulozeniKonec
      
ulozeniDruhyNibble:
      lda myX
      and #%00001111
      ldx currentNibbleValue
      lslx
      lslx
      lslx
      lslx
      stx myX 
      ora myX
      sta myX
      jmp ulozeniKonec
      
ulozeniTretiNibble:
      lda myH
      and #%11110000
      ora currentNibbleValue
      sta myH
      jmp ulozeniKonec
ulozeniCtvrtyNibble:
      lda myH
      and #%00001111
      ldx currentNibbleValue
      lslx
      lslx
      lslx
      lslx
      stx myH 
      ora myH
      sta myH  
ulozeniKonec:
      ldhx myH
      sthx CNT    
      rts
      
      
rezimCitani:
      lda #3
      sta currentMode
      mov #%11111111, PTBDD
      mov #%11111111, PTDDD
      jsr rezimSetDef ; zapnuti hodin
      lda #255
loopNop:
      nop
      deca
      cmp #0
      bne loopNop ; zpomaleni
      
      ldhx CNT
      sthx compareCNT
	  wait

      rts 
      
        
rezimSet:
      lda #2
      sta currentMode
      jsr rezimSetDef
      jsr zmenHodnotuAktivnihoDispleje

	  
      wait
      
      
      
      rts
rezimStart:
      lda #1
      sta currentMode
      
      brclr 6, PTED, skocNaSet 
      brset 6, PTED, skocNaCitani
      jmp konecTestuSkoku
skocNaSet:
      jsr rezimSet
      jmp konecTestuSkoku
skocNaCitani:
      jsr rezimCitani
konecTestuSkoku:            
      
      rts


rezimStop:
      lda #0
      sta currentMode
      ;sei
      mov #%11111111, PTBDD; ; data direction output pro port B, Seg7 1
      mov #%11111111, PTDDD; ; data direction output pro port D, Seg7 2
      ;mov #%11111111, PTEDD; ; data direction output pro port E, DILSwitch
    
      mov #%00000000, PTBD; 
      mov #%00000000, PTDD; 
      ;mov #%00000000, PTED; 
      lda PTED
      and #%10000000
      sta PTED
      
      ;mov #0, RTCSC
      ldhx #0
      sthx CNT
      rts

trikratBlikniAZastav:
      lda #5
      sta currentMode
      lda pocetBliknuti
      cmp #0
      beq blikaniDokonceno
      bne jesteBuduBlikat    ; bug nekde, underflow
blikaniDokonceno:
      lda #4
      sta pocetBliknuti
      mov #$00, PTED
      jsr rezimStop
      jmp konecA
jesteBuduBlikat:
      ;cmp #0
      ;beq konecA
      deca
      sta pocetBliknuti
      wait
konecA:      
      rts

nactiDILSwitch:
      
      brset 7, PTED, rezimStart
      brclr 7, PTED, rezimStop
      rts
      
zvysCNT:
      ldhx CNT
      cphx #$FFFF
      beq trikratBlikniAZastav
      aix #1
      sthx CNT
      rts
snizCNT:
      ldhx CNT
      cphx #$0000
      beq trikratBlikniAZastav
      aix #-1
      sthx CNT  
      rts        


 
mainLoop:
            ; Insert your code here
      NOP     
      ;jsr loadNibbles
      ;jsr displayTest
      jsr nactiDILSwitch            
;      wait
      
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
