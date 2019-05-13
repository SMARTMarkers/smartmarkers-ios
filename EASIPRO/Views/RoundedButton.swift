//
//  RoundedButton.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 27/04/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import UIKit

open class RoundedButton: UIButton {

	private var _title : String?
	private let _busytitle = "Loading..."
    
	
	
    override open func setTitle(_ title: String?, for state: UIControl.State) {
		super.setTitle(title, for: state)
		_title = (state == .normal) ? title : nil
		
		
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		configView()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		configView()
	}
	
	func configView() {
        let height = frame.size.height
        layer.cornerRadius = (height <= 30) ? (height/3 + 5) : 25
		tintColorDidChange()
		titleLabel?.textAlignment = .center
	}
	
	override open func tintColorDidChange() {
		super.tintColorDidChange()
        let titleColor = (tintColor == UIColor.white) ? UIColor.black : UIColor.white

        setTitleColor(titleColor, for: UIControl.State())
		setTitleColor(titleColor, for: .highlighted)
		setTitleColor(titleColor, for: .selected)
		setTitleColor(titleColor, for: .normal)
		setTitleColor(UIColor.gray, for: .disabled)
		updateBackgroundColor()
	}
	
	func updateBackgroundColor() {
		if isEnabled {
			if isHighlighted || isSelected {
				backgroundColor = tintColor.withAlphaComponent(1.0)
			}
			else {
				backgroundColor = tintColor.withAlphaComponent(0.7)
			}
		}
		else {
			backgroundColor = tintColor.withAlphaComponent(0.3)
		}
	}
	
	public func busy() {
		isEnabled = false
		setTitle(_busytitle, for: .disabled)
		
	}
	
	public func reset() {
		isEnabled = true
		setTitle(_title, for: .disabled)
	}

}
