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
