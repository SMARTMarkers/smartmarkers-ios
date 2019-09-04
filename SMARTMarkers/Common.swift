//
//  Common.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 1/4/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation

extension String {
    func sm_base64encoded() -> String {
        let data = self.data(using: .utf8)
        let base64string = data!.base64EncodedString()
        return base64string
    }
    func sm_URLEncoded() -> String {
        let escapedString = self.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)
        return escapedString!
    }
}

extension UIViewController {
    
    func sm_showMsg(msg: String) {
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        let alertViewController = UIAlertController(title: "EASIPRO", message: msg, preferredStyle: .alert)
        alertViewController.addAction(alertAction)
        present(alertViewController, animated: true, completion: nil)
    }
}

extension UIView {
    
    func sm_addVisualConstraint(_ visualFormat: String,_ vs: [String:Any]) {
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: visualFormat, options: [], metrics: nil, views: vs))
    }
}
