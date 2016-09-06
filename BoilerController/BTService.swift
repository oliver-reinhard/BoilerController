//
//  BTService.swift
//  Boiler-Controller
//
//  Created by Oliver on 2016-09-01.
//  Copyright © 2016 Oliver. All rights reserved.
//
//
//  BTService.swift
//  Arduino_Servo
//
//  Created by Owen L Brown on 10/11/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

/* Services & Characteristics UUIDs */
//const uint16_t BC_CONTROLLER_SERVICE_ID[] = { 0x4c, 0xef, 0xdd, 0x58, 0xcb, 0x95, 0x44, 0x50, 0x90, 0xfb, 0xf4, 0x04, 0xdc, 0x20, 0x2f, 0x7c};
let boilerControllerServiceUUID = CBUUID(string: "4CEFDD58-CB95-4450-90FB-F404DC202F7C")
let boilerControllerAdvertisingUUID = CBUUID(string: "4CEF");

let waterSensorCharUUID = CBUUID(string: "0006")
let BLECharacteristicChangedNotification = "BLECharacteristicChangedNotification"
let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"

class BTService: NSObject, CBPeripheralDelegate {
    var peripheral: CBPeripheral?
    var waterSensorCharacteristic: CBCharacteristic?
	
    
    init(initWithPeripheral peripheral: CBPeripheral) {
        super.init()
        
        self.peripheral = peripheral
        self.peripheral?.delegate = self
    }
    
    deinit {
        self.reset()
    }
    
    func startDiscoveringServices() {
        self.peripheral?.discoverServices([boilerControllerServiceUUID])
        print("Peripheral: starting to discover services")
    }
    
    func reset() {
        if peripheral != nil {
            peripheral = nil
        }
        
        // Deallocating therefore send notification
        self.sendBTServiceNotificationWithIsBluetoothConnected(false)
    }
	
	
    // Mark: - CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("Peripheral: discovered services")
        //let charUuidsForService: [CBUUID] = [waterSensorCharUUID]
        
        if (peripheral != self.peripheral) {
            return
        }
        
        if (error != nil) {
            return
        }
        
        if ((peripheral.services == nil) || (peripheral.services!.count == 0)) {
            return
        }
        
        for service in peripheral.services! {
            print("Peripheral:   - service \(service.UUID)")
            if service.UUID == boilerControllerServiceUUID {
                peripheral.discoverCharacteristics(nil, forService: service) // charUuidsForService, forService: service)
                print("Peripheral: starting to discover characteristics")
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if (peripheral != self.peripheral) {
            return
        }
        
        if (error != nil) {
            return
        }
        
        if let characteristics = service.characteristics {
			for characteristic in characteristics {
				if characteristic.properties.contains(CBCharacteristicProperties.Read) {
					peripheral.readValueForCharacteristic(characteristic)
					// print("Characteristic \(characteristic.UUID): Read")
				}
				if characteristic.properties.contains(CBCharacteristicProperties.Notify) {
					peripheral.setNotifyValue(true, forCharacteristic: characteristic)
					// print("Characteristic \(characteristic.UUID): Notify")
				}
					
				// Send notification that Bluetooth is connected and all required characteristics are discovered
				//self.sendBTServiceNotificationWithIsBluetoothConnected(true)
			}
        }
    }
	
	func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic,  error: NSError?) {
		//print("Peripheral: updated value for \(characteristic.UUID)")
		NSNotificationCenter.defaultCenter().postNotificationName(BLECharacteristicChangedNotification, object: characteristic, userInfo: nil)
    }
    
    func sendBTServiceNotificationWithIsBluetoothConnected(isBluetoothConnected: Bool) {
        let connectionDetails = ["isConnected": isBluetoothConnected]
        NSNotificationCenter.defaultCenter().postNotificationName(BLEServiceChangedStatusNotification, object: self, userInfo: connectionDetails)
    }
    
}