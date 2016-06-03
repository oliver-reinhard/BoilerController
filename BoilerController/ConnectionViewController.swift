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

class ConnectionViewController: UIViewController, CBCentralManagerDelegate {
    
    enum ConnectionStatus:Int {
        case Idle = 0
        case Scanning
        case Connecting
        case Connected
    }
    
    private var cm:CBCentralManager?
    var connectionStatus:ConnectionStatus = ConnectionStatus.Idle
    
    @IBOutlet weak var output: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create core bluetooth manager on launch
        if (cm == nil) {
            cm = CBCentralManager(delegate: self, queue: nil)
            output.insertText("CBCentralManager created\n")
            connectionStatus = .Idle
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func connectButton(sender: UIButton) {
        startScan()
    }
    
    func startScan() {
        //Check if Bluetooth is enabled
        if cm?.state == CBCentralManagerState.PoweredOff {
            onBluetoothDisabled()
            return
        }
        
        cm!.scanForPeripheralsWithServices(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
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

    
    
    func connectPeripheral(peripheral:CBPeripheral) {
        
        //Check if Bluetooth is enabled
        if cm?.state == CBCentralManagerState.PoweredOff {
            onBluetoothDisabled()
            return
        }
        stopScan()
        
        //Cancel any current or pending connection to the peripheral
        if peripheral.state == CBPeripheralState.Connected || peripheral.state == CBPeripheralState.Connecting {
            cm!.cancelPeripheralConnection(peripheral)
        }
        
        cm!.connectPeripheral(peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: NSNumber(bool:true)])
        
        connectionStatus = .Connecting
        
        // Start connection timeout timer
        //connectionTimer = NSTimer.scheduledTimerWithTimeInterval(connectionTimeOutIntvl, target: self, selector: Selector("connectionTimedOut:"), userInfo: nil, repeats: false)
    }
    
    //
    // MARK: CBCentralManagerDelegate:
    //
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if (central.state == .PoweredOn){
            output.insertText("Notification: centralManagerDidUpdateState -> power ON\n")
        } else if (central.state == .PoweredOff){
            output.insertText("Notification: centralManagerDidUpdateState -> power OFF\n")
        }
    }
    
    func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
        output.insertText("Notification: centralManager: willRestoreState\n")
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        output.insertText("Notification: centralManager: didDiscoverPeripheral " + peripheral.name! + "\n")
        
        connectionStatus = .Connecting

    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        output.insertText("Notification: centralManager: didConnectPeripheral\n")
        connectionStatus = .Connected

    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        output.insertText("Notification: centralManager: didFailToConnectPeripheral\n")
        connectionStatus = .Idle

    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        output.insertText("Notification: centralManager: didDisconnectPeripheral\n")
        connectionStatus = .Idle

    }
}
