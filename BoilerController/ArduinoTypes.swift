//
//  ArduinoTypes.swift
//  Boiler-Controller
//
//  Created by Oliver on 2016-09-01.
//  Copyright © 2016 Oliver. All rights reserved.
//

import Foundation

typealias BCTemperature = Int16
typealias BCMillis = UInt32
typealias BCStateID = Int8
typealias BCUserCommandID = UInt16
typealias BCUserCommands = UInt16

enum BCSensorStatus : Int8 {
    case Initialising = 0x1
    case ID_Auto_Assigned = 0x2
    case ID_Undefined = 0x4
    case OK = 0x8
    case NOK = 0x10
}

enum BCControllerState : BCStateID {
    // unused values are commented
    case Undefined = -2
    //case Same = -1
    case Init = 0
    case Sensors_NOK = 1
    case Ready = 2
    case Idle = 3
    case Recodrding = 4
    case Standby = 5
    case Heating = 6
    case Overheated = 7
}

enum BCUserCommand : BCUserCommandID {
    // values not used by this App are commented
    case None             = 0       // 1
    //case Info_Help        = 0x1     // 2
    //case Info_Stat        = 0x2     // 3
    //case Info_Config      = 0x4     // 4
    case Info_Log         = 0x8     // 5
    //case Config_Set_Value = 0x10    // 6   (16)
    case Config_Swap_Ids  = 0x20    // 7   (32)
    case Config_Clear_Ids = 0x40    // 8   (64)
    case Config_Ack_Ids   = 0x80    // 9   (128)
    case Config_Reset_All = 0x100   // 10  (256)
    case Rec_On           = 0x200   // 11  (512)
    case Rec_Off          = 0x400   // 12  (1024)
    case Heat_On          = 0x800   // 13  (2048)
    case Heat_Off         = 0x1000  // 14  (4096)
    case Heat_Reset       = 0x2000  // 15  (8192)
}

enum BCGattCharUUID : String {
	// status
	case State 				= "0001" // HEX value!
	case TimeInState 		= "0002"
	case TimeHeated 		= "0003"
	case AcceptedUserCmds 	= "0004"
	case UserRequest 		= "0005"
	case WaterSensor 		= "0006"
	case AmbientSensor 		= "0007"
	// configuration
	case TargetTemp 		= "1000"
	// log
	case LogEntry 			= "2000"
}

