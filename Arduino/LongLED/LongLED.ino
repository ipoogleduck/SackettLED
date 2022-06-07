// scrolltext demo for Adafruit RGBmatrixPanel library.
// Demonstrates double-buffered animation on our 16x32 RGB LED matrix:
// http://www.adafruit.com/products/420
// DOUBLE-BUFFERED ANIMATION DOES NOT WORK WITH ARDUINO UNO or METRO 328.

// Written by Limor Fried/Ladyada & Phil Burgess/PaintYourDragon
// for Adafruit Industries.
// BSD license, all text above must be included in any redistribution.

#include <Arduino.h>   // required before wiring_private.h
#include "wiring_private.h" // pinPeripheral() function
#include <RGBmatrixPanel.h>

// Most of the signal pins are configurable, but the CLK pin has some
// special constraints.  On 8-bit AVR boards it must be on PORTB...
// Pin 11 works on the Arduino Mega.  On 32-bit SAMD boards it must be
// on the same PORT as the RGB data pins (D2-D7)...
// Pin 8 works on the Adafruit Metro M0 or Arduino Zero,
// Pin A4 works on the Adafruit Metro M4 (if using the Adafruit RGB
// Matrix Shield, cut trace between CLK pads and run a wire to A4).

#define CLK  8   // USE THIS ON ADAFRUIT METRO M0, etc.
//#define CLK A4 // USE THIS ON METRO M4 (not M0)
//#define CLK 11 // USE THIS ON ARDUINO MEGA
#define OE   9
#define LAT 10
#define A   A0
#define B   A1
#define C   A2

// Last parameter = 'true' enables double-buffering, for flicker-free,
// buttery smooth animation.  Note that NOTHING WILL SHOW ON THE DISPLAY
// until the first call to swapBuffers().  This is normal.
RGBmatrixPanel matrix(A, B, C, CLK, LAT, OE, true);

Uart Serial2 (&sercom1, 11, 12, SERCOM_RX_PAD_3, UART_TX_PAD_0);
void SERCOM1_Handler()
{
  Serial2.IrqHandler();
}

// Similar to F(), but for PROGMEM string pointers rather than literals
#define F2(progmem_ptr) (const __FlashStringHelper *)progmem_ptr

String str = "KISS YOUR HOMIES GOODNIGHT";
int16_t textX = matrix.width(), hue = 0;

String stringRemaining = ""; //String remaining after cut due to button or delay
String fullStartString = ""; //A string of the original string sent
String stringRemainingAfterRepeat = ""; //Only used during repeats
int delayStartTime = 0; //The millis of the dely start time
int delayTime = 0; //How long in total the delay is

bool scroll = false;

int textSize = 2;
int lastScrollTime;

int currentTextOffset = 0;

void setup() {
  Serial.begin(9600);
  Serial2.begin(9600);

  // Assign pins 12 & 11 SERCOM functionality
  pinPeripheral(12, PIO_SERCOM);
  pinPeripheral(11, PIO_SERCOM);
  
  matrix.begin();
  matrix.setTextWrap(false); // Allow text to run off right edge
  matrix.setTextSize(2);
  
  readString("w");
  
}

int textMin() {
  return str.length() * -12;
}

char readSerial2() {
  int value = Serial2.read();
  return (char)value;
}

int timeSince(int lastTime) {
  return millis()-lastTime;
}



String colorForInt(char color) {
  if (color == '0') {
    return "030315";
  } else if (color == '1') {
    return "000015";
  } else if (color == '2') {
    return "150200";
  } else if (color == '3') {
    return "150700";
  } else if (color == '4') {
    return "001500";
  } else if (color == '5') {
    return "080015";
  } else if (color == '6') {
    return "150000";
  } else {
    return "000000";
  }
}

//Read string from serial
void readString(String string) {
  stringRemaining = "";
  int length = string.length();
  int i = 0;
  Serial.println();
  while (i < length) {
    char ch = string[i];
    //Serial.print(ch);
    if (ch == 'f') {
      matrix.fillScreen(matrix.Color444((string[i+1]*10)+string[i+2], (string[i+3]*10)+string[i+4], (string[i+5]*10)+string[i+6]));
      i += 6;
      matrix.swapBuffers(true);
    } else if (ch == 'p') {
      //
      String colors[3] = {String(string[i+1])+string[i+2], String(string[i+3])+string[i+4], String(string[i+5])+string[i+6]};
      i += 7;
      int timeNow = millis();
      while (string[i] != 'e' && timeSince(timeNow) < 10000) {
        String cords[2] = {String(string[i])+string[i+1], String(string[i+2])+string[i+3]};
        matrix.drawPixel(cords[0].toInt(), cords[1].toInt(), matrix.Color444(colors[0].toInt(), colors[1].toInt(), colors[2].toInt()));
        i += 4;
      }
//    } else if (ch == 'C') {
//      char colorInt = string[i+1];
//      String color = colorForInt(colorInt);
//      String colors[3] = {String(color[0])+color[1], String(color[2])+color[3], String(color[4])+color[5]};
//      i += 2;
//      int timeNow = millis();
//      String bufferValue = "";
//      while ((string[i] != 'e' && string[i] != 'z' && string[i] != 'y') && timeSince(timeNow) < 10000) {
//        String cords[2] = {String(string[i]), String(string[i+1])+string[i+2]};
//        bufferValue += cords[0] + cords[1];
//        matrix.fillRect((cords[1].toInt()*3)+2, 31-((cords[0].toInt()+1)*3), 3, 3, matrix.Color444(colors[0].toInt(), colors[1].toInt(), colors[2].toInt()));
//        i += 3;
//      }
//      if (string[i] == 'z') {
//        bufferValues[bufferZone] = bufferValue;
//      }
    } else if (ch == 't') {
      textSize = String(string[i+1]).toInt();
      matrix.setTextSize(textSize);   // size 1 == 8 pixels high
      i+=2;
      if (string[i] == 'c') { //Set cursor if needed
        int x = (String(string[i+1])+string[i+2]).toInt();
        int y = (String(string[i+3])+string[i+4]).toInt();
        if (string[i+5] == 'x') {
          x += currentTextOffset;
          i+=1;
        } else if (string[i+5] == 'y') {
          y += currentTextOffset;
          i+=1;
        }
        String cords[2] = {String(x),String(y)};
        matrix.setCursor(cords[0].toInt(), cords[1].toInt());
        i+=5;
      }
      String colors[3] = {String(string[i])+string[i+1], String(string[i+2])+string[i+3], String(string[i+4])+string[i+5]};
      matrix.setTextColor(matrix.Color444(colors[0].toInt(), colors[1].toInt(), colors[2].toInt()));
      i += 6;
      int timeNow = millis();
      str = "";
      while (string[i] != '|' && timeSince(timeNow) < 5000) {
        matrix.print(string[i]);
        str += string[i];
        i++;
      }
      
    } else if (ch == 'S') {
      int timeNow = millis();
      String score = "";
      i++;
      while (string[i] != 'e' && timeSince(timeNow) < 2000) {
        score += string[i];
        i++;
      }
      matrix.fillRect(0, 0, 35, 16, matrix.Color444(0,0,0));
      readString("t1c0000x151515Score|t1c0008x151515" + score + "|B");
    } else if (ch == 'L') {
      int timeNow = millis();
      String level = "";
      i++;
      while (string[i] != 'e' && timeSince(timeNow) < 2000) {
        level += string[i];
        i++;
      }
      matrix.fillRect(35, 0, 16, 16, matrix.Color444(0,0,0));
      readString("t1c3500x151515Lv|");
      if (level.length() == 1) {
        readString("t1c3808x151515" + level + "|B");
      } else {
        readString("t1c3508x151515" + level + "|B");
      }
    } else if (ch == 'N') {
      matrix.fillRect(48, 0, 16, 16, matrix.Color444(0,0,0));
      for (int j = 0; j < 2*4; j++) {
        i++;
        char colorInt = string[i];
        String color = colorForInt(colorInt);
        String colors[3] = {String(color[0])+color[1], String(color[2])+color[3], String(color[4])+color[5]};
        matrix.fillRect(48+((j/2)*4), 4+((j%2)*4), 4, 4, matrix.Color444(colors[0].toInt(), colors[1].toInt(), colors[2].toInt()));
      }
      matrix.swapBuffers(true);
    } else if (ch == 's') {
      textX = matrix.width();
      lastScrollTime = millis();
      scroll = true;
      String newString = string;
      newString.remove(0, i+1);
      stringRemaining = newString;
      return;
    } else if (ch == 'd') {
      i++;
      String delayString = "";
      int timeNow = millis();
      while (isDigit(string[i]) && timeSince(timeNow) < 5000) {
        delayString += String(string[i]);
        i++;
      }
      delayStartTime = millis();
      delayTime = delayString.toInt();
      String newString = string;
      newString.remove(0, i);
      stringRemaining = newString;
      Serial.print("String remaining:");
      Serial.println(newString);
      return;
      //delay(delayString.toInt());
    } else if (ch == 'b') {
      matrix.swapBuffers(false);
//      bufferZone = !bufferZone;
//      String lastBuffer = bufferValues[bufferZone];
//      if (lastBuffer != "") {
//        readString("C9" + lastBuffer + "y");
//        bufferValues[bufferZone] = "";
//      }
    } else if (ch == 'B') {
//      bufferValues[!bufferZone] = "";
      matrix.swapBuffers(true);
    } else if (ch == 'r') {
      stringRemaining = fullStartString;
      delayStartTime = millis();
      delayTime = 0;
      String newString = string;
      newString.remove(0, i+1);
      stringRemainingAfterRepeat = newString;
      Serial.print("String remaining for repeat:");
      Serial.println(newString);
      return;
    } else if (ch == 'w') {
//      fullStartString = "t2c0000x151515Search for Sackett LED on the App Store|sr";
      fullStartString = "f000000t1c0800x121212Download|t1c0009x151515SACKETT|t1c4708x151515LED|Bd2000f000000t1c1400x151515On The|t1c0508x030315App Store|Bd2000f000000t1c1104x151515To Play|Bd2000r";
      readString(fullStartString);
    }
    i++;
//    if (i == length) {
//      if (startUp) {
//        startUp = false;
//      } else {
//        Serial.println("Done with String, Requesting next value");
//        requestNewMessage();
//      }
//    }
  }
}

void loop() {

  if (Serial2.available()){
    int value = Serial2.read();
    char ch = (char)value;
    Serial.print(ch);
    if (ch == '$') {
      scroll = false;
      stringRemainingAfterRepeat = "";
      String data = "";
      int timeNow = millis();
      while (ch != '^' && timeSince(timeNow) < 10000) {
        if (Serial2.available()){
          value = Serial2.read();
          ch = (char)value;
          //Serial.print(ch);
          if (ch != '^') {
            data += ch;
          }
        } else {
          delay(10);
        }
      }
      if (timeSince(timeNow) >= 10000) {
        Serial.println("Error, string never finished");
      } else {
        Serial.print(data);
        fullStartString = data;
        readString(data);
        Serial.println();
      }
    }
  }
  if (scroll && timeSince(lastScrollTime) > 30) {
    matrix.fillScreen(0);
    matrix.setCursor(textX, 1);
    matrix.print(str);
    matrix.swapBuffers(false);
    lastScrollTime = millis();
    if((--textX) < textMin())  {
      readString(stringRemaining);
      scroll = false;
    }
  }
  //Delay code
  if (stringRemaining != "" && !scroll && timeSince(delayStartTime) >= delayTime) {
    readString(stringRemaining);
  }
}
