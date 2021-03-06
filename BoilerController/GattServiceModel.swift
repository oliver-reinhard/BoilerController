//
//  ControllerModel.swift
//  Boiler-Controller
//
//  Created by Oliver on 2016-09-05.
//  Copyright © 2016 Oliver. All rights reserved.
//

import Foundation
import CoreBluetooth


public protocol GattAttribute: class {
	
	var characteristicUUID: CBUUID { get }
	var container: GattService { get }
	// only defined for modifiable attributes, else nil
	var updateWithResponse: CBCharacteristicWriteType? { get }
	
	func extractValue(fromCharacteristic characteristic: CBCharacteristic)
	func clearValue()
	// only implemented (i.e invokable) for modifiable attributes:
	func requestedValue(updateDidFail error: NSError?)
}


public enum GattServiceAvailability {
	
	case Available
	case Unavailable
}


public protocol GattService: class, CBServiceObserver {
	
	var serviceUUID: CBUUID { get }
	var attributes: [ CBUUID: GattAttribute ] { get }
	var availability: GattServiceAvailability { get }
	var serviceObservers: [GattServiceObserver] { get }
	var valueManager: CBCharacteristicValueManager? { get }
	
	func addAttribute(attribute: GattAttribute)
}


public class GattReadAttribute<T>: GattAttribute {
	
	public internal(set) var characteristicUUID: CBUUID
	public internal(set) var container: GattService
	// always returns nil for read-only attirbutes:
	public internal(set) var updateWithResponse: CBCharacteristicWriteType? = nil
	public var attributeBufferStartPos = 0
	
	public internal(set) var value: T? {
		didSet {
			// execute on main thread so UI observers don't get into trouble:
			DispatchQueue.main.async (execute: {
				for obs in self.container.serviceObservers {
					obs.attribute(service: self.container, valueDidChangeFor: self)
				}
			})
		}
	}
	
	init(characteristicUUID uuid: CBUUID, container: GattService) {
		self.characteristicUUID = uuid
		self.container = container
		container.addAttribute(attribute: self)
	}
	
	public final func extractValue(fromCharacteristic characteristic: CBCharacteristic) {
		// the characteristic actually has a value:
		guard let data = characteristic.value else {
			value = nil
			return
		}
		value = extractValue(source: (data as NSData))
	}
	
	func extractValue(source: NSData) -> T? {
		return source.extract(startIndex: attributeBufferStartPos)
	}
	
	public func clearValue() {
		value = nil
	}
	
	public func requestedValue(updateDidFail error: NSError?) {
		fatalError("Read-only attribute for \(characteristicUUID) cannot request value updates")
	}
}

/*
 * A write-only attribute is still modeled as a read-also attribute. The service manager will make sure it doesn't
 * invoke read on characteristics that don't support it.
 */
public class GattModifiableAttribute<T>: GattReadAttribute<T> {
		
	public var requestedValue: T? {
		didSet {
			if requestedValue != nil {
				guard let valueManager = container.valueManager else {
					fatalError("valueManager not set")
				}
				valueManager.updateValue(forAttribute: self, value: encode(requestedValue: requestedValue!) as Data, withResponse: updateWithResponse!)
			}
		}
	}
	
	init(characteristicUUID uuid: CBUUID, container: GattService, updateWithResponse: CBCharacteristicWriteType = .withResponse) {
		super.init(characteristicUUID: uuid, container: container)
		self.updateWithResponse = updateWithResponse
	}
	
	func encode(requestedValue value: T) -> NSData {
		return NSData.fromValue(value: value)
	}
	
	public override func requestedValue(updateDidFail error: NSError?) {
		// execute on main thread so UI observers don't get into trouble:
		DispatchQueue.main.async {
			for obs in self.container.serviceObservers {
				obs.attribute(service: self.container, requestedValueDidFailFor: self)
			}
		}
	}
}


public protocol GattServiceObserver: class {
	func service(service: GattService, availabilityDidChange availability: GattServiceAvailability)
	func attribute(service: GattService, valueDidChangeFor attribute: GattAttribute)
	func attribute(service: GattService, requestedValueDidFailFor attribute: GattAttribute)
}


public class GattServiceProxy: GattService {
	
	public internal(set) var serviceUUID: CBUUID
	public internal(set) var attributes = [ CBUUID: GattAttribute ]()
	public internal(set) var availability: GattServiceAvailability = .Unavailable {
		didSet {
			if (availability != oldValue) {
				// execute on main thread so UI observers don't get into trouble:
				DispatchQueue.main.async {
					for obs in self.serviceObservers {
						obs.service(service: self, availabilityDidChange: self.availability)
					}
				}
			}
		}
	}
	public var valueManager: CBCharacteristicValueManager?
	public internal(set) var serviceObservers = [GattServiceObserver]()
	
	init(serviceUUID uuid: CBUUID) {
		self.serviceUUID = uuid
	}
	
	
	public func addAttribute(attribute: GattAttribute) {
		attributes[attribute.characteristicUUID] = attribute
	}
	
	
	public func addServiceObserver(observer: GattServiceObserver) {
		for obs in serviceObservers {
			if obs === observer {
				return
			}
		}
		serviceObservers.append(observer)
	}
	
	
	public func removeServiceObserver(observer: GattServiceObserver) {
		for (index, value) in serviceObservers.enumerated() {
			if value === observer {
				serviceObservers.remove(at: index)
				break
			}
		}
	}
	
	// MARK: CBServiceObserver
	public func characteristic(valueUpdatedFor characteristic: CBCharacteristic)  {
		// we are being notified about a characteristic we are aware of:
		guard let attribute = attributes[characteristic.uuid] else {
			return
		}
		attribute.extractValue(fromCharacteristic: characteristic)
	}
	
	public func service(availabilityDidChange cbAvailability: CBServiceAvailability) {
		switch cbAvailability {
		case .uninitialized, .connectionLost:
			availability = .Unavailable
			for (_, attribute) in attributes {
				attribute.clearValue()
			}
		case .available:
			availability = .Available
		}
	}
}


extension NSData {
	func  extract<T>(startIndex: Int = 0) -> T? {
		let size = MemoryLayout<T>.size - 1 // "-1" is due to the optional return type T? which occupies 1 byte more
		if self.length >= startIndex + size {
			let allocSize = self.length / size
			let buf = UnsafeMutablePointer<T>.allocate(capacity: allocSize)
			buf.initialize(from: self.bytes.assumingMemoryBound(to: T.self), count: 1)
			let value = buf[0]
			buf.deallocate(capacity: allocSize)
			//self.getBytes(&value, length: size)
			return value
		}
		return nil
	}
	
	static func fromValue<T>(value: T) -> NSData {
		let size = MemoryLayout<T>.size
		var temp = value // NSData initializser only accepts mutable data
		let result = NSData(bytes: &temp, length: size)
		//let buf = UnsafeMutablePointer<T>.allocate(capacity: size)
		//buf.initialize(to: value)
		//let result = NSData(bytes: buf, length: size)
		//buf.deallocate(capacity: size)
		return result
	}
	/*
	func extractUInt8(startIndex: Int = 0) -> UInt8 {
		let len = 1
		assert(self.length >= len)
		let range = NSMakeRange(startIndex, startIndex + len)
		var value: UInt8 = 0x00
		self.getBytes(&value, range: range)
		return value
	}
	func extractUInt16(startIndex: Int = 0) -> UInt16 {
		let len = 1
		assert(self.length >= len)
		let range = NSMakeRange(startIndex, startIndex + len)
		var value: UInt16 = 0x0000
		self.getBytes(&value, range: range)
		return value
	}
	func extractUInt32(startIndex: Int = 0) -> UInt32 {
		let len = 1
		assert(self.length >= len)
		let range = NSMakeRange(startIndex, startIndex + len)
		var value: UInt32 = 0x00000000
		self.getBytes(&value, range: range)
		return value
	}
	func extractInt16(startIndex: Int = 0) -> Int16 {
		let len = 1
		assert(self.length >= len)
		let range = NSMakeRange(startIndex, startIndex + len)
		var value: Int16 = 0x0000
		self.getBytes(&value, range: range)
		return value
	}
	func extractInt32(startIndex: Int = 0) -> Int32 {
		let len = 1
		assert(self.length >= len)
		let range = NSMakeRange(startIndex, startIndex + len)
		var value: Int32 = 0x00000000
		self.getBytes(&value, range: range)
		return value
	}
	func extractFloat(startIndex: Int = 0) -> Float {
		let len = 1
		assert(self.length >= len)
		let range = NSMakeRange(startIndex, startIndex + len)
		var value: Float = 0.0
		self.getBytes(&value, range: range)
		return value
	}
	var uint8s:[UInt8] { // Array of UInt8, Swift byte array basically
		var buffer:[UInt8] = [UInt8](count: self.length, repeatedValue: 0)
		self.getBytes(&buffer, length: self.length)
		return buffer
	}
	var utf8:String? {
		return String(data: self, encoding: NSUTF8StringEncoding)
	}
	*/
}
