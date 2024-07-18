// this constant won't change:
// const int  inputPin = 2;    // the pin that the input voltage is attached to
int loopCount = 0;
int outPin = 10;  // pin 10 = tap; pin 11 = opto 

int repeatNumber = 1;
long initialDelay = 900000;
long loopInterval = 5000;



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
Serial.begin(9600);
Serial.println("start!");
}


void loop()
{
  
  delay(initialDelay);
  
  
      
  while (loopCount < repeatNumber){
    for (int i = 0; i < pulseNumber; i++){
      digitalWrite(outPin, HIGH);
      delay(ontime);
      digitalWrite(outPin, LOW);
      delay(offtime);
    }
    loopCount = loopCount+1;
    delay(loopInterval);
  }
  
}
