//
//  LabeledTextField.swift
//  StackViewController
//
//  Created by Indragie Karunaratne on 2016-04-24.
//  Copyright © 2016 Seed Platform, Inc. All rights reserved.
//

import UIKit
import StackViewController

class LabeledDataField: UIView {
	
    private struct Appearance {
        static let LabelTextColor = UIColor(white: 0.56, alpha: 1.0)
        static let DataTextColor = UIColor.blackColor()
        static let Font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
    }
    
    private struct Layout {
        static let EdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        static let StackViewSpacing: CGFloat = 10
    }
    
    private let label: UILabel
    private let data: UILabel
	
	var value : String? {
		get { return data.text }
		set { data.text = newValue }
	}
    
    init(labelText: String) {
        label = UILabel(frame: CGRectZero)
        label.textColor = Appearance.LabelTextColor
        label.font = Appearance.Font
        label.text = labelText
        //label.setContentHuggingPriority(UILayoutPriorityDefaultHigh, forAxis: .Horizontal)
        
        data = UILabel(frame: CGRectZero)
        data.textColor = Appearance.DataTextColor
        data.font = Appearance.Font
		data.textAlignment = .Right
        
        super.init(frame: CGRectZero)
		
		/*
        let stackView = UIStackView(arrangedSubviews: [label, data])
        stackView.axis = .Horizontal
        stackView.spacing = Layout.StackViewSpacing
		stackView.distribution = .Fill
		
        addSubview(stackView)
        stackView.activateSuperviewHuggingConstraints(insets: Layout.EdgeInsets)
		*/
		
		addSubview(label)
		label.snp_makeConstraints { (make) -> Void in
			make.top.equalTo(self.snp_top).offset(Layout.EdgeInsets.top)
			make.left.equalTo(self.snp_left).offset(Layout.EdgeInsets.left)
			make.bottom.equalTo(self.snp_bottom).offset(-Layout.EdgeInsets.bottom)
		}
		addSubview(data)
		data.snp_makeConstraints { (make) -> Void in
			make.centerY.equalTo(label.snp_centerY)
			make.right.equalTo(self.snp_right).offset(-Layout.EdgeInsets.right)
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(NSCoder) not implemented")
	}
}
