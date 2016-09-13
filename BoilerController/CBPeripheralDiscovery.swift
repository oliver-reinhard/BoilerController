//
//  CBDiscovery.swift
//
//  Created by Owen L Brown on 9/24/14 for Arduino_Servo
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//
//  Adapted and extended by Oliver Reinhard
//

import Foundation
import CoreBluetooth
import UIKit


public enum CBPeripheralDiscoveryState {
	
	case Disabled
	case Idle
	case Scanning
	case DiscoveredPeripherals
	case Connected
}

public protocol CBAvailabilityObserver : class {
	func peripheralDiscovery(discovery : CBPeripheralDiscovery, newState state : CBPeripheralDiscoveryState)
}


public class CBPeripheralDiscovery: NSObject, CBCentralManagerDelegate {
	
	public private(set) var advertisingUUID : CBUUID!
 	private var serviceProxies = [CBUUID : GattServiceProxy]()
	
	private var serviceManager: CBServiceManager?
	private var centralManager : CBCentralManager!
	public private(set)  var peripheral : CBPeripheral?
	
	private var availabilityObservers = [CBAvailabilityObserver]()
	
	public private(set) var state = CBPeripheralDiscoveryState.Disabled {
		didSet {
			print("CentralManager: is \(state)")
			// execute on main thread so UI observers don't get into trouble:
			dispatch_async(dispatch_get_main_queue(), {
				for obs in self.availabilityObservers {
					obs.peripheralDiscovery(self, newState: self.state)
				}
			})
		}
	}
	
	init(advertisingUUID : CBUUID) {
		super.init()
		self.advertisingUUID = advertisingUUID
		
		let centralQueue = dispatch_queue_create("boiler-controller", DISPATCH_QUEUE_SERIAL)
		centralManager = CBCentralManager(delegate: self, queue: centralQueue)
	}
	
	
	public func addServiceProxy(proxy : GattServiceProxy) {
		serviceProxies[proxy.serviceUUID] = proxy
		proxy.service(availabilityDidChange: .Uninitialized)
	}
	
	/*
	public func removeServiceProxy(proxy : GattServiceProxy) {
		serviceProxies[proxy.serviceUUID] = nil
		proxy.service(availabilityDidChange: .Uninitialized)
	}
	*/
	
	
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
	
	public func addAvailabilityObserver(observer : CBAvailabilityObserver) {
		for obs in availabilityObservers {
			if obs === observer {
				return
			}
		}
		availabilityObservers.append(observer)
	}
	
	public func removeAvailabilityObserver(observer : CBAvailabilityObserver) {
		for (index, value) in availabilityObservers.enumerate() {
			if value === observer {
				availabilityObservers.removeAtIndex(index)
				break
			}
		}
	}
	
	private func reset(state : CBPeripheralDiscoveryState) {
		self.peripheral = nil
		self.serviceManager?.reset()
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
			self.serviceManager?.reset()
			
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
		if (serviceManager == nil) {
			serviceManager = CBServiceManager(serviceProxies: serviceProxies)
		}
		serviceManager!.startDiscoveringServices(initWithPeripheral: peripheral)
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