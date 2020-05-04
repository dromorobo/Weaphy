/*
      Program : Weaphy.ino
      Version : 0.1
  Description : Weaphy Robot Core Program
     Platform : Arduino IDE
       Author : R. Bliek
         Date : 22-06-2018
*/

#include <SoftwareSerial.h>

#define DEBUG 1

// Hardware Serial
// D00 RX
// D01 TX

// D02

// Leaphy L298P Buzzer
#define BUZZER       4

// Leayphy LED
#define LED_BLUE     3
#define LED_GREEN    5
#define LED_RED      6

// Leaphy Ultrasone
#define US_ECHO      8   
#define US_TRIG      7

// D09 

// Leaphy L298P Motor A/B
#define L298P_MA_SPEED 10 // D10 L298P Motor A PWM Speed control
#define L298P_MA_DIR   12//  D12 L298P Motor A Direction
#define L298P_MB_SPEED 11 // D11 L298P Motor B PWM Speed control
#define L298P_MB_DIR   13 // D13 L298P Motor B Direction

// Leaphy mySerial for ESP
#define SER_RX  14
#define SER_TX  15
#define SER_BPS 9600

#define CMD_FORWARD  "forward"
#define CMD_BACK     "backward"
#define CMD_LEFT     "left"
#define CMD_RIGHT    "right"
#define CMD_LED      "led"
  #define PRM_LED_RED    "red"
  #define PRM_LED_GREEN  "green"
  #define PRM_LED_BLUE   "blue"
#define CMD_STOP     "stop"
#define CMD_START    "start"   

#define CMD_GET      "get"
#define CMD_SET      "set"

#define CMD_SEND     "send"

#define CMD_NETWORK  "network"

#define CMD_LENGTH 20

#define SPD_MIN 70   // minimum pwm speed (motor requires minimum pwm for movement)
#define SPD_MAX 255  // max = 255
#define SPD_INC 10   // increments
        
SoftwareSerial mySerial(SER_RX, SER_TX);

uint8_t led_red, led_blue, led_green; // LED
bool    spd_forward;    // speed-direction
uint8_t spd_left, spd_right; // pwm speed left/right 0 - 255
                        
String getValue(String data, int nr)
{
  int found;
  int prmBase;
  int prmEnd;
  int curChr;
  int strEnd;
  char chrread;
  boolean eol,rdy;

  found = 0;
  prmBase = 0;
  prmEnd = 0;
  curChr= 0;
  strEnd = data.length()-1;
  
  while ((curChr < strEnd) && (found < nr))
  { // There are still characters in data to examine

    chrread = data.charAt(curChr);
    eol = ((curChr >= strEnd) || (chrread == '\n') || (chrread == '\r'));
    
    while ((chrread ==' ') && (!eol))
    { // Discard spaces
      curChr++;
      chrread = data.charAt(curChr);
      eol = ((curChr >= strEnd) || (chrread == '\n') || (chrread == '\r'));
    }

    // prmBase points to the first non-space and/or nothing more to examine

    if (!eol)
    { // There is a parameter found, try to find the end of it
      found++;
      prmBase = curChr;
      prmEnd = prmBase + 1;
      
      chrread = data.charAt(prmEnd);
      eol = ((prmEnd >= strEnd) || (chrread == '\n') || (chrread == '\r'));
      
      while ((chrread != ' ') && (!eol))
      { // try to find the end of the paramter, one chr at a a time
        prmEnd++;
        chrread = data.charAt(prmEnd);
        eol = ((prmEnd >= strEnd) || (chrread == '\n') || (chrread == '\r'));
      }
    }
    
    // prmBase points to first character, and
    // prmEnd points to the next space OR EOL   

    curChr=prmEnd+1;
  }

  if (found == nr)
  {
    return data.substring(prmBase,prmEnd);
  }
  else
  {
    return "";
  }
}  

String readline()
{
  bool eol;
  char rdchar;
  String data = "";
  
  eol = false;

  while (!mySerial.available())
  {
    // Wait for something to appear on serial
  }
  
  do
  {
    if (mySerial.available())
    {
      rdchar = mySerial.read();

      // QaD: first check if it is (part of) Orion protocol [FF 55 00 04 07 data]
      if (rdchar == 0xff)
      { // Suspect orion-packet found
        if (mySerial.available())
        {
          rdchar = mySerial.read();
          if (rdchar == 0x55)
          { // Assume orion-packet found, discard preamble (3 octets), and read next
            for (int i = 0; i <= 3; i++)
            {
              if (mySerial.available())
              {
                rdchar = mySerial.read();
              }
            }
          }
        }
      }
      // End of QaD 
      
      data.concat(rdchar);
      delay(3);
    }
  }
  while ((rdchar != '\r') && (rdchar != '\n'));
  
  return data;
}

void setspeed()
{ // Set direction and speed of motors
  if (spd_forward)
  { // going forward
    digitalWrite(L298P_MA_DIR, HIGH);
    digitalWrite(L298P_MB_DIR, HIGH);
  }
  else
  { // going backward
    digitalWrite(L298P_MA_DIR, LOW);
    digitalWrite(L298P_MB_DIR, LOW);
  }
 
  // Set speed motors
  analogWrite(L298P_MA_SPEED, spd_left);
  analogWrite(L298P_MB_SPEED, spd_right);  
}

void backward()
{ // Go backward at minimum speed
  spd_forward = false;
  spd_left  = SPD_MIN;
  spd_right = SPD_MIN;
  setspeed();
}

void forward()
{ // Go forward at minimum speed
  spd_forward = true;
  spd_left  = SPD_MIN;
  spd_right = SPD_MIN;  
  setspeed();
}

void left()
{ // Turn left, by decrasing speed left motor OR increasing right motor
  if (spd_left> (SPD_MIN + SPD_INC))
  { // Decrease speed left motor
    spd_left = (spd_left - SPD_INC);  
  }
  else
  { // Increase speed right motor (if possible)
    spd_right = ((spd_right + SPD_INC) % SPD_MAX);
  }
  setspeed();
}

void right()
{ // Turn right by decreasing speed right motor OR increasing left motor
  if (spd_right > (SPD_MIN + SPD_INC))
  { // Decrease speed right motor
    spd_right = (spd_right - SPD_INC); 
  }
  else
  { // Increase speed left motor (if possible)
    spd_left = ((spd_left + SPD_INC) % SPD_MAX);
  }
  setspeed();
}

void increase()
{ // Increase speed in 5 percentage points
  // Note: if one of both motors is (almost) at 100% (=255), direction will change
  //       more intelligent solution may be required in future 
  spd_right = ((spd_right + SPD_INC) % SPD_MAX);
  spd_left = ((spd_left + SPD_INC) % SPD_MAX);
  if (spd_right <= SPD_MIN)
  {
    spd_right = SPD_MIN;
  }
  if (spd_left <= SPD_MIN)
  {
    spd_left = SPD_MIN;
  }
  setspeed();
}

void decrease()
{ // Decrease speed in 5 percentage points
  // Note: if one of both motors is (almost) at 0%, direction will change
  //       more intelligent solution may be required in future 
  if (spd_right >= (SPD_MIN + SPD_INC))
  {
    spd_right = (spd_right - SPD_INC);
  }
  else
  {
    spd_right = SPD_MIN;
  }

  if (spd_left >= (SPD_MIN + SPD_INC))
  {
    spd_left = (spd_left - SPD_INC);
  }
  else
  {
    spd_left = SPD_MIN;
  }
  setspeed();
}

void setled(uint8_t red, uint8_t green, uint8_t blue)
{
  analogWrite(LED_RED, red);
  analogWrite(LED_GREEN, green);
  analogWrite(LED_BLUE, blue);
  
  #ifdef DEBUG
    Serial.println("LED set");
  #endif
}

void setup()
{
  char data;

  // Initialize LED
  pinMode(LED_RED, OUTPUT);
  pinMode(LED_GREEN, OUTPUT);
  pinMode(LED_BLUE, OUTPUT);
  led_red = 0;
  led_blue = 0;
  led_green = 0;
  setled(led_red, led_green, led_blue);

  // Initialize L298P Motor Shield, both motors: Speed = 0;
  pinMode(L298P_MA_SPEED, OUTPUT);
  pinMode(L298P_MA_DIR, OUTPUT);
  analogWrite(L298P_MA_SPEED, 0);
  digitalWrite(L298P_MA_DIR, HIGH);
  pinMode(L298P_MB_SPEED, OUTPUT);
  pinMode(L298P_MB_DIR, OUTPUT);
  analogWrite(L298P_MB_SPEED, 0);
  digitalWrite(L298P_MB_DIR, HIGH);
  // Set standaard direction to forward and speed to 80, both motors
  spd_forward = true;
  spd_left = 80;
  spd_right = 80;
 
  // Initialize Serial 1 (hw-serial) and 2 (sw-serial)
  Serial.begin(115200); 
  mySerial.begin(SER_BPS);
  
  // Read and discard garbage on serial 2
  while (mySerial.available())
  {
    data = mySerial.read();
  }
}

void loop() 
{ 
  char data;
  uint8_t i, steps;
  bool isEndOfeyword;
  String line, command, separator, parm1, parm2;
  
  
  // read one line from mySerial
  line = readline();  
  
  command = getValue(line,1);

  if (command == CMD_STOP)
  {
    spd_left = 0;
    spd_right = 0;
    setspeed();
  }
  
  if (command == CMD_FORWARD)
  { 
    if (spd_forward)
    { // increase forward speed
      increase();
    }
    else
    { // go forward
      forward();
    }
  }

  if (command == CMD_BACK)
  {   
    if (!spd_forward)
    { // increase backward speed
      increase();
    }
    else
    { // go backward
      backward();
    }
  }
            
  if (command == CMD_LEFT)
  { 
    left();
  }
  
  if (command == CMD_RIGHT)
  { 
    right();
  }

  if (command == CMD_STOP)
  { 
    spd_left = 0;
    spd_right = 0;
    setspeed();
  }

  if (command == CMD_LED)
  {
    parm1   = getValue(line,2);
    
    if (parm1 == "on") 
    { // SWITCH LED ON
      setled(255, 255, 255);
    }
    
    if (parm1 == "off")
    { // SWITCH LED OFF
      setled(0, 0, 0);
    }
 
    if (parm1 == PRM_LED_RED)
    { // SWITCH LED to red    
      led_red=255;
      led_green=0;
      led_blue=0;
      setled(led_red, led_green, led_blue);
    }
          
    if (parm1 == PRM_LED_BLUE)
    { // SWITCH LED to blue
      led_red=0;
      led_green=0;
      led_blue=255;
      setled(led_red, led_green, led_blue);
    }
    
    if (parm1 == PRM_LED_GREEN)
    { // SWITCH LED to green
      led_red=0;
      led_green=255;
      led_blue=0;
      setled(led_red, led_green, led_blue);
    }
  }
               
  if (command == CMD_NETWORK)
  { // network
  }

  if (command == CMD_SET)
  { // SET something
  }
}
