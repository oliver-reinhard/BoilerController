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
	
    fileprivate struct Appearance {
        static let LabelTextColor = UIColor(white: 0.56, alpha: 1.0)
        static let DataTextColor = UIColor.black
        static let Font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
    }
    
    fileprivate struct Layout {
        static let EdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        static let StackViewSpacing: CGFloat = 10
    }
    
    fileprivate let label: UILabel
    fileprivate let data: UILabel
	
	var value : String? {
		get { return data.text }
		set { data.text = newValue }
	}
    
    init(labelText: String) {
        label = UILabel(frame: CGRect.zero)
        label.textColor = Appearance.LabelTextColor
        label.font = Appearance.Font
        label.text = labelText
        //label.setContentHuggingPriority(UILayoutPriorityDefaultHigh, forAxis: .Horizontal)
        
        data = UILabel(frame: CGRect.zero)
        data.textColor = Appearance.DataTextColor
        data.font = Appearance.Font
		data.textAlignment = .right
        
        super.init(frame: CGRect.zero)
		
		/*
        let stackView = UIStackView(arrangedSubviews: [label, data])
        stackView.axis = .Horizontal
        stackView.spacing = Layout.StackViewSpacing
		stackView.distribution = .Fill
		
        addSubview(stackView)
        stackView.activateSuperviewHuggingConstraints(insets: Layout.EdgeInsets)
		*/
		
		addSubview(label)
		label.snp.makeConstraints { (make) -> Void in
			make.top.equalTo(self.snp.top).offset(Layout.EdgeInsets.top)
			make.left.equalTo(self.snp.left).offset(Layout.EdgeInsets.left)
			make.bottom.equalTo(self.snp.bottom).offset(-Layout.EdgeInsets.bottom)
		}
		addSubview(data)
		data.snp.makeConstraints { (make) -> Void in
			make.centerY.equalTo(label.snp.centerY)
			make.right.equalTo(self.snp.right).offset(-Layout.EdgeInsets.right)
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(NSCoder) not implemented")
	}
}
