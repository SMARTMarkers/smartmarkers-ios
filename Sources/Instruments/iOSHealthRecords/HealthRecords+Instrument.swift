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
open class HealthRecords: Instrument {
    
    public var sm_title: String
    
    public var sm_identifier: String?
    
    public var sm_code: Coding?
    
    public var sm_version: String?
    
    public var sm_publisher: String?
    
    public var sm_type: InstrumentCategoryType?
    
    public var sm_reportSearchOptions: [FHIRReportOptions]?
    
    var settings: [String: Any]?
    
    public init(_ settings: [String:Any]? = nil) {
        sm_title = "HealthKit Clinical Record"
        sm_type = .healthRecords
        sm_identifier = "com.apple.healthkit.clinicalrecords"
        sm_code = Coding.sm_Coding("healthrecords", "http://apple.com", "Health Records")
        self.settings = settings
    }
    
    
	open func sm_taskController(config: InstrumentPresenterOptions?, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {

        let taskViewController = HealthRecordTaskViewController(settings: settings)
        callback(taskViewController, nil)
    }
    
    open func sm_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
		
		guard let data = result.stepResult(forStepIdentifier: ksm_healthrecord_step_authorization)?.results as? [HealthRecordResult] else {
			return nil
		}
		
		var fhirResources = [DomainResource]()
		var errors = [Error]()
		var context = FHIRInstantiationContext()
        
		
		// Found A selector
		if let choices = result.stepResult(forStepIdentifier: ksm_healthrecord_step_review)?.results?.first as? ORKChoiceQuestionResult {
			let clinicalTypes = (choices.choiceAnswers as! [String]).map {
				HKObjectType.clinicalType(forIdentifier: HKClinicalTypeIdentifier(rawValue: $0))!
			}
			
			
			for type in clinicalTypes {
				if let healthRecord = data.filter({ $0.identifier == type.identifier }).first {
					
					if let resources = healthRecord.records?
									.compactMap ({ try? $0.fhirResource?.sm_asR4() })
									.compactMap({ $0 }) {
						fhirResources.append(contentsOf: resources)
					}
				}
			}
		}
		else {
			
			fhirResources =
				data
				.compactMap({ $0.records })
				.flatMap{ $0 }
				.compactMap { try? $0.fhirResource?.sm_asR4() }
				.compactMap({ $0 })
			
			
			
			
		}
		
		return fhirResources.isEmpty ? nil : SMART.Bundle.sm_with(fhirResources)
    }
}


public extension HealthRecords {
	
	class func InstructionItems() -> [ORKBodyItem] {
		[
		"Open the Health app and tap the Summary tab.",
			"Tap your profile picture in the top right-hand corner.",
			"Under Features, tap Health Records then tap Get Started",
			"To add another provider, scroll down to Features, then tap Add Account.",
			"You'll be prompted to allow the Health app to use your location to find hospitals and health networks near you. Choose either Allow Once, Allow While Using App or Don't Allow.",
			"Search for your care provider or health system, then tap to select it",
			"Under Available To Connect, choose an option.",
			"Sign in into the portal. You may be asked to save your password.",
			"Wait for your records to update. It may take a minute for your information to appear."
		].compactMap({
			ORKBodyItem(text: $0, detailText: nil, image: nil, learnMoreItem: nil, bodyItemStyle: .bulletPoint)
		})
	}
	
	class func linkInstructionsAsLearnMoreItem() -> ORKLearnMoreItem {
		
		let instructionStep = ORKLearnMoreInstructionStep(identifier: "learnMore-HealthRecord", _title: "Link your care provider to the Health app", _detailText: nil)
		instructionStep.text = "You will need access credentials to your care provider's patient portal. You can link more than one care provider."
		instructionStep.bodyItems = [.init(horizontalRule: ())] + HealthRecords.InstructionItems()
		return ORKLearnMoreItem(text: "Learn more about how to link your care provider to the health app", learnMoreInstructionStep: instructionStep)
	}
	
	class func InstructionStep() ->  SMInstructionStep {
		
		let step = SMInstructionStep(identifier: "learnMore-HealthRecord", _title: "Link your care provider to the Health app to retrieve your health record", _detailText: nil)
		step.bodyItems = [.init(horizontalRule: ())] + HealthRecords.InstructionItems()
		return step
	}
    
    class func isSupportedByDevice() -> Bool {
        HKHealthStore().supportsHealthRecords()
    }
}
