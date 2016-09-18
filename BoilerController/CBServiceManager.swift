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
	case Uninitialized
	case Available
	case ConnectionLost
}


public class CBServiceManager: NSObject, CBPeripheralDelegate, CBCharacteristicValueManager {
	
	private(set) var serviceProxies = [CBUUID : GattServiceProxy]()
	private(set) var peripheral: CBPeripheral?
	
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
				proxy.service(availabilityDidChange: .ConnectionLost)
			}
		}
		peripheral = nil
    }
	
	
    // Mark: CBPeripheralDelegate
    
    public func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
		print("Peripheral: discovered service(s)")
		
		guard error == nil else {
			for (_, proxy) in serviceProxies {
				proxy.service(availabilityDidChange: .Uninitialized)
			}
			return
		}
		
        guard peripheral == self.peripheral && peripheral.services != nil && peripheral.services!.count > 0 else {
            return
        }
        
        for service in peripheral.services! {
			if serviceProxies[service.UUID] != nil {
				print("Peripheral: starting to discover characteristics for service \(service.UUID)")
				peripheral.discoverCharacteristics(nil, forService: service)
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
				// if the characteristic is part of our service model, then we'll follow up on it:
				if let attribute = getAttribute(forCharacteristic: characteristic) {
					
					if characteristic.properties.contains(CBCharacteristicProperties.Read) {
						peripheral.readValueForCharacteristic(characteristic) // => async : will call 'didUpdateValueForCharacteristic' with result later
						// print("Characteristic \(characteristic.UUID): Read")
					}
					if characteristic.properties.contains(CBCharacteristicProperties.Notify) {
						peripheral.setNotifyValue(true, forCharacteristic: characteristic) // => will call 'didUpdateValueForCharacteristic' when updated
						// print("Characteristic \(characteristic.UUID): Notify")
					}
					if attribute.updateWithResponse == .WithResponse  {
						guard characteristic.properties.contains(CBCharacteristicProperties.Write) else {
							fatalError("Attribute asks for update 'WithResponse' but characteristic \(characteristic.UUID) does not support 'Write'")
						}
					} else if attribute.updateWithResponse == .WithoutResponse {
						guard characteristic.properties.contains(CBCharacteristicProperties.WriteWithoutResponse) else {
							fatalError("Attribute asks for update 'WithoutResponse' but characteristic \(characteristic.UUID) does not support 'WriteWithoutResponse'")
						}
					}
				}
			}
		}
		for (_, proxy) in serviceProxies {
			proxy.service(availabilityDidChange: .Available)
		}
    }
	
	public func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic,  error: NSError?) {
		guard error == nil else {
			if let attribute = getAttribute(forCharacteristic: characteristic) {
				attribute.requestedValue(updateDidFail: error)
			}  // else: ignore this case
			return
		}
		if let proxy = serviceProxies[characteristic.service.UUID] {
			proxy.characteristic(valueUpdatedFor: characteristic)
		}
	}
	
	
	public func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
		print("Peripheral: did write value for characteristic \(characteristic.UUID), error: \(error)")
		if error == nil {
			if characteristic.properties.contains(CBCharacteristicProperties.Read) {
				// unfortunately, the new value is not to be found in characteristic.value => read from server:
				peripheral.readValueForCharacteristic(characteristic) // => async : will call 'didUpdateValueForCharacteristic' with result later
			}
		} else {
			guard let attribute = getAttribute(forCharacteristic: characteristic) else {
				fatalError("Attribute for characteristic \(characteristic.UUID) unknown or unavailable")
			}
			attribute.requestedValue(updateDidFail: error)
		}
	}
	
	// Mark: END CBPeripheralDelegate
	
	
	public func updateValue<T>(forAttribute attribute : GattModifiableAttribute<T>, value : NSData, withResponse type: CBCharacteristicWriteType = .WithResponse) {
		guard peripheral != nil else {
			attribute.container.service(availabilityDidChange: .Uninitialized)
			return
		}
		guard let characteristic = getCharacteristic(forAttribute: attribute) else {
			fatalError("Service unavailable, characteristic \(attribute.characteristicUUID) unknown or unavailable")
		}
		print("Peripheral: writing value '\(attribute.requestedValue)' for characteristic \(characteristic.UUID): *\(value.bytes)*")
		peripheral?.writeValue(value, forCharacteristic: characteristic, type: type)
	}
	
	private func getCharacteristic(forAttribute attribute : GattAttribute) -> CBCharacteristic? {
		guard let services = peripheral?.services else {
			return nil
		}
		for service in services {
			if service.UUID == attribute.container.serviceUUID {
				guard let characteristics = service.characteristics else {
					return nil
				}
				for characteristic in characteristics {
					if characteristic.UUID == attribute.characteristicUUID {
						return characteristic
					}
				}
			}
		}
		return nil
	}
	
	private func getAttribute(forCharacteristic characteristic : CBCharacteristic) -> GattAttribute? {
		let serviceUUID = characteristic.service.UUID
		guard let proxy = serviceProxies[serviceUUID] else {
			return nil
		}
		return proxy.attributes[characteristic.UUID]
	}
}