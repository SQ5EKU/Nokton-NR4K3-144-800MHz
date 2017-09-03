' Program do sterowania PLL UMA1014T w nadajniku Nokton NR4K3 PCB v2 , na 89C2051
' Czestotliwosc pracy: 144.800 MHz
' Wersja z kontrola poprawnej synchronizacji PLL ,
' zabezpieczeniem w przypadku uszkodzenia procesora (nie stoi nosna na przypadkowej czestotliwosci),
' antyzwiecha sprzetowa 5 sekudowa
' Vbat sygnalizuje spadek napiecia zasilania ponizej 11.0 V (aktualnie nie wykorzystany)
'
$regfile = "89c2051.dat"
$crystal = 12800000                                           ' zegar 12.8 MHz

Config Sda = P1.0                                             ' pin 12 , magistrala I2C , SDA
Config Scl = P1.1                                             ' pin 13 , magistrala I2C , SCL

Dim Tmp As Bit                                                

Ptt Alias P1.2                                                ' pin 14 , PTT H=wylaczone , L=zalaczone
Vco Alias P1.3                                                ' pin 15 , zasilanie VCO H=zalaczone , L=wylaczone
Azw Alias P1.7                                                ' pin 19 , antyzwiecha
Vbat Alias P3.3                                               ' pin 7 , VBAT H=niskie napiecie zasilania , L=napiecie OK
Drv Alias P3.4                                                ' pin 8 , wzmacniacz w.cz. H=wylaczony , L=zalaczony
Led Alias P3.5                                                ' pin 9 , LED TX H=swieci , L=zgaszona
Ld Alias P3.7                                                 ' pin 11 , LD UMA1014T H=synchronizacja , L=brak synchronizacji

Declare Sub Pll_on
Declare Sub Pll_off
Declare Sub Pll_sw1
Declare Sub Pll_sw2

Set Ptt
Reset Vco
Tmp = 1
Set Azw
Set Drv
Set Vbat
Set Led
Set Ld


Do                                                            
Reset Azw                                                     ' resetuj antyzwieche niskim stanem
' If Vbat = 0 Then                                             ' jezeli VBAT OK idz dalej , niski stan
  If Tmp = 0 Then                                             ' jezeli wartosc rowna 0 idz dalej
   If Ptt = 0 Then                                            ' jezeli PTT zalaczone , niski stan
    Set Vco                                                   ' wlacz zasilanie VCO
    Waitms 10
    Gosub Pll_on
    Gosub Pll_sw1
    End If                                                    
   End If                                                     
' End If                                                      

 If Ptt = 1 Then                                              ' jezeli PTT wylaczone idz dalej , wysoki stan
  If Tmp = 1 Then                                             ' jezeli wartosc rowna 1 idz dalej
  Waitms 10
  Gosub Pll_off
  Gosub Pll_sw2
  End If                                                     
 End If                                                       

Set Azw                                                      
Loop
End


Pll_on:
' Programowanie UMA1014T przez I2C
' Ustawianie parametrow PLL nadajnika
I2cstart                                                      ' start
I2cwbyte &B11000100                                           ' device address , SAA pin at +5V , write
I2cwbyte &B00001000                                           ' disable alarm , auto-increment , following register A
I2cwbyte &B00001100                                           ' no power down , current 0.5mA , reference divider 1024
I2cwbyte &B10100100                                           ' passive filter , VCO A
I2cwbyte &B00101101                                           ' main divider - high byte (144.800 MHz)
I2cwbyte &B01000000                                           ' main divider - low byte (144.800 MHz)
I2cstop                                                       ' stop
Return

Pll_sw1:
' Ustawienia wyjsc podczas nadawania
Waitms 50
 If Ld = 1 Then                                               ' jezeli LD UMA1014T OK idz dalej , wysoki stan
 Reset Led                                                    ' zaswiec LED tx , niski stan
 Tmp = 1                                                      ' wpisz wartosc 1
 Reset Drv                                                    ' zalacz wzmacniacz w.cz.
 Else                                                         ' w przeciwnym wypadku idz do procedury Pll_off ---
 Goto Pll_off                                                 ' --- powtarzajac sekwencje trybu uspienia UMA1014T ---
 End If                                                       ' --- czasem UMA1014T nie startuje poprawnie.
Return

Pll_off:
' Programowanie UMA1014T przez I2C
' Ustawianie ukladu w tryb power down (UMA1014T pobiera okolo 3mA)
I2cstart                                                      ' start
I2cwbyte &B11000100                                           ' device address , SAA pin at +5V , write
I2cwbyte &B00001000                                           ' disable alarm , auto-increment , following register A
I2cwbyte &B10000000                                           ' power down on , current 0.5mA , reference divider 128
I2cwbyte &B10100100                                           ' passive filter , VCO A
I2cwbyte &B00100111                                           ' main divider - high byte
I2cwbyte &B11010000                                           ' main divider - low byte
I2cstop                                                       ' stop
Return

Pll_sw2:
' Ustawienia wyjsc na standby'u
Reset Azw                                                     ' resetuj antyzwieche
Set Drv                                                       ' wylacz wzmacniacz w.cz.
Tmp = 0                                                       ' wpisz wartosc 0
Set Led                                                       ' zgas LED tx . wysoki stan
Reset Vco                                                     ' wylacz zasilanie VCO
Return