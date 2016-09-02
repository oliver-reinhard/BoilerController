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

class ConnectionViewController: UIViewController, CBCentralManagerDelegate {
    
    //const uint16_t BC_CONTROLLER_SERVICE_ID[] = { 0x4c, 0xef, 0xdd, 0x58, 0xcb, 0x95, 0x44, 0x50, 0x90, 0xfb, 0xf4, 0x04, 0xdc, 0x20, 0x2f, 0x7c};
    //let boilerControllerServiceUUID = CBUUID(string: "4CEFDD58-CB95-4450-90FB-F404DC202F7C")
    let boilerControllerAdvertisingUUID = CBUUID(string: "4CEF");
    
    enum ConnectionStatus : Int {
        case Idle = 0
        case Scanning
        case Connecting
        case Connected
    }
    
    private var cm : CBCentralManager?
    private var peripheral: CBPeripheral?
    private var connectionStatus : ConnectionStatus = ConnectionStatus.Idle
    
    var service: BTService? {
        didSet {
            if let service = self.service {
                service.startDiscoveringServices()
            }
        }
    }
    
    @IBOutlet weak var startStopScan: UIButton!
    @IBOutlet weak var output: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create core bluetooth manager on launch
        if (cm == nil) {
            cm = CBCentralManager(delegate: self, queue: nil)
            output.insertText("CBCentralManager created\n")
            connectionStatus = .Idle
        }
        
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
        if (connectionStatus == .Idle) {
            startScan()
            startStopScan.setTitle("Stop", forState: UIControlState.Normal)
        } else if (connectionStatus == .Scanning || connectionStatus == .Connecting) {
            stopScan()
            connectionStatus = .Idle
            startStopScan.setTitle("Scan", forState: UIControlState.Normal)
        }
    }

    
    func startScan() {
        //Check if Bluetooth is enabled
        if cm?.state == CBCentralManagerState.PoweredOff {
            onBluetoothDisabled()
            return
        }
        
        cm!.scanForPeripheralsWithServices([boilerControllerAdvertisingUUID], options: nil)
        output.insertText("Started Scan …\n")
        connectionStatus = .Scanning
    }
    
    
    func stopScan(){
        cm?.stopScan()
    }
    
    
    func onBluetoothDisabled(){
        //Show alert to enable bluetooth
        let alert = UIAlertController(title: "Bluetooth disabled", message: "Enable Bluetooth in system settings", preferredStyle: UIAlertControllerStyle.Alert)
        let aaOK = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(aaOK)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    //
    // MARK: CBCentralManagerDelegate:
    //
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        output.insertText("CentralManager: DidUpdateState -> power ")
        if (central.state == .PoweredOn){
            output.insertText("ON\n")
        } else if (central.state == .PoweredOff){
            output.insertText("OFF\n")
        }
    }
    
    func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
        output.insertText("CentralManager: willRestoreState\n")
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        output.insertText("CentralManager: didDiscoverPeripheral \(peripheral.name!))\n")
        connectionStatus = .Connecting
        
        if ((peripheral.name == nil) || (peripheral.name == "")) {
            return
        }
        
        // If not already connected to a peripheral, then connect to this one
        if ((self.peripheral == nil) || (self.peripheral?.state == CBPeripheralState.Disconnected)) {
            // Retain the peripheral before trying to connect
            self.peripheral = peripheral
            
            // Reset service
            self.service = nil
            
            central.connectPeripheral(peripheral, options: nil)
        }

    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        
        if (peripheral == self.peripheral) {
            self.service = BTService(initWithPeripheral: peripheral, output: self.output)
            
            output.insertText("CentralManager: didConnectPeripheral \(peripheral.name!) \n")
            connectionStatus = .Connected
        }
        stopScan()


    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        output.insertText("CentralManager: didFailToConnectPeripheral\n")
        connectionStatus = .Idle

    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        output.insertText("CentralManager: didDisconnectPeripheral\n")
        connectionStatus = .Idle

    }
}
