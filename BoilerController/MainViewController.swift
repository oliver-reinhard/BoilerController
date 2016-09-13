//
//  MainViewController.swift
//  BoilerController
//
//  Created by Oliver on 2016-04-07.
//  Copyright © 2016 Oliver. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, ControllerModelContext, GattServiceObserver {
	
	var controllerModel : ControllerModel!
	
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
	
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
	}
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		guard controllerModel != nil else {
			fatalError("Expected BCModel to be set")
		}
        
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
			make.right.equalTo(mainView.snp_right)
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
		
		updateState()
		updateTimeInState()
		updateTimeHeated()
		updateTimeToGo()
		updateAcceptedCommands()
		updateWaterSensor()
		updateAmbientSensor()
		updateTargetTemp()
		
		controllerModel.addServiceObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func targetTempChanged(sender: UIStepper) {
		controllerModel.targetTemperature.requestedValue = sender.value
    }
    
    @IBAction func leftButtonPressed(sender: UIButton) {
        print("Left")
    }
    
    @IBAction func rightButtonPressed(sender: UIButton) {
        print("Right")
	}
	
	
	// MARK: GattServiceObserver
	func service(service : GattService, availabilityDidChange availability : GattServiceAvailability) {
		print("Main View: service availability: \(availability)")
	}
	
	func attribute(service : GattService, valueDidChangeFor attribute : GattAttribute) {
		let model = self.controllerModel
		if attribute === model.state {
			self.updateState()
		} else if attribute === model.timeInState {
			self.updateTimeInState()
		} else if attribute === model.timeHeated {
			self.updateTimeHeated()
		} else if attribute === model.acceptedUserCmds {
			self.updateAcceptedCommands()
		} else if attribute === model.waterSensor {
			self.updateWaterSensor()
		} else if attribute === model.ambientSensor {
			self.updateAmbientSensor()
		} else if attribute === model.targetTemperature {
			self.updateTargetTemp()
		} else {
			print("Unhandled attribute: \(attribute)")
		}
	}
	
	func attribute(service : GattService, requestedValueDidFailFor attribute : GattAttribute) {
		
	}

	
	private func formatTime(millis : BCMillis?) -> String {
		guard millis != nil else {
			return "-:--:--"
		}
		let zero : Character = "0"
		let separator : Character = ":"
		let secs = millis! / 1000
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
	
	private func formatTemperature(temperature : Double?, printDecimal : Bool) -> String {
		let unit = "°C"
		guard temperature != nil else {
			return "--" + unit
		}
		if (printDecimal) {
			let t = floor(temperature! * 10) / 10
			return t.description + unit
		} else {
			let t : Int16 = Int16(temperature!)
			return t.description + unit
		}
	}
	
	private func updateState() {
		guard let value = controllerModel.state.value else {
			state.text = "--"
			return
		}
		state.text = value.display()
	}
	
	private func updateTimeInState() {
		timeInState.text = formatTime(controllerModel.timeInState.value)
	}
	
	private func updateTimeHeated() {
		timeHeated.text = formatTime(controllerModel.timeHeated.value)
	}
	
	private func updateTimeToGo() {
		timeToGo.text = formatTime(nil)
	}
	
	private func updateAcceptedCommands() {
		//super.acceptedCommands(controllerModel.acceptedUserCmds.value)  /////////////////////// fix this
	}
	
	private func updateWaterSensor() {
		guard let sensor = controllerModel.waterSensor.value else {
			waterTemp.text = formatTemperature(nil, printDecimal: true)
			return
		}
		if sensor.status == .OK {
			waterTemp.text = formatTemperature(sensor.temperature, printDecimal: true)
		} else {
			waterTemp.text = sensor.status.display()
		}
	}
	
	private func updateAmbientSensor() {
		guard let sensor = controllerModel.ambientSensor.value else {
			airTemp.text = formatTemperature(nil, printDecimal: true)
			return
		}
		if sensor.status == .OK {
			airTemp.text = formatTemperature(sensor.temperature, printDecimal: true)
		} else {
			airTemp.text = sensor.status.display()
		}
	}
	
	private func updateTargetTemp() {
		targetTemp.text = formatTemperature(controllerModel.targetTemperature.value, printDecimal: false)
	}
}

