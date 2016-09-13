//
//  ControllerModel.swift
//  Boiler-Controller
//
//  Created by Oliver on 2016-09-05.
//  Copyright © 2016 Oliver. All rights reserved.
//

import Foundation
import CoreBluetooth


public protocol GattAttribute : class {
	
	var characteristicUUID : CBUUID { get }
	var container : GattService { get }
	
	func extractValue(fromCharacteristic characteristic: CBCharacteristic)
	func clearValue()
	func requestedValue(updateDidFail error : NSError?)
}


public enum GattServiceAvailability {
	
	case Available
	case Unavailable
}


public protocol GattService : class {
	
	var serviceUUID : CBUUID { get }
	var attributes : [ CBUUID : GattAttribute ] { get }
	var availability : GattServiceAvailability { get }
	var serviceObservers : [GattServiceObserver] { get }
	var valueManager : CBCharacteristicValueManager? { get }
	
	func addAttribute(attribute : GattAttribute)
	func service(availabilityDidChange cbAvailability : CBServiceAvailability)
	func characteristic(valueUpdatedFor characteristic: CBCharacteristic)
}


public class GattReadAttribute<T> : GattAttribute {
	
	public internal(set) var characteristicUUID : CBUUID
	public internal(set) var container : GattService
	public var attributeBufferStartPos = 0
	
	public internal(set) var value : T? {
		didSet {
			// execute on main thread so UI observers don't get into trouble:
			dispatch_async(dispatch_get_main_queue(), {
				for obs in self.container.serviceObservers {
					obs.attribute(self.container, valueDidChangeFor: self)
				}
			})
		}
	}
	
	init(characteristicUUID uuid : CBUUID, container : GattService) {
		self.characteristicUUID = uuid
		self.container = container
		container.addAttribute(self)
	}
	
	public final func extractValue(fromCharacteristic characteristic: CBCharacteristic) {
		// the characteristic actually has a value:
		guard let data = characteristic.value else {
			value = nil
			return
		}
		value = extractValue(data)
	}
	
	func extractValue(source : NSData) -> T? {
		return source.extract(attributeBufferStartPos)
	}
	
	public func clearValue() {
		value = nil
	}
	
	public func requestedValue(updateDidFail error : NSError?) {
		// empty: read-only attribute does not request value updates
	}
}


public class GattModifiableAttribute<T> : GattReadAttribute<T> {
	
	public var requestedValue : T? {
		didSet {
			if requestedValue != nil {
				guard let valueManager = container.valueManager else {
					fatalError("valueManager not set")
				}
				valueManager.updateValue(forAttribute: self, value: encode(requestedValue: requestedValue!))
			}
		}
	}
	
	override init(characteristicUUID uuid: CBUUID, container : GattService) {
		super.init(characteristicUUID: uuid, container: container)
	}
	
	func encode(requestedValue value : T) -> NSData {
		return NSData.fromValue(value)
	}
	
	public override func requestedValue(updateDidFail error : NSError?) {
		// execute on main thread so UI observers don't get into trouble:
		dispatch_async(dispatch_get_main_queue(), {
			for obs in self.container.serviceObservers {
				obs.attribute(self.container, requestedValueDidFailFor: self)
			}
		})
	}
}


public protocol GattServiceObserver : class {
	func service(service : GattService, availabilityDidChange availability : GattServiceAvailability)
	func attribute(service : GattService, valueDidChangeFor attribute : GattAttribute)
	func attribute(service : GattService, requestedValueDidFailFor attribute : GattAttribute)
}


public class GattServiceProxy : GattService, CBServiceObserver {
	
	public internal(set) var serviceUUID : CBUUID
	public internal(set) var attributes = [ CBUUID : GattAttribute ]()
	public internal(set) var availability : GattServiceAvailability = .Unavailable {
		didSet {
			if (availability != oldValue) {
				// execute on main thread so UI observers don't get into trouble:
				dispatch_async(dispatch_get_main_queue(), {
					for obs in self.serviceObservers {
						obs.service(self, availabilityDidChange: self.availability)
					}
				})
			}
		}
	}
	public var valueManager : CBCharacteristicValueManager?
	public internal(set) var serviceObservers = [GattServiceObserver]()
	
	init(serviceUUID uuid: CBUUID) {
		self.serviceUUID = uuid
	}
	
	
	public func addAttribute(attribute : GattAttribute) {
		attributes[attribute.characteristicUUID] = attribute
	}
	
	
	public func addServiceObserver(observer : GattServiceObserver) {
		for obs in serviceObservers {
			if obs === observer {
				return
			}
		}
		serviceObservers.append(observer)
	}
	
	
	public func removeServiceObserver(observer : GattServiceObserver) {
		for (index, value) in serviceObservers.enumerate() {
			if value === observer {
				serviceObservers.removeAtIndex(index)
				break
			}
		}
	}
	
	public func characteristic(valueUpdatedFor characteristic: CBCharacteristic)  {
		// we are being notified about a characteristic we are aware of:
		guard let attribute = attributes[characteristic.UUID] else {
			return
		}
		attribute.extractValue(fromCharacteristic: characteristic)
	}
	
	public func service(availabilityDidChange cbAvailability : CBServiceAvailability) {
		switch cbAvailability {
		case .Uninitialized, .ConnectionLost:
			availability = .Unavailable
			for (_, attribute) in attributes {
				attribute.clearValue()
			}
		case .Available:
			availability = .Available
		}
	}
}


extension NSData {
	func  extract<T>(startIndex : Int = 0) -> T? {
		let size = sizeof(T) - 1
		let allocSize = self.length / size
		if self.length >= startIndex + size {
			let buf = UnsafeMutablePointer<T>.alloc(allocSize)
			buf.initializeFrom(UnsafeMutablePointer<T>(self.bytes), count: 1)
			let value = buf[0]
			buf.dealloc(allocSize)
			return value
		}
		return nil
	}
	
	static func fromValue<T>(value : T) -> NSData {
		let size = sizeof(T)
		let buf = UnsafeMutablePointer<T>.alloc(size)
		buf.initialize(value)
		let result = NSData(bytes: buf, length: size)
		buf.dealloc(size)
		return result
	}
	/*
	func extractUInt8(startIndex : Int = 0) -> UInt8 {
		let len = 1
		assert(self.length >= len)
		let range = NSMakeRange(startIndex, startIndex + len)
		var value : UInt8 = 0x00
		self.getBytes(&value, range: range)
		return value
	}
	func extractUInt16(startIndex : Int = 0) -> UInt16 {
		let len = 1
		assert(self.length >= len)
		let range = NSMakeRange(startIndex, startIndex + len)
		var value : UInt16 = 0x0000
		self.getBytes(&value, range: range)
		return value
	}
	func extractUInt32(startIndex : Int = 0) -> UInt32 {
		let len = 1
		assert(self.length >= len)
		let range = NSMakeRange(startIndex, startIndex + len)
		var value : UInt32 = 0x00000000
		self.getBytes(&value, range: range)
		return value
	}
	func extractInt16(startIndex : Int = 0) -> Int16 {
		let len = 1
		assert(self.length >= len)
		let range = NSMakeRange(startIndex, startIndex + len)
		var value : Int16 = 0x0000
		self.getBytes(&value, range: range)
		return value
	}
	func extractInt32(startIndex : Int = 0) -> Int32 {
		let len = 1
		assert(self.length >= len)
		let range = NSMakeRange(startIndex, startIndex + len)
		var value : Int32 = 0x00000000
		self.getBytes(&value, range: range)
		return value
	}
	func extractFloat(startIndex : Int = 0) -> Float {
		let len = 1
		assert(self.length >= len)
		let range = NSMakeRange(startIndex, startIndex + len)
		var value : Float = 0.0
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
