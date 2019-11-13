//
//  AmslerGridInstrument.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 3/15/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART


public class AmslerGrid : Instrument {
    
    static let amslerGridRightEye = "amsler.grid.right"
    static let amslerGridLeftEye  = "amsler.grid.left"
    
    public var sm_taskDescription: String?
    
    public var sm_title: String
    
    public var sm_type: InstrumentCategoryType?

    public var sm_identifier: String?
    
    public var sm_code: Coding?
    
    public var sm_version: String?
    
    public var sm_publisher: String?
    
    public var sm_resultingFhirResourceType: [FHIRSearchParamRelationship]?
    
    public init() {
        sm_title        = "Amsler Grid"
        sm_identifier   = "amslergrid"
        sm_type         = .ActiveTask
        sm_code         = SMARTMarkers.Instruments.ActiveTasks.amslerGrid.coding
        sm_resultingFhirResourceType = [
            FHIRSearchParamRelationship(Observation.self, ["code": "http://researchkit.org|\(sm_identifier!)"]),
            FHIRSearchParamRelationship(Media.self,       ["subject": ""]) // Filled in by `Reports`
        ]
    }
    
    public func sm_taskController(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let amslerGridTask = ORKOrderedTask.amslerGridTask(withIdentifier: self.sm_identifier!, intendedUseDescription: sm_taskDescription, options: [])
        let taskVC = ORKTaskViewController(task: amslerGridTask, taskRun: UUID())
        callback(taskVC, nil)
    }
    
    public func sm_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        var components = [ObservationComponent]()
        var images = [Media]()
        
        if let lefteye = result.stepResult(forStepIdentifier: "amsler.grid.left"), let gridResult = lefteye.results?.first as? ORKAmslerGridResult, let media = gridResult.sm_asMedia() {
            let oc = ObservationComponent()
            let cc = CodeableConcept()
            cc.coding = [Coding.sm_ResearchKit(AmslerGrid.amslerGridLeftEye, "Amsler Grid Left Eye")]
            oc.code = cc
            let note = Annotation()
            note.text = "Amsler Grid Left Eye"
            media.note = [note]
            components.append(oc)
            images.append(media)
        }
        
        if let righteye = result.stepResult(forStepIdentifier: "amsler.grid.right"), let gridResult = righteye.results?.first as? ORKAmslerGridResult, let media = gridResult.sm_asMedia() {
            let oc = ObservationComponent()
            let cc = CodeableConcept()
            cc.coding = [Coding.sm_ResearchKit(AmslerGrid.amslerGridRightEye, "Amsler Grid Right Eye")]
            oc.code = cc
            let note = Annotation()
            note.text = "Amsler Grid Right Eye"
            media.note = [note]
            components.append(oc)
            images.append(media)
        }
        
        if components.count > 0 {
            
            let observation = Observation()
            if let coding = self.sm_code {
                let cc = CodeableConcept()
                cc.coding = [coding]
                observation.code = cc
            }
            observation.status = ObservationStatus.final
            observation.component = components
            var mediaBundleEntries = images.map{ $0.sm_asBundleEntry() }
            observation.derivedFrom = mediaBundleEntries.map { $0.sm_asReference() }

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
        media.type = CodeableConcept.sm_From([Coding.sm_Coding("image", "http://terminology.hl7.org/CodeSystem/media-type", "Image")], text: "Image")
        return media
    }
    
}
