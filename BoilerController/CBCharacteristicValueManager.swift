//
//  BTCharacteristicValueManager.swift
//  Boiler-Controller
//
//  Created by Oliver on 2016-09-10.
//  Copyright © 2016 Oliver. All rights reserved.
//
import CoreBluetooth

public protocol CBCharacteristicValueManager {
	
	func updateValue<T>(forAttribute attribute : GattModifiableAttribute<T>, value : NSData, withResponse type: CBCharacteristicWriteType)
}