// testshapes demo for RGBmatrixPanel library.
// Demonstrates the drawing abilities of the RGBmatrixPanel library.
// For 32x64 RGB LED matrix.

// WILL NOT FIT on ARDUINO UNO -- requires a Mega, M0 or M4 board

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
#define D   A3

RGBmatrixPanel matrix(A, B, C, D, CLK, LAT, OE, true, 64);

Uart Serial2 (&sercom1, 11, 12, SERCOM_RX_PAD_3, UART_TX_PAD_0);
void SERCOM1_Handler()
{
  Serial2.IrqHandler();
}

String str = "";

int16_t textX = matrix.width();

int textSize = 2;
int lastScrollTime;

int textMin() {
  return str.length() * -6 * textSize;
}

void printToDisplay(String myStr) {
  matrix.print(myStr);
  // Update display
  matrix.swapBuffers(false);
}


int buttonState = 0;
int lastButtonState = 0;
int lastButtonPress = 0; //ms of button press
int lastLightValue;

String stringRemaining = ""; //String remaining after cut due to button or delay
String fullStartString = ""; //A string of the original string sent
String stringRemainingAfterRepeat = ""; //Only used during repeats
int delayStartTime = 0; //The millis of the dely start time
int delayTime = 0; //How long in total the delay is

bool scroll = false;

bool waitingForButtonPress = false;
bool skippingNextButtonPress = false; //If allowed to skip button press in next send
int lastMessageRequestTime = 0;

int dotPosition = 0;
int dotVelocity = 1;
bool showNotification = false;
int hue = 0;
int lastNotificationUpdate = 0; //Time since last update of notification

int currentTextOffset = 0;

String bufferValues[2] = {"", ""};
bool bufferZone = false;

bool startUp = true; //Ignores requesting new string when reading startup string
//const String startup = "$f000000p15000001014516ed500p15000015081608ed50f000000p150000140815081608170815091609ed50f000000p150000150616061407150716071707140815081608170815091609ed50f000000p15000014051705130614061506160617061806130714071507160717071807130814081508160817081808140915091609170915101610ed50f000000p1500001305140517051805120613061406150616061706180619061207130714071507160717071807190712081308140815081608170818081908130914091509160917091809141015101610171015111611ed50f000000p15000013041404170418041205130514051505160517051805190511061206130614061506160617061806190620061107120713071407150716071707180719072007110812081308140815081608170818081908200812091309140915091609170918091909131014101510161017101810141115111611171115121612ed50f000000p150000120313031803190311041204130414041704180419042004100511051205130514051505160517051805190520052105100611061206130614061506160617061806190620062106100711071207130714071507160717071807190720072107100811081208130814081508160817081808190820082108110912091309140915091609170918091909200912101310141015101610171018101910131114111511161117111811141215121612171215131613ed500f000000p15000013041404170418041205130514051505160517051805190511061206130614061506160617061806190620061107120713071407150716071707180719072007110812081308140815081608170818081908200812091309140915091609170918091909131014101510161017101810141115111611171115121612ed500f000000p150000120313031803190311041204130414041704180419042004100511051205130514051505160517051805190520052105100611061206130614061506160617061806190620062106100711071207130714071507160717071807190720072107100811081208130814081508160817081808190820082108110912091309140915091609170918091909200912101310141015101610171018101910131114111511161117111811141215121612171215131613ed500f000000p15000013041404170418041205130514051505160517051805190511061206130614061506160617061806190620061107120713071407150716071707180719072007110812081308140815081608170818081908200812091309140915091609170918091909131014101510161017101810141115111611171115121612ed500f000000p150000120313031803190311041204130414041704180419042004100511051205130514051505160517051805190520052105100611061206130614061506160617061806190620062106100711071207130714071507160717071807190720072107100811081208130814081508160817081808190820082108110912091309140915091609170918091909200912101310141015101610171018101910131114111511161117111811141215121612171215131613ed500f000000^";


// the setup function runs once when you press reset or power the board
void setup() {
  Serial.begin(9600);
  Serial2.begin(9600);
  
  // Assign pins 12 & 11 SERCOM functionality
  pinPeripheral(12, PIO_SERCOM);
  pinPeripheral(11, PIO_SERCOM);

  //Button init
  pinMode(13, INPUT);
  
  //Matrix init
  matrix.begin();
  matrix.setRotation(3);

  matrix.setTextWrap(false); // Allow text to run off right edges

  readString("w");

//  readString("t4c0000x151515Testing peepeepoopoo|sr");
//  showNotification = true;
}

int timeSince(int lastTime) {
  return millis()-lastTime;
}

//void requestNewMessage() {
//  Serial2.write("O");
//  lastMessageRequestTime = millis();
//}

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
  } else if (color == '7') {
    return "151515";
  } else {
    return "000000";
  }
}

//Read string from serial
void readString(String string) {
  stringRemaining = "";
  showNotification = false;
  int length = string.length();
  int i = 0;
  Serial.println();
  while (i < length) {
    char ch = string[i];
    //Serial.print(ch);
    if (ch == 'f') {
      matrix.fillScreen(matrix.Color444((string[i+1]*10)+string[i+2], (string[i+3]*10)+string[i+4], (string[i+5]*10)+string[i+6]));
      i += 6;
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
    } else if (ch == 'M') { //Fast bloack layout
      for (int j = 0; j < 10; j++) {
        i++;
        int yCord = 0;
        while (string[i] != 'e') {
          char colorInt = string[i];
          String color = colorForInt(colorInt);
          String colors[3] = {String(color[0])+color[1], String(color[2])+color[3], String(color[4])+color[5]};
          matrix.fillRect((j*3)+1, ((20-yCord-1)*3)+2, 3, 3, matrix.Color444(colors[0].toInt(), colors[1].toInt(), colors[2].toInt()));
          yCord++;
          i++;
        }
      }
    }else if (ch == 'C') { //One block in tetris
      char colorInt = string[i+1];
      String color = colorForInt(colorInt);
      String colors[3] = {String(color[0])+color[1], String(color[2])+color[3], String(color[4])+color[5]};
      i += 2;
      int timeNow = millis();
      String bufferValue = "";
      while ((string[i] != 'e' && string[i] != 'z' && string[i] != 'y') && timeSince(timeNow) < 10000) {
        String cords[2] = {String(string[i]), String(string[i+1])+string[i+2]};
        bufferValue += cords[0] + cords[1];
        matrix.fillRect(((cords[0].toInt())*3)+1, (cords[1].toInt()*3)+2, 3, 3, matrix.Color444(colors[0].toInt(), colors[1].toInt(), colors[2].toInt()));
        i += 3;
      }
      if (string[i] == 'z') {
        bufferValues[bufferZone] = bufferValue;
      }
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
    } else if (ch == 'D') { //Draw boarder
      matrix.drawRect(0, 0, 32, 64, matrix.Color444(2, 2, 2));
      matrix.drawRect(0, 1, 32, 62, matrix.Color444(2, 2, 2));
    } else if (ch == '*') { //Gets this during endgame
      String endString = "d1000";
      for (int j = 0; j < 20; j++) {
        String cords = j < 10 ? "0" + String(j) : String(j);
        endString += "E" + cords + "171Bd200";
      }
      //endString += "d700f000000B";
      readString(endString);
    } else if (ch == 'E') { //Reads engame chars
      int y = (String(string[i+1])+string[i+2]).toInt();
      i += 2;
      for (int j = 0; j < 3; j++) {
        i++;
        char colorInt = string[i];
        String color = colorForInt(colorInt);
        String colors[3] = {String(color[0])+color[1], String(color[2])+color[3], String(color[4])+color[5]};
        matrix.fillRect(1,(y*3)+j+2, 30, 1, matrix.Color444(colors[0].toInt(), colors[1].toInt(), colors[2].toInt()));
      }
    }else if (ch == 'b') {
      matrix.swapBuffers(false);
      bufferZone = !bufferZone;
      String lastBuffer = bufferValues[bufferZone];
      if (lastBuffer != "") {
        readString("C9" + lastBuffer + "y");
        bufferValues[bufferZone] = "";
      }
    } else if (ch == 'B') {
      bufferValues[!bufferZone] = "";
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
    } else if (ch == 'R') {
      i++;
      if (string[i] == '0') {
        matrix.setRotation(0);
      } else {
        matrix.setRotation(3);
      }
    } else if (ch == 'w') {
      String string1 = "f000000Bt1c0400x151515Play|Bd500t1c0010x150000T|t1150200E|p00000010101016et1c1110x150700T|t1001500R|t1c2210x001515I|t1c2710x080015S|Bd500t2c0420x151515On|Bd500t1c0437x151515This|Bd500t2c0147x151515B|t2c1147x151515I|t2c2147x151515G|Bd500f000000R0t4c0000x151515DISPLAY|sR3";
      String string2 = "f000000DBd50C2300301400500zbd50C2301302401501zbd50C2300400401402zbd50C2301401500501zbd50C2302402501502zbd50C2202302401402zbd50C2102202301302zbd50C2103203302303zbd50C2003103202203zbd50C2004104203204zbd50C2005105204205zbd50C2006106205206zbd50C2007107206207zbd50C2008108207208zbd50C2009109208209zbd50C2010110209210zbd50C2011111210211zbd50C2012112211212zbd50C2013113212213zbd50C2014114213214zbd50C2015115214215zbd50C2016116215216zbd50C2017117216217zbd50C2018118217218zbd50C2019119218219zbd50C2019119218219eBd50C5300400401500zbd50C5300400401zbd50C5300400500zbd50C5400500600zbd50C5401500501601zbd50C5501600601701zbd50C5601700701801zbd50C5701800801901zbd50C5702801802902zbd50C5703802803903zbd50C5704803804904zbd50C5705804805905zbd50C5706805806906zbd50C5707806807907zbd50C5708807808908zbd50C5709808809909zbd50C5710809810910zbd50C5711810811911zbd50C5712811812912zbd50C5713812813913zbd50C5714813814914zbd50C5715814815915zbd50C5716815816916zbd50C5717816817917zbd50C5718817818918zbd50C5719818819919zbd50C5719818819919eBd50C6300400401501zbd50C6301401402502zbd50C6401402500501zbd50C6501502600601zbd50C6601602700701zbd50C6602603701702zbd50C6603604702703zbd50C6604605703704zbd50C6605606704705zbd50C6606607705706zbd50C6607608706707zbd50C6608609707708zbd50C6609610708709zbd50C6610611709710zbd50C6611612710711zbd50C6612613711712zbd50C6613614712713zbd50C6614615713714zbd50C6615616714715zbd50C6616617715716zbd50C6617618716717zbd50C6618619717718zbd50C6618619717718eBd50C5300400401500zbd50C5300400401zbd50C5301400401402zbd50C5301400401501zbd50C5401500501601zbd50C5402501502602zbd50C5403502503603zbd50C5404503504604zbd50C5405504505605zbd50C5406505506606zbd50C5407506507607zbd50C5408507508608zbd50C5409508509609zbd50C5410509510610zbd50C5411510511611zbd50C5412511512612zbd50C5413512513613zbd50C5414513514614zbd50C5415514515615zbd50C5315414415515zbd50C5316415416516zbd50C5317416417517zbd50C5318417418518zbd50C5319418419519zbd50C5319418419519eBd50f000000DMee2ee5ee6e66e5eeBd50C2300301400500zbd50C2301302401501zbd50C2302303402502zbd50C2303304403503zbd50C2304305404504zbd50C2303403404405zbd50C2304404503504zbd50C2305405504505zbd50C2404405406506zbd50C2304305306406zbd50C2204205206306zbd50C2104105106206zbd50C2004005006106zbd50C2005006007107zbd50C2006007008108zbd50C2007008009109zbd50C2008009010110zbd50C2009010011111zbd50C2010011012112zbd50C2011012013113zbd50C2012013014114zbd50C2013014015115zbd50C2014015016116zbd50C2015016017117zbd50C2016017018118zbd50C2017018019119zbd50C2017018019119eBr"; 
      fullStartString = string1 + string2;
      readString(fullStartString);
    }
    i++;
    if (i == length) {
      if (startUp) {
        startUp = false;
      } else {
//        Serial.println("Done with String, Requesting next value");
//        requestNewMessage();
      }
    }
  }
}


// the loop function runs over and over again forever
void loop() {
  if (Serial2.available()){
    int value = Serial2.read();
    char ch = (char)value;
    Serial.print(ch);
    if (ch == '$') {
      scroll = false;
      stringRemainingAfterRepeat = "";
      matrix.setRotation(3);
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
  if (scroll && timeSince(lastScrollTime) > 0) {
    matrix.fillScreen(0);
    matrix.setCursor(textX, 1);
    printToDisplay(str);
    lastScrollTime = millis();
    if((--textX) < textMin())  {
      readString(stringRemaining);
      scroll = false;
    }
  }
  //Delay code
  if (stringRemaining != "" && !scroll && timeSince(delayStartTime) >= delayTime && !waitingForButtonPress) {
    readString(stringRemaining);
  }
}
