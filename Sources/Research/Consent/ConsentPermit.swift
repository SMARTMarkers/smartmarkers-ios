//
//  ConsentPermit.swift
//  SMARTMarkers
//
//  Created by raheel on 3/30/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART

public protocol EnrollmentModeTypeNum {
    
    var title: String { get }
    var summary: String { get }
    var value: String { get }
    
}
public protocol EnumDescriptorProtocol: CaseIterable {
    
    static var category_title: String { get }
    static var code_system: String { get }
    static func Create(value: String) -> Self?
}

public extension EnumDescriptorProtocol where Self: EnrollmentModeTypeNum {
    
    static func Choices() -> [ORKTextChoice] {
        Self.allCases.map ({
            ORKTextChoice(text: $0.title, detailText: $0.summary, value: $0.value as NSCoding & NSCopying & NSObjectProtocol, exclusive: true)
        })
    }
    
    
    static func asBodyItems() -> [ORKBodyItem] {
        Self.allCases.map ({
            ORKBodyItem(text: $0.title, detailText: $0.summary, image: nil, learnMoreItem: nil, bodyItemStyle: .bulletPoint)
        })
    }
    
    
    func inFHIRCode() -> Coding {
        let code = self.value
        let display = self.summary
        return Coding.sm_Coding(code, Self.code_system, display)
    }
    
    func inHTML() -> String {
        var html = "<h3>\(Self.category_title)</h3>"
        html += "<ul>"
        for option in Self.allCases {
            let symbol = (option.value == self.value) ? "&#x2611;" : "&#x2610;"
            html += "<li><span>\(symbol)</span> <strong>\(option.title)</strong></br>\(option.summary)</li>"
        }
        html += "</ul>"
        return html
    }
    
    static func From(consent: Consent) -> Self? {
        
        if let coding = consent.provision?.action?.first?.sm_coding(for: Self.code_system),
           let code = coding.code?.string{
            return Self.Create(value: code)
        }
        return nil
    }
    
    static func From(documentReference: DocumentReference) -> Self? {
        
        if let coding = documentReference.context?.event?.filter({ (cc) -> Bool in
            cc.coding?.first?.system?.absoluteString == Self.code_system
        }).first {
            let code = coding.coding!.first!.code!.string
            return Self.Create(value: code)
        }

        return nil
    }
    
}

