//
//  BTCharacteristicValueObserver.swift
//  Boiler-Controller
//
//  Created by Oliver on 2016-09-10.
//  Copyright © 2016 Oliver. All rights reserved.
//

import CoreBluetooth

public protocol BTCharacteristicValueObserver {
	func characteristicValueUpdated(forCharacteristic characteristic : CBCharacteristic)
}