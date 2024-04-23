// this constant won't change:
const int inputPin = 2;  // the pin that the input voltage is attached to
int outPin = 11;         // pin 10 = tap; pin 11 = opto

// tap settings: outPin 10, pulseNumber 3, pulseDuration 10
// optoSettings: outPin 11, pulseNumber 3, pulseDuration 10


// Variables will change:
int inputState = 0;      // current state of the input
int lastInputState = 0;  // previous state of the input

void setup() {
  // initialize the input pin as a input: (not really necessary as the default is INPUT
  pinMode(inputPin, INPUT);
  pinMode(outPin, OUTPUT);
  Serial.begin(9600);
}


void loop() {
  // read the input pin:
  inputState = digitalRead(inputPin);

  if (inputState == HIGH) {
    // if the current state is HIGH then the input
    // went from not high to high:
    //Serial.println("Went high");

    // *****************************************
    // do the stuff that a HIGH input triggers
    // *****************************************


    digitalWrite(outPin, HIGH);
    // delay(80);
    // digitalWrite(outPin, LOW);
    // delay(20);




  } else {
    // if the current state is LOW then the input
    // went from high to not high: do nothing except print something if you want.
    //Serial.println("Went low");
    digitalWrite(outPin, LOW);
  }

  // save the current state as the last state,
  //for next time through the loop
  lastInputState = inputState;
}