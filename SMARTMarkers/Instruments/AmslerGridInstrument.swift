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


public class AmslerGridPRO : ActiveInstrumentProtocol {
    
    public var ip_taskDescription: String?

    public init() { }
    
    public var ip_title: String {
        return "Amsler Grid"
    }
    
    public var ip_identifier: String? {
        return "amsler.grid"
    }
    
    public var ip_code: Coding? {
        return Coding.sm_Coding(ip_identifier!, "http://researchkit.org", "Amsler Grid")
    }
    
    public var ip_version: String? {
        return nil
    }
    
    public var ip_publisher: String?
    
    public var ip_resultingFhirResourceType: [FHIRSearchParamRelationship]? {
        return [FHIRSearchParamRelationship(Observation.self, ["code": ip_identifier!])]
    }
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        let amslerGridTask = ORKOrderedTask.amslerGridTask(withIdentifier: self.ip_identifier!, intendedUseDescription: ip_taskDescription, options: [])
        let taskVC = ORKTaskViewController(task: amslerGridTask, taskRun: UUID())
        callback(taskVC, nil)
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        var components = [ObservationComponent]()
        var images = [Media]()
        
        if let lefteye = result.stepResult(forStepIdentifier: "amsler.grid.left"), let gridResult = lefteye.results?.first as? ORKAmslerGridResult, let media = gridResult.sm_asMedia() {
            let oc = ObservationComponent()
            let cc = CodeableConcept()
            cc.coding = [Coding.sm_Coding("amsler.grid.left", "http://researchkit.org", "Amsler Grid Left Eye")]
            oc.code = cc
            components.append(oc)
            images.append(media)
        }
        
        if let righteye = result.stepResult(forStepIdentifier: "amsler.grid.right"), let gridResult = righteye.results?.first as? ORKAmslerGridResult, let media = gridResult.sm_asMedia() {
            let oc = ObservationComponent()
            let cc = CodeableConcept()
            cc.coding = [Coding.sm_Coding("amsler.grid.right", "http://researchkit.org", "Amsler Grid Right Eye")]
            oc.code = cc
            components.append(oc)
            images.append(media)
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
            var mediaBundleEntries = images.map{ $0.sm_asBundleEntry() }
            observation.basedOn = mediaBundleEntries.map { $0.sm_asReference() }

            mediaBundleEntries.append(observation.sm_asBundleEntry())
            
            let bundle = SMART.Bundle()
            bundle.entry = mediaBundleEntries
            bundle.type = BundleType.transaction
            return bundle
        }
        
        return nil
    }
    
}


extension ORKAmslerGridResult {
    
    func sm_Attachment() -> SMART.Attachment? {
        guard let img = image, let base64 = img.pngData()?.base64EncodedString() else { return nil }
        let dt = DateTime.now
        let attachment = SMART.Attachment()
        attachment.data = Base64Binary(value: base64)
        attachment.contentType = FHIRString("image/png")
        attachment.creation = dt
        attachment.title = identifier.fhir_string
        return attachment
    }
    
    func sm_asMedia() -> SMART.Media? {
        guard let attachment = sm_Attachment() else { return nil }
        let media = Media()
        media.content = attachment
        media.status = .completed
        return media
    }
    
}
