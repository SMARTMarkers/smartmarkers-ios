//
//  Enrollment.swift
//  SMARTMarkers
//
//  Created by raheel on 3/29/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART


open class Enrollment: NSObject, ORKTaskViewControllerDelegate {

    /// Research Study to enroll in
    public unowned let study: Study
    
    // TODO: Consider adding "manager" and put study, preprocessor and persistor into manager, including the server
    /// Preprocessor
    public let preProcessor: (any PreProcessorProtocol)?
    
    public unowned let server: Server?
    
    
    /// ParticipantType
    let participantType: any Participant.Type

    /// Eligibliity
    public let eligibility: Eligibility?
    
    /// Consent controller
    public let consentController: SConsentController
    
    open var pdfRenderer: ORKHTMLPDFPageRenderer?
    
    open var participant: (any Participant)?

    public var isEnrolled: Bool {
        participant != nil
    }
    
    public typealias EnrollmentCallback = ((_ participant: (any Participant)?,
                                     _ error: Error?) -> Void)
    
    public var onSuccessfulEnrollment: EnrollmentCallback?
    
    public init(
        repository: Server?,
        for study: Study,
        participantType: any Participant.Type,
        eligibilityController: Eligibility?,
        consentController: SConsentController,
        preProcessor: (any PreProcessorProtocol)?,
        callback: EnrollmentCallback?) {
            
            
            // TODO: eligibilityController is nil if study.eligbility is referenced for some reason
            self.server = repository
            self.study = study
            self.eligibility = eligibilityController ?? study.eligibility
            self.consentController = consentController
            self.onSuccessfulEnrollment = callback
            self.preProcessor = preProcessor
            self.participantType = participantType
    }
   
    

    
    
    public func EnrollParticipant(_server: Server?, callback: @escaping ((_ participant: (any Participant)?, _ error: Error?) -> Void)) {
        
        
        let signature = consentController.consentResult?.signature?.signature
        
        guard let givenName = signature?.givenName,
              let familyName = signature?.familyName else {
            callback(nil, SMError.undefined(description: "No given/family name to register Participant"))
            return
        }
        
        
        guard let srv = _server ?? self.server else {
            callback(nil, SMError.undefined(description: "No server to register"))
            return
        }
       
        do {
            let fhirPt = participantType
            let new_participant = try participantType.CreateNewStudyParticipant(
                givenName: givenName,
                lastName: familyName,
                participantIdentifier: nil, // creates new
                contactEmail: consentController.consentResult?.email,
                study: self.study
            )
            
            preProcessor?.prepareEnrollment(participant: new_participant)
            
            
      
            
            srv.ready { srvErr in
                if let srvErr {
                    callback(nil, srvErr)
                    return
                }
                
                new_participant.fhirPatient.createAndReturn(srv) { fhirerror in
                    
                    if let fhirerror = fhirerror {
                        callback(nil, fhirerror)
                    }
                    else {
                        smLog("[ENROLLING] >> Patient ID: \(new_participant.fhirResourceId ?? "")")
                        guard let consent = try? self.consentController.createFHIRConsent(for: new_participant) else {
                            callback(nil, SMError.CannotEnroll(message: "error making consent resource", error: nil))
                            return
                        }
//                        self.preProcessor?.prepareEnrollment(participant: new_participant)
                        consent.createAndReturn(srv) { (e2) in
                            if let e2 = e2 {
                                smLog(e2.description)
                                callback(nil, e2)
                            }
                            else {
                                smLog("[ENROLLING] >> Consent\t\(consent.id!.string)")
                                
                                let sub = new_participant.fhirResearchSubject
                                sub.individual = try! new_participant.fhirPatient.asRelativeReference()
                                sub.status = .onStudy
                                sub.consent = try? consent.asRelativeReference()
                                sub.identifier = new_participant.fhirPatient.identifier
                                sub.createAndReturn(srv) { (nerr) in
                                    if let nerr = nerr {
                                        smLog(nerr.description)
                                        callback(new_participant, nil)
                                    }
                                    else {
                                        smLog("[ENROLLING] >> ResearchSubject\t\(sub.id!.string)")
                                        let new = self.participantType.init(patient: new_participant.fhirPatient, for: self.study, consent: consent, subject: sub)
                                        callback(new, nil)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        catch  {
            callback(nil, error)
        }
    }
    

    
    open func viewController() throws -> ORKTaskViewController {
        
        let task = EnrollmentTask(enrollment: self)
        let taskViewController = InstrumentTaskViewController(task: task, taskRun: UUID())
        taskViewController.delegate = self
        return taskViewController
    }
   
    
    
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        
        
        taskViewController.dismiss(animated: true) {
            
            
//            self.eligibilityCheckCompletion?(task.is_eligible)
//            self.eligibilityCheckCompletion = nil
        }
    }
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, shouldPresent step: ORKStep) -> Bool {
        
        if let stp = step as? ORKConsentReviewStep {
//            fatalError("Append enrollment option")
            // use consentController.appendToDocForRview()
        }
        
//        if let stp = step as? ORKConsentReviewStep,
//           let sharingStepResult = taskViewController.result.stepResult(forStepIdentifier: "ConsentSharingStep"),
//              let res = sharingStepResult.results?.first as? ORKChoiceQuestionResult,
//              let answer = res.choiceAnswers?.first as? String,
//              let option = EnrollmentMode(rawValue: answer) {
//            (stp.consentDocument as! SMConsentDocument).appendToDocument(option.inHTML())
//        }

        return true
    }
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, learnMoreButtonPressedWith learnMoreStep: ORKLearnMoreInstructionStep, for stepViewController: ORKStepViewController) {


        let clss = learnMoreStep.instantiateStepViewController(with: ORKResult())
        clss.ppmg_setNavigationDoneButton()
        let nav = UINavigationController(rootViewController: clss)
//        nav.view.tintColor = .ppmg_Red
        stepViewController.present(nav, animated: true, completion: nil)
    }
}




