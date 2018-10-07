//
//  ViewController.swift
//  SmoothRide
//
//  Created by Dhruv Kakran on 10/7/18.
//  Copyright © 2018 Dhruv Kakran. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation
import GoogleMaps
import Firebase
import FirebaseDatabase

// MARK: - Core Bluetooth service IDs
let BLE_Heart_Rate_Service_CBUUID = CBUUID(string: "0x180D")

// MARK: - Core Bluetooth characteristic IDs
let BLE_Heart_Rate_Measurement_Characteristic_CBUUID = CBUUID(string: "0x2A37")

class MainViewController: UIViewController, CBPeripheralDelegate, CBCentralManagerDelegate,CLLocationManagerDelegate {
    
    let rootRef = Database.database().reference()
    var centralManager: CBCentralManager?
    let locationMgr = CLLocationManager()
    var userLocation = CLLocation()
    var roadSensorPeripheral: CBPeripheral?
    @IBOutlet weak var bumpsCount: UILabel!
    @IBOutlet weak var potholesCount: UILabel!
    
    var potholeCount = 0
    var bumpCount = 0
    
    private var throttler: Throttler? = nil
    
    /// Throttling interval
    public var throttlingInterval: Double? = 0 {
        didSet {
            guard let interval = throttlingInterval else {
                self.throttler = nil
                return
            }
            self.throttler = Throttler(seconds: Int(interval))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        locationMgr.requestWhenInUseAuthorization()
        locationMgr.delegate = self
        locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        locationMgr.startUpdatingLocation()
        self.throttlingInterval = 0.15
        self.potholesCount.text = "0"
        self.bumpsCount.text = "0"
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if(locations.count > 0){
            self.userLocation = locations[0]
            print(userLocation)
        }
    }
    
    func getLocationString(completion : @escaping (String) -> ()){
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(self.userLocation, completionHandler: {(placemarks,error) in
            if(error == nil){
                let pm = placemarks! as [CLPlacemark]
                if pm.count > 0 {
                    let pm = placemarks![0]
                    var addressString : String = ""
                    if pm.subLocality != nil {
                        addressString = addressString + pm.subLocality! + ", "
                    }
                    if pm.thoroughfare != nil {
                        addressString = addressString + pm.thoroughfare! + ", "
                    }
                    if pm.locality != nil {
                        addressString = addressString + pm.locality! + ", "
                    }
                    if pm.country != nil {
                        addressString = addressString + pm.country! + ", "
                    }
                    if pm.postalCode != nil {
                        addressString = addressString + pm.postalCode! + " "
                    }
                    completion(addressString)
            }
            }})
    }
    
    func registerIssue(type : String){
        let info = ["type" : type, "lat" : String(format : "%f", self.userLocation.coordinate.latitude), "long" : String(format : "%f", self.userLocation.coordinate.longitude)]
        rootRef.child("ISSUES").childByAutoId().setValue(info)
    }
    
    func alertUserWithType(type : String?){
        if(type == "AEI="){
            throttler?.throttle {
                self.getLocationString(completion: {(result) in
                    self.displayAlert(withTitle: "Pothole Detected at " + result, withMessage: "Please Slow Down" )
                    self.registerIssue(type: "Pothole")
                    self.bumpCount += 1
                    self.bumpsCount.text = String(self.bumpCount)
                })
            }
        }
        else if(type == "ACE="){
            throttler?.throttle {
                self.getLocationString(completion: {(result) in
                    self.displayAlert(withTitle: "SpeedBump Detected at " + result, withMessage: "Please Slow Down" )
                    self.registerIssue(type: "SpeedBump")
                    self.bumpCount += 1
                    self.bumpsCount.text = String(self.bumpCount)
                })
            }
        }
    }
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("Bluetooth status is UNKNOWN")
        case .resetting:
            print("Bluetooth status is RESETTING")
        case .unsupported:
            print("Bluetooth status is UNSUPPORTED")
        case .unauthorized:
            print("Bluetooth status is UNAUTHORIZED")
        case .poweredOff:
            print("Bluetooth status is POWERED OFF")
        case .poweredOn:
            print("Bluetooth status is POWERED ON")
            centralManager?.scanForPeripherals(withServices: [BLE_Heart_Rate_Service_CBUUID])
            
        } // END switch
    }
    
    
    func decodePeripheralState(peripheralState: CBPeripheralState) {
        switch peripheralState {
        case .disconnected:
            print("Peripheral state: disconnected")
        case .connected:
            print("Peripheral state: connected")
        case .connecting:
            print("Peripheral state: connecting")
        case .disconnecting:
            print("Peripheral state: disconnecting")
        }
        
    } // END func decodePeripheralState(peripheralState

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral.name!)
        decodePeripheralState(peripheralState: peripheral.state)
        // STEP 4.2: MUST store a reference to the peripheral in
        // class instance variable
        roadSensorPeripheral = peripheral
        // STEP 4.3: since HeartRateMonitorViewController
        // adopts the CBPeripheralDelegate protocol,
        // the peripheralHeartRateMonitor must set its
        // delegate property to HeartRateMonitorViewController
        // (self)
        roadSensorPeripheral?.delegate = self
        
        // STEP 5: stop scanning to preserve battery life;
        // re-scan if disconnected
        centralManager?.stopScan()
        
        // STEP 6: connect to the discovered peripheral of interest
        centralManager?.connect(roadSensorPeripheral!)
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        DispatchQueue.main.async { () -> Void in
            print("Connected to Peripheral")
            
        }
        
        // STEP 8: look for services of interest on peripheral
        roadSensorPeripheral?.discoverServices([BLE_Heart_Rate_Service_CBUUID])
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        DispatchQueue.main.async { () -> Void in
            print("Disconnected from Peripheral")
            
        }
        
        // STEP 16: in this use-case, start scanning
        // for the same peripheral or another, as long
        // as they're HRMs, to come back online
        centralManager?.scanForPeripherals(withServices: [BLE_Heart_Rate_Service_CBUUID])
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        for service in peripheral.services! {
            
            if service.uuid == BLE_Heart_Rate_Service_CBUUID {
                
                print("Service: \(service)")
                
                // STEP 9: look for characteristics of interest
                // within services of interest
                peripheral.discoverCharacteristics(nil, for: service)
                
            }
            
        }
        
    } // END func peripheral(... didDiscoverServices
    
    // STEP 10: confirm we've discovered characteristics
    // of interest within services of interest
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        for characteristic in service.characteristics! {
            print("Discovered characteristic of interest ", characteristic)
            if characteristic.uuid == BLE_Heart_Rate_Measurement_Characteristic_CBUUID {
                // STEP 11: subscribe to regular notifications
                // for characteristic of interest;
                // "When you enable notifications for the
                // characteristic’s value, the peripheral calls
                // ... peripheral(_:didUpdateValueFor:error:)
                //
                // Notify    Mandatory
                //
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
        } // END for
        
    } // END func peripheral(... didDiscoverCharacteristicsFor service
    
    // STEP 12: we're notified whenever a characteristic
    // value updates regularly or posts once; read and
    // decipher the characteristic value(s) that we've
    // subscribed to
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == BLE_Heart_Rate_Measurement_Characteristic_CBUUID {
            // STEP 13: we generally have to decode BLE
            // data into human readable format
            self.alertUserWithType(type: characteristic.value?.base64EncodedString())
        } // END if characteristic.uuid ==...
        
    } // END func peripheral(... didUpdateValueFor characteristic
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension UIViewController{
    
    func displayAlert(withTitle title : String, withMessage message : String?){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert,animated: true)
    }
    
}

