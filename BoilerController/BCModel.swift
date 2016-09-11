//
//  ControllerModel.swift
//  Boiler-Controller
//
//  Created by Oliver on 2016-09-05.
//  Copyright © 2016 Oliver. All rights reserved.
//

import Foundation
import CoreBluetooth


public let BCModelPropertyChangedNotification = "BCModelPropertyChangedNotification"

public class ReadOnlyBCModelProperty<T> {
	
	public internal(set) var value : T? {
		didSet {
			NSNotificationCenter.defaultCenter().postNotificationName(BCModelPropertyChangedNotification, object: self)
		}
	}
}


public class BCModelProperty<T> : ReadOnlyBCModelProperty<T> {
	
	public internal(set) var valueManager : BTCharacteristicValueManager?
	
	func writeRemote(value : T) {
		
	}
}

public final class BCModel : BTCharacteristicValueObserver {
	
	// status
	public let state 				= ReadOnlyBCModelProperty<BCControllerState>()
	public let timeInState			= ReadOnlyBCModelProperty<BCMillis>()
	public let timeHeated			= ReadOnlyBCModelProperty<BCMillis>()
	public let acceptedUserCmds		= ReadOnlyBCModelProperty<BCUserCommands>()
	public let userRequest			= BCModelProperty<BCUserCommand>()
	public let waterTemperature		= ReadOnlyBCModelProperty<Double>()
	public let waterSensorStatus	= ReadOnlyBCModelProperty<BCSensorStatus>()
	public let ambientTemperature	= ReadOnlyBCModelProperty<Double>()
	public let ambientSensorStatus	= ReadOnlyBCModelProperty<BCSensorStatus>()

	// configuration
	public let  targetTemperature	= BCModelProperty<Double>()

	// log
	public let logEntry				= ReadOnlyBCModelProperty<Int>()
	
	public var valueManager : BTCharacteristicValueManager? {
		didSet {
			userRequest.valueManager =  self.valueManager
			targetTemperature.valueManager = self.valueManager
		}
	}
	
	public func addPropertyChangedObserver(block : (NSNotification) -> Void) {
		NSNotificationCenter.defaultCenter().addObserverForName(BCModelPropertyChangedNotification, object: nil, queue: nil, usingBlock: block)
	}
	
	
	public func characteristicValueUpdated(forCharacteristic characteristic: CBCharacteristic)  {
		// we are being notified about a characteristic we are aware of:
		guard let gattCharUUID = BCGattCharUUID(rawValue: characteristic.UUID.UUIDString) else {
			return
		}
		// the characteristic actually has a value:
		guard let value = characteristic.value else {
			return
		}
					
		switch gattCharUUID {
		case .State:
			if let rawState : BCStateID? = extract(value, startAt: 0) {
				if let state = BCControllerState(rawValue: rawState!) {
					self.state.value = state
				}
			}
		case .TimeInState:
			if let time : BCMillis? = extract(value) {
				timeInState.value = time
			}
		case .TimeHeated:
			if let time : BCMillis? = extract(value) {
				timeHeated.value = time
			}
		case .AcceptedUserCmds:
			if let cmds : BCUserCommands? = extract(value) {
				acceptedUserCmds.value = cmds
			}
		case .UserRequest:  // is not notified
			break
		case .WaterSensor:
			if let encodedValue : Int32? = extract(value) {
				let temp = Double(encodedValue! >> 8) / 100.0
				let rawStatus = Int8(encodedValue! & 0x000F)
				if let status = BCSensorStatus(rawValue: rawStatus) {
					waterTemperature.value = temp
					waterSensorStatus.value = status
				}
			}
		case .AmbientSensor:
			if let encodedValue : Int32? = extract(value) {
				let temp = Double(encodedValue! >> 8) / 100.0
				let rawStatus = Int8(encodedValue! & 0x000F)
				if let status = BCSensorStatus(rawValue: rawStatus) {
					ambientTemperature.value = temp
					ambientSensorStatus.value = status
				}
			}
		case .TargetTemp:
			if let temp : BCTemperature? = extract(value) {
				targetTemperature.value = Double(temp!) / 100.0
			}
		case .LogEntry:
			logEntry.value = 44
		}
	}
	
	private func  extract<T>(data : NSData, startAt bytePos : Int = 0) -> T? {
		let size = sizeof(T) - 1
		let allocSize = data.length / size
		if data.length >= bytePos + size {
			let buf = UnsafeMutablePointer<T>.alloc(allocSize)
			buf.initializeFrom(UnsafeMutablePointer<T>(data.bytes), count: 1)
			let value = buf[0]
			buf.dealloc(allocSize)
			return value
		}
		return nil
	}
}

extension NSData {
	func  extract<T>(startAt bytePos : Int) -> T? {
		let size = sizeof(T) - 1
		let allocSize = self.length / size
		if self.length >= bytePos + size {
			let buf = UnsafeMutablePointer<T>.alloc(allocSize)
			buf.initializeFrom(UnsafeMutablePointer<T>(self.bytes), count: 1)
			let value = buf[0]
			buf.dealloc(allocSize)
			return value
		}
		return nil
	}
	
	static func fromValue<T>(value : T) -> NSData {
		let size = sizeof(T) - 1
		let buf = UnsafeMutablePointer<T>.alloc(size)
		buf.initialize(value)
		let result = NSData(bytes: buf, length: size)
		buf.dealloc(size)
		return result
	}
}

protocol BCModelContext {
	var controllerModel : BCModel! { get set }
}