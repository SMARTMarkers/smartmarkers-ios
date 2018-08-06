//
//  PROPrescriber.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 6/28/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


public typealias PrescriberType = (DomainResource & PrescribingResource_Protocol)

public protocol PrescribedInstrumentDelegate : class {
    
    func resolveInstrument(callback: @escaping ((InstrumentResourceProtocol?) -> Void))
    
}

public protocol PrescribingResource_Protocol : FHIRResourceProtocol {
    
    var pro_prescriberName: String? { get }
    var pro_code: [Coding]? { get }
    var pro_categoryText: String? { get }
    var pro_title: String? { get }
    func getSchedule() -> Schedule?
    func resolveInstrument(callback : @escaping ((_ instrument: InstrumentResourceProtocol?) -> Void))

}

extension ProcedureRequest : PrescribingResource_Protocol {
    
    public func getSchedule() -> Schedule? {
        return Schedule(prescribing: self)
    }
    
    public var pro_prescriberName: String? {
        return requester?.agent?.display?.string.uppercased()
    }
    
    public var pro_code: [Coding]? {
        return code?.coding
    }
    
    public var pro_categoryText: String? {
        return category?.first?.text?.string
    }
    
    public var pro_title: String? {
        return self.ep_titleCode ?? self.ep_titleCategory ?? "REQ #\(self.id!.string)"
    }
    
    public func resolveInstrument(callback : @escaping ((_ instrument: InstrumentResourceProtocol?) -> Void)) {
        if let questionnaireExtension = extensions(forURI: kStructureDefinition_QuestionnaireRequest)?.first {
            questionnaireExtension.valueReference?.resolve(Questionnaire.self, callback: { (questionnaire) in
                if let questionnaire = questionnaire {
                    let instrument = InstrumentResource(questionnaire)
                    callback(instrument)
                }
                else {
                    callback(nil)
                }
            })
        }
        else {
            callback(nil)
        }
        
    }
}


public protocol PRBaseProtocol : class {
    
    var resource: PrescriberType? { get set }
    var schedule: Schedule? { get set }
    init(_ resource: PrescriberType)
    var delegate: PrescribedInstrumentDelegate? { get }

}




open class PrescribingResource : PRBaseProtocol {
    
    public weak var delegate: PrescribedInstrumentDelegate?
    
    public var resource: PrescriberType?
    
    public var schedule: Schedule?
    
    public var identifier: String? {
        return resource?.pro_identifier
    }
    
    public var title: String? {
        return  resource?.pro_title
    }
    
    public var code: [Coding]? {
        return resource?.pro_code
    }
    
    public var prescriberName: String? {
        return resource?.pro_prescriberName
    }
    
    public var category: String? {
        return resource?.pro_categoryText
    }
    
    open func resolveInstrument(callback: @escaping ((InstrumentResourceProtocol?) -> Void)) {
        resource?.resolveInstrument(callback: { (instrument) in
            if let instrument = instrument {
                callback(instrument)
            }
            else {
                self.delegate?.resolveInstrument(callback: callback)
            }
        })
    }
    
    public required init(_ pr: PrescriberType) {
        resource = pr
        schedule = pr.getSchedule()
    }
    
    public func coding(for system: String) -> Coding? {
        return code?.filter { $0.system?.absoluteString == system }.first
    }
    
    public func loincCode() -> String? {
        return coding(for: kLoincSystemKey)?.code?.string
    }
    
    
    
}


