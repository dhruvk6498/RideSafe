        // the number of the input pin
const int outPin1 = 13; //speedbumps
const int outPin2 = 12; //potholes

const int trigPin2 = 6;
const int echoPin2 = 7;

int duration3, distance3;

void setup()
{
  Serial.begin (9600);
  pinMode(trigPin2, OUTPUT);
  pinMode(echoPin2, INPUT);
  pinMode(outPin1, OUTPUT);
  pinMode(outPin2, OUTPUT);

  digitalWrite (trigPin2, HIGH);
  delayMicroseconds (10);
  digitalWrite (trigPin2, LOW);
  duration3 = pulseIn (echoPin2, HIGH);
  distance3 = (duration3/2) / 29.1;

      Serial.print("2nd Sensor: start distance");
      Serial.print(distance3);  
      Serial.print("cm    ");
  


}

void secondsensor(){ // This function is for second sensor.
    int duration2, distance2;
    digitalWrite (trigPin2, HIGH);
    delayMicroseconds (10);
    digitalWrite (trigPin2, LOW);
    duration2 = pulseIn (echoPin2, HIGH);
    distance2 = (duration2/2) / 29.1;
  
      Serial.print("2nd Sensor: "); 
      Serial.print(distance2);  
      Serial.print("cm    ");
   
    if (distance2 < (distance3 - 3)) {  // Change the number for long or short distances.
      digitalWrite (outPin1, HIGH);
      digitalWrite (outPin2, LOW);
    }
 else if(distance2 > (distance3 + 3)) {
      digitalWrite (outPin2, HIGH);
      digitalWrite (outPin1, LOW);
    }    
    else { digitalWrite (outPin1, LOW);
    digitalWrite (outPin2, LOW);}
}



void loop()
{
Serial.println("\n");
secondsensor();
delay(100);
}
