//
//  BTService.swift
//
//  Created by Owen L Brown on 10/11/14 for Arduino_Servo
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//
//  Adapted and extended by Oliver Reinhard
//

import Foundation
import UIKit
import CoreBluetooth

public protocol BTCharacteristicValueObserver {
	func characteristicValueUpdated(forCharacteristic characteristic : CBCharacteristic)
}


class BTService: NSObject, CBPeripheralDelegate {
	
    private(set) var peripheral: CBPeripheral?
	private(set) var serviceUUID : CBUUID!
	private(set) var observer : BTCharacteristicValueObserver?
    
	init(initWithPeripheral peripheral: CBPeripheral, forService serviceUUID : CBUUID, observedBy observer : BTCharacteristicValueObserver?) {
        super.init()
        
        self.peripheral = peripheral
        self.peripheral?.delegate = self
		self.serviceUUID = serviceUUID
		self.observer = observer
    }
    
    deinit {
        self.reset()
    }
    
    func startDiscoveringServices() {
        self.peripheral?.discoverServices([serviceUUID])  // discover this particular service only
        print("Peripheral: starting to discover services")
    }
    
    func reset() {
        peripheral = nil
    }
	
	
    // Mark: - CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
		print("Peripheral: discovered service(s)")
		
		guard error == nil else {
			return
		}
		
        guard peripheral == self.peripheral && peripheral.services != nil && peripheral.services!.count > 0 else {
            return
        }
        
        for service in peripheral.services! {
            if service.UUID == serviceUUID {
                peripheral.discoverCharacteristics(nil, forService: service) // charUuidsForService, forService: service)
                print("Peripheral: starting to discover characteristics")
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
		guard error == nil else {
			return
		}
		
		guard peripheral == self.peripheral else {
			return
		}
		
        if let characteristics = service.characteristics {
			print("Peripheral: discovered \(characteristics.count) characteristics")
			for characteristic in characteristics {
				if characteristic.properties.contains(CBCharacteristicProperties.Read) {
					peripheral.readValueForCharacteristic(characteristic) // => async : will call 'didUpdateValueForCharacteristic' with result later
					// print("Characteristic \(characteristic.UUID): Read")
				}
				if characteristic.properties.contains(CBCharacteristicProperties.Notify) {
					peripheral.setNotifyValue(true, forCharacteristic: characteristic) // => will call 'didUpdateValueForCharacteristic' when updated
					// print("Characteristic \(characteristic.UUID): Notify")
				}
			}
        }
    }
	
	func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic,  error: NSError?) {
		guard error == nil else {
			return
		}
		observer?.characteristicValueUpdated(forCharacteristic: characteristic)
    }
}