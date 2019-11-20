//
//  SMARTLoginViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 15/02/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation

// options
let fhirserverbaseURL = ""
let viewtitle = "PROF"
let loginTitle = "LOGIN"
let hospitalName = 		"SMART Hospital"


open class SMARTLoginViewController: UIViewController {
    
    weak var statuslbl : UILabel?
    
    open internal(set) var loginButton : UIButton?
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        setupViews()
    }
	
	convenience init() {
		self.init(nibName:nil, bundle:nil)
		modalPresentationStyle = .formSheet
		
	}

    func setupViews() {
        let userlbl = SMARTLoginViewController.titleLabel()
        let cancelBtn = cancelButton()
        userlbl.numberOfLines = 0
        userlbl.adjustsFontSizeToFitWidth = true
        userlbl.lineBreakMode = .byWordWrapping
        let btn = UIButton.SMButton(title: loginTitle, target: self, action: #selector(login(_:)))
        let lbl = SMARTLoginViewController.titleLabel()
        userlbl.text = SMARTManager.shared.practitioner?.name?.first?.human ?? ""
        userlbl.textColor = UIColor.lightGray
        statuslbl = userlbl

        let logo = SMARTLoginViewController.logo(imageName: "", fileExtension: "")
        let v = [
            "cbtn"  : cancelBtn,
            "btn"   : btn,
            "tlbl"  : lbl,
            "view"  : view,
            "logo"  : logo,
            "user"  : userlbl
            ] as [String: Any]
        view.addSubview(cancelBtn)
        view.addSubview(btn)
        view.addSubview(lbl)
        view.addSubview(logo)
        view.addSubview(userlbl)
        
        func ac(_ s: String,_ vs: [String:Any]) {
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: s, options: [], metrics: nil, views: vs))
        }
        
       
        let centerY = NSLayoutConstraint(item: btn,
                                         attribute: .centerY,
                                         relatedBy: .equal,
                                         toItem: view,
                                         attribute: .centerY,
                                         multiplier: 1.0,
                                         constant: 0.0);
        let centerX = NSLayoutConstraint(item: logo,
                                         attribute: .centerX,
                                         relatedBy: .equal,
                                         toItem: view,
                                         attribute: .centerX,
                                         multiplier: 1.0,
                                         constant: 0.0);
        ac("V:|[cbtn(55)]", v)
        ac("H:|[cbtn]", v)
        ac("H:|-50-[btn]-50-|", v)
        ac("H:|-50-[tlbl]-50-|", v)
        ac("H:|-50-[user]-50-|", v)
        ac("V:[btn(55)]", v)
        ac("V:[btn]-40-[user]", v)
        ac("V:[tlbl]-20-[btn]", v)
        ac("V:[user]-20-[logo]", v)
        ac("V:[logo]-30-|", v)
        ac("H:[logo(120)]", v)
        ac("V:[logo(70)]", v)
        view.addConstraint(centerY);
        view.addConstraint(centerX)

    }
    
    
    class func logo(imageName: String, fileExtension: String) -> UIImageView {
        let path = Bundle.main.path(forResource: imageName, ofType: fileExtension) ?? ""
        let img = UIImage(contentsOfFile: path)
        let imgView = UIImageView(image: img)
        imgView.frame = CGRect(x: 0, y: 0, width: 150, height: 100)
        imgView.translatesAutoresizingMaskIntoConstraints = true
        return imgView
    }

    
    
    func cancelButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.frame = CGRect(x: 0, y: 0, width: 70, height: 55)
        btn.setTitle("Cancel", for: .normal)
        btn.addTarget(self, action: #selector(cancel(_ :)), for: .touchUpInside)
        return btn
    }
    
    @objc
    func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    class func titleLabel() -> UILabel {
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        titleLabel.font = UIFont.boldSystemFont(ofSize: 30)
        titleLabel.text =  Bundle.main.object(forInfoDictionaryKey: "SM_APP_TITLE") as? String
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.adjustsFontSizeToFitWidth = true
        return titleLabel
    }
    
    
    
    @objc func login(_ sender: Any) {
        SMARTManager.shared.authorize { [weak self] (success, error) in
            
            if let error = error {
                print(error as Any)
            }
            
            if success {
                DispatchQueue.main.async {
                    let name = (SMARTManager.shared.usageMode == .Practitioner) ? SMARTManager.shared.practitioner?.name?.first?.human : SMARTManager.shared.patient?.humanName
                    self?.statuslbl?.text = name
                    self?.dismiss(animated: true, completion: nil)
                }
            }
            else {
                DispatchQueue.main.async {
                    if let error = error {
                        self?.statuslbl?.text = "Authorization Failed. Try again \(error.asOAuth2Error.localizedDescription)"
                    }
                }
            }
        }
    }
    
}
