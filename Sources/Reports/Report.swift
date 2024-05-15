//
//  Report.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 3/1/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


/**
 Report Protocol
 All FHIR resources inheriting from `Resource` that are results of a PGHD `Instrument` must conform to the report protocol.
 */
public protocol Report: Resource {
    
    /// FHIR resourceType
    var rp_resourceType: String { get }
    
    /// Identifier: usually `resource.id`
    var rp_identifier: String? { get }
    
    /// Display friendly title
    var rp_title : String? { get }
    
    /// Type of report; based on `Coding`
    var rp_code: Coding? { get }
    
    /// Report description
    var rp_description: String? { get }
    
    /// Date resource created/generated/updated
    var rp_date: Date? { get }
    
    /// Observation value; if any
    var rp_observation: String? { get }
    
    /// Representation `ViewController`
    var rp_viewController: UIViewController? { get }
	
	/// Assign a `Patient` to the generated Resource
	@discardableResult
	func sm_assign(patient: Patient) -> Bool
    
}

/**
 Default extension for `Report`
 
 rp_resourceType returns FHIR Resource Type; rp_viewController returns a generic `ReportViewController`
 */
public extension Report {

    var rp_resourceType: String {
        return sm_resourceType()
    }
    
    var rp_viewController: UIViewController? {
        return ReportViewController(self)
    }
	
	var sm_Unit: String? {
		if let slf = self as? Observation {
			return slf.valueQuantity?.unit?.string ??
				slf.valueQuantity?.code?.string ??
				slf.component?.first?.valueQuantity?.unit?.string ??
				slf.component?.first?.valueQuantity?.code?.string
		}
		return nil
	}
}

public struct FHIRReportOptions {
    
    public let resourceType: Report.Type
    public let relation: [String: String]
    public init(_ type: Report.Type, _ relation: [String: String]) {
        self.resourceType = type
        self.relation = relation
    
    }
}




extension SMART.Bundle {
    
    func sm_ContentSummary() -> String? {
        
        let content = entry?.reduce(into: String(), { (bundleString, entry) in
            let report = entry.resource as? Report
            bundleString += report?.sm_resourceType() ?? "Type: \(entry.resource?.sm_resourceType() ?? "-")"
            bundleString += ": " + (report?.rp_date?.shortDate ?? "-")
            bundleString += "\n"
        })
        
        return content == nil ? nil : String(content!.dropLast())
    }
    
    func sm_resourceCount() -> Int {
        return entry?.count ?? 0
    }
}
