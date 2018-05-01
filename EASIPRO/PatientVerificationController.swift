//
//  PatientVerificationController.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 18/03/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import UIKit
import SMART

class PatientVerificationController: UIViewController {

	let patient : Patient
	
	let datePicker = UIDatePicker()
	
	open var onCompletion : ((_ success: Bool) -> Void)?
	
	
	init(patient: Patient ) {
		
		datePicker.datePickerMode = .date
		datePicker.translatesAutoresizingMaskIntoConstraints = false
		self.patient = patient
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		view.backgroundColor = UIColor.white
		configureView()
		

    }
	
	func moveToPROMeasures() {
		
		//Verification is always assumed to be the topMost hence can be popped.
		if let navigationController = self.navigationController, navigationController.topViewController == self {
			navigationController.popViewController(animated: true)
		}
	}
	
	@objc func verifyPatient(_ sender: Any?) {
		
		
		if verify() == false {
			let alert = UIAlertController(title: "Verification Failed", message: "Incorrect entry, please try again or talk to the practitioner", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
			alert.addAction(UIAlertAction(title: "DEMO:OVERRIDE", style: .destructive, handler: { [unowned self] (_ ) in
				self.moveToPROMeasures()
			}))
			present(alert, animated: true)
			return
		}
		moveToPROMeasures()
	}

	@objc func cancelVerification(_ sender: Any?) {
		
		LocalAuth.verifyDeviceUser { [weak self] (success, error) in
			if success {
				self?.dismiss(animated: true)
			}
		}
	}
	
	func verify() -> Bool {
		return datePicker.date.fhir_asDate() == patient.birthDate
	}
	
	
	func EPButton(_ title: String) -> UIButton {
		
		let frame = CGRect(x: 0, y: 0, width: 100, height: 100)
		let btn = RoundedButton(frame: frame)
		btn.translatesAutoresizingMaskIntoConstraints = false
		btn.setTitle(title, for: .normal)
		btn.titleLabel?.font = UIFont.systemFont(ofSize: 20)
		return btn
	}
	func EPtitleLabel(_ title: String) -> UILabel {
		let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
		titleLabel.font = UIFont.boldSystemFont(ofSize: 30)
		titleLabel.text = title
		titleLabel.textAlignment = .center
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		return titleLabel
	}
	
	func configureView() {
		
		let verifyButton = EPButton("Verify")
		verifyButton.addTarget(self, action: #selector(verifyPatient(_:)), for: .touchUpInside)

		let cancelButton = UIButton(type: .roundedRect)
		cancelButton.setTitle("Cancel", for: .normal)
		cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
		cancelButton.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
		cancelButton.translatesAutoresizingMaskIntoConstraints = false

		cancelButton.addTarget(self, action: #selector(cancelVerification(_:)), for: .touchUpInside)

		
		
		let titleLabel   = EPtitleLabel("Enter your birthday for Verification")
		let subtitleLabel = EPtitleLabel(patient.ep_MRNumber())
		subtitleLabel.textColor = UIColor.lightGray
		subtitleLabel.adjustsFontSizeToFitWidth = true
		subtitleLabel.font = UIFont.systemFont(ofSize: 20)
		

		
		let patientLabel = EPtitleLabel(patient.humanName!)
		let views = ["titlelbl" : titleLabel, "patientlbl": patientLabel, "verifyBtn" : verifyButton, "cancelBtn" : cancelButton, "datepicker" : datePicker, "subtitlelbl" : subtitleLabel]
		Array(views.values).forEach { view.addSubview($0) }
		
		func ac(_ s: String,_ vs: [String:Any]) {
			view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: s, options: [], metrics: nil, views: vs))
		}
		
		
		let centerY = NSLayoutConstraint(item: datePicker,
										 attribute: .centerY,
										 relatedBy: .equal,
										 toItem: view,
										 attribute: .centerY,
										 multiplier: 1.0,
										 constant: 0.0);
		ac("V:|-40-[titlelbl]", views)
		ac("H:|-[titlelbl]-|", views)
		ac("H:|-[subtitlelbl]-|", views)
		ac("H:|-70-[verifyBtn]-70-|", views)



		ac("H:|-[datepicker]-|", views)
		view.addConstraint(centerY)
		ac("H:|-40-[patientlbl]-40-|", views)
		ac("V:[patientlbl]-[subtitlelbl]-20-[datepicker]-20-[verifyBtn(60)]", views)
		ac("H:[cancelBtn]-20-|", views)
		ac("V:|-30-[cancelBtn]", views )
		
		
	}

}
