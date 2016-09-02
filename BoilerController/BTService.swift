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
let waterSensorCharUUID = CBUUID(string: "0006")
let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"

class BTService: NSObject, CBPeripheralDelegate {
    var peripheral: CBPeripheral?
    var waterSensorCharacteristic: CBCharacteristic?
    var output: UITextView?
    
    
    init(initWithPeripheral peripheral: CBPeripheral, output: UITextView) {
        super.init()
        
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        self.output = output
    }
    
    deinit {
        self.reset()
    }
    
    func startDiscoveringServices() {
        self.peripheral?.discoverServices([boilerControllerServiceUUID])
        output?.insertText("Peripheral: starting to discover service \n")
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
        output?.insertText("Peripheral: did discover services\n")
        let charUuidsForService: [CBUUID] = [waterSensorCharUUID]
        
        if (peripheral != self.peripheral) {
            // Wrong Peripheral
            return
        }
        
        if (error != nil) {
            return
        }
        
        if ((peripheral.services == nil) || (peripheral.services!.count == 0)) {
            // No Services
            return
        }
        
        for service in peripheral.services! {
            output?.insertText("Peripheral:   - service \(service.UUID)\n")
            if service.UUID == boilerControllerServiceUUID {
                peripheral.discoverCharacteristics(charUuidsForService, forService: service)
                output?.insertText("Peripheral: starting to discover characteristics\n")
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if (peripheral != self.peripheral) {   // Wrong Peripheral
            return
        }
        
        if (error != nil) {
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.UUID == waterSensorCharUUID {
                    self.waterSensorCharacteristic = (characteristic)
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                    
                    output?.insertText("Peripheral: water sensor found \n")
                    
                    //peripheral.readValueForCharacteristic(characteristic)
                    
                    //characteristic.
                    
                    // Send notification that Bluetooth is connected and all required characteristics are discovered
                    //self.sendBTServiceNotificationWithIsBluetoothConnected(true)
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic,  error: NSError?) {
        output?.insertText("Peripheral: water sensor value = \(characteristic.value) \n")
    }
    
    // Mark: - Private
    
    func writePosition(position: UInt8) {
        
        /******** (1) CODE TO BE ADDED *******/
        
    }
    
    func sendBTServiceNotificationWithIsBluetoothConnected(isBluetoothConnected: Bool) {
        let connectionDetails = ["isConnected": isBluetoothConnected]
        NSNotificationCenter.defaultCenter().postNotificationName(BLEServiceChangedStatusNotification, object: self, userInfo: connectionDetails)
    }
    
}