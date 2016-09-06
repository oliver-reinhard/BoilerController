//
//  ControllerModel.swift
//  Boiler-Controller
//
//  Created by Oliver on 2016-09-05.
//  Copyright © 2016 Oliver. All rights reserved.
//

import Foundation
import CoreBluetooth

private var instance : BoilerControllerModel?

var modelInstance : BoilerControllerModel {
	get {
		if instance == nil {
			instance = BoilerControllerModel()
			NSNotificationCenter.defaultCenter().addObserverForName(BLECharacteristicChangedNotification, object: nil, queue: nil, usingBlock: gattCharacteristicValueChanged)
		}
		return instance
	}
}

private func gattCharacteristicValueChanged(notification : NSNotification) {
	instance.gattCharacteristicValueChanged(notification)
}


class BoilerControllerModel : NSObject {
	// status
	var state : BCControllerState?
	var timeInState : BCMillis?
	var timeHeated : BCMillis?
	var acceptedUserCmds : BCUserCommands?
	var userRequest 	 : BCUserCommand?
	var waterTemperature : Double?
	var waterSensorStatus : BCSensorStatus?
	var ambientTemperature : Double?
	var ambientSensorStatus : BCSensorStatus?
	// configuration
	var targetTemperature : Double?
	// log
	var logEntry : Int? /////// Fix this
	
	
	func gattCharacteristicValueChanged(notification : NSNotification)  {
		if let characteristic = notification.object as? CBCharacteristic {
			if let value = characteristic.value {
				if let gattCharUUID = BCGattCharUUID(rawValue: characteristic.UUID.UUIDString) {
					
					switch gattCharUUID {
					case .State:
						if let rawState : BCStateID? = extract(value, startAt: 0) {
							if let state = BCControllerState(rawValue: rawState!) {
								self.state = state
							}
						}
					case .TimeInState:
						if let time : BCMillis? = extract(value, startAt: 0) {
							timeInState = time
						}
					case .TimeHeated:
						if let time : BCMillis? = extract(value, startAt: 0) {
							timeHeated = time
						}
					case .AcceptedUserCmds:
						if let cmds : BCUserCommands? = extract(value, startAt: 0) {
							acceptedUserCmds = cmds
						}
					case .UserRequest:  // is not notified
						break
					case .WaterSensor:
						if let encodedValue : Int32? = extract(value, startAt: 0) {
							let temp = Double(encodedValue! >> 8) / 100
							let rawStatus = Int8(encodedValue! & 0x000F)
							if let status = BCSensorStatus(rawValue: rawStatus) {
								waterTemperature = temp
								waterSensorStatus = status
							}
						}
					case .AmbientSensor:
						if let encodedValue : Int32? = extract(value, startAt: 0) {
							let temp = Double(encodedValue! >> 8) / 100
							let rawStatus = Int8(encodedValue! & 0x000F)
							if let status = BCSensorStatus(rawValue: rawStatus) {
								ambientTemperature = temp
								ambientSensorStatus = status
							}
						}
					case .TargetTemp:
						if let temp : BCTemperature? = extract(value, startAt: 0) {
							targetTemperature = Double(temp!)
						}
					case .LogEntry:
						logEntry = 44
					}
					
				}
			}
		}
	}
	
	private func  extract<T>(data : NSData, startAt bytePos : Int) -> T? {
		let size = sizeof(T) - 1
		let allocSize = data.length / size
		if data.length >= bytePos + size {
			let buf = UnsafeMutablePointer<T>.alloc(allocSize)
			buf.initializeFrom(UnsafeMutablePointer<T>(data.bytes), count: 1)
			let value = buf[0]
			buf.dealloc(allocSize)
			return value;
		}
		return nil
	}
}