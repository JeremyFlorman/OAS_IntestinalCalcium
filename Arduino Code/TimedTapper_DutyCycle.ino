// this constant won't change:
// const int  inputPin = 2;    // the pin that the input voltage is attached to
int outPin = 10;  // pin 10 = tap; pin 11 = opto 

int loopNumber = 1;
long initialDelay = 1800000;
long loopInterval = 3000;
int loopCount = 0;


int pulseNumber = 3; //# of taps in tap-train
float dutyCycle = 0.3; 
int interval = 50; // duty cycle duration


float ontime = dutyCycle*interval;
float offtime = interval-ontime;

// tap settings: outPin 10, pulseNumber 3, pulseDuration 10
// optoSettings: outPin 11, pulseNumber 3, pulseDuration 10 




void setup()
{
pinMode(outPin, OUTPUT);

}


void loop()
{
  Serial.println(initialDelay/1000);
  delay(initialDelay);
  
  
      
  while (loopCount < loopNumber){
    for (int i = 0; i < pulseNumber; i++){
      digitalWrite(outPin, HIGH);
      delay(ontime);
      digitalWrite(outPin, LOW);
      delay(offtime);
    }
    delay(loopInterval);
    loopCount = loopCount+1;
  }
  
}