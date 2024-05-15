//
//  Swift.swift
//  SMARTMarkers
//
//  Created by raheel on 3/29/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART




public class StudyProtocol {
    
    public let resource: PlanDefinition
    
    public let activities: [StudyActivityDefinition]?
    
    public init(_ protocolPlanDefinition: PlanDefinition) throws {
        
        self.resource = protocolPlanDefinition
        var acts = [StudyActivityDefinition]()
        for action in self.resource.action ?? [] {
            let saDefinition = try StudyActivityDefinition(action)
            acts.append(saDefinition)
        }
        
        self.activities = acts.isEmpty ? nil : acts
    }
    
}


open class Study {
    /// title, name of the study
    open var name: String?
    
    /// study home page of the study
    open var website: URL?
    
    /// main identifier of the study
    open var identifier: SMART.Identifier?
    
    /// study description
    open var studyDescription: String?
    
    /// Period of Study
    open var period: Period?
    
    /// Study Sponsor Organization
    open var organization: Organization?
    
    /// Eligbility: from `enrollment` reference to `Group`
    open var eligibility: Eligibility?
    
    /// Activities: from `protocol` reference to `PlanDefinition`
    open var activityTasks: [any StudyTaskProtocol]?
    
    /// principle investigator
    open var principleInvestigator: Practitioner?
    
    /// Study Protocol
    open var study_protocol: StudyProtocol?
 
    /// FHIR Resource
    public let resource: ResearchStudy
    
    /// Consent Controller
    open var consentController: SConsentController?
    
    /// Contact email
    open var contactEmail: String?
    
    open var contactPhone: String?
    
    open var contactName: String?
    
    /// Study Objectives
    open var objectives: [String]?
    
    /// Additional Study Notes, relies on `ResearchStudy.note.[].annotation.text `
    open var study_notes: [String]? {
        resource.note?.compactMap({ $0.text?.string })
    }
    
    /// Preparing Protocol
    public internal(set) var preparingProtocol = false
    
    /// Initializer, expects FHIR ResearchStudy
    required public init(_ researchStudy: ResearchStudy) throws {
        
        self.resource = researchStudy
        self.name = researchStudy.title?.string
        self.identifier = researchStudy.identifier?.first
        self.studyDescription = researchStudy.description_fhir?.string
        
        // enrollment: inclusion and exclusion groups
        if let enrollmentgroups = researchStudy.enrollment {
            let groups = enrollmentgroups.compactMap({ $0.resolved(Group.self) })
            do {
                self.eligibility = try Eligibility(groups)
            }
            catch {
                fatalError(error.localizedDescription)
            }
        }
        
        // collate study objectives in a string
        if let objs = researchStudy.objective {
            let labels = objs.compactMap { "\($0.name!.string)\n\($0.type?.text?.string ?? "")" as String }
            self.objectives = labels
        }
        
        self.organization = researchStudy.sponsor?.resolved(Organization.self)
        
        if let contact = researchStudy.contact?.first {
            self.contactName = contact.name?.string
            for detail in contact.telecom ?? [] {
                if detail.system == .phone {
                    self.contactPhone = detail.value?.string
                }
                else if detail.system == .email {
                    self.contactEmail = detail.value?.string
                }
            }
        }
       
        smLog("---> preparing protocol")

        preparingProtocol = true
        self.prepareProtocol { success, error in
            smLog("---> protocol prep=\(success); with err=\(String(describing: error))")
            self.preparingProtocol = false
        }
        

    }
    
    func prepareProtocol(callback: @escaping ((_ success: Bool, _ error: Error?) -> Void)) {
        
        guard let protocol_fhir = resource.protocol_fhir else {
            callback(false, SMError.undefined(description: "No protocol found in FHIR ResearchStudy"))
            return
        }
        
        
        // Only accepts One PlanDefintion as the main Protocol
        // Only resolves resources that are contained.
        // Todo: Support URL resolution
        // Todo: Support multiple PlanDefinitions
        
        do {
            if let planDef = protocol_fhir.first?.resolved(PlanDefinition.self) {
                self.study_protocol = try StudyProtocol(planDef)
                
                for a in self.study_protocol?.activities ?? [] {
                    smLog(a)
                    smLog(a.resource)
                    smLog(a.instrument)
                }
                callback(true, nil)
            }
        }
        catch {
            smLog(error)
            callback(false, error)
            
        }
    }
    
    
    /// Extension to be added to generated data as reference
    open lazy var researchStudy_extension: Extension? = {
        
        guard let relativeRef = try? self.resource.asRelativeReference() else {
            smLog("[caution]: cannot add studyExtension; do not have a reference")
            return nil
        }
        
        let ref = Reference()
        let ext = Extension()
        ext.url = "http://hl7.org/fhir/StructureDefinition/workflow-researchStudy"
        ext.valueReference = relativeRef
        return ext
    }()
}
