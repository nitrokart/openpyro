/*
OpenPyro Field box 8 channels
   Version: 0.2.1.31
   Release: 26.08.2011
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

#define time_set_CH 100  // Delay on channel 100 ms
#define time_set_VD 100  // Delay LED on RX_TX
#define USART_RATE  9600 // Baud rate RS-485
#define USART_BYTE_Usec  11000000/USART_RATE // Time to transfer one byte

#define RC_Begin_Code   5327920

#define RX_RS_pin   0   // Sign in to receive data in UART RX.
#define TX_RS_pin   1   // Output data from UART TX.
#define TX_RX_pin   15  // Output for mode RS-485, TX or RX.

#define RF_pin   2      // RF input for the library VirtualWire
#define RC_pin   2      // RF input for the library RCSwitch

#define AKB_LED     11  // LED (red) indicate the battery status
#define TX_RX_LED   12  // LED (yellow), indicating exchange through UART
#define ON_OFF_LED  13  // LED (green) confirm the operation of the device
#define Adr_C       4   // The number of address bits
#define L_C         8   // Number of Channels
// An array containing the port numbers used in the microcontroller Projects to address selection jumpers receiver, MSB - pin 15.
unsigned char Adr_pin [Adr_C] = { 16, 17, 18, 19}; 
// Containing an array of ports of the microcontroller used in the Projects for the channels. From 3 to 10 channels.
unsigned char CH_L[L_C] = {3, 4, 5, 6, 7, 8, 9, 10};
//---------------------------------------------------------------------------
//The declaration of variables
unsigned char Adress = 0;   // Address of the device in a RS485 network

unsigned char ACP_val_1 = 0;
unsigned char ACP_val_2 = 0;

unsigned char rx_bayt = 0;
unsigned char CH_rx = 0;
unsigned char rx_count = 0;
unsigned char CRC8 = 0;
unsigned char CRC = 0;

unsigned char Fire = 0;
unsigned char L =0;
unsigned char TX_RX_SET =0;
char i = 0;
unsigned int ACP_val = 0;
unsigned int ACP_val_AB = 0;
unsigned int Adress_val = 0;
unsigned long time_stop = 0;
unsigned long time_VD_stop =0;
unsigned long RC_Code_0 =0;
unsigned long RC_Code_16 =0;

    uint8_t RF_RX_Buf[VW_MAX_MESSAGE_LEN];
    uint8_t buflen = VW_MAX_MESSAGE_LEN;

RCSwitch mySwitch = RCSwitch();
//---------------------------------------------------------------------------
//The declaration of the user functions
void Fire_CH (unsigned char CH);
void CLR_CH ();
void CRC_8(unsigned char b);
void RF_Rx_Decode();
void Rx_Decode();

void RC_Decode(unsigned long decimal, unsigned int length, unsigned int delay, unsigned int* raw);
//---------------------------------------------------------------------------
void RC_Decode(unsigned long decimal, unsigned int length, unsigned int delay, unsigned int* raw) {
 if (length == 24) { 
    RC_Code_0 = RC_Begin_Code  +((Adress-1)*16); 
    RC_Code_16 = RC_Begin_Code + (Adress*16) ;
    if (RC_Code_0 <= decimal && decimal <= RC_Code_16 )  Fire_CH ( (decimal - RC_Code_0)-1 );
 }
}
//---------------------------------------------------------------------------
void RF_Rx_Decode(){

  // To indicate the exchange of UART
  digitalWrite(TX_RX_LED, HIGH);
  time_VD_stop = millis() +  time_set_VD;
  TX_RX_SET = 1;  
  
  if (RF_RX_Buf[2] == ((RF_RX_Buf[0] + RF_RX_Buf[1])& 127)){
    if (RF_RX_Buf[0] == (Adress + 0x80) ) Fire_CH ( (RF_RX_Buf[1] - 1));
  }
}
//---------------------------------------------------------------------------
void Rx_Decode(){ // Processing of parcels received by UART
 
  // Для индикации обмена по UART
  digitalWrite(TX_RX_LED, HIGH);
  time_VD_stop = millis() +  time_set_VD;
  TX_RX_SET = 1;

  rx_bayt = Serial.read();


  if ( (rx_bayt|127) == 255 && rx_count ==0){
    if (rx_bayt ==  Adress+0x80){ 
      rx_count++;
      CRC=rx_bayt;
    }
  }  
  else if (rx_count == 1){
    CRC += rx_bayt;
    CRC = CRC & 127;
    CH_rx = rx_bayt;
    rx_count++;
  }
  else if (rx_count == 2){
    if (CRC == rx_bayt && CH_rx < 32)  Fire_CH ( CH_rx-1);
    rx_count=0; 
  } 
  
}
//---------------------------------------------------------------------------
void CRC_8(unsigned char b){
  for(char i = 0; i < 8; b = b >> 1, i++){
	if((b ^ CRC8) & 1) CRC8 = ((CRC8 ^ 0x18) >> 1) | 0x80;
	else CRC8 = (CRC8 >> 1) & ~0x80;
  }
}
//---------------------------------------------------------------------------
void CLR_CH (){
  digitalWrite(CH_L[L], LOW); 
  Fire = 0;
}
//---------------------------------------------------------------------------
void Fire_CH (unsigned char CH){
  if (CH < L_C ){
    CLR_CH ();
    L = CH;
    digitalWrite(CH_L[CH], HIGH); 
    Fire = 1;
    time_stop = millis() +  time_set_CH;
  } 
}
//---------------------------------------------------------------------------
void setup(){ 
  Serial.begin(USART_RATE);   // Data speed UART
  
  pinMode(RC_pin, INPUT);    

  pinMode(RF_pin, INPUT);      

  vw_set_ptt_pin (-1); 
  vw_set_tx_pin (-1);
  vw_set_rx_pin (RF_pin);  
  vw_setup(2000);	 // Bits per sec   
  vw_rx_start();         // Start the receiver PLL running
  

  
    mySwitch.enableReceive(0, RC_Decode);

  // Configure the ports of the microcontroller
  pinMode(RX_RS_pin, INPUT);    // Set up to enter for UART - RX.
  pinMode(TX_RS_pin, OUTPUT);   // Set up in output for UART - TX.
  pinMode(TX_RX_pin, OUTPUT);   // Set up for output to control the reception of signals, RS-485.

  pinMode(ON_OFF_LED, OUTPUT);  // Set up in output for LEDs confirm operation.
  pinMode(TX_RX_LED, OUTPUT);   // Set up in output for the LEDs on the exchange network RS-485.
  pinMode(AKB_LED, OUTPUT);     // Set up in output for the LED battery status.
  
  for (i=0; i<Adr_C; i++ ) pinMode(Adr_pin[i], INPUT);     // Set up the input on the receiver to select the address jumpers
  for (i=0; i<Adr_C; i++ ) digitalWrite(Adr_pin[i], HIGH); // Include internal pull-up resistors to +5 V
  
  for (i=0; i<L_C; i++ )   pinMode(CH_L[i], OUTPUT);       // In a series of ports set up channels for output.

  // ! Warning! the choice of internal reference voltage output Vref must be left in the air                        
  analogReference(INTERNAL);    // Select the internal reference voltage for ADC

  // ! Warning! Reading the destination address (can be done only when running in the microcontroller)
  Adress = 0;                           // Zero out the variable store address
  for (i=0; i<Adr_C; i++ ){             
    Adress_val = digitalRead(Adr_pin[i]);
    Adress = (Adress)  << 0x01;
    if ( Adress_val == 0 ) Adress = (Adress + 0x01); 
  }
  
  // If you do not use jumper that put the following line of address
  //Adress = 1;

  // Green LED supply confirmation of the device.
  digitalWrite(ON_OFF_LED, HIGH);
}
//---------------------------------------------------------------------------
void loop(){
  // Test voltage (not working yet - you need to pick up level)
  ACP_val = analogRead(0);
  if (ACP_val < (4*6.8)) digitalWrite(AKB_LED, HIGH);
  else               digitalWrite(AKB_LED, LOW);
   
  // Check if the byte
   if (Serial.available() > 0) Rx_Decode(); 
   
  // Disable timer channel delay
   if (Fire == 1) if ( time_stop < millis()) CLR_CH ();
   
  // Turn off the LED receiving transfer
   if (TX_RX_SET == 1) if (time_VD_stop < millis()){ 
     digitalWrite(TX_RX_LED, LOW);
     TX_RX_SET = 0;
   }  
   
   // Reception to 433.92 using WirtualVire
   if (vw_get_message( RF_RX_Buf, &buflen)){
      RF_Rx_Decode();
   }
}
//--------------------------------------------------------------------------- 
