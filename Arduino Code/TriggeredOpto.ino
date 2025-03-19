// this constant won't change:
const int inputPin = 2;                // the pin that the input voltage is attached to
int outPin = 10;                       // pin 10 = tap; pin 11 = opto
int pulseDur = 35;                     // duration of individual pulses in ms
int hz = 4;                            // frequency (pulses per second)
int offTime = (1000 / hz) - pulseDur;  // ammount of time LED is off between pulses

int stimDur = 1;  // how long the stimulation lasts in seconds


// Variables will change:
int inputState = 0;      // current state of the input
int lastInputState = 0;  // previous state of the input

void setup() {
  // initialize the input pin as a input: (not really necessary as the default is INPUT
  pinMode(inputPin, INPUT);
  pinMode(outPin, OUTPUT);
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.begin(9600);
}


void loop() {
  // read the input pin:
  inputState = digitalRead(inputPin);

  if (inputState == HIGH) {
    // if the current state is HIGH then the input
    // went from not high to high:
    // Serial.println(offTime);

    // *****************************************
    // do the stuff that a HIGH input triggers
    // *****************************************

    for (int i = 0; i < stimDur * hz; i++) {
      digitalWrite(outPin, HIGH);
      digitalWrite(LED_BUILTIN, HIGH);
      Serial.println("on");
      delay(pulseDur);
      digitalWrite(outPin, LOW);
      digitalWrite(LED_BUILTIN, LOW);
      Serial.println("off");
      delay(offTime);
    }




  } else {
    // if the current state is LOW then the input
    // went from high to not high: do nothing except print something if you want.
    // Serial.println("Stimulus Off");
    digitalWrite(outPin, LOW);
  }

  // save the current state as the last state,
  //for next time through the loop
  lastInputState = inputState;
}