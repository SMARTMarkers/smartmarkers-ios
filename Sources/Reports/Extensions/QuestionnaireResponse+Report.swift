//
//  QuestionnaireResponse+Report.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 9/4/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


extension QuestionnaireResponse : Report {
	
	@discardableResult
	public func sm_assign(patient: Patient) -> Bool {
		
		if let patientReference = try? patient.asRelativeReference() {
			subject = patientReference
			return true
		}
		
		return false
	}
	
    
    public var rp_identifier: String? {
        return id?.string ?? ""
    }
    
    public var rp_code: Coding? {
        resolveQuestionnaireIfContained()?.sm_code
    }
    
    public var rp_title: String? {
        resolveQuestionnaireIfContained()?.sm_title ?? "Survey"
    }
    
    public var rp_description: String? {
        return "QuestionnaireResponse ID: \(id?.string ?? "-")"
    }
    
    public var rp_date: Date? {
        return authored?.nsDate
    }
    
    public var rp_observation: String? {
        
        // Check if PROMIS, if yes, send back T-Score
        if let promisScore = promis_tscore {
            return promisScore
        }
        
        return nil
    }
    
    public var rp_viewController: UIViewController? {
        return QuestionnaireResponseViewController(self)
    }
    
    
    var promis_tscore: String? {
        
        if let scores = extensions(forURI: kSD_QuestionnaireResponseScores)?.first {
            let theta = scores.extensions(forURI: kSD_QuestionnaireResponseScoresTheta)?.first?.valueDecimal
            let deviation = scores.extensions(forURI: kSD_QuestionnaireResponseScoresStandardError)?.first?.valueDecimal
            if let theta = theta, let deviation = deviation {
                let tscore = String(round((Double(theta.decimal.description)! * 10) + 50.0))
                // let standardError =  String(round(Double(deviation.decimal.description)! * 10))
                return  tscore
            }
        }
        return nil
    }
    
    private func resolveQuestionnaireIfContained() -> Questionnaire? {
        

        guard let fragment = self.questionnaire?.fragment else {
            return nil
        }
        
        return contained?.filter({ $0.id?.string == fragment }).first as? Questionnaire
    }
}



