#include <CurieBLE.h>

BLEPeripheral blePeripheral;       // BLE Peripheral Device (the board you're programming)
BLEService heartRateService("180D"); // BLE Heart Rate Service

// BLE Heart Rate Measurement Characteristic"
BLECharacteristic heartRateChar("2A37",  // standard 16-bit characteristic UUID
    BLERead | BLENotify, 2);  // remote clients will be able to get notifications if this characteristic changes
                              // the characteristic is 2 bytes long as the first field needs to be "Flags" as per BLE specifications
                              // https://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicViewer.aspx?u=org.bluetooth.characteristic.heart_rate_measurement.xml

int oldHeartRate = 0;  // last heart rate reading from analog input
long previousMillis = 0;  // last time the heart rate was checked, in ms

const int speedbump = 2; //speedbump input from board2
const int pothole = 3; //pothole input from board2
const int speedbumpPin = 13; //speedbump output
const int potholePin = 12; //pothole output
const int trigPin1 = 6;
const int echoPin1 = 7;

int speedbumpoutput = 0; //digitalread value for speedbump input from board2
int potholeoutput = 0; //digitalread value for pothole input from board2
int devicestate = 0; //final returned value to phone

int duration0, distance0;


void setup() {
  Serial.begin(9600);    // initialize serial communication
  pinMode(11, OUTPUT);   // initialize the LED on pin 13 to indicate when a central is connected

  pinMode(speedbumpPin, OUTPUT);
  pinMode(potholePin, OUTPUT);
  pinMode(speedbump, INPUT);
  pinMode(pothole, INPUT);
  pinMode(trigPin1, OUTPUT);
  pinMode(echoPin1, INPUT);
  
   
  digitalWrite (trigPin1, HIGH);
  delayMicroseconds (10);
  digitalWrite (trigPin1, LOW);
  duration0 = pulseIn (echoPin1, HIGH);
  distance0 = (duration0/2) / 29.1;

      Serial.print("1st Sensor: start distance");
      Serial.print(distance0);  
      Serial.print("cm    ");
  
  /* Set a local name for the BLE device
     This name will appear in advertising packets
     and can be used by remote devices to identify this BLE device
     The name can be changed but maybe be truncated based on space left in advertisement packet */
  blePeripheral.setLocalName("SmoothRide");
  blePeripheral.setAdvertisedServiceUuid(heartRateService.uuid());  // add the service UUID
  blePeripheral.addAttribute(heartRateService);   // Add the BLE Heart Rate service
  blePeripheral.addAttribute(heartRateChar); // add the Heart Rate Measurement characteristic

  /* Now activate the BLE device.  It will start continuously transmitting BLE
     advertising packets and will be visible to remote BLE central devices
     until it receives a new connection */
  blePeripheral.begin();
  Serial.println("Bluetooth device active, waiting for connections...");
}

void firstsensor()
{ // This function is for first sensor.
  speedbumpoutput = digitalRead(speedbump);
  potholeoutput = digitalRead(pothole);
  int duration1, distance1;
  digitalWrite (trigPin1, HIGH);
  delayMicroseconds (10);
  digitalWrite (trigPin1, LOW);
  duration1 = pulseIn (echoPin1, HIGH);
  distance1 = (duration1/2) / 29.1;

      Serial.print("1st Sensor: ");
      Serial.print(distance1);  
      Serial.print("cm    ");

  if ((distance1 < (distance0 - 3)) && (speedbumpoutput == HIGH) && (potholeoutput == LOW))
  {  // Change the number for long or short distances.
    digitalWrite (speedbumpPin, HIGH);
    digitalWrite (potholePin, LOW);
    devicestate = 1; //speedbump detected
  } 
  else if ((distance1 > (distance0 + 3)) || ((potholeoutput == HIGH) && (speedbumpoutput == LOW)))
    {
    digitalWrite (potholePin, HIGH);
    digitalWrite (speedbumpPin, LOW);
    devicestate = 2; //pothole detected
    }    
  else 
  { 
    digitalWrite (potholePin, LOW);
    digitalWrite (speedbumpPin, LOW);
    devicestate = 3; //normal road ahead
       
  }
}


void loop() {
  Serial.println("\n");
  firstsensor();
  delay(100);
  // listen for BLE peripherals to connect:
  BLECentral central = blePeripheral.central();

  // if a central is connected to peripheral:
  if (central) {
    Serial.print("Connected to central: ");
    // print the central's MAC address:
    Serial.println(central.address());
    // turn on the LED to indicate the connection:
    digitalWrite(11, HIGH);

    // check the heart rate measurement every 200ms
    // as long as the central is still connected:
    while (central.connected()) {
        firstsensor();
        updateHeartRate();
        delay(200);
      }
    
    // when the central disconnects, turn off the LED:
    digitalWrite(11, LOW);
    Serial.print("Disconnected from central: ");
    Serial.println(central.address());
  
  //delay(100);
}}

void updateHeartRate() {
  /* Read the current voltage level on the A0 analog input pin.
     This is used here to simulate the heart rate's measurement.
  */
  int heartRateMeasurement = devicestate;
  int heartRate = map(heartRateMeasurement, 0, 3, 0, 100);
  if (heartRate != oldHeartRate) {      // if the heart rate has changed
    Serial.print("Heart Rate is now: "); // print it
    Serial.println(heartRate);
    const unsigned char heartRateCharArray[2] = { 0, (char)heartRate };
    heartRateChar.setValue(heartRateCharArray, 2);  // and update the heart rate measurement characteristic
    oldHeartRate = heartRate;           // save the level for next comparison
  }
}

