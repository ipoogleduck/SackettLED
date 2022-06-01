#include <SoftwareSerial.h>

SoftwareSerial bigDisp(3,4); //HC-12 TX Pin, HC-12 RX Pin
SoftwareSerial longDisp(5,6); //HC-12 TX Pin, HC-12 RX Pin

bool longDisplay = false;

int timeSince(int lastTime) {
  return millis()-lastTime;
}

int lastSendTime = -1;

void(* resetFunc) (void) = 0; //declare reset function @ address 0

void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600); // start the comm between BLE + Arduino chips
  bigDisp.begin(9600); //Serial to HC-12
  longDisp.begin(9600); //Serial to HC-12
  pinMode(2, OUTPUT);    // sets the digital pin 2 as output
  delay(200); // wait for outputs and serial monitor to settle
}

void loop() {
  // put your main code here, to run repeatedly:
  while (bigDisp.available()) { //If HC-12 has data
    Serial.write(bigDisp.read()); //Send the data to serial moniter
  }
  while (Serial.available()) { //If Serial moniter has data
    lastSendTime = millis();
    char checkChar = Serial.read();
    if (checkChar == '&') {
      longDisplay = true;
//      Serial.write("T");
      continue;
    } else if (checkChar == '%') {
      longDisplay = false;
//      Serial.write("F");
      continue;
    } else if (checkChar == '*') {
      bigDisp.write("$*^");
      continue;
    }
    if (longDisplay) {
      longDisp.write(checkChar);
    } else {
      bigDisp.write(checkChar);
    }
//    Serial.write(checkChar);
//    Serial.write("1");
  }
  if (lastSendTime != -1 && timeSince(lastSendTime) > 15000) {
    //Reset
    bigDisp.write("$w^");
    longDisp.write("$w^");
    resetFunc();
  }
}

void performFunction(char tempChar) {
  if (tempChar == 'A') { //Ignite
    digitalWrite(LED_BUILTIN, HIGH);
    digitalWrite(2, HIGH);
    Serial.write('Y'); //Signify success
    delay(500);
    Serial.write('Y'); //Signify success
    delay(500);
    digitalWrite(LED_BUILTIN, LOW);
    digitalWrite(2, LOW);
  } else if (tempChar == 'B') { //Check status of Ignition Slave
    Serial.write('Z');
  }
}
