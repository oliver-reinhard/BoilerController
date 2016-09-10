//
//  BTDiscovery.swift
//
//  Created by Owen L Brown on 9/24/14 for Arduino_Servo
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//
//  Adapted and extended by Oliver Reinhard
//

import Foundation
import CoreBluetooth
import UIKit

public class BTDiscovery: NSObject, CBCentralManagerDelegate {
	
	private(set) var serviceUUID : CBUUID!
	private(set) var advertisingUUID : CBUUID!
	private(set) var observer : BTCharacteristicValueObserver?
	private var centralManager : CBCentralManager?
    private var service: BTService? {
        didSet {
            if let service = self.service {
                service.startDiscoveringServices()
            }
        }
	}
	private var peripheral : CBPeripheral?
	
	init(forService serviceUUID : CBUUID, advertisingUUID : CBUUID?, observedBy observer : BTCharacteristicValueObserver?) {
		super.init()
		
		let centralQueue = dispatch_queue_create("boiler-controller", DISPATCH_QUEUE_SERIAL)
		centralManager = CBCentralManager(delegate: self, queue: centralQueue)
		self.serviceUUID = serviceUUID
		if advertisingUUID != nil {
			self.advertisingUUID = advertisingUUID!
		} else {
			// service advertises first 2 bytes (= 4 hex characters) of 16-byte UUID
			let uuid2str = String(serviceUUID.UUIDString.characters.prefix(4))
			self.advertisingUUID = CBUUID(string: uuid2str)
		}
		self.observer = observer
	}
	
	
	func startScan() {
		centralManager?.scanForPeripheralsWithServices([advertisingUUID], options: nil)
		print("\nCentralManager: Started Scan for advertising UUID \(advertisingUUID)...")
	}
	
	func clearDevices() {
		self.service = nil
		self.peripheral = nil
	}
	
	
	// MARK: - CBCentralManagerDelegate
	
	public func centralManagerDidUpdateState(central: CBCentralManager) {
		switch (central.state) {
		case CBCentralManagerState.PoweredOff:
			self.clearDevices()
			
		case CBCentralManagerState.Unauthorized:
			// Indicate to user that the iOS device does not support BLE.
			break
			
		case CBCentralManagerState.Unknown:
			// Wait for another event
			break
			
		case CBCentralManagerState.PoweredOn:
			self.startScan()
			
		case CBCentralManagerState.Resetting:
			self.clearDevices()
			
		case CBCentralManagerState.Unsupported:
			break
		}
	}
	
	public func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
		guard peripheral.name != nil && peripheral.name != "" else {
			return
		}
		
		if self.peripheral == nil || self.peripheral?.state == CBPeripheralState.Disconnected {
			self.peripheral = peripheral
			self.service = nil // reset service
			central.connectPeripheral(peripheral, options: nil)
		}
	}
	
	public func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
		
		guard peripheral == self.peripheral else {
			return
		}
		central.stopScan()
		print("CentralManager: connected to peripheral \(peripheral.name!)")
		self.service = BTService(initWithPeripheral: peripheral, forService: serviceUUID, observedBy: observer)
	}
	
	public func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
		print("CentralManager: failed to connect to peripheral \(peripheral.name!)")
		
	}
	
	public func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
		if peripheral == self.peripheral {
			print("CentralManager: disconnected from peripheral \(peripheral.name!)")

			self.service = nil;
			self.peripheral = nil;
		}
		self.startScan()
	}
	
	public func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
		print("CentralManager: will restore state")
	}
	
}
