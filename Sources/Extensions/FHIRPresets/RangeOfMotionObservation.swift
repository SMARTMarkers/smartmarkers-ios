//
//  RangeOfMotionObservation.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 4/16/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit

public extension Observation {
    
    //https://zulip-uploads.s3.amazonaws.com/10155/asOP7kN_xL_McwtgOiTLTtcc/NoninBtle.json?Signature=H%2BTjf8NLt%2BC1172L5ynFOSVwhkY%3D&Expires=1555427590&AWSAccessKeyId=AKIAIEVMBCAT2WD3M5KQ
    
    class func sm_RangeOfMotion(flexed: Double, extended: Double, date: Date, limbOption: ORKPredefinedTaskLimbOption) -> Observation {
        
        let observation = Observation()

        
        return observation
        

    }
    
    class func sm_RangeOfMotion(start: Double, finish: Double, range: Double, date:Date) -> Observation {
        
        let observation = Observation()
        observation.effectiveDateTime = date.fhir_asDateTime()
        observation.status = .final
        let quantityStart = Quantity.sm_Angle(start)
        let componentStart = ObservationComponent()
        componentStart.valueQuantity = quantityStart
        let quantityFinish = Quantity.sm_Angle(finish)
        let componentFinish = ObservationComponent()
        componentFinish.valueQuantity = quantityFinish
        let quantityRange = Quantity.sm_Angle(range)
        let componentRange = ObservationComponent()
        componentRange.valueQuantity = quantityRange
        
        observation.component = [componentStart, componentFinish, componentRange]
        

        return observation
    }
    
}

public extension Coding {
    
	func sm_asCodeableConcept(_ text: String? = nil) -> CodeableConcept {
        return CodeableConcept.sm_From([self], text: text ?? display?.string)
    }
	
	class func sm_AgeLoinc() -> Coding {
		sm_LOINC("30525-0", "Age")
	}
    
    class func sm_ActiveRangeOfMotionPanel() -> Coding {
        return
            sm_LOINC("41359-1", "Active range of motion panel Quantitative")
        
    }
    
    //Knee Extended
    class func sm_KneeRightExtendedRangeofMotionQuantitative() -> Coding {
        return
            sm_LOINC("41349-2", "Knee - right Extension Active Range of Motion Quantitative")
        
    }
    
    class func sm_KneeLeftExtendedRangeofMotionQuantitative() -> Coding {
        return
            sm_LOINC("41345-0", "Knee - left Extension Active Range of Motion Quantitative")
        
    }
    
    //Knee Flexed
    class func sm_KneeRightFlexedRangeofMotionQuantitative() -> Coding {
        return
            sm_LOINC("41347-6", "Knee - right Flexion Active Range of Motion Quantitative")
        
    }
    
    class func sm_KneeLeftFlexedRangeofMotionQuantitative() -> Coding {
        return
            sm_LOINC("41343-5", "Knee - left Flexion Active Range of Motion Quantitative")
        
    }
    
    
    // Shoulder Flexion
    
    class func sm_ShoulderLeftFlexionRangeOfMotionQuantitative() -> Coding {
        return
            sm_LOINC("41295-7", "Shoulder - left Flexion Active Range of Motion Quantitative")
        
    }
    
    class func sm_ShoulderRightFlexionRangeOfMotionQuantitative() -> Coding {
        return
            sm_LOINC("41307-0", "Shoulder - Right Flexion Active Range of Motion Quantitative")
        
    }
    
    // Shoulder Extension

    class func sm_ShoulderLeftExtensionRangeOfMotionQuantitative() -> Coding {
        return
            sm_LOINC("41297-3", "Shoulder - left Extension Active Range of Motion Quantitative")
        
    }
    
    class func sm_ShoulderRightExtensionRangeOfMotionQuantitative() -> Coding {
        return
            sm_LOINC("41309-6", "Shoulder - Right Extension Active Range of Motion Quantitative")
        
    }
    
    
    class func sm_bodySite_KneeLeft() -> Coding {
        return sm_SNOMED("82169009", "Knee Left")
    }
    
    class func sm_bodySite_KneeRight() -> Coding {
        return sm_SNOMED("6757004", "Knee Right")
    }
    
    class func sm_bodySite_ShoulderRight() -> Coding {
        return sm_SNOMED("91774008", "Shoulder Right")
    }
    
    class func sm_bodySite_ShoulderLeft() -> Coding {
        return sm_SNOMED("91775009", "Shoulder Left")
    }
    
}

public extension CodeableConcept {
    
    
    

    class func sm_BodySiteKneeBoth() -> CodeableConcept {
        return sm_From(
            [Coding.sm_bodySite_KneeRight(),
             Coding.sm_bodySite_KneeLeft()], text: "Both Knee Regions")
    }
    
    class func sm_BodySiteKneeLeft() -> CodeableConcept {
        return sm_From([Coding.sm_bodySite_KneeLeft()], text: "Left Knee Region")
    }
    
    class func sm_BodySiteKneeRight() -> CodeableConcept {
        return sm_From([Coding.sm_bodySite_KneeRight()], text: "Right Knee Region")
    }
    
    class func sm_BodySiteShoulderLeft() -> CodeableConcept {
        return sm_From([Coding.sm_bodySite_ShoulderLeft()], text: "Left Shoulder Region")
    }
    
    class func sm_BodySiteShoulderRight() -> CodeableConcept {
        return sm_From([Coding.sm_bodySite_ShoulderRight()], text: "Left Shoulder Region")
    }
    
    class func sm_BodySiteShoulderBoth() -> CodeableConcept {
        return sm_From(
            [Coding.sm_bodySite_ShoulderRight(),
             Coding.sm_bodySite_ShoulderLeft()], text: "Both Shoulder Regions")
    }
    
}

public extension Quantity {
    
    class func sm_Angle(_ degree: Double) -> Quantity {
        let quantity = Quantity()
        quantity.code = FHIRString("deg")
        quantity.system = FHIRURL("http://unitsofmeasure.org")
        quantity.unit = "degree (plane angle)"
        quantity.value = FHIRDecimal(Decimal(degree))
        return quantity
    }
    
}
