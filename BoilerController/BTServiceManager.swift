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

public class BTServiceManager: NSObject, CBPeripheralDelegate, BTCharacteristicValueManager {
	
	private(set) var serviceUUID : CBUUID!
	private(set) var observer : BTCharacteristicValueObserver?
	private(set) var peripheral: CBPeripheral?
	
	init(forService serviceUUID : CBUUID, observedBy observer : BTCharacteristicValueObserver?) {
        super.init()
		
		self.serviceUUID = serviceUUID
		self.observer = observer
    }
    
    deinit {
        self.reset()
    }
    
	func startDiscoveringServices(initWithPeripheral peripheral: CBPeripheral) {
		self.peripheral = peripheral
		self.peripheral?.delegate = self
        self.peripheral?.discoverServices([serviceUUID])  // discover this particular service only
        print("Peripheral: starting to discover services")
    }
    
    func reset() {
        peripheral = nil
    }
	
	
    // Mark: - CBPeripheralDelegate
    
    public func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
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
    
    public func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
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
	
	public func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic,  error: NSError?) {
		guard error == nil else {
			return
		}
		dispatch_async(dispatch_get_main_queue(), {
			self.observer?.characteristicValueUpdated(forCharacteristic: characteristic)
		})
	}
	
	private func getCharacteristic(withUUID uuid : CBUUID) -> CBCharacteristic? {
		guard let services = peripheral?.services else {
			return nil
		}
		for service in services {
			if service.UUID == serviceUUID {
				guard let characteristics = service.characteristics else {
					return nil
				}
				for characteristic in characteristics {
					if characteristic.UUID == uuid {
						return characteristic
					}
				}
			}
		}
		return nil
	}
	
	public func writeValue<T>(forCharacteristicUUID uuid : CBUUID, value : T) {
		
	}
	
	/*
	func writeValue(withUUID uuid : CBUUID, value : NSData)  {
		guard let characteristic = getCharacteristic(withUUID: uuid) else {
			fatalError("Service unavailable, characteristic: \(uuid) unknown or unavailable")
			//
			// FIX THIS: should throw an error rather than crash (the service *can* become unavailable)
			//
		}
		peripheral?.writeValue(value, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithoutResponse)
	}
	
	func writeValue(withUUID uuid : CBUUID, int16 : Int16)  {
		var mutableValue = int16
		writeValue(withUUID: uuid, value: NSData(bytes: &mutableValue, length:2))
	}
	
	func writeValue(withUUID uuid : CBUUID, int32 : Int32)  {
		var mutableValue = int32
		writeValue(withUUID: uuid, value: NSData(bytes: &mutableValue, length:4))
	}
	
	func writeValue(withUUID uuid : CBUUID, float : Float)  {
		var mutableValue = float
		writeValue(withUUID: uuid, value: NSData(bytes: &mutableValue, length:2))
	}
	*/
}