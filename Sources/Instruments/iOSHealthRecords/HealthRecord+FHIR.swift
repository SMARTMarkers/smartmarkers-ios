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

        if #available(iOS 14.0, *) {
            if self == .medicationRequest   { return MedicationRequest()    as! T }
        }
        
        throw SMError.instrumentHealthKitClinicalRecordTypeNotSupported(type: "<HKFHIRResourceType: \(self.rawValue)>")
    }
}

public extension HKFHIRResource {
    
	// Todo: Accomodate HKFHIRVersion
    func sm_asR4<T:DomainResource>() throws -> T {
        
		let json = try JSONSerialization.jsonObject(with: data, options: []) as! FHIRJSON
		let resource = try self.resourceType.as_FHIRResource()
        if #available(iOS 14, *) {
            if fhirVersion.majorVersion == 4, fhirVersion.minorVersion == 0 {
                var ctx = FHIRInstantiationContext()
                resource.populate(from: json, context: &ctx)
            }
            else {
                try resource.sm_populate(from: json, source: sourceURL, version: nil)
            }
        }
        else {
            try resource.sm_populate(from: json, source: sourceURL, version: nil)
        }
        
        
		return resource as! T
    }
}

public extension DomainResource {
    
    func sm_populate(from dstu2: FHIRJSON, source: URL?, version: String?) throws {
        
        let type = sm_resourceType()
		
		if let source = source {
			let resourceMeta = meta ?? Meta()
			resourceMeta.source = source.fhir_url
			meta = resourceMeta
		}
		
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
        else if type == "MedicationStatement" {
            let slf = self as! MedicationStatement
            try slf.sm__populate(from: dstu2, source: source)
        }
        else if type == "MedicationDispense" {
            let slf = self as! MedicationDispense
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
    
}


public extension MedicationDispense {
    
    func sm__populate(from r4: FHIRJSON, source: URL?) throws {
        
        var ctx = FHIRInstantiationContext()
        ctx.strict = false
        populate(from: r4, context: &ctx)
    }
}

public extension MedicationStatement {
    
    func sm__populate(from dstu2: FHIRJSON, source: URL?) throws {
        
        var ctx = FHIRInstantiationContext()
        populate(from: dstu2, context: &ctx)
        
        if let patient_reference = dstu2["patient"] as? FHIRJSON {
            subject = try Reference(json: patient_reference).using(source: source)
        }

        if let jsonA = dstu2["dosage"] as? [FHIRJSON] {
            for (i, json) in jsonA.enumerated() {
                if let punit = json["timing"] as? FHIRJSON,
                   let rep = punit["repeat"] as? FHIRJSON,
                   let unit = rep["periodUnits"] as? String {
                    self.dosage![i].timing!.repeat_fhir!.periodUnit = unit.fhir_string
                }
            }
        }
    }
}
    
public extension Procedure {
    
    func sm__populate(from dstu2: FHIRJSON, source: URL?) throws {
        
        var ctx = FHIRInstantiationContext()
        populate(from: dstu2, context: &ctx)
                
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
        
        if let subject = subject {
            var exts = extension_fhir ?? [Extension]()
            exts.append(Extension.CreateProvenonce(for: subject.using(source: source)))
            extension_fhir = exts
        }
    }
    
}


public extension MedicationRequest {
    
    func sm__populate(from dstu2: FHIRJSON, source: URL?) throws {
        
		var ctx = FHIRInstantiationContext()
		populate(from: dstu2, context: &ctx)
		
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
		
		if let subject = subject {
			var exts = extension_fhir ?? [Extension]()
			exts.append(Extension.CreateProvenonce(for: subject.using(source: source)))
			extension_fhir = exts
		}

    }
}

public extension Condition {
    
    func sm__populate(from dstu2: FHIRJSON, source: URL?) throws {
        var ctx = FHIRInstantiationContext()
        populate(from: dstu2, context: &ctx)
        
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
		
		if let subject = subject {
			var exts = extension_fhir ?? [Extension]()
			exts.append(Extension.CreateProvenonce(for: subject.using(source: source)))
			extension_fhir = exts
		}

    }
}

public extension Reference {
    
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

public extension AllergyIntolerance {
    
    func sm__populate(from dstu2: FHIRJSON, source: URL?) throws {
        
        var ctx = FHIRInstantiationContext()
        populate(from: dstu2, context: &ctx)
        
        if let subject = patient {
            var exts = extension_fhir ?? [Extension]()
            exts.append(Extension.CreateProvenonce(for: subject.using(source: source)))
            extension_fhir = exts
        }

    }
}


public extension Observation {
    
    func sm__populate(from dstu2: FHIRJSON, source: URL?) throws {

		var ctx = FHIRInstantiationContext()
		populate(from: dstu2, context: &ctx)
		
		if let subject = subject {
			var exts = extension_fhir ?? [Extension]()
			exts.append(Extension.CreateProvenonce(for: subject.using(source: source)))
			extension_fhir = exts
		}
		
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
    
}

public extension Immunization {
    
    func sm__populate(from dstu2: FHIRJSON, source: URL?) throws {
        
		
        let immunizationFunctionCodingSystem                = "http://terminology.hl7.org/CodeSystem/v2-0443"
        let immunizationFunctionCodeOrderingProvider        = "OP"
        let immunizationFunctionCodeOrderingProviderDisplay = "Ordering Provider"
        
		var ctx = FHIRInstantiationContext()
		populate(from: dstu2, context: &ctx)
		
        status = .completed
        
        if let subject = patient {
            var exts = extension_fhir ?? [Extension]()
            exts.append(Extension.CreateProvenonce(for: subject.using(source: source)))
            extension_fhir = exts
        }
        
        
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



public extension SMART.Extension {
    
    class func CreateProvenonce(for reference: Reference) -> Extension {
        let ext = Extension()
        ext.url = FHIRString("http://fhir-registry.smarthealthit.org/provenonce-reference-resource-location")
        ext.valueReference = reference
        return ext
    }
    
    
}
