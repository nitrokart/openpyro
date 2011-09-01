/*
  RCSwitch - Arduino libary for remote control outlet switches
  Copyright (c) 2011 Suat Özgür.  All right reserved.
  
  Contributors:
  - Gordeev Andrey Vladimirovich / gordeev(at)openpyro(dot)com
  
  Project home: http://code.google.com/p/rc-switch/

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#include "RCSwitch.h"

RCSwitchCallback RCSwitch::mCallback;


RCSwitch::RCSwitch() {
  this->nReceiverInterrupt = -1;
  this->nTransmitterPin = -1;
  this->setPulseLength(350);
  this->setRepeatTransmit(10);
}

/**
 * deprecated
 */
RCSwitch::RCSwitch(int nTransmitterPin) {
  this->enableTransmit(nTransmitterPin);
  this->setPulseLength(350);
  this->setRepeatTransmit(10);
}

/**
 * deprecated
 */
RCSwitch::RCSwitch(int nTransmitterPin, int nDelay) {
  this->enableTransmit(nTransmitterPin);
  this->setPulseLength(nDelay);
  this->setRepeatTransmit(10);
}

/**
  * Sets pulse length in microseconds
  */
void RCSwitch::setPulseLength(int nPulseLength) {
  this->nPulseLength = nPulseLength;
}

/**
  * Sets Repeat Transmits
  */
void RCSwitch::setRepeatTransmit(int RepeatTransmit) {
  this->RepeatTransmit = RepeatTransmit;
}

/**
 * Enable transmissions
 *
 * @param nTransmitterPin    Arduino Pin to which the sender is connected to
 */
void RCSwitch::enableTransmit(int nTransmitterPin) {
  this->nTransmitterPin = nTransmitterPin;
  pinMode(this->nTransmitterPin, OUTPUT);
}

/**
  * Disable transmissions
  */
void RCSwitch::disableTransmit() {
  this->nTransmitterPin = -1;
}

/**
 * Switch a remote switch on (Type C Intertechno)
 *
 * @param sFamily  Familycode (a..f)
 * @param nGroup   Number of group (1..4)
 * @param nDevice  Number of device (1..4)
  */
void RCSwitch::switchOn(char sFamily, int nGroup, int nDevice) {
  this->sendTriState( this->getCodeWordC(sFamily, nGroup, nDevice, true) );
}

/**
 * Switch a remote switch off (Type C Intertechno)
 *
 * @param sFamily  Familycode (a..f)
 * @param nGroup   Number of group (1..4)
 * @param nDevice  Number of device (1..4)
 */
void RCSwitch::switchOff(char sFamily, int nGroup, int nDevice) {
  this->sendTriState( this->getCodeWordC(sFamily, nGroup, nDevice, false) );
}

/**
 * Switch a remote switch on (Type B with two rotary/sliding switches)
 *
 * @param nAddressCode  Number of the switch group (1..4)
 * @param nChannelCode  Number of the switch itself (1..4)
 */
void RCSwitch::switchOn(int nAddressCode, int nChannelCode) {
  this->sendTriState( this->getCodeWordB(nAddressCode, nChannelCode, true) );
}

/**
 * Switch a remote switch off (Type B with two rotary/sliding switches)
 *
 * @param nAddressCode  Number of the switch group (1..4)
 * @param nChannelCode  Number of the switch itself (1..4)
 */
void RCSwitch::switchOff(int nAddressCode, int nChannelCode) {
  this->sendTriState( this->getCodeWordB(nAddressCode, nChannelCode, false) );
}

/**
 * Switch a remote switch on (Type A with 10 pole DIP switches)
 *
 * @param sGroup        Code of the switch group (refers to DIP switches 1..5 where "1" = on and "0" = off, if all DIP switches are on it's "11111")
 * @param nChannelCode  Number of the switch itself (1..4)
 */
void RCSwitch::switchOn(String sGroup, int nChannel) {
  this->sendTriState( this->getCodeWordA(sGroup, nChannel, true) );
}

/**
 * Switch a remote switch off (Type A with 10 pole DIP switches)
 *
 * @param sGroup        Code of the switch group (refers to DIP switches 1..5 where "1" = on and "0" = off, if all DIP switches are on it's "11111")
 * @param nChannelCode  Number of the switch itself (1..4)
 */
void RCSwitch::switchOff(String sGroup, int nChannel) {
  this->sendTriState( this->getCodeWordA(sGroup, nChannel, false) );
}

/**
 * Returns a String[13], representing the Code Word to be send. 
 * A Code Word consists of 9 address bits, 3 data bits and one sync bit but in our case only the first 8 address bits and the last 2 data bits were used.
 * A Code Bit can have 4 different states: "F" (floating), "0" (low), "1" (high), "S" (synchronous bit)
 *
 * +-------------------------------+--------------------------------+-----------------------------------------+-----------------------------------------+----------------------+------------+
 * | 4 bits address (switch group) | 4 bits address (switch number) | 1 bit address (not used, so never mind) | 1 bit address (not used, so never mind) | 2 data bits (on|off) | 1 sync bit |
 * | 1=0FFF 2=F0FF 3=FF0F 4=FFF0   | 1=0FFF 2=F0FF 3=FF0F 4=FFF0    | F                                       | F                                       | on=FF off=F0         | S          |
 * +-------------------------------+--------------------------------+-----------------------------------------+-----------------------------------------+----------------------+------------+
 * 
 * @param nAddressCode  Number of the switch group (1..4)
 * @param nChannelCode  Number of the switch itself (1..4)
 * @param bStatus       Wether to switch on (true) or off (false)
 * 
 * @return String[13]
 */
String RCSwitch::getCodeWordB(int nAddressCode, int nChannelCode, boolean bStatus) {
   String code[5] = { "FFFF", "0FFF", "F0FF", "FF0F", "FFF0" };

   if (nAddressCode < 1 || nAddressCode > 4 || nChannelCode < 1 || nChannelCode > 4) {
    return "";
   }

   return code[nAddressCode] + code[nChannelCode] + "FF" + (bStatus==true?"FF":"F0");
}

/**
 * Like getCodeWord  (Type A)
 */
String RCSwitch::getCodeWordA(String sGroup, int nChannelCode, boolean bStatus) {
  String code[6] = { "FFFFF", "0FFFF", "F0FFF", "FF0FF", "FFF0F", "FFFF0" };

  if (sGroup.length() != 5 || nChannelCode < 1 || nChannelCode > 5) {
    return "";
  }
  
  String sAddressCode = "";
  for (int i = 0; i<5; i++) {
    if (sGroup[i] == '0') {
      sAddressCode += "F";
    } else {
      sAddressCode += "0";
    }
  }
  
  return sAddressCode + code[nChannelCode] + (bStatus==true?"0F":"F0");
}

/**
 * Like getCodeWord (Type C = Intertechno)
 */
String RCSwitch::getCodeWordC(char sFamily, int nGroup, int nDevice, boolean bStatus) {
  if ( (byte)sFamily < 97 || (byte)sFamily > 112) {
    return "";
  }
  if (nGroup < 1 || nGroup > 4 || nDevice < 1 || nDevice > 4) {
    return "";
  }
  char* sDeviceGroupCode =  dec2binWzerofill(  (nDevice-1) + (nGroup-1)*4, 4  );
  String familycode[16] = { "0000", "F000", "0F00", "FF00", "00F0", "F0F0", "0FF0", "FFF0", "000F", "F00F", "0F0F", "FF0F", "00FF", "F0FF", "0FFF", "FFFF" };
  String sReturn = familycode[ (int)sFamily - 97 ];
  for (int i = 0; i<4; i++) {
    sReturn = sReturn + (sDeviceGroupCode[3-i] == '1' ? "F" : "0");
  }
  sReturn = sReturn + "0F";
  sReturn = sReturn + (bStatus==true?"FF":"F0");
  return sReturn;
}

/**
 * Sends a Code Word 
 * @param sCodeWord   /^[10FS]*$/  -> see getCodeWord
 */
void RCSwitch::sendTriState(String sCodeWord) {
  for (int nRepeat=0; nRepeat<RepeatTransmit; nRepeat++) {
    for(int i=0; i<sCodeWord.length(); i++) {
      switch(sCodeWord[i]) {
        case '0':
          this->sendT0();
        break;
        case 'F':
          this->sendTF();
        break;
        case '1':
          this->sendT1();
        break;
      }
    }
    this->sendSync();    
  }
}

void RCSwitch::send(unsigned long Code, unsigned int length) {
  this->send( this->dec2binWzerofill(Code, length) );
}

void RCSwitch::send(char* sCodeWord) {
  for (int nRepeat=0; nRepeat<RepeatTransmit; nRepeat++) {
    int i = 0;
    while (sCodeWord[i] != '\0') {
      switch(sCodeWord[i]) {
        case '0':
          this->send0();
        break;
        case '1':
          this->send1();
        break;
      }
      i++;
    }
    this->sendSync();
  }
}

void RCSwitch::transmit(int nHighPulses, int nLowPulses) {
  
  if (this->nTransmitterPin != -1) {
    int nRec = this->nReceiverInterrupt;
    if (this->nReceiverInterrupt != -1) {
      this->disableReceive();
    }
    digitalWrite(this->nTransmitterPin, HIGH);
    delayMicroseconds( this->nPulseLength * nHighPulses);
    digitalWrite(this->nTransmitterPin, LOW);
    delayMicroseconds( this->nPulseLength * nLowPulses);
    if (nRec != -1) {
      this->enableReceive(nRec, this->mCallback);
    }
  }
}

/**
 * Sends a "0" Bit
 *            _    
 * Waveform: | |___
 */
void RCSwitch::send0() {
  this->transmit(1,3);
}

/**
 * Sends a "1" Bit
 *            ___  
 * Waveform: |   |_
 */
void RCSwitch::send1() {
  this->transmit(3,1);
}


/**
 * Sends a Tri-State "0" Bit
 *            _     _
 * Waveform: | |___| |___
 */
void RCSwitch::sendT0() {
  this->transmit(1,3);
  this->transmit(1,3);
}

/**
 * Sends a Tri-State "1" Bit
 *            ___   ___
 * Waveform: |   |_|   |_
 */
void RCSwitch::sendT1() {
  this->transmit(3,1);
  this->transmit(3,1);
}

/**
 * Sends a Tri-State "F" Bit
 *            _     ___
 * Waveform: | |___|   |_
 */
void RCSwitch::sendTF() {
  this->transmit(1,3);
  this->transmit(3,1);
}

/**
 * Sends a "Sync" Bit
 *            _ 
 * Waveform: | |_______________________________
 */
void RCSwitch::sendSync() {
  this->transmit(1,31);
}

/**
 * Enable receiving data
 */
void RCSwitch::enableReceive(int interrupt, RCSwitchCallback callback) {
  this->nReceiverInterrupt = interrupt;
  attachInterrupt(this->nReceiverInterrupt, receiveInterrupt, CHANGE);
  this->mCallback = callback;
}

/**
 * Disable receiving data
 */
void RCSwitch::disableReceive() {
  detachInterrupt(this->nReceiverInterrupt);
  this->nReceiverInterrupt = -1;
}

/**
 * 
 */
void RCSwitch::receiveInterrupt() {

  static unsigned int duration;
  static unsigned int changeCount;
  static unsigned int timings[RCSWITCH_MAX_CHANGES];
  static unsigned long lastTime;
  static unsigned int repeatCount;
  

  long time = micros();
  duration = time - lastTime;
 
  if (duration > 5000 && duration > timings[0] - 200 && duration < timings[0] + 200) {
    repeatCount++;
    changeCount--;
    if (repeatCount == 2) {
    
      unsigned long code = 0;
      unsigned long delay = timings[0] / 31;
      unsigned long delayTolerance = delay*0.3;    
      for (int i = 1; i<changeCount ; i=i+2) {
      
          if (timings[i] > delay-delayTolerance && timings[i] < delay+delayTolerance && timings[i+1] > delay*3-delayTolerance && timings[i+1] < delay*3+delayTolerance) {
            code = code << 1;
          } else if (timings[i] > delay*3-delayTolerance && timings[i] < delay*+delayTolerance && timings[i+1] > delay-delayTolerance && timings[i+1] < delay+delayTolerance) {
            code+=1;
            code = code << 1;
          } else {
            // Failed
            i = changeCount;
            code = 0;
            repeatCount = 0;
          }
      }      
      code = code >> 1;
      (mCallback)(code, changeCount/2, delay, timings);
      repeatCount = 0;
    }
    changeCount = 0;
  } else if (duration > 5000) {
    changeCount = 0;
  }
 
  if (changeCount >= RCSWITCH_MAX_CHANGES) {
    changeCount = 0;
    repeatCount = 0;
  }
  timings[changeCount++] = duration;
  lastTime = time;  
}

/**
  * Turns a decimal value to its binary representation
  */
char* RCSwitch::dec2binWzerofill(unsigned long Dec, unsigned int bitLength){
  static char bin[64]; 
  unsigned int i=0;

  while (Dec > 0) {
    bin[32+i++] = (Dec & 1 > 0) ? '1' : '0';
    Dec = Dec >> 1;
  }

  for (unsigned int j = 0; j< bitLength; j++) {
    if (j >= bitLength - i) {
      bin[j] = bin[ 31 + i - (j - (bitLength - i)) ];
    }else {
      bin[j] = '0';
    }
  }
  bin[bitLength] = '\0';
  
  return bin;
}

