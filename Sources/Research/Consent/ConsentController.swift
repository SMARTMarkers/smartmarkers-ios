//
//  ConsentController.swift
//  SMARTMarkers
//
//  Created by raheel on 3/29/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


open class Consented {
    
    public let consentResource: Consent
    
    public init(_ consentResource: Consent) {
        self.consentResource = consentResource
    }
    
    public var base64String: String {
            return consentResource.sourceAttachment!.data!.value
    }
    
    public var signedDate: Date? {
        consentResource.dateTime?.nsDate
    }
    
    open func writePDF() throws -> URL {
        let base = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let url = base.appendingPathComponent("consent-signed.pdf")
        let data = Data(base64Encoded: base64String)
        try data?.write(to: url, options: [.completeFileProtection])
        return url
    }
}



open class SConsentController: NSObject, ORKTaskViewControllerDelegate {
    
    public static let FirstStepIdentifier = "consentStep"
    public static let SharingStepIdentifier = "ConsentSharingStep"
    public static let ReviewStepIdentifier = "ConsentReviewStep"
    public static let LocationStepIdentifier = "LocationStep"
    public static let RegistrationStepIdentifier = "RegistrationStep"
    public static let ConsentAbortNoticeStepIdentifier = "abortedConsentNotice"
    
    public let requiredConsentToSubmitHealthRecord: Bool
    public let requiredConsentToShareData: Bool
    public let requiredToShowEnrollmentOptions: Bool
    public let consentDocument: SMConsentDocument
    public var consentResult: SMConsentResult?
    public internal(set) var consented: Consented?
    public internal(set) var signedPDF: Data?
    public internal(set) var consentStepIdentifiers = [String]()
    
    public var isConsented: Bool {
        consentResult?.isConsented ?? false
    }
    public var onConsentTaskDidEnd: ((_ controller: SConsentController, _ consent: Consented?) -> Void)?
    
    public init(study_title: String, htmlTemplate: String, signatureTitle: String?, signaturePageContent: String?, requiredToShowEnrollmentOptions: Bool = false, requiredConsentToShare: Bool = false, requiredConsentToSubmitHealthRecord: Bool = false) {
        
        self.requiredConsentToShareData = requiredConsentToShare
        self.requiredToShowEnrollmentOptions = requiredToShowEnrollmentOptions
        self.requiredConsentToSubmitHealthRecord = requiredConsentToSubmitHealthRecord
        
        self.consentDocument = SMConsentDocument()
        self.consentDocument.title = study_title
        self.consentDocument.htmlContent_template = htmlTemplate
        self.consentDocument.signaturePageContent = signaturePageContent
        self.consentDocument.signaturePageTitle = "Consent Signature"
        self.consentDocument.htmlContent_template = htmlTemplate
        self.consentDocument.htmlReviewContent = htmlTemplate
        self.consentDocument.canAppendToDocument = (self.requiredConsentToShareData || self.requiredToShowEnrollmentOptions || self.requiredConsentToSubmitHealthRecord)
        let signature = ORKConsentSignature.sm_NewSignature()
        // TODO: Comply with enrollment option
        signature.requiresName = true
        // TODO: Must commply with enrollment option
        signature.requiresSignatureImage = true
        signature.title = signatureTitle ?? "Signature of Participant"
        self.consentDocument.addSignature(signature)
        
    }
    
    open func createConsentResult(from taskresult: ORKTaskResult) -> SMConsentResult {
        
        return SMConsentResult(taskresult)
    }
    
    open func handleResultAndMakePDF(from taskResult: ORKTaskResult, pdfRenderer: ORKHTMLPDFPageRenderer, callback: @escaping ((_ completed: Bool) -> Void)) {
        
        self.consentResult = self.createConsentResult(from: taskResult)
        guard isConsented && consentResult!.apply(to: consentDocument) else {
            self.onConsentTaskDidEnd?(self, nil)
            self.onConsentTaskDidEnd = nil
            callback(true)
            return
        }
        
        let group = DispatchGroup()
        group.enter()
        consentDocument.makeCustomPDF(with: pdfRenderer) { pdfData, error in
            if let pdfData, let pdfURL = Self.signedConsentURL() {
                do {
                    smLog("[Consent] --> \(pdfURL.absoluteString)")
                    try pdfData.write(to: pdfURL, options: .atomic)
                    self.signedPDF = pdfData
                    self.onConsentTaskDidEnd?(self, nil)
                    self.onConsentTaskDidEnd = nil
                }
                catch let err {
                    smLog("failed to write consent PDF: \(err)")
                    self.onConsentTaskDidEnd?(self, nil)
                    self.onConsentTaskDidEnd = nil
                }
            }
            else {
                smLog("[Consent] failed to created PDFData \(error.debugDescription)")
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.onConsentTaskDidEnd = nil
            callback(self.signedPDF != nil)
        }
        
    }
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: (any Error)?) {
        taskViewController.dismiss(animated: true, completion: nil)
    }
    class func signedConsentURL(mustExist: Bool = false) -> URL? {
            do {
                let base = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let url = base.appendingPathComponent("consent-signed.pdf")
                if !mustExist || FileManager().fileExists(atPath: url.path) {
                    return url
                }
            }
            catch let err {
                fatalError(err.localizedDescription)
                smLog(err.localizedDescription)
            }
            return nil
    }
    
    class func writePDF(data: Data) throws -> URL {
        do {
            let base = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let url = base.appendingPathComponent("consent-signed.pdf")
            try data.write(to: url, options: [.completeFileProtection])
            return url
        }
        catch let err {
            throw err
        }
    }
    
    
    
    open func createSteps(prefix: [ORKStep]? = nil) -> [ORKStep] {
        
        var steps = prefix ?? [ORKStep]()

        // Review Step
        let signature = consentDocument.signatures!.first!
        
        let reviewStep = SMConsentReviewStep(identifier: Self.ReviewStepIdentifier, signature: signature, in: consentDocument)
        reviewStep.title = "Signing Consent"
        reviewStep.reasonForConsent = "By agreeing, you confirm that you read the consent form and that you wish to enroll in this research study"
        reviewStep.isOptional = false
        reviewStep.requiresScrollToBottom = true
        steps.append(reviewStep)
        
        // Collect all Consent
        self.consentStepIdentifiers = steps.map({ $0.identifier })
        return steps
    }
    
    
    open func createFHIRConsent(for participant: any Participant) throws -> Consent {
        
        
        guard let signedPDF else {
            throw SMError.CannotEnroll(message: "SignedPDF not created", error: nil)
        }
        
        guard let ptIdentifer = participant.fhirPatient.id?.string else {
            throw SMError.CannotEnroll(message: "Patient.id cannot be found for reference", error: nil)
        }
        
        let consent: Consent
        if let template = participant.smConsent?.consentResource {
            consent = template
        }
        else {
            consent = Consent()
        }
        let signatureDateString = consentResult!.signature!.signature!.signatureDate!
        let isodateFormatter = ISO8601DateFormatter()
        let date = isodateFormatter.date(from: signatureDateString)
        let signedDateTime = date?.fhir_asDateTime()
        consent.dateTime = signedDateTime
        
        let attachment = Attachment()
        attachment.contentType = "application/pdf"
        attachment.data = Base64Binary(value: signedPDF.base64EncodedString())
        attachment.title = "Signed Consent Document"
        attachment.creation = signedDateTime
        consent.sourceAttachment = attachment
        
        let pt_reference = try participant.fhirPatient.asRelativeReference()
        consent.patient = pt_reference
        consent.performer = [pt_reference]
        
        return consent
    }
    
}
