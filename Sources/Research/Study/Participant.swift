//
//  Participant.swift
//  SMARTMarkers
//
//  Created by raheel on 3/29/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART



/// Protocol to create FHIR based Participant
public protocol Participant: class, CustomStringConvertible {
    
    associatedtype ConsentedType: Consented
        
    /// Study Participant Identifier
    var identifier: String? { get  }
    
    /// First name
    var firstName: String? { get  }
    
    /// Participant Last name
    var lastName: String? { get  }
    
    /// Signed Consent
    var smConsent: ConsentedType? { get set }
    
    /// Participating Study
    var study: Study { get set }
    
    /// Is consented to participate?
    var isConsented: Bool { get }
    
    /// enrollment status
    var isEnrolled: Bool { get }
    
    /// Completed all Study Tasks
    var didCompleteAllTasks: Bool { get }
    
    /// Corresponds to `Patient.id`
    var fhirResourceId: String? { get }
    
    /// Contact Email Retrieved from Patient resource
    var contactEmail: String? { get }
    
    ///  FHIR Patient resource
    var fhirPatient: Patient { get set }
   
    /// FHIR ResearchSubject resource;  used to derive participation status
    var fhirResearchSubject: ResearchSubject { get set }
    
    var status: ResearchSubjectStatus { get set }
    
    init(patient: Patient, for study: Study, consent: Consent?, subject: ResearchSubject)
    
    func taskDidConclude(task: StudyTask)
    
    func update<Task>(from userGeneratedData: [DomainResource]?, ofTask studyTask: Task) where Task : StudyTaskProtocol

    static func synthetic_identifier() -> String
    
    static func CreateNewStudyParticipant(givenName: String?, lastName: String?, participantIdentifier: String?, contactEmail: String?, study: Study) throws -> Self

}

extension Participant {
    
    public static func synthetic_identifier() -> String {
        UUID().uuidString
    }
    
    public var isConsented: Bool {
        smConsent?.signedDate != nil
    }
    
    public var isEnrolled: Bool {
        fhirResourceId != nil
    }
    
    public var fhirResourceId: String? {
        fhirPatient.id?.string
    }
    
    public var description: String {
        """
        Participant ID: \(identifier ?? "-N/A-")
        FHIR Resource ID: \(fhirResourceId ?? "-N/A-")
        """
    }
    
    public var contactEmail: String? {
        fhirPatient.telecom?.filter({ $0.system == .email }).first?.value?.string
    }
    
    public var status: SMART.ResearchSubjectStatus {
        get { fhirResearchSubject.status! }
        set {
            fhirResearchSubject.status = newValue
            fhirResearchSubject.id = nil
            // TODO: persist resource and send
        }
    }
    
}


/// Extension to udpate status
extension Participant {
    
    public func updateStatusIfNeeded(to server: Server, persistor: (any DataPersistor)?, callback: @escaping ((_ error: Error?) -> Void)) {
       
        updateStatusIfNeeded1(to: server, callback: callback)
        /*
        guard fhirResearchSubject.status != nil, fhirResearchSubject.id == nil else {
            smLog("Participant status submitted")
            callback(nil)
            return
        }
        
        server.ready { [self] (readyErr) in
            if let e = readyErr {
                smLog("[SERVER]: NOT READY, aborted recording participant status \(status.rawValue)..\(e.description)")
                try? persistor?.persist(participant: self)
//                try? persistor?.persist(self)
                callback(e)
            }
            else {
                smLog("[SERVER]: READY")
                fhirResearchSubject.createAndReturn(server) { [self] (error) in
                    if let error = error {
                        smLog("[MANAGER]: Error recording participant status: \(status.rawValue) on the server: \(error.description)")
                    }
                    else {
                        smLog("[MANAGER]: Recorded participant status: \(status.rawValue): \(fhirResearchSubject.id!.string)")
                    }
                    try? persistor?.persist(participant: self)
//                    try? persistor?.persist(self)
                    callback(error)
                }
            }
        }*/
        
    }

    
    public func updateStatusIfNeeded1(to server: Server?, callback: @escaping ((_ error: Error?) -> Void)) {
        
        
        guard fhirResearchSubject.status != nil, fhirResearchSubject.id == nil else {
            smLog("Participant status submitted")
            callback(nil)
            return
        }
        
        server?.ready { [self] (readyErr) in
            if let e = readyErr {
                smLog("[SERVER]: NOT READY, aborted recording participant status \(status.rawValue)..\(e.description)")

                callback(e)
            }
            else {
                smLog("[SERVER]: READY")
                fhirResearchSubject.createAndReturn(server!) { (error) in
                    if let error = error {
                        smLog("[MANAGER]: Error recording participant status: \(status.rawValue) on the server: \(error.description)")
                    }
                    else {
                        smLog("[MANAGER]: Recorded participant status: \(status.rawValue): \(fhirResearchSubject.id!.string)")
                    }

                    callback(error)
                }
            }
        }
    }
}

