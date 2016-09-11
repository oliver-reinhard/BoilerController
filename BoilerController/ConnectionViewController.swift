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

class ConnectionViewController: UIViewController, BCModelContext, BTAvailabilityObserver {
	
	/* Services & Characteristics UUIDs */
	//const uint16_t BC_CONTROLLER_SERVICE_ID[] = { 0x4c, 0xef, 0xdd, 0x58, 0xcb, 0x95, 0x44, 0x50, 0x90, 0xfb, 0xf4, 0x04, 0xdc, 0x20, 0x2f, 0x7c};
	let boilerControllerServiceUUID = CBUUID(string: "4CEFDD58-CB95-4450-90FB-F404DC202F7C")
	let boilerControllerAdvertisingUUID = CBUUID(string: "4CEF");
	
	var controllerModel : BCModel!
	private var btPeripheralDiscovery : BTPeripheralDiscovery!
	
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
		
		
		btPeripheralDiscovery = BTPeripheralDiscovery(forService: boilerControllerServiceUUID, advertisingUUID: boilerControllerAdvertisingUUID, observedBy: controllerModel)
		btPeripheralDiscovery.addAvailabilityObserver(self)
	}
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
	
    @IBAction func scanButtonPressed(sender: UIButton) {
		if btPeripheralDiscovery.state == .Idle || btPeripheralDiscovery.state == .DiscoveredPeripherals {
			btPeripheralDiscovery.startScan()
		} else if btPeripheralDiscovery.state == .Scanning {
			btPeripheralDiscovery.stopScan()
		}
    }
	
	@IBAction func connectButtonPressed(sender: UIButton) {
		if btPeripheralDiscovery.state == .DiscoveredPeripherals {
			btPeripheralDiscovery.connectToPeripheral()
		} else if btPeripheralDiscovery.state == .Connected {
			btPeripheralDiscovery.disconnectFromPeripheral()
		}
	}
	
	func peripheralDiscovery(discovery : BTPeripheralDiscovery, state : BTDiscoveryState) {
		if discovery == btPeripheralDiscovery {
			
			startStopScan.enabled = state == .Idle || state == .Scanning || state == .DiscoveredPeripherals
			let scanTitle =  state == .Scanning ? "Stop" : "Scan"
			startStopScan.setTitle(scanTitle, forState: .Normal)
			
			if state == .DiscoveredPeripherals || state == .Connected {
				deviceName.text = btPeripheralDiscovery.peripheral?.name
			} else {
				deviceName.text = "No device"
			}
			
			connect.enabled = state == .DiscoveredPeripherals || state == .Connected
			let connectTitle =  state == .DiscoveredPeripherals ? "Connect" : "Disconnect"
			connect.setTitle(connectTitle, forState: .Normal)
		}
	}
	
	func serviceDiscovery(discovery : BTServiceManager, isAvailable : Bool) {
		// empty
	}

}
