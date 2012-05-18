/*
OpenPyro Transmitter mini (SuperbFire protocol only)
   Version: 0.2.7.28
   Release: 18.05.2012
   License: GPLv3
   Autor:   Gordeev Andrey Vladimirovich (OpenPyro)
   Autor e-mail:  gordeev@openpyro.com
   WEBSAIT: http://www.openpyro.com
*/

//---------------------------------------------------------------------------
// include the library code:
#include <RCSwitch.h>
//---------------------------------------------------------------------------
//The declaration of constants
#define Max_Adress      32
#define Max_CH          32

#define CH_In_Bank      8
#define Max_Bank        4 //(Max_CH/CH_In_Bank )

#define USART_USB_RATE  9600  //
#define USART_BYTE_RS_Usec  11000000/USART_USB_RATE //

#define RF_pin          12   //

#define TX_LED_pin      13   //

unsigned char Bank    = 0;   //
unsigned char Units   = 0;
unsigned char rx_bayt = 0;
unsigned char rx_count= 0;
unsigned char CH_rx   = 0;
unsigned char Adress_rx=1;
unsigned char CRC8    = 0;

char i_ = 0;

unsigned long RC_Code =0;
unsigned char Protocol = 0;

#define Prot_C       5     // The number of protocol bits
unsigned char Prot_pin [Prot_C] = { 14, 15, 16, 17, 18};

unsigned long Unit_Code[Max_Adress] ={
0b000110100111100100010000, 
0b001110100111100100110000, 
0b011110100111100101110000,
0b001010100111100101010000, 
0b100010100111100110000000, 
0b110010100111100111000000, 
0b111010100111100111100000, 
0b101010100111100110100000, 
0b101110100111100110110000, 
0b110110100111100111010000,

0b010010100111100101000000, 
0b011010100111100101100000,

0b000110101111100100010000, 
0b001110101111100100110000, 
0b011110101111100101110000,
0b001010101111100101010000, 
0b100010101111100110000000, 
0b110010101111100111000000, 
0b111010101111100111100000, 
0b101010101111100110100000, 
0b101110101111100110110000, 
0b110110101111100111010000,

0b000110110111100100010000, 
0b001110110111100100110000, 
0b011110110111100101110000,
0b001010110111100101010000, 
0b100010110111100110000000, 
0b110010110111100111000000, 
0b111010110111100111100000, 
0b101010110111100110100000, 
0b101110110111100110110000, 
0b110110110111100111010000 };

RCSwitch mySwitch = RCSwitch();
//---------------------------------------------------------------------------
void CRC_8(unsigned char b);
void Fire();
void Rx_Decode();
void RF_Send(unsigned char rf_ch);
//---------------------------------------------------------------------------
void RF_Send(unsigned char rf_ch){
  RC_Code = Unit_Code[Adress_rx-1]+rf_ch ;
  mySwitch.send(RC_Code,24);
}
//---------------------------------------------------------------------------
void Rx_Decode(){ //

  rx_bayt = Serial.read();

  // CRC8 PyroIgnitorControl
  if (rx_bayt == 0xFF && rx_count ==0){
    CRC8=0;
    rx_count++;
  }
  else if (rx_count == 1){
    CRC_8(rx_bayt);
    Adress_rx = rx_bayt;
    rx_count++;
  }
  else if (rx_count == 2){
    CRC_8(rx_bayt);
    CH_rx = rx_bayt;
    rx_count++;
  }
  else if (rx_count == 3){
    if (CRC8 == rx_bayt )   Fire();
    rx_count=0;
  }
}
//---------------------------------------------------------------------------
void Fire(){
  if (CH_rx > Max_CH) return;
  
  digitalWrite(TX_LED_pin, HIGH);
  
  if       (digitalRead(Prot_pin[0]) == 0) Protocol =0;
  else if  (digitalRead(Prot_pin[1]) == 0) Protocol =1;
  else                                     Protocol =2;

  switch (Protocol){
    case 0:
            mySwitch.setRepeatTransmit(16);
            RF_Send(1);
    break;
    case 1:
            Bank = (CH_rx-1) / CH_In_Bank;
            Units = CH_rx - Bank*CH_In_Bank;
            mySwitch.setRepeatTransmit(6);
            RF_Send(Bank+9);
            delay(50);
            mySwitch.setRepeatTransmit(4);
            RF_Send(Units);
            delay(50);
    break;
  }
  digitalWrite(TX_LED_pin, LOW);  
}
//---------------------------------------------------------------------------
void CRC_8(unsigned char b){
  for(char i = 0; i < 8; b = b >> 1, i++){
	if((b ^ CRC8) & 1) CRC8 = ((CRC8 ^ 0x18) >> 1) | 0x80;
	else CRC8 = (CRC8 >> 1) & ~0x80;
  }
}
//---------------------------------------------------------------------------
void setup() {
  // Transmitter is connected to Arduino Pin
  mySwitch.enableTransmit(RF_pin);
  //Set pulse length.
  mySwitch.setPulseLength(215);
  mySwitch.setRepeatTransmit(10);

  for (i_=0; i_<Prot_C; i_++ ) pinMode(Prot_pin[i_], INPUT);     // Set up the input on the receiver to select the protocol jumpers
  for (i_=0; i_<Prot_C; i_++ ) digitalWrite(Prot_pin[i_], HIGH); // Include internal pull-up resistors to +5 V

  Serial.begin(USART_USB_RATE);
  
  pinMode(TX_LED_pin ,  OUTPUT);  
}
//---------------------------------------------------------------------------
void loop() {
  if (Serial.available() > 0) Rx_Decode();
}
//---------------------------------------------------------------------------

