//
//  CBService.swift
//
//  Created by Owen L Brown on 10/11/14 for Arduino_Servo
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//
//  Adapted and extended by Oliver Reinhard
//

import Foundation
import UIKit
import CoreBluetooth


public enum CBServiceAvailability {
	case uninitialized
	case available
	case connectionLost
}


open class CBServiceManager: NSObject, CBPeripheralDelegate, CBCharacteristicValueManager {
	
	fileprivate(set) var serviceProxies = [CBUUID : GattServiceProxy]()
	fileprivate(set) var peripheral: CBPeripheral?
	
	init(serviceProxies : [CBUUID : GattServiceProxy]) {
		super.init()
		guard serviceProxies.count > 0 else {
			fatalError("Expected at least one GattServiceProxy")
		}
		self.serviceProxies = serviceProxies
		for (_, proxy) in serviceProxies {
			proxy.valueManager = self
		}
	}
	
    deinit {
        self.reset()
    }
	
    
	func startDiscoveringServices(initWithPeripheral peripheral: CBPeripheral) {
		self.peripheral = peripheral
		self.peripheral?.delegate = self
        self.peripheral?.discoverServices(Array(serviceProxies.keys))
        print("Peripheral: starting to discover services")
    }
    
    func reset() {
		if peripheral != nil {
			for (_, proxy) in serviceProxies {
				proxy.service(availabilityDidChange: .connectionLost)
			}
		}
		peripheral = nil
    }
	
	
    // Mark: CBPeripheralDelegate
    
    open func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		print("Peripheral: discovered service(s)")
		
		guard error == nil else {
			for (_, proxy) in serviceProxies {
				proxy.service(availabilityDidChange: .uninitialized)
			}
			return
		}
		
        guard peripheral == self.peripheral && peripheral.services != nil && peripheral.services!.count > 0 else {
            return
        }
        
        for service in peripheral.services! {
			if serviceProxies[service.uuid] != nil {
				print("Peripheral: starting to discover characteristics for service \(service.uuid)")
				peripheral.discoverCharacteristics(nil, for: service)
			}
        }
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		guard error == nil else {
			return
		}
		
		guard peripheral == self.peripheral else {
			return
		}
		
        if let characteristics = service.characteristics {
			print("Peripheral: discovered \(characteristics.count) characteristics")
			
			for characteristic in characteristics {
				// if the characteristic is part of our service model, then we'll follow up on it:
				if let attribute = getAttribute(forCharacteristic: characteristic) {
					
					if characteristic.properties.contains(CBCharacteristicProperties.read) {
						peripheral.readValue(for: characteristic) // => async : will call 'didUpdateValueForCharacteristic' with result later
						// print("Characteristic \(characteristic.UUID): Read")
					}
					if characteristic.properties.contains(CBCharacteristicProperties.notify) {
						peripheral.setNotifyValue(true, for: characteristic) // => will call 'didUpdateValueForCharacteristic' when updated
						// print("Characteristic \(characteristic.UUID): Notify")
					}
					if attribute.updateWithResponse == .withResponse  {
						guard characteristic.properties.contains(CBCharacteristicProperties.write) else {
							fatalError("Attribute asks for update 'WithResponse' but characteristic \(characteristic.uuid) does not support 'Write'")
						}
					} else if attribute.updateWithResponse == .withoutResponse {
						guard characteristic.properties.contains(CBCharacteristicProperties.writeWithoutResponse) else {
							fatalError("Attribute asks for update 'WithoutResponse' but characteristic \(characteristic.uuid) does not support 'WriteWithoutResponse'")
						}
					}
				}
			}
		}
		for (_, proxy) in serviceProxies {
			proxy.service(availabilityDidChange: .available)
		}
    }
	
	open func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,  error: Error?) {
		guard error == nil else {
			if let attribute = getAttribute(forCharacteristic: characteristic) {
				attribute.requestedValue(updateDidFail: error as NSError?)
			}  // else: ignore this case
			return
		}
		if let proxy = serviceProxies[characteristic.service.uuid] {
			proxy.characteristic(valueUpdatedFor: characteristic)
		}
	}
	
	
	open func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		print("Peripheral: did write value for characteristic \(characteristic.uuid), error: \(error)")
		if error == nil {
			if characteristic.properties.contains(CBCharacteristicProperties.read) {
				// unfortunately, the new value is not to be found in characteristic.value => read from server:
				peripheral.readValue(for: characteristic) // => async : will call 'didUpdateValueForCharacteristic' with result later
			}
		} else {
			guard let attribute = getAttribute(forCharacteristic: characteristic) else {
				fatalError("Attribute for characteristic \(characteristic.uuid) unknown or unavailable")
			}
			attribute.requestedValue(updateDidFail: error as NSError?)
		}
	}
	
	// Mark: END CBPeripheralDelegate
	
	
	open func updateValue<T>(forAttribute attribute : GattModifiableAttribute<T>, value : Data, withResponse type: CBCharacteristicWriteType = .withResponse) {
		guard peripheral != nil else {
			attribute.container.service(availabilityDidChange: .uninitialized)
			return
		}
		guard let characteristic = getCharacteristic(forAttribute: attribute) else {
			fatalError("Service unavailable, characteristic \(attribute.characteristicUUID) unknown or unavailable")
		}
		print("Peripheral: writing value '\(attribute.requestedValue)' for characteristic \(characteristic.uuid): *\((value as NSData).bytes)*")
		peripheral?.writeValue(value, for: characteristic, type: type)
	}
	
	fileprivate func getCharacteristic(forAttribute attribute : GattAttribute) -> CBCharacteristic? {
		guard let services = peripheral?.services else {
			return nil
		}
		for service in services {
			if service.uuid == attribute.container.serviceUUID {
				guard let characteristics = service.characteristics else {
					return nil
				}
				for characteristic in characteristics {
					if characteristic.uuid == attribute.characteristicUUID {
						return characteristic
					}
				}
			}
		}
		return nil
	}
	
	fileprivate func getAttribute(forCharacteristic characteristic : CBCharacteristic) -> GattAttribute? {
		let serviceUUID = characteristic.service.uuid
		guard let proxy = serviceProxies[serviceUUID] else {
			return nil
		}
		return proxy.attributes[characteristic.uuid]
	}
}
