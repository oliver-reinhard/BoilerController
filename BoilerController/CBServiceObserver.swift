//
//  BTCharacteristicValueObserver.swift
//  Boiler-Controller
//
//  Created by Oliver on 2016-09-10.
//  Copyright © 2016 Oliver. All rights reserved.
//

import CoreBluetooth

public protocol CBServiceObserver {
	func service(availabilityDidChange cbAvailability : CBServiceAvailability)
	func characteristic(valueUpdatedFor characteristic : CBCharacteristic)
}