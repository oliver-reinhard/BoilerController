//
//  BTCharacteristicValueManager.swift
//  Boiler-Controller
//
//  Created by Oliver on 2016-09-10.
//  Copyright © 2016 Oliver. All rights reserved.
//
import CoreBluetooth

public protocol BTCharacteristicValueManager {
	
	//func writeValue(forCharacteristicUUID uuid : CBUUID, value : NSData)
	//func writeValue(forCharacteristicUUID uuid : CBUUID, int16 : Int16)
	//func writeValue(forCharacteristicUUID uuid : CBUUID, int32 : Int32)
	//func writeValue(forCharacteristicUUID uuid : CBUUID, float : Float)
	func writeValue<T>(forCharacteristicUUID uuid : CBUUID, value : T)
}