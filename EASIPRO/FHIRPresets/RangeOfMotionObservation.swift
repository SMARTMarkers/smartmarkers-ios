//
//  RangeOfMotionObservation.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 4/16/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

public extension Observation {
    
    //https://zulip-uploads.s3.amazonaws.com/10155/asOP7kN_xL_McwtgOiTLTtcc/NoninBtle.json?Signature=H%2BTjf8NLt%2BC1172L5ynFOSVwhkY%3D&Expires=1555427590&AWSAccessKeyId=AKIAIEVMBCAT2WD3M5KQ
    
    public class func sm_RangeOfMotion(start: Double, finish: Double, range: Double, date:Date) -> Observation {
        
        let observation = Observation()
        observation.effectiveDateTime = date.fhir_asDateTime()
        observation.status = ObservationStatus.final
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
    
    //Knee Codes
    public class func sm_KneeRightRangeofMotion() -> [Coding] {
        return [
            sm_LOINC("41349-2", "Knee - right Extension Active Range of Motion Quantitative"),
            sm_LOINC("41347-6", "Knee - right Flexion Active Range of Motion")
        ]
    }
    
    public class func sm_KneeLeftRangeofMotion() -> [Coding] {
        return [
            sm_LOINC("41345-0", "Knee - left Extension Active Range of Motion Quantitative"),
            sm_LOINC("41343-5", "Knee - left Flexion Active Range of Motion")
        ]
    }
    
    public class func sm_bodySite_KneeBoth() -> Coding {
        return sm_SNOMED("36701003", "Knee")
    }
    
    public class func sm_bodySite_KneeLeft() -> Coding {
        return sm_SNOMED("82169009", "Knee Left")
    }
    
    public class func sm_bodySite_KneeRight() -> Coding {
        return sm_SNOMED("6757004", "Knee Right")
    }
    
    //Shoulder Codes: TODO!
    public class func sm_bodySite_Shoulder() -> Coding {
        return sm_SNOMED("16982005", "Shoulder")
    }
}

public extension CodeableConcept {
    
    public class func sm_KneeLeftRangeOfMotion() -> CodeableConcept {
        return sm_From(Coding.sm_KneeLeftRangeofMotion(), text: "Knee Left Active Range of Motion")
    }
    
    public class func sm_KneeRightRangeOfMotion() -> CodeableConcept {
        return sm_From(Coding.sm_KneeRightRangeofMotion(), text: "Knee Right Active Range of Motion")
    }
    
    public class func sm_KneeBothRangeOfMotion() -> CodeableConcept {
        
        let arr = Coding.sm_KneeLeftRangeofMotion() + Coding.sm_KneeRightRangeofMotion()
        return sm_From(
            arr, text: "Knee Both Active Range of Motion")
    }


    public class func sm_BodySiteKneeBoth() -> CodeableConcept {
        return sm_From([Coding.sm_bodySite_KneeBoth()], text: "Knee Joint")
    }
    
    public class func sm_BodySiteKneeLeft() -> CodeableConcept {
        return sm_From([Coding.sm_bodySite_KneeLeft()], text: "Left Knee Region")
    }
    
    public class func sm_BodySiteKneeRight() -> CodeableConcept {
        return sm_From([Coding.sm_bodySite_KneeRight()], text: "Right Knee Region")
    }
    
    public class func sm_BodySiteShoulder() -> CodeableConcept {
        return sm_From([Coding.sm_bodySite_Shoulder()], text: "Shoulder Region")
    }
}

public extension Quantity {
    
    public class func sm_Angle(_ degree: Double) -> Quantity {
        let quantity = Quantity()
        quantity.code = FHIRString("deg")
        quantity.system = FHIRURL("http://unitsofmeasure.org")
        quantity.unit = "degree (plane angle)"
        quantity.value = FHIRDecimal(Decimal(degree))
        return quantity
    }
    
}
