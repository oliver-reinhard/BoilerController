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
	private var cbPeripheralDiscovery : CBPeripheralDiscovery!
	
    @IBOutlet weak var startStopScan: UIButton!
	@IBOutlet weak var deviceName: UITextField!
	@IBOutlet weak var connect: UIButton!
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
        startStopScan.snp_makeConstraints { (make) -> Void in
			make.top.equalTo(self.view).inset(100)
            make.centerX.equalTo(self.view)
        }
		
		deviceName.snp_makeConstraints { (make) -> Void in
			make.top.equalTo(startStopScan.snp_bottom).offset(30)
			make.centerX.equalTo(self.view)
		}
		
		connect.snp_makeConstraints { (make) -> Void in
			make.top.equalTo(deviceName.snp_bottom).offset(30)
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
    
	
    @IBAction func scanButtonPressed(sender: UIButton) {
		if cbPeripheralDiscovery.state == .Idle || cbPeripheralDiscovery.state == .DiscoveredPeripherals {
			cbPeripheralDiscovery.startScan()
		} else if cbPeripheralDiscovery.state == .Scanning {
			cbPeripheralDiscovery.stopScan()
		}
    }
	
	@IBAction func connectButtonPressed(sender: UIButton) {
		if cbPeripheralDiscovery.state == .DiscoveredPeripherals {
			cbPeripheralDiscovery.connectToPeripheral()
		} else if cbPeripheralDiscovery.state == .Connected {
			cbPeripheralDiscovery.disconnectFromPeripheral()
		}
	}
	
	func peripheralDiscovery(discovery : CBPeripheralDiscovery, newState state : CBPeripheralDiscoveryState) {
		if discovery == cbPeripheralDiscovery {
			
			startStopScan.enabled = state == .Idle || state == .Scanning || state == .DiscoveredPeripherals
			let scanTitle =  state == .Scanning ? "Stop" : "Scan"
			startStopScan.setTitle(scanTitle, forState: .Normal)
			
			if state == .DiscoveredPeripherals || state == .Connected {
				deviceName.text = cbPeripheralDiscovery.peripheral?.name
			} else {
				deviceName.text = "No device"
			}
			
			connect.enabled = state == .DiscoveredPeripherals || state == .Connected
			let connectTitle =  state == .DiscoveredPeripherals ? "Connect" : "Disconnect"
			connect.setTitle(connectTitle, forState: .Normal)
		}
	}

}
