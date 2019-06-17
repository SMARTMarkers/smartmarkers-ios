//
//  Instrument+PROMeasure.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 5/23/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation


// Support methods

public extension InstrumentProtocol {
    
    func asPROMeasure() -> PROMeasure {
        return PROMeasure(instrument: self)
    }
    
}
