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
	
	
	override open func setTitle(_ title: String?, for state: UIControlState) {
		super.setTitle(title, for: state)
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
		layer.cornerRadius = 25
		tintColorDidChange()
		titleLabel?.textAlignment = .center
	}
	
	override open func tintColorDidChange() {
		super.tintColorDidChange()
		setTitleColor(tintColor, for: UIControlState())
		setTitleColor(UIColor.white, for: .highlighted)
		setTitleColor(UIColor.white, for: .selected)
		setTitleColor(UIColor.white, for: .normal)
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
