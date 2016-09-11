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


public enum BTDiscoveryState {
	
	case Disabled
	case Idle
	case Scanning
	case DiscoveredPeripherals
	case Connected
}

public protocol BTAvailabilityObserver : class {
	func peripheralDiscovery(discovery : BTPeripheralDiscovery, state : BTDiscoveryState)
	func serviceDiscovery(discovery : BTServiceManager, isAvailable : Bool)
}


public class BTPeripheralDiscovery: NSObject, CBCentralManagerDelegate {
	
	
	private(set) var serviceUUID : CBUUID!
	private(set) var advertisingUUID : CBUUID!
	private(set) var observer : BTCharacteristicValueObserver?
	private var service: BTServiceManager!
	private var centralManager : CBCentralManager!
	public private(set) var peripheral : CBPeripheral?
	
	private var availabilityObservers = [BTAvailabilityObserver]()
	
	public private(set) var state = BTDiscoveryState.Disabled {
		didSet {
			print("CentralManager: is \(state)")
			dispatch_async(dispatch_get_main_queue(), {
				for obs in self.availabilityObservers {
					obs.peripheralDiscovery(self, state: self.state)
				}
			})
		}
	}
	
	init(forService serviceUUID : CBUUID, advertisingUUID : CBUUID?, observedBy observer : BTCharacteristicValueObserver?) {
		super.init()
		
		self.serviceUUID = serviceUUID
		if advertisingUUID != nil {
			self.advertisingUUID = advertisingUUID!
		} else {
			// service advertises first 2 bytes (= 4 hex characters) of 16-byte UUID
			let uuid2str = String(serviceUUID.UUIDString.characters.prefix(4))
			self.advertisingUUID = CBUUID(string: uuid2str)
		}
		self.observer = observer
		self.service = BTServiceManager(forService: serviceUUID, observedBy: observer)
		
		let centralQueue = dispatch_queue_create("boiler-controller", DISPATCH_QUEUE_SERIAL)
		centralManager = CBCentralManager(delegate: self, queue: centralQueue)
	}
	
	
	public func startScan() {
		if state == .Idle || state == .DiscoveredPeripherals {
			reset(.Scanning)
			centralManager?.scanForPeripheralsWithServices([advertisingUUID], options: nil)
			print("\nCentralManager: Started Scan for advertising UUID \(advertisingUUID)")
		}
	}
	
	
	public func stopScan() {
		if state == .Scanning {
			centralManager?.stopScan()
			print("\nCentralManager: Stopped Scan, isScanning = \(centralManager.isScanning)")
			state = peripheral == nil ? .Idle : .DiscoveredPeripherals
		}
	}
	
	public func connectToPeripheral() {
		if state == .DiscoveredPeripherals {
			centralManager.connectPeripheral(peripheral!, options: nil)
		}
	}
	
	public func disconnectFromPeripheral() {
		if state == .Connected {
			centralManager.cancelPeripheralConnection(peripheral!)
		}
	}
	
	public func addAvailabilityObserver(observer : BTAvailabilityObserver) {
		for obs in availabilityObservers {
			if obs === observer {
				return
			}
		}
		availabilityObservers.append(observer)
	}
	
	public func removeAvailabilityObserver(observer : BTAvailabilityObserver) {
		for (index, value) in availabilityObservers.enumerate() {
			if value === observer {
				availabilityObservers.removeAtIndex(index)
				break
			}
		}
		availabilityObservers.append(observer)
	}
	
	private func reset(state : BTDiscoveryState) {
		self.peripheral = nil
		self.service.reset()
		self.state = state
	}
	
	
	// MARK: - CBCentralManagerDelegate
	
	public func centralManagerDidUpdateState(central: CBCentralManager) {
		switch (central.state) {
		case CBCentralManagerState.PoweredOff:
			self.reset(.Disabled)
			
		case CBCentralManagerState.Unauthorized:
			// Indicate to user that the iOS device does not support BLE.
			state = .Disabled
			
		case CBCentralManagerState.Unknown:
			// Wait for another event
			state = .Disabled
			
		case CBCentralManagerState.PoweredOn:
			state = .Idle
			
		case CBCentralManagerState.Resetting:
			self.reset(.Disabled)
			
		case CBCentralManagerState.Unsupported:
			state = .Disabled
		}
	}
	
	public func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
		
		guard peripheral.name != nil && peripheral.name != "" else {
			return
		}
		
		//
		// This method wil be called more than once for a scan if several devices are being detected.
		// At this time we can handle just a single one and we'll give preference to the first one discovered.
		//
		if self.peripheral == nil || self.peripheral?.state == CBPeripheralState.Disconnected {
			print("CentralManager: discovered peripheral \(peripheral.name!), advertisment: \(advertisementData), RSSI: \(RSSI)")
			self.peripheral = peripheral
			self.service.reset()
			
			// stop after the first one discovered
			stopScan()
		}
	}
	
	
	public func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
		
		guard peripheral == self.peripheral else {  // we're only dealing with 1 peripheral here
			return
		}
		print("CentralManager: connected to peripheral \(peripheral.name!), isScanning = \(centralManager.isScanning)")
		state = .Connected
		
		// auto-discover services:
		service.startDiscoveringServices(initWithPeripheral: peripheral)
	}
	
	
	public func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
		
		guard peripheral == self.peripheral else {	// we're only dealing with 1 peripheral here
			return
		}
		print("CentralManager: failed to connect to peripheral \(peripheral.name!), isScanning = \(centralManager.isScanning)")
		reset(.Idle)
		startScan()
	}
	
	
	public func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
		
		guard peripheral == self.peripheral else {
			return
		}
		print("CentralManager: disconnected from peripheral \(peripheral.name!), isScanning = \(centralManager.isScanning)")
		reset(.Idle)
		startScan()
	}
	
	
	public func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
		print("CentralManager: will restore state, isScanning = \(centralManager.isScanning)")
	}
}
