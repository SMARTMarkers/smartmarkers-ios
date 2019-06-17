//
//  BloodPressureObservation.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 3/14/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


public extension Observation {
    
    class func sm_BloodPressure(systolic: Int, diastolic: Int, date: Date) -> Observation {
        
        // BP LOINC Coding
        let bp_Coding = Coding.sm_Coding_BP_LOINC()
        let bp_CodableConcept = CodeableConcept()
        bp_CodableConcept.coding = [bp_Coding]
        
        //Category
        let categoryCoding = Coding()
        categoryCoding.code = FHIRString("vital-signs")
        categoryCoding.system = FHIRURL("http://hl7.org/fhir/observation-category")
        let categoryCodeableConcept = CodeableConcept()
        categoryCodeableConcept.coding = [categoryCoding]
        
        //Systolic Observation Component
        let systolicQuantity = Quantity()
        systolicQuantity.unit = FHIRString("mmHg")
        systolicQuantity.system = FHIRURL("http://unitsofmeasure.org")
        systolicQuantity.value = FHIRDecimal(integerLiteral: systolic)
        systolicQuantity.code = FHIRString("mmHg")
        let systolicCode = Coding.sm_Coding_SBP_LOINC()
        let systolicCodableConcept = CodeableConcept()
        systolicCodableConcept.coding = [systolicCode]
        systolicCodableConcept.text = FHIRString("Systolic Blood Pressure")
        let systolicObservationComponent = ObservationComponent()
        systolicObservationComponent.code = systolicCodableConcept
        systolicObservationComponent.valueQuantity = systolicQuantity
        
        //Diastolic Observation Component
        let diastolicQuantity = Quantity()
        diastolicQuantity.unit = FHIRString("mmHg")
        diastolicQuantity.system = FHIRURL("http://unitsofmeasure.org")
        diastolicQuantity.value = FHIRDecimal(integerLiteral: diastolic)
        diastolicQuantity.code = FHIRString("mmHg")
        let diastolicCode = Coding.sm_Coding_DBP_LOINC()
        let diastolicCodableConcept = CodeableConcept()
        diastolicCodableConcept.coding = [diastolicCode]
        diastolicCodableConcept.text = FHIRString("Diastolic Blood Pressure")
        let diastolicObservationComponent = ObservationComponent()
        diastolicObservationComponent.code = diastolicCodableConcept
        diastolicObservationComponent.valueQuantity = diastolicQuantity
        
        let observation = Observation()
        observation.code = bp_CodableConcept
        observation.status = ObservationStatus.final
        observation.effectiveDateTime = date.fhir_asDateTime()
        observation.category = [categoryCodeableConcept]
        observation.component = [systolicObservationComponent, diastolicObservationComponent]
        return observation
    }
    
}

public extension Coding {
    
    class func sm_Coding_BP_LOINC() -> Coding {
        return sm_LOINC("55284-4", "Blood Pressure")
    }
    
    class func sm_Coding_SBP_LOINC() -> Coding {
        return sm_LOINC("8462-4", "Diastolic Blood Pressure")
    }
    
    class func sm_Coding_DBP_LOINC() -> Coding {
        return sm_LOINC("8480-6", "Systolic Blood Pressure")
    }
    
}
