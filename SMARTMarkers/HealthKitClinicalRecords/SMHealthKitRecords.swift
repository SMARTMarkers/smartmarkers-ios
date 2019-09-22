//
//  SMHealthKitRecords.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 9/20/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART

@available(iOS 12.0, *)
public class SMHealthKitRecords: Instrument {
    
    public init() { }
    
    public var ip_title: String {
        return "HealthKit Clinical Record"
    }
    
    public var ip_identifier: String? {
        return "com.apple.healthkit.clinicalrecords"
    }
    
    public var ip_code: Coding? {
        return nil
    }
    
    public var ip_version: String? {
        return nil
    }
    
    public var ip_publisher: String? {
        return nil
    }
    
    public var ip_resultingFhirResourceType: [FHIRSearchParamRelationship]? {
        return nil
    }
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let taskViewController = HKClinicalRecordTaskViewController()
        callback(taskViewController, nil)
        
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        if let dataResults = result.stepResult(forStepIdentifier: ksm_step_auth)?.results as? [HKClinicalRecordResult] {
            
            var domainResources = [DomainResource]()
            for healthKitRecord in dataResults  {
                do {
                    if let resources = try healthKitRecord.clinicalRecords?.compactMap ({ try $0.fhirResource?.sm_asR4() }) {
                        domainResources.append(contentsOf: resources)
                    }
                }
                catch {
                    print(error)
                }
            }
            
            domainResources.forEach { (d) in
                print(d.sm_resourceType())
                print(try? d.asJSON())
            }
            
            return domainResources.isEmpty ? nil : SMART.Bundle.sm_with(domainResources)
            
            
            
            
            
            
            
            
            
            for hk in dataResults {

                var imms = [DomainResource]()
                for r in hk.clinicalRecords ?? [] {
                    
                    if let fhir = r.fhirResource?.data {
                        let json = try? JSONSerialization.jsonObject(with: fhir, options: [])
                        if let json = json as? FHIRJSON {
                            print(json)
                            
                            do {
                                print(hk.identifier)
                                print(r.fhirResource?.sourceURL)
                                let o = try Observation.mapToR4(json: json)
                                imms.append(o)
                            }
                            catch {
                                print(error)
                            }
                        }
                        
                    }
                    
                }
                
                if !imms.isEmpty {
                    let bundle = SMART.Bundle.sm_with(imms)
                    return bundle
                }
                print("---------------------------")

            }
            
            
        }
        return nil
    }
    
    
    
}


extension Observation {
    
    class func mapToR4(json: FHIRJSON) throws -> Observation {
     
        do {
        
            let o = Observation()
            
            if let category = json["category"] as? FHIRJSON {
                o.category =  [try CodeableConcept(json: category)]
            }
            
            if let status = json["status"] as? String {
                o.status = ObservationStatus(rawValue: status)
            }
            
            if let encounter = json["encounter"] as? FHIRJSON {
                let reference = try Reference(json: encounter)
                reference.reference = FHIRString("https://localhost:9090/resource/Encounter/3232")  
                o.encounter = reference
            }
            
            o.code = try CodeableConcept(json: json["code"] as! FHIRJSON)
            
            if let components = json["component"] as? [FHIRJSON] {
                o.component = try components.map ({ try ObservationComponent(json: $0) })
            }
            
            if let issued = json["issued"] as? String {
                o.issued = Instant(string: issued)
            }
            
            return o
        }
        catch {
            print(error)
            throw error
        }
    }

}

extension Immunization {
    
    class func mapToR4(from json: FHIRJSON) throws -> Immunization? {
        
        let i = Immunization()
        
        i.status = .completed
        
        if let vc = try? CodeableConcept(json: json["vaccineCode"] as! FHIRJSON) {
            i.vaccineCode = vc
        }
        
        if let occuranceDate = json["date"] as? String {
            i.occurrenceString = FHIRString(occuranceDate)
        }
        
        if let _ = json["requester"] as? FHIRJSON {

        }
        
        if let encounter = json["encounter"] as? FHIRJSON, let reference = try? Reference(json: encounter) {
            i.encounter = reference
        }
        
        
        return i
    }
    
}
