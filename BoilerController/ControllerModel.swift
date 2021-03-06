//
//  ControllerModel.swift
//  Boiler-Controller
//
//  Created by Oliver on 2016-09-05.
//  Copyright © 2016 Oliver. All rights reserved.
//

import Foundation
import CoreBluetooth

public class BCControllerStateAttribute : GattReadAttribute<BCControllerState> {
	
	init(characteristicUUID uuid: BCGattCharUUID, container: GattService) {
		super.init(characteristicUUID: CBUUID(string: uuid.rawValue), container: container)
	}
	
	override func extractValue(source: NSData) -> BCControllerState? {
		if let rawState : BCStateID? = source.extract() {
			if let state = BCControllerState(rawValue: rawState!) {
				return state
			}
		}
		return nil
	}
}

public struct BCTemperatureSensor {
	var temperature : Double
	var status : BCSensorStatus
}


public class BCTemperatureSensorAttribute : GattReadAttribute<BCTemperatureSensor> {
	
	init(characteristicUUID uuid: BCGattCharUUID, container: GattService) {
		super.init(characteristicUUID: CBUUID(string: uuid.rawValue), container: container)
	}
	
	override func extractValue(source: NSData) -> BCTemperatureSensor? {
		if let encodedValue : Int32? = source.extract() {
			let temp = Double(encodedValue! >> 8) / 100.0
			let rawStatus = Int8(encodedValue! & 0x000F)
			if let status = BCSensorStatus(rawValue: rawStatus) {
				return BCTemperatureSensor(temperature: temp, status: status)
			}
		}
		return nil
	}
}


public class BCTemperatureAttribute : GattModifiableAttribute<Double> {
	
	init(characteristicUUID uuid: BCGattCharUUID, container: GattService) {
		super.init(characteristicUUID: CBUUID(string: uuid.rawValue), container: container)
	}
	
	override func extractValue(source: NSData) -> Double? {
		if let temp100 : BCTemperature? = source.extract() {
			return Double(temp100!) / 100.0
		}
		return nil
	}
	
	override func encode(requestedValue value: Double) -> NSData {
		let temp100 = BCTemperature(value * 100)
		return NSData.fromValue(value: temp100)
	}
}


public class BCLogEntryAttribute : GattReadAttribute<Int> {
	
	init(characteristicUUID uuid: BCGattCharUUID, container: GattService) {
		super.init(characteristicUUID: CBUUID(string: uuid.rawValue), container: container)
	}
	
	override func extractValue(source: NSData) -> Int {
		return 44  /// FIX THIS
	}
}


public class ControllerModel : GattServiceProxy {
	
	// status
	open fileprivate(set) var state 				: BCControllerStateAttribute!
	open fileprivate(set) var timeInState			: GattReadAttribute<BCSeconds>!
	open fileprivate(set) var timeHeated			: GattReadAttribute<BCSeconds>!
	open fileprivate(set) var timeToGo			: GattReadAttribute<BCSeconds>!
	open fileprivate(set) var acceptedUserCmds	: GattReadAttribute<BCUserCommands>!
	open fileprivate(set) var userRequest			: GattModifiableAttribute<BCUserCommandID>!
	open fileprivate(set) var waterSensor			: GattReadAttribute<BCTemperatureSensor>!
	open fileprivate(set) var ambientSensor		: GattReadAttribute<BCTemperatureSensor>!
	
	// configuration
	open fileprivate(set) var targetTemperature	: GattModifiableAttribute<Double>!
	
	// log
	open fileprivate(set) var logEntry			: GattReadAttribute<Int>!
	
	open var canUpdateConfigValues : Bool {
		return acceptedUserCmds.value != nil && (acceptedUserCmds.value! & BCUserCommand.config_Set_Value.rawValue != 0)
	}
	
	init() {
		super.init(serviceUUID: boilerControllerServiceUUID)
		
		state 				= BCControllerStateAttribute(characteristicUUID:   .State, container: self)
		timeInState			= createReadAttribute(characteristicUUID:          .TimeInState) // [s]
		timeHeated			= createReadAttribute(characteristicUUID:          .TimeHeated)  // [s]
		timeToGo			= createReadAttribute(characteristicUUID:          .TimeToGo)    // [s]
		acceptedUserCmds	= createReadAttribute(characteristicUUID:          .AcceptedUserCmds)
		userRequest			= createModifiableAttribute(characteristicUUID:    .UserRequest)
		waterSensor			= BCTemperatureSensorAttribute(characteristicUUID: .WaterSensor, container: self)
		ambientSensor		= BCTemperatureSensorAttribute(characteristicUUID: .AmbientSensor, container: self)
		
		// configuration
		targetTemperature	= BCTemperatureAttribute(characteristicUUID: .TargetTemp, container: self)
		
		// log
		logEntry			= BCLogEntryAttribute(characteristicUUID: .LogEntry, container: self)
	}
	
	fileprivate func createReadAttribute<T>(characteristicUUID uuid: BCGattCharUUID) -> GattReadAttribute<T> {
		return GattReadAttribute<T>(characteristicUUID: CBUUID(string: uuid.rawValue), container: self)
	}
	
	fileprivate func createModifiableAttribute<T>(characteristicUUID uuid: BCGattCharUUID) -> GattModifiableAttribute<T> {
		return GattModifiableAttribute<T>(characteristicUUID: CBUUID(string: uuid.rawValue), container: self)
	}
}

protocol ControllerModelContext {
	var controllerModel : ControllerModel! { get set }
}
