//
//  MainViewController.swift
//  BoilerController
//
//  Created by Oliver on 2016-04-07.
//  Copyright © 2016 Oliver. All rights reserved.
//

import UIKit
import StackViewController

class MainViewController: UIViewController, ControllerModelContext, GattServiceObserver {
	
	var controllerModel : ControllerModel!
	let stackViewController: StackViewController
	
	var ambientTemp: LabeledDataFieldController!
	var waterTemp: LabeledDataFieldController!
	
	var targetTemp: LabeledDataFieldController!
	static let minTargetTemp = 30
	static let maxTargetTemp = 50
	var targetTempPicker : UIPickerView!
	let targetTempPickerHandler = TargetTempPickerHandler()
	
	var state: LabeledDataFieldController!
	var timeInState: LabeledDataFieldController!
	var timeToGo: LabeledDataFieldController!
	var timeHeated: LabeledDataFieldController!
	
	
	enum ButtonAction {
		case None
		case Rec_On
		case Rec_Off
		case Heat_On
		case Heat_Off
		case Heat_Reset
		case Configuration
		
		func display() -> String {
			switch self {
			case None:
				return "N/A"
			case Rec_On:
				return "Recording On"
			case Rec_Off:
				return "Recording Off"
			case Heat_On:
				return "Heat On"
			case Heat_Off:
				return "Heat Off"
			case Heat_Reset:
				return "Reset Heat"
			case .Configuration:
				return "Configuration"
			}
		}
	}
	
	var leftButton : UIButton!
	var leftButtonState =   (ButtonAction.None, BCUserCommand.None)
	var rightButton : UIButton!
	var rightButtonState = (ButtonAction.None, BCUserCommand.None)
	
	required init?(coder aDecoder: NSCoder) {
		stackViewController = StackViewController()
		stackViewController.stackViewContainer.separatorViewFactory = StackViewContainer.createSeparatorViewFactory()
		super.init(coder: aDecoder)
		edgesForExtendedLayout = .None
	}
	
	override func loadView() {
		view = UIView(frame: CGRectZero)
		view.backgroundColor = .whiteColor()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		guard controllerModel != nil else {
			fatalError("Expected ControllerModel to be set")
		}
		controllerModel.addServiceObserver(self)
		
		let titleLabel = UILabel(frame: CGRectZero)
		titleLabel.text = "Controller"
		titleLabel.textColor = UIColor.blackColor()
		titleLabel.font = UIFont.boldSystemFontOfSize(18)
		view.addSubview(titleLabel)

		ambientTemp = LabeledDataFieldController(labelText: "Ambient Temperature")
		stackViewController.addItem(ambientTemp)
		updateAmbientSensor()
		
		waterTemp = LabeledDataFieldController(labelText: "Water Temperature")
		stackViewController.addItem(waterTemp)
		updateWaterSensor()

		targetTemp = LabeledDataFieldController(labelText: "Target Temperature")
		stackViewController.addItem(targetTemp)
		targetTemp.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MainViewController.didTapTargetTemp)))
		updateTargetTemp()
		
		targetTempPicker = UIPickerView(frame: CGRectZero)
		targetTempPicker.dataSource = targetTempPickerHandler
		targetTempPicker.delegate = targetTempPickerHandler
		targetTempPicker.hidden = true
		targetTempPickerHandler.controllerModel = controllerModel

		state = LabeledDataFieldController(labelText: "State")
		stackViewController.addItem(state)
		updateState()

		timeInState = LabeledDataFieldController(labelText: "Time in State")
		stackViewController.addItem(timeInState)
		updateTimeInState()

		timeToGo = LabeledDataFieldController(labelText: "Time to Go")
		stackViewController.addItem(timeToGo)
		updateTimeToGo()

		timeHeated = LabeledDataFieldController(labelText: "Time Heated")
		stackViewController.addItem(timeHeated)
		updateTimeHeated()
		
		view.addSubview(stackViewController.view)
		addChildViewController(stackViewController)
		//stackViewController.view.activateSuperviewHuggingConstraints()
		stackViewController.didMoveToParentViewController(self)
		
		leftButton = UIButton(type: .System)
		leftButton.titleLabel!.font = titleLabel.font
		leftButton.addTarget(self, action: #selector(MainViewController.leftButtonPressed(_:)), forControlEvents: .TouchUpInside)
		view.addSubview(leftButton)
		
		rightButton = UIButton(type: .System)
		rightButton.titleLabel!.font = titleLabel.font
		rightButton.addTarget(self, action: #selector(MainViewController.rightButtonPressed(_:)), forControlEvents: .TouchUpInside)
		view.addSubview(rightButton)
		updateAcceptedCommands()
		
		//
		// Layout
		//
		let padding = UIEdgeInsetsMake(30, 15, 25, 15)
		let spacing = 5
		
		titleLabel.snp_makeConstraints { (make) -> Void in
			make.top.equalTo(view.snp_top).offset(padding.top)
			make.centerX.equalTo(view.snp_centerX)
		}

		leftButton.snp_makeConstraints { (make) -> Void in
			make.left.equalTo(view.snp_left).offset(padding.left)
			make.bottom.equalTo(view.snp_bottom).offset(-padding.bottom)
		}
		
		rightButton.snp_makeConstraints { (make) -> Void in
			make.right.equalTo(view.snp_right).offset(-padding.right)
			make.centerY.equalTo(leftButton.snp_centerY)
		}
		
		stackViewController.view.snp_makeConstraints { (make) -> Void in
			make.top.equalTo(titleLabel.snp_bottom).offset(spacing)
			make.left.equalTo(view.snp_left)
			make.bottom.equalTo(leftButton.snp_top).offset(-spacing)
			make.right.equalTo(view.snp_right)
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func didTapTargetTemp() {
		UIView.animateWithDuration(0.5) { () -> Void in
			let picker = self.targetTempPicker
			// only show picker view if target temp is not nil
			if picker.hidden && self.controllerModel.targetTemperature.value != nil {
				self.stackViewController.insertItem(picker, atIndex: 3)
				picker.hidden = false
			} else if !picker.hidden {
				self.stackViewController.removeItem(picker)
				picker.hidden = true
			}
		}
	}
	
	func leftButtonPressed(sender: UIButton!) {
		if leftButtonState.1 != .None {
			controllerModel.userRequest.requestedValue = leftButtonState.1.rawValue
			//print("Left: \(leftButtonState.1)")
		}
    }
	
	func rightButtonPressed(sender: UIButton!) {
		if rightButtonState.1 != .None {
			controllerModel.userRequest.requestedValue = rightButtonState.1.rawValue
        	//print("Right: \(rightButtonState.1)")
		}
	}
	
	private func evaluateUserCommandsForLeftButton() -> (ButtonAction, BCUserCommand) {
		if let userCommands = controllerModel.acceptedUserCmds.value {
			if userCommands & BCUserCommand.Rec_On.rawValue > 0 {
				return (.Rec_On, BCUserCommand.Rec_On)
				
			} else if userCommands & BCUserCommand.Rec_Off.rawValue > 0 {
				return (.Rec_Off, BCUserCommand.Rec_Off)
				
			} else if userCommands & BCUserCommand.Heat_Reset.rawValue > 0 {
				return (.Heat_Reset, BCUserCommand.Heat_Reset)
			}
		}
		return (.None, BCUserCommand.None)
		
	}
	
	private func evaluateUserCommandsForRightButton() -> (ButtonAction, BCUserCommand) {
		if let userCommands = controllerModel.acceptedUserCmds.value {
			if userCommands & BCUserCommand.Heat_On.rawValue > 0 {
				return (.Heat_On, BCUserCommand.Heat_On)
				
			} else if userCommands & BCUserCommand.Heat_Off.rawValue > 0 {
				return (.Heat_Off, BCUserCommand.Heat_Off)
				
			} else if userCommands.containsConfigurationCommand() {
				return (.Configuration, BCUserCommand.None)
			}
		}
		return (.None, BCUserCommand.None)
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
		} else if attribute === model.timeToGo {
			self.updateTimeToGo()
		} else if attribute === model.acceptedUserCmds {
			self.updateAcceptedCommands()
		} else if attribute === model.waterSensor {
			self.updateWaterSensor()
		} else if attribute === model.ambientSensor {
			self.updateAmbientSensor()
		} else if attribute === model.targetTemperature {
			self.updateTargetTemp()
		} else {
			print("Unhandled attribute: \(attribute.characteristicUUID)")
		}
	}
	
	func attribute(service : GattService, requestedValueDidFailFor attribute : GattAttribute) {
		
	}
	

	// DISPLAY utility functions
	
	private func formatTime(secs : BCSeconds?) -> String {
		guard secs != nil && secs != UndefinedBCSeconds else {
			return "-:--:--"
		}
		let zero : Character = "0"
		let separator : Character = ":"
		let secPart = secs! % 60
		let mins = secs! / 60
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
	
	
	// FIELD updates
	
	private func updateState() {
		guard let value = controllerModel.state.value else {
			state.value = "--"
			return
		}
		state.value = value.display()
	}
	
	private func updateTimeInState() {
		timeInState.value = formatTime(controllerModel.timeInState.value)
	}
	
	private func updateTimeHeated() {
		timeHeated.value = formatTime(controllerModel.timeHeated.value)
	}
	
	private func updateTimeToGo() {
		let seconds = controllerModel.timeToGo.value
		timeToGo.value = formatTime(seconds)
	}
	
	private func updateAcceptedCommands() {
		leftButtonState = evaluateUserCommandsForLeftButton()
		leftButton.setTitle(leftButtonState.0.display(), forState: .Normal)
		leftButton.enabled = leftButtonState.0 != .None
		
		rightButtonState = evaluateUserCommandsForRightButton()
		rightButton.setTitle(rightButtonState.0.display(), forState: .Normal)
		rightButton.enabled = rightButtonState.0 != .None
		
		targetTempPicker.userInteractionEnabled = controllerModel.canUpdateConfigValues
	}
	
	private func updateAmbientSensor() {
		guard let sensor = controllerModel.ambientSensor.value else {
			ambientTemp.value = formatTemperature(nil, printDecimal: true)
			return
		}
		if sensor.status == .OK {
			ambientTemp.value = formatTemperature(sensor.temperature, printDecimal: true)
		} else {
			ambientTemp.value = sensor.status.display()
		}
	}
	
	private func updateWaterSensor() {
		guard let sensor = controllerModel.waterSensor.value else {
			waterTemp.value = formatTemperature(nil, printDecimal: true)
			return
		}
		if sensor.status == .OK {
			waterTemp.value = formatTemperature(sensor.temperature, printDecimal: true)
		} else {
			waterTemp.value = sensor.status.display()
		}
	}
	
	private func updateTargetTemp() {
		let value = controllerModel.targetTemperature.value
		targetTemp.value = formatTemperature(value, printDecimal: false)
		guard value != nil else {
			return
		}
		let intValue = Int(value!)
		if intValue >= MainViewController.minTargetTemp && intValue <= MainViewController.maxTargetTemp {
			let index = intValue - MainViewController.minTargetTemp
			targetTempPicker.selectRow(index, inComponent: 0, animated: !targetTempPicker.hidden)
		}
	}
	
	
	class TargetTempPickerHandler : NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
		
		static let numberOfRows = MainViewController.maxTargetTemp - MainViewController.minTargetTemp + 1
		
		var controllerModel : ControllerModel?
		
		func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
			return 1
		}
		func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
			return TargetTempPickerHandler.numberOfRows
		}
		func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
			guard row < TargetTempPickerHandler.numberOfRows else {
				fatalError("Row index out of bounds: \(row)")
			}
			return String(MainViewController.minTargetTemp + row) + "°C"
		}
		func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
			//print("Row \(row) selected")
			guard controllerModel != nil else {
				return
			}
			controllerModel!.targetTemperature.requestedValue = Double(MainViewController.minTargetTemp + row)
		}
	}
}