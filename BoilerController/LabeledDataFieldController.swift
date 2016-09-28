//
//  LabeledTextFieldController.swift
//  StackViewController
//
//  Created by Indragie Karunaratne on 2016-04-24.
//  Copyright © 2016 Seed Platform, Inc. All rights reserved.
//

import UIKit

class LabeledDataFieldController: UIViewController {
	
    fileprivate let labelText: String
    
    init(labelText: String) {
        self.labelText = labelText
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(NSCoder) not implemented")
    }
    
    override func loadView() {
        view = LabeledDataField(labelText: labelText)
    }
	
	var value : String? {
		get {
			guard view != nil else { return nil }
			return (view as! LabeledDataField).value
		}
		set {
			guard view != nil else { return }
			(view as! LabeledDataField).value = newValue
		}
	}
}
