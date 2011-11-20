/*
OpenPyro Transmitter light
   Version: 0.2.1.21
   Release: 19.11.2011
   License: GPLv3
   Autor:   Gordeev Andrey Vladimirovich (OpenPyro)
   Autor e-mail:  gordeev@openpyro.com
   WEBSAIT: http://www.openpyro.com
*/

//---------------------------------------------------------------------------
// include the library code:

#include <VirtualWire.h>
#include <RCSwitch.h>
//---------------------------------------------------------------------------
//The declaration of constants

#define Max_Adress      30
#define Max_CH          32

#define CH_In_Bank      8
#define Max_Bank        4 //(Max_CH/CH_In_Bank )

#define RC_Begin_Code   5327920
#define time_Bat_test   1000  //
#define time_Key_ask    10    //
#define USART_USB_RATE  9600  //
#define USART_BYTE_RS_Usec  11000000/USART_USB_RATE //
#define TX_RX_pin       13   //
#define RF_pin          12   //
unsigned char Adress  = 1;   //
unsigned char Bank    = 0;   //
unsigned char Units   = 0;
unsigned char CH      = 0;   //
unsigned char C_      = 0;   //
unsigned char b_      = 0;   //
unsigned char d_      = 0;   //
unsigned char rx_bayt = 0;
unsigned char rx_count= 0;
unsigned char CH_rx   = 0;
unsigned char Adress_rx=1;
unsigned char CRC8    = 0;
unsigned char CRC     = 0;
unsigned char F_Key   = 0;
unsigned int  U       = 0;
unsigned char row_t;
char Last_Key = 0;
unsigned char KpdState  = 0;
char i_ = 0;
char e_ = 0;
unsigned int ACP_val       = 0;
unsigned long time_TemeMs  = 0;
unsigned long time_RF      = 0;
unsigned long time_RS      = 0;
unsigned long time_USB     = 0;
unsigned long msNow        = 0;
unsigned long RC_Code =0;
unsigned char LCD_Contrast = 0;
unsigned char LCD_BackLight= 0;
unsigned char Contrast_HEX = 0;
unsigned char BackLight_HEX= 0;
unsigned char Menu = 0;
unsigned char Select_Cursor[6] = {0,0,0,0,0,0};
unsigned char Menu_Item[6] = {2,0,2,1,0,0};
unsigned char Blink_S = 0;
unsigned char Protocol = 0;
uint8_t RF_TX_Buf[3];       // Buffer RF 433.92 МГц.
byte NewChar[8] ;
//---------------------------------------------------------------------------

RCSwitch mySwitch = RCSwitch();

void CRC_8(unsigned char b);
void Fire();
void FireNext();
void FireReset();
void Key_Ask();
void Firing_Clear();
void Rx_Decode();
void RF_Send(unsigned char rf_ch);
void Select_Show(char Row_Select);
//---------------------------------------------------------------------------
void RF_Send(unsigned char rf_ch){
  if (Protocol == 0)   mySwitch.setRepeatTransmit(6);
  else    mySwitch.setRepeatTransmit(3);
  RC_Code = RC_Begin_Code+rf_ch+((Adress-1)*16);
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
    if (CRC8 == rx_bayt ){

      Adress = Adress_rx;
      if (Protocol == 0)F_Key = CH_rx;
      else{
        Bank = (CH_rx-1) / CH_In_Bank;
        F_Key = CH_rx - Bank*CH_In_Bank;
      }
      Fire();
    }
    rx_count=0;
  }
}
//---------------------------------------------------------------------------
void Fire(){
  if (Menu!=1) return;
  if (Bank*CH_In_Bank+F_Key > Max_CH) return;
  if (Protocol == 0 && F_Key>12 ) return;

  if (F_Key> CH_In_Bank) CH = F_Key;
  else {
    Units = F_Key;
    CH = Bank*CH_In_Bank + Units;
  }

  CRC =  Adress + 128;
  RF_TX_Buf[0] = CRC;
  Serial.print( CRC , BYTE);
  CRC = CRC + CH;
  RF_TX_Buf[1] = CH;
  Serial.print( CH , BYTE);
  CRC = CRC & 127;
  RF_TX_Buf[2] = CRC;
  Serial.print( CRC , BYTE);


  time_TemeMs = millis();


  switch (Protocol){
    case 0:
           if (CH<=12) RF_Send(CH);
    break;
    case 1:
            RF_Send(Bank+9);
            //delay(200);
            RF_Send(Units);
            //delay(200);
    break;
    case 2:
            vw_send((uint8_t *)RF_TX_Buf, sizeof(RF_TX_Buf));
            vw_wait_tx();
    break;
  }

  d_ = (CH-1)/CH_In_Bank;
  b_ = (CH-1) - d_*CH_In_Bank;


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
  pinMode(TX_RX_pin,     OUTPUT);  //
  digitalWrite(TX_RX_pin, HIGH) ;  //

  //Wirtual wire setup
  vw_set_tx_pin(RF_pin);
  vw_set_rx_pin(-1);
  vw_set_ptt_pin(-1);
  vw_setup(3000);	           // Bits per sec
  vw_rx_stop();

  // Transmitter is connected to Arduino Pin
  mySwitch.enableTransmit(RF_pin);
  //Set pulse length.
  mySwitch.setPulseLength(340);
  mySwitch.setRepeatTransmit(4);

  for (i=0; i<Adr_C; i++ ) pinMode(Adr_pin[i], INPUT);     // Set up the input on the receiver to select the address jumpers
  for (i=0; i<Adr_C; i++ ) digitalWrite(Adr_pin[i], HIGH); // Include internal pull-up resistors to +5 V

  Serial.begin(USART_USB_RATE);
}
//---------------------------------------------------------------------------
void loop() {
  if (Serial.available() > 0) Rx_Decode();
}
//---------------------------------------------------------------------------
