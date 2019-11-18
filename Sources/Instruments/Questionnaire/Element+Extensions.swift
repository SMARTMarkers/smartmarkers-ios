//
//  Element+Extensions.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 9/13/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


extension SMART.Element {
    
    public func sm_questionItem_instructions() -> String? {
        return extensions(forURI: kSD_QuestionnaireInstruction)?.first?.valueString?.localized
    }
    
    public func sm_questionItem_Help() -> String? {
        return extensions(forURI: kSD_QuestionnaireHelp)?.first?.valueString?.localized
    }
    
}
