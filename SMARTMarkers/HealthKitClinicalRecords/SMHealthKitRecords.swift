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
            
            for hk in dataResults {
                print(hk.identifier)
                print(hk.clinicalRecords?.count)
                var imms = [Immunization]()
                for r in hk.clinicalRecords ?? [] {
                    
                    if let fhir = r.fhirResource?.data {
                        let json = try? JSONSerialization.jsonObject(with: fhir, options: [])
                        if let json = json as? FHIRJSON {
                            print(json)
                            
                            let srv = SMARTManager.shared.client.server
                            let rh  = FHIRJSONRequestHandler(.POST)
                            rh.json = json
                            
                            do {
                                if let o = try Immunization.mapToR4(from: json) {
                                    imms.append(o)
                                    print(try o.sm_jsonString())

                                }
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

extension Immunization {
    
    class func mapToR4(from json: FHIRJSON) throws -> Immunization? {
        
        let i = Immunization()
        
        i.status = .completed
        
        if let id = json["id"] as? String {
            //i.id = FHIRString(id)
        }
        
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
