//
//  AmslerGridInstrument.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 3/15/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART


public class AmslerGridPRO : InstrumentProtocol {
    
    public var description: String?

    public init(_description: String? = nil) {
        description = _description
    }
    
    public var ip_title: String {
        return "Amsler Grid"
    }
    
    public var ip_identifier: String {
        return "amsler.grid"
    }
    
    public var ip_code: Coding? {
        return Coding.sm_Coding(ip_identifier, "http://researchkit.org", "Amsler Grid")
    }
    
    public var ip_version: String? {
        return nil
    }
    
    public var ip_resultingFhirResourceType: [PROFhirLinkRelationship]? {
        return [PROFhirLinkRelationship(Observation.self, ["code": ip_identifier])]
    }
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        let amslerGridTask = ORKOrderedTask.amslerGridTask(withIdentifier: self.ip_identifier, intendedUseDescription: description, options: [])
        let taskVC = ORKTaskViewController(task: amslerGridTask, taskRun: UUID())
        callback(taskVC, nil)
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        var components = [ObservationComponent]()
        
        if let lefteye = result.stepResult(forStepIdentifier: "amsler.grid.left"), let gridResult = lefteye.results?.first as? ORKAmslerGridResult, let fhirAttachment = gridResult.sm_toFHIR() {
            let oc = ObservationComponent()
            let cc = CodeableConcept()
            cc.coding = [Coding.sm_Coding("amsler.grid.left", "http://researchkit.org", "Amsler Grid Left Eye")]
            oc.code = cc
            oc.valueAttachment = fhirAttachment
            components.append(oc)
        }
        
        if let righteye = result.stepResult(forStepIdentifier: "amsler.grid.right"), let gridResult = righteye.results?.first as? ORKAmslerGridResult, let fhirAttachment = gridResult.sm_toFHIR() {
            let oc = ObservationComponent()
            let cc = CodeableConcept()
            cc.coding = [Coding.sm_Coding("amsler.grid.right", "http://researchkit.org", "Amsler Grid Right Eye")]
            oc.code = cc
            oc.valueAttachment = fhirAttachment
            components.append(oc)
        }
        
        if components.count > 0 {
            let observation = Observation()
            if let coding = self.ip_code {
                let cc = CodeableConcept()
                cc.coding = [coding]
                observation.code = cc
            }
            observation.status = ObservationStatus.final
            observation.component = components
            let bID = "urn:uuid:\(UUID().uuidString)"
            let entry = BundleEntry()
            entry.fullUrl = FHIRURL(bID)
            entry.resource = observation
            entry.request = BundleEntryRequest(method: .POST, url: FHIRURL("Observation")!)
            let bundle = SMART.Bundle()
            bundle.entry = [entry]
            bundle.type = BundleType.transaction
            return bundle
        }
        
        return nil
    }
    
}


extension ORKAmslerGridResult {
    
    func sm_toFHIR() -> SMART.Attachment? {
        guard let img = image, let base64 = UIImagePNGRepresentation(img)?.base64EncodedString() else { return nil }
        let dt = DateTime.now
        let attachment = SMART.Attachment()
        attachment.data = Base64Binary(value: base64)
        attachment.contentType = FHIRString("image/png")
        attachment.creation = dt
        attachment.title = identifier.fhir_string
        return attachment
    }
    
}
