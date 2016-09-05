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
        let charUuidsForService: [CBUUID] = [waterSensorCharUUID]
        
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
                peripheral.discoverCharacteristics(charUuidsForService, forService: service)
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
                if characteristic.UUID == waterSensorCharUUID {
                    self.waterSensorCharacteristic = (characteristic)
                    
                    print("Peripheral: water sensor found")
                    
                    peripheral.readValueForCharacteristic(characteristic)
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                    
                    // Send notification that Bluetooth is connected and all required characteristics are discovered
                    //self.sendBTServiceNotificationWithIsBluetoothConnected(true)
                }
            }
        }
    }
	
	func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic,  error: NSError?) {
		if characteristic.UUID == waterSensorCharUUID {
			print("Peripheral: water sensor raw value = \(characteristic.value)")
			if characteristic.value?.length == 4 {
				var buf = UnsafeMutablePointer<Int32>.alloc(1)
				buf.initializeFrom(UnsafeMutablePointer<Int32>((characteristic.value?.bytes)!), count: 1)
				
				//var value = [UInt8] (count: 4, repeatedValue : 0) //?  // CFSwapInt32LittleToHost
				//characteristic.value?.getBytes(value, length: 4)
				let value = buf[0]
				let status = value & 0x000F
				let temp = Double(value >> 8) / 100
				buf.destroy()
				print("Peripheral: water sensor: \(temp)°C, status \(status)")
			}
		}
    }
    
    func sendBTServiceNotificationWithIsBluetoothConnected(isBluetoothConnected: Bool) {
        let connectionDetails = ["isConnected": isBluetoothConnected]
        NSNotificationCenter.defaultCenter().postNotificationName(BLEServiceChangedStatusNotification, object: self, userInfo: connectionDetails)
    }
    
}