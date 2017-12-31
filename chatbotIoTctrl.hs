#include <Process.h>
#include <YunClient.h>
#include <SPI.h>

IPAddress server(1,214,89,9);
int port=9981;
YunClient client;

//root dst
String root="http://:";
//urls
String dusturl = "/dust/";
String fanurl = "/fanchk/";

//measure Common
int samplingTime = 280;
int deltaTime = 40;
int sleepTime = 9680;

//input
int imeasurePin = 0; //Connect dust sensor to Arduino A0 pin
int iledPower = 2;   //Connect 3 led driver pins of dust sensor to Arduino D2

float ivoMeasured = 0;
float icalcVoltage = 0;
float idustDensity = 0;
int irst=0;
int iqrst=0;

//output
int omeasurePin = 1; //Connect dust sensor to Arduino A1 pin
int oledPower = 3;   //Connect 3 led driver pins of dust sensor to Arduino D3
 
float ovoMeasured = 0;
float ocalcVoltage = 0;
float odustDensity = 0;
int orst=0;
int oqrst=0;

//fanounput
int motorPin=6;

void setup() {
  // Initialize Bridge
  Serial.begin(9600);
  Bridge.begin();
  delay(10);
  //output setup
  pinMode(iledPower,OUTPUT);
  pinMode(oledPower,OUTPUT);
  pinMode(motorPin, OUTPUT);
}
void loop() 
{
  //wifichk();
  if(chker(fanurl))
  {
    fan(true);
  }
  else
  {
    fan(false);
  }
  delay(3000);
  iqrst=dust25calc(0);
  oqrst=dust25calc(1);
  dustreg(root+dusturl,iqrst,oqrst);
}
int dust25calc(int flag)
{  
  if(flag==0)
  {
    digitalWrite(iledPower,LOW); // power on the LED
    delayMicroseconds(samplingTime);
    ivoMeasured = analogRead(imeasurePin); // read the input dust value  
  }
  else
  {
    digitalWrite(oledPower,LOW); // power on the LED
    delayMicroseconds(samplingTime);
    ovoMeasured = analogRead(omeasurePin); // read the output dust value 
  }
  delayMicroseconds(deltaTime);
  if(flag==0)
  {
    digitalWrite(iledPower,HIGH); // turn the LED off
  }
  else
  {
    digitalWrite(oledPower,HIGH); // turn the LED off  
  }
  delayMicroseconds(sleepTime);
  if(flag==0)
  {
    // 0 - 5V mapped to 0 - 1023 integer values
    // recover voltage
    icalcVoltage = ivoMeasured * (5.0 / 1024.0);
    // linear eqaution taken from http://www.howmuchsnow.com/arduino/airquality/
    // Chris Nafis (c) 2012
    idustDensity = 0.17 * icalcVoltage - 0.1;
    return (int(idustDensity*1000/2.5));
  }
  else
  {
    // 0 - 5V mapped to 0 - 1023 integer values
    // recover voltage
    ocalcVoltage = ovoMeasured * (5.0 / 1024.0);
    // linear eqaution taken from http://www.howmuchsnow.com/arduino/airquality/
    // Chris Nafis (c) 2012
    odustDensity = 0.17 * ocalcVoltage - 0.1;
    return (int(odustDensity*1000/2.5));
  }
}


void dustreg(String url, int ivalue, int ovalue)
{  
  // We now create a URI for the request
  url+=String(ivalue)+"/";
  url+=String(ovalue);
  
  Serial.print("Requesting URL: ");
  Serial.println(url);
  Process p;        // Create a process and call it "p"
  p.begin("curl");  // Process that launch the "curl" command
  p.addParameter(url); // Add the URL parameter to "curl"
  p.run();      // Run the process and wait for its termination
  while (p.available()>0) {
    char c = p.read();
    //Serial.print(c);
  }
  // Ensure the last bit of data is sent.
  Serial.flush();
}

bool chker(String param)
{
  //Serial.print("Requesting URL: ");
  //Serial.println(root+param);
  Process p;        // Create a process and call it "p"
  p.begin("curl");  // Process that launch the "curl" command
  p.addParameter(root+param); // Add the URL parameter to "curl"
  p.run();      // Run the process and wait for its termination
  while (p.available()>0) {
    char c = p.read();
    Serial.flush();
    if(c=='o'){
      return true;
      break;  
    }
    else{
      return false;
      break;
    }
  }
}

void wifichk()
{
  Process wifiCheck;  // initialize a new process
  wifiCheck.runShellCommand("/usr/bin/pretty-wifi-info.lua");  // command you want to run
  // while there's any characters coming back from the
  // process, print them to the serial monitor:
  while (wifiCheck.available() > 0) {
    char c = wifiCheck.read();
    Serial.print(c);
  }
  Serial.println();
  delay(5000);
}
void fan(bool onoroff)
{
  if(onoroff==false)
  {
      analogWrite(motorPin, 0);
  }
  else
  {
      analogWrite(motorPin, 255);
  }
}
