//
//  ArduinoTypes.swift
//  Boiler-Controller
//
//  Created by Oliver on 2016-09-01.
//  Copyright © 2016 Oliver. All rights reserved.
//

import Foundation
import CoreBluetooth

/* Services & Characteristics UUIDs */
//const uint16_t BC_CONTROLLER_SERVICE_ID[] = { 0x4c, 0xef, 0xdd, 0x58, 0xcb, 0x95, 0x44, 0x50, 0x90, 0xfb, 0xf4, 0x04, 0xdc, 0x20, 0x2f, 0x7c};
let boilerControllerServiceUUID = CBUUID(string: "4CEFDD58-CB95-4450-90FB-F404DC202F7C")
let boilerControllerAdvertisingUUID = CBUUID(string: "4CEF");

public typealias BCTemperature = Int16
public typealias BCSeconds = Int32
public let UndefinedBCSeconds : BCSeconds = -1
public typealias BCStateID = Int8
public typealias BCUserCommandID = UInt16
public typealias BCUserCommands = UInt16

extension BCUserCommands {
	
	func containsConfigurationCommand() -> Bool {
		let configCommands = BCUserCommand.config_Set_Value.rawValue
			| BCUserCommand.config_Ack_Ids.rawValue
			| BCUserCommand.config_Swap_Ids.rawValue
			| BCUserCommand.config_Clear_Ids.rawValue
			| BCUserCommand.config_Reset_All.rawValue
		return self & configCommands > 0
	}
}

public enum BCSensorStatus : Int8 {
    case initialising = 0x1
    case id_Auto_Assigned = 0x2
    case id_Undefined = 0x4
    case ok = 0x8
    case nok = 0x10
	
	func display() -> String {
		switch self {
		case .initialising:
			return "Init"
		case .id_Auto_Assigned:
			return "ID Auto"
		case .id_Undefined:
			return "ID Undef"
		case .ok:
			return "OK"
		case .nok:
			return "NOK"
		}
	}
}


public enum BCControllerState : BCStateID {
    // unused values are commented
    case undefined = -2
    //case Same = -1
    case Init = 0
    case sensors_NOK = 1
    case ready = 2
    case idle = 3
    case recording = 4
    case standby = 5
    case heating = 6
	case overheated = 7
	
	func display() -> String {
		switch self {
		case .undefined:
			return "Undef"
		case .Init:
			return "Init"
		case .sensors_NOK:
			return "Sensors NOK"
		case .ready:
			return "Ready"
		case .idle:
			return "Idle"
		case .recording:
			return "Recording"
		case .standby:
			return "Standby"
		case .heating:
			return "Heating"
		case .overheated:
			return "Overheated"
		}
	}

}

public enum BCUserCommand : BCUserCommandID {
    // values not used by this App are commented
    case none             = 0       // 1
    //case Info_Help        = 0x1     // 2
    //case Info_Stat        = 0x2     // 3
    //case Info_Config      = 0x4     // 4
    case info_Log         = 0x8     // 5
    case config_Set_Value = 0x10    // 6   (16)
    case config_Swap_Ids  = 0x20    // 7   (32)
    case config_Clear_Ids = 0x40    // 8   (64)
    case config_Ack_Ids   = 0x80    // 9   (128)
    case config_Reset_All = 0x100   // 10  (256)
    case rec_On           = 0x200   // 11  (512)
    case rec_Off          = 0x400   // 12  (1024)
    case heat_On          = 0x800   // 13  (2048)
    case heat_Off         = 0x1000  // 14  (4096)
	case heat_Reset       = 0x2000  // 15  (8192)
	
}

enum BCGattCharUUID : String {
	// status
	case State 				= "0001" // HEX value!
	case TimeInState 		= "0002"
	case TimeHeated 		= "0003"
	case TimeToGo	 		= "0004"
	case AcceptedUserCmds 	= "0005"
	case UserRequest 		= "0006"
	case WaterSensor 		= "0007"
	case AmbientSensor 		= "0008"
	// configuration
	case TargetTemp 		= "1000"
	// log
	case LogEntry 			= "2000"
}

