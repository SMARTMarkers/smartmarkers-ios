//
//  Common.swift
//  SMARTMarkers
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
    
    func slice(from: String, to: String) -> String? {
        
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
    
    
    
//    public func sm_htmlToNSAttributedString(largeFontSize: Bool = false) -> NSAttributedString? {
//        
//        let size = UIFont.preferredFont(forTextStyle: .body).pointSize
//        let titleSize = UIFont.preferredFont(forTextStyle: .title2).pointSize
//        let str =  String(format:"<span style=\"font-family: '-apple-system'; font-size: \(largeFontSize ? titleSize : size)\">%@</span>", self)
//
//        
//        if let attributedString = try? NSAttributedString(data: Data(str.utf8),
//                                                          options: [.documentType: NSAttributedString.DocumentType.html,
//                                                                    .characterEncoding: String.Encoding.utf8.rawValue],
//                                                          documentAttributes: nil) {
//            return attributedString
//        }
//        
//        return nil
//    }
}

extension UIViewController {
    
    func sm_showMsg(msg: String) {
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        let alertViewController = UIAlertController(title: "SMART Markers", message: msg, preferredStyle: .alert)
        alertViewController.addAction(alertAction)
        present(alertViewController, animated: true, completion: nil)
    }
}

extension UIView {
    
    func sm_addVisualConstraint(_ visualFormat: String,_ vs: [String:Any]) {
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: visualFormat, options: [], metrics: nil, views: vs))
    }
    
        func addBorder(_ edge: UIRectEdge, color: UIColor, thickness: CGFloat) {
            let subview = UIView()
            subview.translatesAutoresizingMaskIntoConstraints = false
            subview.backgroundColor = color
            self.addSubview(subview)
            switch edge {
            case .top, .bottom:
                subview.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 0).isActive = true
                subview.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0).isActive = true
                subview.heightAnchor.constraint(equalToConstant: thickness).isActive = true
                if edge == .top {
                    subview.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
                } else {
                    subview.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
                }
            case .left, .right:
                subview.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
                subview.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
                subview.widthAnchor.constraint(equalToConstant: thickness).isActive = true
                if edge == .left {
                    subview.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 0).isActive = true
                } else {
                    subview.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0).isActive = true
                }
            default:
                break
            }
        }
}

extension UIButton {
    
    class func SMButton(title: String, target: AnyObject, action: Selector) -> UIButton {
        
        let frame = CGRect(x: 0, y: 0, width: 100, height: 20)
        let btn = RoundedButton(frame: frame)
        btn.setTitle(title, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        btn.addTarget(target, action: action , for: UIControl.Event.touchUpInside)
        
        return btn
    }
}


public extension String {
    
    func sm_htmlToNSAttributedString(largeFontSize: Bool = false) -> NSAttributedString? {
        
        let size = UIFont.preferredFont(forTextStyle: .body).pointSize
        let titleSize = UIFont.preferredFont(forTextStyle: .title2).pointSize
        let str =  String(format:"<span style=\"font-family: '-apple-system'; font-size: \(largeFontSize ? titleSize : size)\">%@</span>", self)

        if let attributedString = try? NSAttributedString(data: Data(str.utf8),
                                                          options: [.documentType: NSAttributedString.DocumentType.html,
                                                                    .characterEncoding: String.Encoding.utf8.rawValue],
                                                          documentAttributes: nil) {
            return attributedString
        }
        
        return nil
    }
}
