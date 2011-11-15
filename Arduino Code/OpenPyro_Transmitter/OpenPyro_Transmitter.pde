/*
OpenPyro Transmitter 1024 channels
   Version: 0.1.4.20
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
#include <EEPROM.h>
#include <LiquidCrystal.h>
#include <Keypad.h>

//---------------------------------------------------------------------------
//The declaration of constants

#define Max_Adress      32
#define Max_CH          32
#define CH_In_Bank      8
#define Max_Bank        4 //(Max_CH/CH_In_Bank )

#define RC_Begin_Code   5327920

#define time_Bat_test   1000  // 
#define time_Key_ask    10    //

#define time_Show_RF    300    // 
#define time_Show_RS    300    // 
#define time_Show_USB   300    // 

#define USART_USB_RATE  9600  // 
#define USART_BYTE_RS_Usec  11000000/USART_USB_RATE // 

#define TX_RX_pin       13   // 
#define IR_RF_pin       12   // 
#define CONTRAST_pin    5    // 
#define LED_pin         11   // 

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

unsigned char Firing[Max_Adress][Max_Bank];

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

char * ProtocolNemeShot[3] = {"AlphaFire","SuperbFire","OpenPyro  "};
char * ProtocolNeme[3] = {"  AlphaFire  12 Cue "
                         ,"  SuperbFire 32 Cue "
                         ,"  OpenPyro   32 Cue "};

uint8_t RF_TX_Buf[3];       // Buffer RF 433.92 МГц.

byte NewChar[8] ;

//---------------------------------------------------------------------------
unsigned long time_Bat =0;
unsigned long time_Key =0;

// initialize the library with the numbers of the interface pins
LiquidCrystal lcd(14, 15, 16, 17, 18, 19);

RCSwitch mySwitch = RCSwitch();

// The Keymap
const byte ROWS = 4; // Four rows
const byte COLS = 4; // Three columns
// Define the Keymap
char keys[ROWS][COLS] = {
  {'1','2','3','A',},
  {'4','5','6','B',},
  {'7','8','9','C',},
  {'*','0','#','D' }
};
// Connect keypad ROW0, ROW1, ROW2 and ROW3 to these Arduino pins.
byte rowPins[ROWS] = { 10,  4,  3,  2  };
// Connect keypad COL0, COL1 and COL2 to these Arduino pins.
byte colPins[COLS] = { 9,  8,  7,  6  }; 
// Create the Keypad
Keypad kpd = Keypad( makeKeymap(keys), rowPins, colPins, ROWS, COLS );

void CRC_8(unsigned char b);
void Fire();
void Adress_minus();      
void Adress_plus();  

void Cursor_minus();      
void Cursor_plus();  
void Cursor_CLR();

void FireNext(); 
void FireReset();

void Apdate_Slever();
void Apdate_Bat();
void Key_Ask();

void Firing_Clear();

void Rx_Decode();
void RF_Send(unsigned char rf_ch);
void PrintTemeMs();

void ShowMenu();

void Show_RS();
void CLR_RS();

void Show_USB();
void CLR_USB();

void Show_RF();
void CLR_RF();

void LCD_Char_Setup();

void Select_Show(char Row_Select);

void Contrast_Show(char Inc1) ;
void BackLight_Show(char Inc2);

void CH_Show(unsigned char Ch_To_Show);
//---------------------------------------------------------------------------
void CH_Show(unsigned char Ch_To_Show){
  
        if      (Ch_To_Show==9)      {lcd.setCursor(4+9, 2);  lcd.print("A");}
        else if (Ch_To_Show==10)     {lcd.setCursor(4+10, 2); lcd.print("B");}
        else if (Ch_To_Show==11)     {lcd.setCursor(4+11, 2); lcd.print("C");}
        else if (Ch_To_Show==12)     {lcd.setCursor(4+12, 2); lcd.print("D");   }     
        else if (Ch_To_Show < 9)     {lcd.setCursor(4+Ch_To_Show, 2); lcd.print(Ch_To_Show, DEC); }  

}
//---------------------------------------------------------------------------
void Contrast_Show(char Inc1){
  if ((Contrast_HEX+Inc1)>= 0 && (Contrast_HEX+Inc1)<= 16) Contrast_HEX = Contrast_HEX + Inc1;  
  
  lcd.setCursor(2, 3);
  for (i_=0; i_<16; i_++ ){  
    if ((15-i_) < Contrast_HEX)     lcd.write(3); 
    else     lcd.write(255);  
  }
  
  LCD_Contrast  =  Contrast_HEX*4; 
  analogWrite(CONTRAST_pin, LCD_Contrast);  // 0   ‚

}
//---------------------------------------------------------------------------
void BackLight_Show(char Inc2){
  if ((BackLight_HEX+Inc2)>= 0 && (BackLight_HEX+Inc2)<= 16) BackLight_HEX = BackLight_HEX + Inc2;  
 
  lcd.setCursor(2, 3);
  for (i_=0; i_<16; i_++ ){  
    if (i_ < BackLight_HEX)     lcd.write(255); 
    else     lcd.write(3);  
  }
  if (BackLight_HEX == 16) LCD_BackLight = 255;
  else LCD_BackLight = BackLight_HEX*16; 
  analogWrite(LED_pin,      LCD_BackLight); // 255      
}
//---------------------------------------------------------------------------
void Apdate_Bat(){
  time_Bat = millis() +  time_Bat_test;  
  time_RF = millis() +  time_Show_RF; 
  
  ACP_val = analogRead(7);
  U = ACP_val*100/452;

  if (U>=80){
    lcd.setCursor(16, 0);  
    lcd.write(255);            
    lcd.write(255);
    lcd.write(255);
    lcd.write(1);  
  }  
  else if (U>=76){
    lcd.setCursor(16, 0);  
    lcd.write(255);            
    lcd.write(255);
    lcd.write(255);
    lcd.write(4);  
  }   
  else if (U>=72){
    lcd.setCursor(16, 0);  
    lcd.write(255);            
    lcd.write(255);
    lcd.write(3);
    lcd.write(4);  
  }
  else if (U>=68){
    lcd.setCursor(16, 0);  
    lcd.write(255);            
    lcd.write(3);
    lcd.write(3);
    lcd.write(4);  
  }  
  else if (U<5){
      lcd.setCursor(16, 0);  
      lcd.print ("pwPC"); 
  }
  else{
    if (Blink_S ==0){
      lcd.setCursor(16, 0);  
      lcd.write(2);            
      lcd.write(3);
      lcd.write(3);
      lcd.write(4);
      Blink_S =1;  
    }
    else{
      lcd.setCursor(16, 0);  
      lcd.print ("    ");
      Blink_S =0;      
    }
  } 
}
//---------------------------------------------------------------------------
void Apdate_Slever(){
  lcd.setCursor(5, 1);  
  lcd.print(Adress, DEC);
  lcd.print(" ");
 
  if(Protocol == 0){
    lcd.setCursor(5, 2);
    for (i_=0; i_<12; i_++ ){
        C_ = i_;
        d_ = C_/CH_In_Bank;
        b_ = C_ - d_*CH_In_Bank;
        if (C_>=Max_CH) lcd.print(" ");
        else if (0 == bitRead(Firing[Adress-1][d_], b_))  lcd.print(".");
        else if (i_==8)   lcd.print("A");
        else if (i_==9)  lcd.print("B");
        else if (i_==10)  lcd.print("C");
        else if (i_==11)  lcd.print("D");        
        else              lcd.print(i_+1, DEC);   
  
    }
  }  
  else{
    lcd.setCursor(16, 1);
    for (i_=0; i_<Max_Bank; i_++ ){
      if (i_ == Bank ) lcd.print(i_+10, HEX);   
      else            lcd.print("-");
    }
   
    lcd.setCursor(5, 2);
    for (i_=0; i_<CH_In_Bank; i_++ ){
        C_ = Bank*CH_In_Bank + i_;
        d_ = C_/CH_In_Bank;
        b_ = C_ - d_*CH_In_Bank;
        if (C_>=Max_CH) lcd.print(" ");
        else if (0 == bitRead(Firing[Adress-1][d_], b_))  lcd.print(".");
        else if (i_==9)  lcd.print("0");           
        else           lcd.print(i_+1, DEC);  
    
    } 
  }  
}
//---------------------------------------------------------------------------
void Show_RF(){
  time_RF = millis() +  time_Show_RF;   
  lcd.setCursor(12, 0);  
  lcd.write(7);
}
//---------------------------------------------------------------------------
void CLR_RF(){
  lcd.setCursor(12, 0);  
  lcd.write(32);   
}
//---------------------------------------------------------------------------
void Show_RS(){
  time_RS = millis() +  time_Show_RS; 
  lcd.setCursor(13, 0);  
  lcd.write(6); 
}
//---------------------------------------------------------------------------
void CLR_RS(){
  lcd.setCursor(13, 0);  
  lcd.write(32);   
}
//---------------------------------------------------------------------------
void Show_USB(){
  time_USB = millis() +  time_Show_USB; 
  lcd.setCursor(14, 0);  
  lcd.write(5);   
}
//---------------------------------------------------------------------------
void CLR_USB(){
  lcd.setCursor(14, 0);  
  lcd.write(32);  
}
//---------------------------------------------------------------------------
void Cursor_Show(){
  lcd.setCursor(0, 1);  
  lcd.print(" ");
  lcd.setCursor(0, 2);  
  lcd.print(" ");
  lcd.setCursor(0, 3);  
  lcd.print(" "); 
 
  lcd.setCursor(0, (Select_Cursor[Menu]+1));
  lcd.write(0); 
}
//---------------------------------------------------------------------------
void Select_Show(char Row_Select){
  lcd.setCursor(1, 1);  
  lcd.print(" ");
  lcd.setCursor(1, 2);  
  lcd.print(" ");
  lcd.setCursor(1, 3);  
  lcd.print(" ");
  
  if (Row_Select >= 0){ 
    lcd.setCursor(1, (Row_Select+1));
    lcd.write(62);
  } 
}
//---------------------------------------------------------------------------
void Cursor_minus(){
  Select_Cursor [Menu] --;  
  if(Select_Cursor[Menu]==255) Select_Cursor[Menu]=Menu_Item[Menu];
  Cursor_Show();
}
//---------------------------------------------------------------------------
void Cursor_plus(){
  Select_Cursor[Menu] ++;  
  if(Select_Cursor[Menu]>Menu_Item[Menu]) Select_Cursor[Menu]=0;
  Cursor_Show();
}
//---------------------------------------------------------------------------
void PrintTemeMs(){
  if(Protocol == 0) row_t =1;
  else row_t =2;
  
  lcd.setCursor(13, row_t);
  lcd.print("      ");
  time_TemeMs = millis() - time_TemeMs;  
  lcd.setCursor(15, row_t);
  lcd.print(time_TemeMs, DEC);
  lcd.print("ms");
}
//---------------------------------------------------------------------------
void ShowMenu(){

  switch (Menu){
      case 0:
              lcd.clear();    
              lcd.setCursor(0, 0);  
              lcd.print("Main Menu");
              
              lcd.setCursor(0, 1);  
              lcd.print("  Firing mode"); 
 
              lcd.setCursor(0, 2);
              lcd.print("  Protocol set"); 
  
              lcd.setCursor(0, 3);
              lcd.print("  LCD setup");  
               Cursor_Show();
              
      break;  
      case 1: 
              lcd.clear();        
              lcd.setCursor(0, 0);  
              lcd.print(ProtocolNemeShot[Protocol]);
              
              lcd.setCursor(0, 1);              
              lcd.print("Slot:");
              
              if(Protocol != 0){
              lcd.setCursor(11, 1);  
              lcd.print("Bank:");
              }
              
              lcd.setCursor(0, 2);  
              lcd.print("Cue :"); 
 
              lcd.setCursor(0, 3);
              lcd.print(" 9.FireNext  *.Menu ");
              
              FireReset();
              Apdate_Slever();
      break;  
      case 2: 
              lcd.clear();        
              lcd.setCursor(0, 0);  
              lcd.print("Protocol set");
              
              lcd.setCursor(0, 1);  
              lcd.print(ProtocolNeme[0]); 
 
              lcd.setCursor(0, 2);
              lcd.print(ProtocolNeme[1]); 
  
              lcd.setCursor(0, 3);
              lcd.print(ProtocolNeme[2]);  
              Cursor_Show();     
              Select_Show(Protocol);
      break;        
      case 3: 
              lcd.clear(); 
              Select_Show(-1);              
              lcd.setCursor(0, 0);  
              lcd.print("LCD setup");
              
              lcd.setCursor(0, 1);  
              lcd.print("  Contrast"); 
 
              lcd.setCursor(0, 2);
              lcd.print("  Backlight"); 
              Cursor_Show();
     break;
     case 4:    
              Contrast_Show(0);
     break;
     case 5:    
              BackLight_Show(0);
     break;
  }   
  Apdate_Bat();  
}
//---------------------------------------------------------------------------
void Key_Ask()
{
  time_Key = millis() +  time_Key_ask;
  char key = kpd.getKey();
  
  if(key) Last_Key = key; // same as if(key != NO_KEY)
  KpdState = kpd.getState();
  if( 2 == kpd.getState())    Last_Key = 'N';

  switch (Menu){
    case 0:    
            switch (key){
              case '#':   Cursor_minus(); break;      
              case '0':   Cursor_plus();  break;   
              case 'D':   Menu = Select_Cursor[Menu]+1; Last_Key = 'N';  ShowMenu(); break;      
            }     
    break;  
    case 1:    
            switch (Last_Key){
              case '1':   F_Key = 1; Fire(); break;
              case '2':   F_Key = 2; Fire(); break;
              case '3':   F_Key = 3; Fire(); break;
              case '4':   F_Key = 4; Fire(); break;
              case '5':   F_Key = 5; Fire(); break;
              case '6':   F_Key = 6; Fire(); break;
              case '7':   F_Key = 7; Fire(); break;
              case '8':   F_Key = 8; Fire(); break;

              case 'A':   if(Protocol == 0){F_Key = 9; Fire(); } else  {Bank=0; F_Key = 0;   Apdate_Slever();}   break;      
              case 'B':   if(Protocol == 0){F_Key = 10; Fire(); } else {Bank=1; F_Key = 0;   Apdate_Slever();}   break;      
              case 'C':   if(Protocol == 0){F_Key = 11; Fire(); } else {Bank=2; F_Key = 0;  Apdate_Slever();}   break;
              case 'D':   if(Protocol == 0){F_Key = 12; Fire(); } else {Bank=3; F_Key = 0;  Apdate_Slever();}   break;
              case 'N':   break;       
            }   
            switch (key){
              case '9':   FireNext();     break;
              case '#':   Adress_plus();  break;      
              case '0':   Adress_minus(); break;   
              case '*':   Menu = 0; ShowMenu(); break;      
            }      
    break;
    case 2:    
            switch (key){
              case '#':   Cursor_minus(); break;      
              case '0':   Cursor_plus();  break;   
              case 'D':   Protocol = Select_Cursor[Menu]; EEPROM.write(3, Protocol);  Select_Show(Protocol); break;   
              case '*':   Menu = 0;   ShowMenu(); break;      
            }     
    break; 
    case 3:    
            switch (key){
              case '#':   Cursor_minus(); break;      
              case '0':   Cursor_plus();  break;
              case 'D':   Select_Show(Select_Cursor[Menu]); Menu = Select_Cursor[Menu]+4; ShowMenu(); break;               
              case '*':   Menu = 0;   ShowMenu(); break;      
            }     
    break;  
    case 4:    
            switch (key){
              case '#':   Contrast_Show( -1); break;      
              case '0':   Contrast_Show( 1); break;
              case '*':   Menu = 3;   EEPROM.write(1, Contrast_HEX );  ShowMenu(); break;     
            }     
    break;  
    case 5:    
            switch (key){
              case '#':   BackLight_Show(1);  break;      
              case '0':   BackLight_Show(-1);  break;
              case '*':   Menu = 3;  EEPROM.write(2, BackLight_HEX );  ShowMenu(); break;     
            }     
    break;      
  }  
}
//---------------------------------------------------------------------------
void RF_Send(unsigned char rf_ch){
  if (Protocol == 0)   mySwitch.setRepeatTransmit(6);
  else    mySwitch.setRepeatTransmit(3);
  RC_Code = RC_Begin_Code+rf_ch+((Adress-1)*16);
  mySwitch.send(RC_Code,24);
}
//---------------------------------------------------------------------------
void Rx_Decode(){ // 
  Show_USB();
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
void Firing_Clear(){
  for (i_=0; i_<Max_Adress; i_++ ) for (e_=0; e_<Max_Bank; e_++ ) Firing[i_][e_]=0xFF; 
}
//---------------------------------------------------------------------------
void FireReset(){
  Adress = 1;
  Bank = 0;  
  Units= 0;
  F_Key =0;
  CH = 0; 
  Firing_Clear();
  Apdate_Slever();
}
//---------------------------------------------------------------------------
void FireNext(){
   F_Key ++;
 
   if (Protocol == 0){
      if (F_Key > 12 ){   
       F_Key = 1; 
       Bank = 0 ;
       Adress++;
       Apdate_Slever();  
      }
   }
   else{
     if (F_Key > CH_In_Bank ){ 
       F_Key = 1; 
       Bank++;
       Apdate_Slever();
     }  
     if ((Bank*CH_In_Bank+F_Key) > Max_CH ){ 
       F_Key = 1; 
       Bank = 0 ;
       Adress++;
       Apdate_Slever();
       if (Adress>Max_Adress) {
         Adress=1;
       }
     }   
   }
 Fire();
}
//---------------------------------------------------------------------------
void Adress_plus(){
  Adress++;
  F_Key = 0;   
  if (Adress>Max_Adress) {
   Adress=1;
  }  
  Apdate_Slever();
}
//---------------------------------------------------------------------------
void Adress_minus(){
  Adress--;
  F_Key = 0;  
  if (Adress<1) {
    Adress= Max_Adress;
  }  
  Apdate_Slever();
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
 
  CH_Show(F_Key);  
  Show_RS();
  
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
  Show_RF();
  
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
  
  PrintTemeMs();  

  d_ = (CH-1)/CH_In_Bank;
  b_ = (CH-1) - d_*CH_In_Bank;
  bitClear(Firing[Adress-1][d_], b_) ; 
   
  Apdate_Slever();
}
//---------------------------------------------------------------------------
void CRC_8(unsigned char b){
  for(char i = 0; i < 8; b = b >> 1, i++){
	if((b ^ CRC8) & 1) CRC8 = ((CRC8 ^ 0x18) >> 1) | 0x80;
	else CRC8 = (CRC8 >> 1) & ~0x80;
  }
}
//---------------------------------------------------------------------------
void LCD_Char_Setup(){
  NewChar[0]=B10000;
  NewChar[1]=B11000;
  NewChar[2]=B11100;
  NewChar[3]=B11110;
  NewChar[4]=B11100;
  NewChar[5]=B11000;
  NewChar[6]=B10000;
  NewChar[7]=B00000;  
  lcd.createChar(0, NewChar);  
   
  NewChar[0]=B11100;
  NewChar[1]=B11100;
  NewChar[2]=B11111;
  NewChar[3]=B11111;
  NewChar[4]=B11111;
  NewChar[5]=B11111;
  NewChar[6]=B11100;
  NewChar[7]=B11100;
  lcd.createChar(1, NewChar);

  NewChar[0]=B11111;
  NewChar[1]=B10000;
  NewChar[2]=B10000;
  NewChar[3]=B10000;
  NewChar[4]=B10000;
  NewChar[5]=B10000;
  NewChar[6]=B10000;
  NewChar[7]=B11111;
  lcd.createChar(2, NewChar);

  NewChar[0]=B11111;
  NewChar[1]=B00000;
  NewChar[2]=B00000;
  NewChar[3]=B00000;
  NewChar[4]=B00000;
  NewChar[5]=B00000;
  NewChar[6]=B00000;
  NewChar[7]=B11111;
  lcd.createChar(3, NewChar);

  NewChar[0]=B11100;
  NewChar[1]=B00100;
  NewChar[2]=B00111;
  NewChar[3]=B00001;
  NewChar[4]=B00001;
  NewChar[5]=B00111;
  NewChar[6]=B00100;
  NewChar[7]=B11100;
  lcd.createChar(4, NewChar);

  NewChar[0]=B01110;
  NewChar[1]=B01010;
  NewChar[2]=B11111;
  NewChar[3]=B11111;
  NewChar[4]=B11111;
  NewChar[5]=B01110;
  NewChar[6]=B00100;
  NewChar[7]=B00100;
  lcd.createChar(5, NewChar);

  NewChar[0]=B01000;
  NewChar[1]=B10100;
  NewChar[2]=B01000;
  NewChar[3]=B01010;
  NewChar[4]=B01010;
  NewChar[5]=B00010;
  NewChar[6]=B00101;
  NewChar[7]=B00010;
  lcd.createChar(6, NewChar);

  NewChar[0]=B00100;
  NewChar[1]=B10101;
  NewChar[2]=B01110;
  NewChar[3]=B00100;
  NewChar[4]=B00100;
  NewChar[5]=B00100;
  NewChar[6]=B00100;
  NewChar[7]=B00100;
  lcd.createChar(7, NewChar);
}
//---------------------------------------------------------------------------
void setup() {
  pinMode(CONTRAST_pin,  OUTPUT);  // 
  pinMode(LED_pin,       OUTPUT);  // 
  pinMode(TX_RX_pin,     OUTPUT);  // 

  digitalWrite(TX_RX_pin, HIGH) ;  //  

  //Wirtual wire setup   
  vw_set_tx_pin(IR_RF_pin);
  vw_set_rx_pin(-1);
  vw_set_ptt_pin(-1);  
  vw_setup(3000);	           // Bits per sec   
  vw_rx_stop();
  
  // set up the LCD's number of columns and rows: 
  lcd.begin(20, 4);
  // set up the special simbol
  LCD_Char_Setup();

  // Transmitter is connected to Arduino Pin   
  mySwitch.enableTransmit(IR_RF_pin);
  //Set pulse length.
  mySwitch.setPulseLength(340); 
  mySwitch.setRepeatTransmit(4); 
  
  Contrast_HEX  = EEPROM.read(1);
  BackLight_HEX = EEPROM.read(2);
  Protocol      = EEPROM.read(3); 
  
  if (Contrast_HEX  > 16){ EEPROM.write(1, 3);  Contrast_HEX  = 3 ;}
  if (BackLight_HEX > 16){ EEPROM.write(2, 10); BackLight_HEX = 10;}
  if (Protocol > 3)      { EEPROM.write(3, 1);  Protocol      = 1 ;}
 /* 
  EEPROM.write(1, 3);  Contrast_HEX  = 3 ;
  EEPROM.write(2, 10); BackLight_HEX = 10;
  EEPROM.write(3, 1);  Protocol      = 1 ;
 */ 
  LCD_Contrast  =  Contrast_HEX*4; 
  if (BackLight_HEX == 16) LCD_BackLight = 255;
  else LCD_BackLight = BackLight_HEX*16; 
 
  
  Select_Cursor[2] = Protocol ;   
  
  analogWrite(CONTRAST_pin, LCD_Contrast );  // 0   ‚
  analogWrite(LED_pin,      LCD_BackLight);  // 255   
  
  Serial.begin(USART_USB_RATE); 
  
  kpd.setHoldTime (20) ;        // 
  kpd.setDebounceTime (10) ;    // 
   
  analogReference(INTERNAL);    // 

  ShowMenu();
}
//---------------------------------------------------------------------------
void loop() {
  if (Serial.available() > 0) Rx_Decode(); 

  msNow = millis(); 
  if ( time_Bat < msNow) Apdate_Bat();
  if ( time_Key < msNow) Key_Ask();
  if ( time_RF  < msNow) CLR_RF();
  if ( time_RS  < msNow) CLR_RS();
  if ( time_USB < msNow) CLR_USB(); 
}
//---------------------------------------------------------------------------
