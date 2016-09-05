//
//  BTDiscovery.swift
//  Arduino_Servo
//
//  Created by Owen L Brown on 9/24/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

class BTDiscovery: NSObject, CBCentralManagerDelegate {
  
	private var centralManager : CBCentralManager?
    private var service: BTService? {
        didSet {
            if let service = self.service {
                service.startDiscoveringServices()
            }
        }
	}
	private var peripheral : CBPeripheral?
	
	init(output: UITextView) {
		super.init()
		
		let centralQueue = dispatch_queue_create("boiler-controller", DISPATCH_QUEUE_SERIAL)
		centralManager = CBCentralManager(delegate: self, queue: centralQueue)
	}
	
	
	func startScanning() {
		centralManager?.scanForPeripheralsWithServices([boilerControllerAdvertisingUUID], options: nil)
		print("\nCentralManager: Started Scan ...")
	}
	
	func clearDevices() {
		self.service = nil
		self.peripheral = nil
	}
	
	
	// MARK: - CBCentralManagerDelegate
	
	func centralManagerDidUpdateState(central: CBCentralManager) {
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
			self.startScanning()
			
		case CBCentralManagerState.Resetting:
			self.clearDevices()
			
		case CBCentralManagerState.Unsupported:
			break
		}
	}
	
	func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
		if peripheral.name == nil || peripheral.name == "" {
			return
		}
		
		if self.peripheral == nil || self.peripheral?.state == CBPeripheralState.Disconnected {
			self.peripheral = peripheral
			self.service = nil // reset service
			central.connectPeripheral(peripheral, options: nil)
		}
	}
	
	func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
		if peripheral == self.peripheral {
			print("CentralManager: connected to peripheral \(peripheral.name!)")
			self.service = BTService(initWithPeripheral: peripheral)
		}
		central.stopScan()
	}
	
	func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
		print("CentralManager: failed to connect to peripheral \(peripheral.name!)")
		
	}
	
	func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
		if peripheral == self.peripheral {
			print("CentralManager: disconnected from peripheral \(peripheral.name!)")

			self.service = nil;
			self.peripheral = nil;
		}
		self.startScanning()
	}
	
	func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
		print("CentralManager: will restore state")
	}
	
}
