//
//  ActiveInstrumentProtocol.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 4/18/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


public protocol ActiveInstrumentProtocol: Instrument {
    
    var ip_taskDescription: String? { get set }
    
    
}

public extension ActiveInstrumentProtocol {
    

}
