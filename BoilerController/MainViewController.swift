//
//  FirstViewController.swift
//  BoilerController
//
//  Created by Oliver on 2016-04-07.
//  Copyright © 2016 Oliver. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    @IBOutlet var outerView: UIView!
    @IBOutlet weak var mainView: UIView!
    
    @IBOutlet weak var airLabel: UILabel!
    @IBOutlet weak var airTemp: UILabel!
    
    @IBOutlet weak var waterLabel: UILabel!
    @IBOutlet weak var waterTemp: UILabel!
    
    @IBOutlet weak var targetTempLabel: UILabel!
    @IBOutlet weak var targetTemp: UILabel!
    @IBOutlet weak var targetTempStepper: UIStepper!
    
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var state: UILabel!
    @IBOutlet weak var timeInState: UILabel!
    
    @IBOutlet weak var timeToGoLabel: UILabel!
    @IBOutlet weak var timeToGo: UILabel!
    
    @IBOutlet weak var timeHeatedLabel: UILabel!
    @IBOutlet weak var timeHeated: UILabel!
    
    @IBOutlet weak var waterSensorFootnote: UILabel!
    
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let padding = UIEdgeInsetsMake(30, 10, 10, 10)
        let lineSpacing = 15
        
         mainView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(outerView.snp_top).offset(padding.top)
            make.left.equalTo(outerView.snp_left).offset(padding.left)
            make.bottom.equalTo(outerView.snp_bottom).offset(-padding.bottom)
            make.right.equalTo(outerView.snp_right).offset(-padding.right)
        }
        
        airTemp.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(mainView.snp_top)
            make.right.equalTo(mainView.snp_right)
        }
        
        airLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(airTemp.snp_centerY)
            make.left.equalTo(mainView.snp_left)
        }
        
        waterTemp.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(airTemp.snp_bottom).offset(lineSpacing)
            make.right.equalTo(mainView.snp_right)
        }
        
        waterLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(waterTemp.snp_centerY)
            make.left.equalTo(mainView.snp_left)
        }
        
        targetTemp.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(waterTemp.snp_bottom).offset(lineSpacing)
            make.right.equalTo(mainView.snp_right)
        }
        
        targetTempLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(targetTemp.snp_centerY)
            make.left.equalTo(mainView.snp_left)
        }
        
        targetTempStepper.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(targetTemp.snp_bottom).offset(lineSpacing / 3)
            make.right.equalTo(mainView.snp_right)
        }

        state.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(targetTempStepper.snp_bottom).offset(lineSpacing)
            make.right.equalTo(mainView.snp_right)
        }
        
        stateLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(state.snp_centerY)
            make.left.equalTo(mainView.snp_left)
        }
        
        timeInState.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(state.snp_bottom).offset(lineSpacing / 3)
            make.centerX.equalTo(state.snp_centerX)
        }
        
        timeToGo.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(timeInState.snp_bottom).offset(lineSpacing)
            make.centerX.equalTo(state.snp_centerX)
        }
        
        timeToGoLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(timeToGo.snp_centerY)
            make.left.equalTo(mainView.snp_left)
        }
        
        timeHeated.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(timeToGo.snp_bottom).offset(lineSpacing)
            make.centerX.equalTo(state.snp_centerX)
        }
        
        timeHeatedLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(timeHeated.snp_centerY)
            make.left.equalTo(mainView.snp_left)
        }
        
        waterSensorFootnote.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(timeHeated.snp_bottom).offset(lineSpacing * 2)
            make.left.equalTo(mainView.snp_left)
        }
        
        leftButton.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(mainView.snp_left).offset(40)
            make.bottom.equalTo(mainView.snp_bottom).offset(-10)
        }
        
        rightButton.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(leftButton.snp_centerY)
            make.right.equalTo(mainView.snp_right).offset(-40)
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func targetTempChanged(sender: UIStepper) {
        updateTargetTemperature(sender.value)
    }
    
    @IBAction func leftButtonPressed(sender: UIButton) {
        print("Left")
    }
    
    @IBAction func rightButtonPressed(sender: UIButton) {
        print("Right")
    }
    
    func updateAmbientTemperature(temperature : Double, status : BCSensorStatus) {
        airTemp.text = formatTemperature(temperature, printDecimal: true)
    }
    
    func updateWaterTemperature(temperature : Double, status : BCSensorStatus) {
        waterTemp.text = formatTemperature(temperature, printDecimal: true)
    }
    
    func updateTargetTemperature(temperature : Double) {
        targetTemp.text = formatTemperature(temperature, printDecimal: false)
    }
    
    func updateState(state : BCControllerState) {
        self.state.text = state.rawValue.description // !!!!! FIX THIS
    }
    
    func updateTimeInState(millis : BCMillis) {
        timeInState.text = formatTime(millis)
    }
    
    func updateTimeHeated(millis : BCMillis) {
        timeHeated.text = formatTime(millis)
    }
    
    func updateTimeToGo(millis : BCMillis) {
        timeToGo.text = formatTime(millis)
    }
    
    func updateAvailableCommands(commands : BCUserCommands) {
        
    }
    
    private func formatTime(millis : BCMillis) -> String {
        let zero : Character = "0"
        let separator : Character = ":"
        let secs = millis / 1000
        let secPart = secs % 60
        let mins = secs / 60
        let minPart = mins % 60
        let hours = mins / 60
        var result = hours.description
        result.append(separator)
        if (minPart < 10) {
            result.append(zero)
        }
        result.appendContentsOf(minPart.description)
        result.append(separator)
        if (secPart < 10) {
            result.append(zero)
        }
        result.appendContentsOf(secPart.description)
        return result
    }
    
    private func formatTemperature(temperature : Double, printDecimal : Bool) -> String {
        let unit = "°C"
        if (printDecimal) {
            let t = floor(temperature * 10) / 10
            return t.description + unit
        } else {
            let t : Int16 = Int16(temperature)
            return t.description + unit
        }
    }
    
}

