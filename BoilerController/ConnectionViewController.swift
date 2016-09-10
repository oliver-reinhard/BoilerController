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

class ConnectionViewController: UIViewController, BCModelContext {
	
	/* Services & Characteristics UUIDs */
	//const uint16_t BC_CONTROLLER_SERVICE_ID[] = { 0x4c, 0xef, 0xdd, 0x58, 0xcb, 0x95, 0x44, 0x50, 0x90, 0xfb, 0xf4, 0x04, 0xdc, 0x20, 0x2f, 0x7c};
	let boilerControllerServiceUUID = CBUUID(string: "4CEFDD58-CB95-4450-90FB-F404DC202F7C")
	let boilerControllerAdvertisingUUID = CBUUID(string: "4CEF");
	
	var controllerModel : BCModel!
	private var btDiscovery : BTDiscovery!
	
    @IBOutlet weak var startStopScan: UIButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
        startStopScan.snp_makeConstraints { (make) -> Void in make.top.equalTo(40)
            make.centerX.equalTo(self.view)
        }
	}
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
	
    @IBAction func scanButtonPressed(sender: UIButton) {
		if btDiscovery == nil {
			btDiscovery = BTDiscovery(forService: boilerControllerServiceUUID, advertisingUUID: boilerControllerAdvertisingUUID, observedBy: controllerModel)
        }
    }

}
