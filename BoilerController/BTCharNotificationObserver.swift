//
//  BTCharNotificationObserver.swift
//  Boiler-Controller
//
//  Created by Oliver on 2016-09-05.
//  Copyright © 2016 Oliver. All rights reserved.
//

import Foundation
import CoreBluetooth

class BTCharNotificationObserver {
	
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
	
	func stateChanged(newState : BCControllerState) {
		print("BTCharNotificationObserver: stateChanged to \(newState)")
	}
	
	func timeInStateChanged(time : BCMillis) {
		print("BTCharNotificationObserver: timeInStateChanged to  \(time)")
	}
	
	func timeHeatedChanged(time : BCMillis) {
		print("BTCharNotificationObserver: timeHeatedChanged to  \(time)")
	}
	
	func acceptedCommandsChanged(cmds : BCUserCommands) {
		print("BTCharNotificationObserver: acceptedCommandsChanged to  \(cmds)")
	}
	
	func waterSensorChanged(newTemperature : Double, newStatus:  BCSensorStatus) {
		print("BTCharNotificationObserver: waterSensorChanged to \(newTemperature)°C, status \(newStatus)")
		
	}
	
	func ambientSensorChanged(newTemperature : Double, newStatus:  BCSensorStatus) {
		print("BTCharNotificationObserver: ambientSensorChanged to \(newTemperature)°C, status \(newStatus)")
		
	}
	
	func targetTempChanged(newTemperature : Double) {
		print("BTCharNotificationObserver: targetTempChanged to \(newTemperature)°C")
	}
	
	func newLogEntry() {
		print("BTCharNotificationObserver: newLogEntry")

	}

	func characteristicValueChanged(notification : NSNotification)  {
		if let characteristic = notification.object as? CBCharacteristic {
			if let value = characteristic.value {
				if let gattCharUUID = BCGattCharUUID(rawValue: characteristic.UUID.UUIDString) {
				
					switch gattCharUUID {
					case .State:
						if let rawState : BCStateID? = extract(value, startAt: 0) {
							if let state = BCControllerState(rawValue: rawState!) {
								stateChanged(state)
							}
						}
					case .TimeInState:
						if let time : BCMillis? = extract(value, startAt: 0) {
							timeInStateChanged(time!)
						}
					case .TimeHeated:
						if let time : BCMillis? = extract(value, startAt: 0) {
							timeHeatedChanged(time!)
						}
					case .AcceptedUserCmds:
						if let cmds : BCUserCommands? = extract(value, startAt: 0) {
							acceptedCommandsChanged(cmds!)
						}
					case .UserRequest:  // is not notified
						break
					case .WaterSensor:
						if let encodedValue : Int32? = extract(value, startAt: 0) {
							let temp = Double(encodedValue! >> 8) / 100
							let rawStatus = Int8(encodedValue! & 0x000F)
							if let status = BCSensorStatus(rawValue: rawStatus) {
								waterSensorChanged(temp, newStatus: status)
							}
						}
					case .AmbientSensor:
						if let encodedValue : Int32? = extract(value, startAt: 0) {
							let temp = Double(encodedValue! >> 8) / 100
							let rawStatus = Int8(encodedValue! & 0x000F)
							if let status = BCSensorStatus(rawValue: rawStatus) {
								ambientSensorChanged(temp, newStatus: status)
							}
						}
					case .TargetTemp:
						if let temp : BCTemperature? = extract(value, startAt: 0) {
							targetTempChanged(Double(temp!))
						}
					case .LogEntry:
						newLogEntry()
					}

				}
			}
		}
	}
}