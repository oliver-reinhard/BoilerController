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
		case none
		case rec_On
		case rec_Off
		case heat_On
		case heat_Off
		case heat_Reset
		case configuration
		
		func display() -> String {
			switch self {
			case .none:
				return "N/A"
			case .rec_On:
				return "Recording On"
			case .rec_Off:
				return "Recording Off"
			case .heat_On:
				return "Heat On"
			case .heat_Off:
				return "Heat Off"
			case .heat_Reset:
				return "Reset Heat"
			case .configuration:
				return "Configuration"
			}
		}
	}
	
	var leftButton : UIButton!
	var leftButtonState =   (ButtonAction.none, BCUserCommand.none)
	var rightButton : UIButton!
	var rightButtonState = (ButtonAction.none, BCUserCommand.none)
	
	required init?(coder aDecoder: NSCoder) {
		stackViewController = StackViewController()
		stackViewController.stackViewContainer.separatorViewFactory = StackViewContainer.createSeparatorViewFactory()
		super.init(coder: aDecoder)
		edgesForExtendedLayout = UIRectEdge()
	}
	
	override func loadView() {
		view = UIView(frame: CGRect.zero)
		view.backgroundColor = .white
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		guard controllerModel != nil else {
			fatalError("Expected ControllerModel to be set")
		}
		controllerModel.addServiceObserver(observer: self)
		
		let titleLabel = UILabel(frame: CGRect.zero)
		titleLabel.text = "Controller"
		titleLabel.textColor = UIColor.black
		titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
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
		
		targetTempPicker = UIPickerView(frame: CGRect.zero)
		targetTempPicker.dataSource = targetTempPickerHandler
		targetTempPicker.delegate = targetTempPickerHandler
		targetTempPicker.isHidden = true
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
		stackViewController.didMove(toParentViewController: self)
		
		leftButton = UIButton(type: .system)
		leftButton.titleLabel!.font = titleLabel.font
		leftButton.addTarget(self, action: #selector(MainViewController.leftButtonPressed(_:)), for: .touchUpInside)
		view.addSubview(leftButton)
		
		rightButton = UIButton(type: .system)
		rightButton.titleLabel!.font = titleLabel.font
		rightButton.addTarget(self, action: #selector(MainViewController.rightButtonPressed(_:)), for: .touchUpInside)
		view.addSubview(rightButton)
		updateAcceptedCommands()
		
		//
		// Layout
		//
		let padding = UIEdgeInsetsMake(30, 15, 25, 15)
		let spacing = 5
		
		titleLabel.snp.makeConstraints { (make) -> Void in
			make.top.equalTo(view.snp.top).offset(padding.top)
			make.centerX.equalTo(view.snp.centerX)
		}

		leftButton.snp.makeConstraints { (make) -> Void in
			make.left.equalTo(view.snp.left).offset(padding.left)
			make.bottom.equalTo(view.snp.bottom).offset(-padding.bottom)
		}
		
		rightButton.snp.makeConstraints { (make) -> Void in
			make.right.equalTo(view.snp.right).offset(-padding.right)
			make.centerY.equalTo(leftButton.snp.centerY)
		}
		
		stackViewController.view.snp.makeConstraints { (make) -> Void in
			make.top.equalTo(titleLabel.snp.bottom).offset(spacing)
			make.left.equalTo(view.snp.left)
			make.bottom.equalTo(leftButton.snp.top).offset(-spacing)
			make.right.equalTo(view.snp.right)
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func didTapTargetTemp() {
		UIView.animate(withDuration: 0.5, animations: { () -> Void in
			let picker = self.targetTempPicker
			// only show picker view if target temp is not nil
			if (picker?.isHidden)! && self.controllerModel.targetTemperature.value != nil {
				self.stackViewController.insertItem(picker!, atIndex: 3)
				picker?.isHidden = false
			} else if !(picker?.isHidden)! {
				self.stackViewController.removeItem(picker!)
				picker?.isHidden = true
			}
		}) 
	}
	
	func leftButtonPressed(_ sender: UIButton!) {
		if leftButtonState.1 != .none {
			controllerModel.userRequest.requestedValue = leftButtonState.1.rawValue
			//print("Left: \(leftButtonState.1)")
		}
    }
	
	func rightButtonPressed(_ sender: UIButton!) {
		if rightButtonState.1 != .none {
			controllerModel.userRequest.requestedValue = rightButtonState.1.rawValue
        	//print("Right: \(rightButtonState.1)")
		}
	}
	
	fileprivate func evaluateUserCommandsForLeftButton() -> (ButtonAction, BCUserCommand) {
		if let userCommands = controllerModel.acceptedUserCmds.value {
			if userCommands & BCUserCommand.rec_On.rawValue > 0 {
				return (.rec_On, BCUserCommand.rec_On)
				
			} else if userCommands & BCUserCommand.rec_Off.rawValue > 0 {
				return (.rec_Off, BCUserCommand.rec_Off)
				
			} else if userCommands & BCUserCommand.heat_Reset.rawValue > 0 {
				return (.heat_Reset, BCUserCommand.heat_Reset)
			}
		}
		return (.none, BCUserCommand.none)
		
	}
	
	fileprivate func evaluateUserCommandsForRightButton() -> (ButtonAction, BCUserCommand) {
		if let userCommands = controllerModel.acceptedUserCmds.value {
			if userCommands & BCUserCommand.heat_On.rawValue > 0 {
				return (.heat_On, BCUserCommand.heat_On)
				
			} else if userCommands & BCUserCommand.heat_Off.rawValue > 0 {
				return (.heat_Off, BCUserCommand.heat_Off)
				
			} else if userCommands.containsConfigurationCommand() {
				return (.configuration, BCUserCommand.none)
			}
		}
		return (.none, BCUserCommand.none)
	}
	
	
	// MARK: GattServiceObserver
	func service(service : GattService, availabilityDidChange availability : GattServiceAvailability) {
		print("Main View: service availability: \(availability)")
	}
	
	func attribute(service : GattService, valueDidChangeFor attribute : GattAttribute) {
		let model = self.controllerModel
		if attribute === model?.state {
			self.updateState()
		} else if attribute === model?.timeInState {
			self.updateTimeInState()
		} else if attribute === model?.timeHeated {
			self.updateTimeHeated()
		} else if attribute === model?.timeToGo {
			self.updateTimeToGo()
		} else if attribute === model?.acceptedUserCmds {
			self.updateAcceptedCommands()
		} else if attribute === model?.waterSensor {
			self.updateWaterSensor()
		} else if attribute === model?.ambientSensor {
			self.updateAmbientSensor()
		} else if attribute === model?.targetTemperature {
			self.updateTargetTemp()
		} else {
			print("Unhandled attribute: \(attribute.characteristicUUID)")
		}
	}
	
	func attribute(service : GattService, requestedValueDidFailFor attribute : GattAttribute) {
		
	}
	

	// MARK: DISPLAY utility functions
	
	fileprivate func formatTime(_ secs : BCSeconds?) -> String {
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
		result.append(minPart.description)
		result.append(separator)
		if (secPart < 10) {
			result.append(zero)
		}
		result.append(secPart.description)
		return result
	}
	
	fileprivate func formatTemperature(_ temperature : Double?, printDecimal : Bool) -> String {
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
	
	
	// MARK: FIELD updates
	
	fileprivate func updateState() {
		guard let value = controllerModel.state.value else {
			state.value = "--"
			return
		}
		state.value = value.display()
	}
	
	fileprivate func updateTimeInState() {
		timeInState.value = formatTime(controllerModel.timeInState.value)
	}
	
	fileprivate func updateTimeHeated() {
		timeHeated.value = formatTime(controllerModel.timeHeated.value)
	}
	
	fileprivate func updateTimeToGo() {
		let seconds = controllerModel.timeToGo.value
		timeToGo.value = formatTime(seconds)
	}
	
	fileprivate func updateAcceptedCommands() {
		leftButtonState = evaluateUserCommandsForLeftButton()
		leftButton.setTitle(leftButtonState.0.display(), for: UIControlState())
		leftButton.isEnabled = leftButtonState.0 != .none
		
		rightButtonState = evaluateUserCommandsForRightButton()
		rightButton.setTitle(rightButtonState.0.display(), for: UIControlState())
		rightButton.isEnabled = rightButtonState.0 != .none
		
		targetTempPicker.isUserInteractionEnabled = controllerModel.canUpdateConfigValues
	}
	
	fileprivate func updateAmbientSensor() {
		guard let sensor = controllerModel.ambientSensor.value else {
			ambientTemp.value = formatTemperature(nil, printDecimal: true)
			return
		}
		if sensor.status == .ok {
			ambientTemp.value = formatTemperature(sensor.temperature, printDecimal: true)
		} else {
			ambientTemp.value = sensor.status.display()
		}
	}
	
	fileprivate func updateWaterSensor() {
		guard let sensor = controllerModel.waterSensor.value else {
			waterTemp.value = formatTemperature(nil, printDecimal: true)
			return
		}
		if sensor.status == .ok {
			waterTemp.value = formatTemperature(sensor.temperature, printDecimal: true)
		} else {
			waterTemp.value = sensor.status.display()
		}
	}
	
	fileprivate func updateTargetTemp() {
		let value = controllerModel.targetTemperature.value
		targetTemp.value = formatTemperature(value, printDecimal: false)
		guard value != nil && targetTempPicker != nil else {
			return
		}
		let intValue = Int(value!)
		if intValue >= MainViewController.minTargetTemp && intValue <= MainViewController.maxTargetTemp {
			let index = intValue - MainViewController.minTargetTemp
			targetTempPicker.selectRow(index, inComponent: 0, animated: !targetTempPicker.isHidden)
		}
	}
	
	
	// MARK: TargetTempPickerHandler
	
	class TargetTempPickerHandler : NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
		
		static let numberOfRows = MainViewController.maxTargetTemp - MainViewController.minTargetTemp + 1
		
		var controllerModel : ControllerModel?
		
		func numberOfComponents(in pickerView: UIPickerView) -> Int {
			return 1
		}
		func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
			return TargetTempPickerHandler.numberOfRows
		}
		func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
			guard row < TargetTempPickerHandler.numberOfRows else {
				fatalError("Row index out of bounds: \(row)")
			}
			return String(MainViewController.minTargetTemp + row) + "°C"
		}
		func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
			//print("Row \(row) selected")
			guard controllerModel != nil else {
				return
			}
			controllerModel!.targetTemperature.requestedValue = Double(MainViewController.minTargetTemp + row)
		}
	}
}
