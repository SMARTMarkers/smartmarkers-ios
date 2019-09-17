//
//  InstrumentFactory.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 3/15/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation


public class Instruments {
    
    public static func OMRONBloodPressure(settings: [String:Any]) -> Instrument? {
        return OMRON(authSettings: settings)
    }
    
    public static var AmslerGrid: Instrument? {
        return AmslerGridPRO()
    }
    
    public static var HolePegTestPRO: Instrument? {
        return NineHolePegTestPRO()
    }
    
    public static var PASATPRO: Instrument? {
        return PSATPRO()
    }
    
}

