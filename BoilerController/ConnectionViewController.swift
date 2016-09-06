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

class ConnectionViewController: UIViewController {
	
	var btDiscovery : BTDiscovery?
	
    @IBOutlet weak var startStopScan: UIButton!
    @IBOutlet weak var output: UITextView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
        startStopScan.snp_makeConstraints { (make) -> Void in make.top.equalTo(40)
            make.centerX.equalTo(self.view)
        }
        output.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(startStopScan.snp_bottom).offset(40)
            make.centerX.equalTo(self.view)
            make.width.equalTo(self.view.snp_width).offset(-20)
            make.height.greaterThanOrEqualTo(400)
        }
	}
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
	
    @IBAction func scanButtonPressed(sender: UIButton) {
		if btDiscovery == nil {
			btDiscovery = BTDiscovery(output: output)
        }
    }

}
