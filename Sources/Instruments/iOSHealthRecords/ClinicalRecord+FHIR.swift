//
//  HKFHIRResource+FHIR.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 9/21/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import HealthKit


extension HKFHIRResourceType {
    
    func as_FHIRResource<T: DomainResource>() throws -> T {
        
        if self == .allergyIntolerance  { return AllergyIntolerance()   as! T }
        if self == .immunization        { return Immunization()         as! T }
        if self == .observation         { return Observation()          as! T }
        if self == .condition           { return Condition()            as! T }
        if self == .medicationDispense  { return MedicationDispense()   as! T }
        if self == .medicationOrder     { return MedicationRequest()    as! T }
        if self == .medicationStatement { return MedicationStatement()  as! T }
        if self == .procedure           { return Procedure()            as! T }
        
        throw SMError.instrumentHealthKitClinicalRecordTypeNotSupported(type: "<HKFHIRResourceType: \(self.rawValue)>")
    }
}

extension HKFHIRResource {
    
    func sm_asR4<T:DomainResource>() throws -> T {
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as! FHIRJSON
            let resource = try self.resourceType.as_FHIRResource()
            try resource.sm_populate(from: json, source: sourceURL)
            return resource as! T
        }
        catch {
            
            throw error
        }
    }
}

extension DomainResource {
    
    func sm_populate(from dstu2: FHIRJSON, source: URL?) throws {
        
        let type = sm_resourceType()
        do {
            if type == "Immunization" {
                let slf = self as! Immunization
                try slf.sm__populate(from: dstu2, source: source)
            }
            else if type == "Observation" {
                let slf = self as! Observation
                try slf.sm__populate(from: dstu2, source: source)
            }
            else if type == "AllergyIntolerance" {
                let slf = self as! AllergyIntolerance
                try slf.sm__populate(from: dstu2, source: source)
            }
            else if type == "Condition" {
                let slf = self as! Condition
                try slf.sm__populate(from: dstu2, source: source)
            }
            else if type == "MedicationRequest" {
                let slf = self as! MedicationRequest
                try slf.sm__populate(from: dstu2, source: source)
            }
            else if type == "Procedure" {
                let slf = self as! Procedure
                try slf.sm__populate(from: dstu2, source: source)
            }
            else {
                throw SMError.instrumentHealthKitClinicalRecordTypeNotSupported(type: type)
            }
            
            
        }
        catch {
            throw error
        }
        
    }
    
}

extension Procedure {
    
    func sm__populate(from dstu2: FHIRJSON, source: URL?) throws {
        
        var ctx = FHIRInstantiationContext()
        populate(from: dstu2, context: &ctx)
        
        id = nil
        
        if let performr = (dstu2["performer"] as? [FHIRJSON])?.first {
            if let actr = performr["actor"] as? FHIRJSON {
                let p = ProcedurePerformer()
                p.actor = try? Reference(json: actr).using(source: source)
                p.function = try? CodeableConcept(json: performr["role"] as? FHIRJSON ?? [:])
                performer = [p]
            }
        }
        
        if let cencounter = dstu2["encounter"] as? FHIRJSON {
            encounter = try Reference(json: cencounter).using(source: source)
        }
    }
    
}


extension MedicationRequest {
    
    func sm__populate(from dstu2: FHIRJSON, source: URL?) throws {
        
        do {
            if let cat = dstu2["category"] as? FHIRJSON {
                category =  [try CodeableConcept(json: cat)]
            }
            
            if let cat = dstu2["dosageInstruction"] as? FHIRJSON {
                dosageInstruction = [try Dosage(json: cat)]
            }
            
            if let prescribr = dstu2["prescriber"] as? FHIRJSON {
                requester = try Reference(json: prescribr).using(source: source)
            }
            
            if let medicationCC = dstu2["medicationCodeableConcept"] as? FHIRJSON {
                medicationCodeableConcept = try CodeableConcept(json: medicationCC)
            }
            
            if let nte = dstu2["note"] as? String {
                note = [Annotation(text: nte.fhir_string)]
            }
            
            if let stats = dstu2["status"] as? String {
                status = MedicationrequestStatus(rawValue: stats)
            }
            
            if let datewritten = dstu2["dateWritten"] as? String {
                authoredOn = DateTime(string: datewritten)
            }
            
            intent = .order
            
        }
        catch {
            throw error
        }

    }
}

extension Condition {
    
    func sm__populate(from dstu2: FHIRJSON, source: URL?) throws {
        var ctx = FHIRInstantiationContext()
        populate(from: dstu2, context: &ctx)
        
        do {
            if let cat = dstu2["category"] as? FHIRJSON {
                category =  [try CodeableConcept(json: cat)]
            }
            
            if let cs = dstu2["clinicalStatus"] as? String {
                let concept = CodeableConcept()
                concept.coding = [Coding.sm_Coding(cs, kHL7ConditionClinicalStatus, "")]
                clinicalStatus = concept
            }
            
            if let vs = dstu2["verificationStatus"] as? String {
                let concept = CodeableConcept()
                concept.coding = [Coding.sm_Coding(vs, kHL7ConditionVerificationStatus, "")]
                verificationStatus = concept
            }
            
            if let assertr = dstu2["asserter"] as? FHIRJSON {
                asserter = try Reference(json: assertr).using(source: source)
            }
          
            
            
            
            
        }
        catch {
            throw error
        }
    }
}

extension Reference {
    
    func using(source: URL?) -> Reference {
        
        guard var source = source, let ref = reference?.string  else { return self }
        if let _ = URL(string: ref)?.scheme {
            return self
        }
        
        source.deleteLastPathComponent()
        source.deleteLastPathComponent()
        
        let refString = source.absoluteString +  ref
        reference = refString.fhir_string
        return self
        
    }
}

extension AllergyIntolerance {
    
    func sm__populate(from dstu2: FHIRJSON, source: URL?) throws {
        
        var ctx = FHIRInstantiationContext()
        populate(from: dstu2, context: &ctx)

    }
}


extension Observation {
    
    func sm__populate(from dstu2: FHIRJSON, source: URL?) throws {

        do {
            
            var ctx = FHIRInstantiationContext()
            populate(from: dstu2, context: &ctx)
            
            
            if let cat = dstu2["category"] as? FHIRJSON {
                category =  [try CodeableConcept(json: cat)]
            }
            
            if let ostatus = dstu2["status"] as? String {
                status = ObservationStatus(rawValue: ostatus)
            }
            
            if let cencounter = dstu2["encounter"] as? FHIRJSON {
                encounter = try Reference(json: cencounter).using(source: source)
            }
            
            code = try CodeableConcept(json: dstu2["code"] as! FHIRJSON)
            
            if let components = dstu2["component"] as? [FHIRJSON] {
                component = try components.map ({ try ObservationComponent(json: $0) })
            }
            
            if let oissued = dstu2["issued"] as? String {
                issued = Instant(string: oissued)
            }
            
        }
        catch {
            throw error
        }
    }
    
}

extension Immunization {
    
    func sm__populate(from dstu2: FHIRJSON, source: URL?) throws {
        
        let immunizationFunctionCodingSystem                = "http://terminology.hl7.org/CodeSystem/v2-0443"
        let immunizationFunctionCodeOrderingProvider        = "OP"
        let immunizationFunctionCodeOrderingProviderDisplay = "Ordering Provider"
        
        status = .completed
        
        if let vc = try? CodeableConcept(json: dstu2["vaccineCode"] as! FHIRJSON) {
            vaccineCode = vc
        }
        
        if let occuranceDate = dstu2["date"] as? String {
            occurrenceString = FHIRString(occuranceDate)
        }
        
        if let requester = dstu2["requester"] as? FHIRJSON {
            let performr = ImmunizationPerformer()
            performr.actor = try? Reference(json: requester).using(source: source)
            let coding = Coding.sm_Coding(immunizationFunctionCodingSystem, immunizationFunctionCodeOrderingProvider, immunizationFunctionCodeOrderingProviderDisplay)
            performr.function = CodeableConcept.sm_From([coding], text: nil)
            performer = [performr]
        }
        
        if let cencounter = dstu2["encounter"] as? FHIRJSON {
            encounter = try Reference(json: cencounter).using(source: source)
        }
    }
    
}



