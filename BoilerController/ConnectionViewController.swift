//
//  ConnectionViewController.swift
//  BoilerController
//
//  Created by Oliver on 2016-05-20.
//  Copyright © 2016 Oliver. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth
import SnapKit

class ConnectionViewController: UIViewController, ControllerModelContext, CBAvailabilityObserver {
	
	
	var controllerModel : ControllerModel!
	fileprivate var cbPeripheralDiscovery : CBPeripheralDiscovery!
	
    @IBOutlet weak var startStopScan: UIButton!
	@IBOutlet weak var deviceName: UITextField!
	@IBOutlet weak var connect: UIButton!
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
        startStopScan.snp.makeConstraints { (make) -> Void in
			make.top.equalTo(self.view).inset(100)
            make.centerX.equalTo(self.view)
        }
		
		deviceName.snp.makeConstraints { (make) -> Void in
			make.top.equalTo(startStopScan.snp.bottom).offset(30)
			make.centerX.equalTo(self.view)
		}
		
		connect.snp.makeConstraints { (make) -> Void in
			make.top.equalTo(deviceName.snp.bottom).offset(30)
			make.centerX.equalTo(self.view)
		}
		
		
		cbPeripheralDiscovery = CBPeripheralDiscovery(advertisingUUID: boilerControllerAdvertisingUUID)
		cbPeripheralDiscovery.addServiceProxy(controllerModel)
		cbPeripheralDiscovery.addAvailabilityObserver(self)
	}
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
	
    @IBAction func scanButtonPressed(_ sender: UIButton) {
		if cbPeripheralDiscovery.state == .idle || cbPeripheralDiscovery.state == .discoveredPeripherals {
			cbPeripheralDiscovery.startScan()
		} else if cbPeripheralDiscovery.state == .scanning {
			cbPeripheralDiscovery.stopScan()
		}
    }
	
	@IBAction func connectButtonPressed(_ sender: UIButton) {
		if cbPeripheralDiscovery.state == .discoveredPeripherals {
			cbPeripheralDiscovery.connectToPeripheral()
		} else if cbPeripheralDiscovery.state == .connected {
			cbPeripheralDiscovery.disconnectFromPeripheral()
		}
	}
	
	func peripheralDiscovery(_ discovery : CBPeripheralDiscovery, newState state : CBPeripheralDiscoveryState) {
		if discovery == cbPeripheralDiscovery {
			
			startStopScan.isEnabled = state == .idle || state == .scanning || state == .discoveredPeripherals
			let scanTitle =  state == .scanning ? "Stop" : "Scan"
			startStopScan.setTitle(scanTitle, for: UIControlState())
			
			if state == .discoveredPeripherals || state == .connected {
				deviceName.text = cbPeripheralDiscovery.peripheral?.name
			} else {
				deviceName.text = "No device"
			}
			
			connect.isEnabled = state == .discoveredPeripherals || state == .connected
			let connectTitle =  state == .discoveredPeripherals ? "Connect" : "Disconnect"
			connect.setTitle(connectTitle, for: UIControlState())
		}
	}

}
