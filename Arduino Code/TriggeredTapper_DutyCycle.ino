// this constant won't change:
const int  inputPin = 2;    // the pin that the input voltage is attached to
int outPin = 10;  // pin 10 = tap; pin 11 = opto 
int pulseNumber = 3; //75 for opto; 20 for tap
int loopNumber = 1;



float dutyCycle = 0.3;
int interval = 50; // intertap interval (ms)
long initialDelay = 0;
long loopInterval = 30000;

float ontime = dutyCycle*interval;
float offtime = interval-ontime;

// tap settings: outPin 10, pulseNumber 3, pulseDuration 10
// optoSettings: outPin 11, pulseNumber 3, pulseDuration 10 


// Variables will change:
int inputState = 0;         // current state of the input
int lastInputState = 0;     // previous state of the input

void setup()
{
  // initialize the input pin as a input: (not really necessary as the default is INPUT
  pinMode(inputPin, INPUT);
  pinMode(outPin, OUTPUT);
  Serial.begin(9600);
}


void loop()
{
  // read the input pin:
  inputState = digitalRead(inputPin);

  // compare the inputState to its previous state (lastInputState)
  if (inputState != lastInputState)  
  {
    if (inputState == HIGH)
    {
      // if the current state is HIGH then the input
      // went from not high to high:
      Serial.println("Went high");

      // *****************************************
      // do the stuff that a HIGH input triggers
      // *****************************************
      delay(initialDelay);
      
      for (int n = 0; n < loopNumber; n++){
        for (int i = 0; i < pulseNumber; i++){
          digitalWrite(outPin, HIGH);
          delay(ontime);
          digitalWrite(outPin, LOW);
          delay(offtime);
        }
         delay(loopInterval);
      }
    

    } 
     else 
    {
      // if the current state is LOW then the input
      // went from high to not high: do nothing except print something if you want.
      Serial.println("Went low");
    }
  }
  // save the current state as the last state,
  //for next time through the loop
  lastInputState = inputState;
}