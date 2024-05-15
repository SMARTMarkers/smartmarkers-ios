//
//  ConsentDocument.swift
//  SMARTMarkers
//
//  Created by raheel on 3/29/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit

public let SMARTMarkersConsentTaskIdentifier = "smartmarkers.consent.task"

public class SMConsentInstruction: ORKInstructionStep {
    public var consentDocument: SMConsentDocument?
}


public class SMConsentDocument: ORKConsentDocument {
    
    public var htmlContent_template: String?
    
    public var canAppendToDocument: Bool?
    
    var textToAppend: String? {
        didSet {
            if canAppendToDocument == true {
                var ammendmend = htmlContent_template
                ammendmend?.append(textToAppend ?? "")
                htmlReviewContent = ammendmend
            }
        }
    }
    
    public override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func appendToDocument(_ text: String) {
        textToAppend = text
    }
    

    
}

open class SMConsentReviewStep: ORKConsentReviewStep {
    
    override public class func stepViewControllerClass() -> AnyClass {
        SMConsentReviewStepViewController.self
    }
}

open class SMConsentReviewStepViewController: ORKConsentReviewStepViewController {

    private var fixCheck = false
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !fixCheck { fix() }
    }

    func fix() {
        for v in self.view.subviewsRecursive() {
            if let n = v as? ORKNavigationContainerView {
                n.updateContinueAndSkipEnabled()
            }
        }
        fixCheck = true
    }
    
    private var email: String?
    
    public override func makeNameForm() -> ORKFormStepViewController {
        
        let formstep = ORKFormStep(identifier: "nameForm" , title: self.step?.title, text: self.step?.text)
        formstep.useSurveyMode = false
        let regularExpression = try! NSRegularExpression(pattern: "^[A-Za-z][A-Za-z0-9\\s-']*$", options: [])
        
        let given = ORKTextAnswerFormat.textAnswerFormat(withValidationRegularExpression: regularExpression, invalidMessage: "Invalid entry")
        given.multipleLines = false
        given.autocapitalizationType = UITextAutocapitalizationType.words
        given.autocorrectionType = .no
        given.spellCheckingType = .no
        given.placeholder = "Tap here"
        let givemItem = ORKFormItem(identifier: "given", text: "First name", answerFormat: given, optional: false)
        
        let family = ORKTextAnswerFormat.textAnswerFormat()
        family.multipleLines = false
        family.autocapitalizationType = UITextAutocapitalizationType.words
        family.autocorrectionType = UITextAutocorrectionType.no
        family.spellCheckingType = .no
        family.textContentType = .familyName
        family.placeholder = "Tap here"
        let familyItem = ORKFormItem(identifier: "family", text: "Last name", answerFormat: family, optional: false)
        
        
        let email_regex = try! NSRegularExpression(pattern: "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}$", options: .caseInsensitive)
        let email_af = ORKTextAnswerFormat.textAnswerFormat(withValidationRegularExpression: email_regex, invalidMessage: "Please type a valid email address")
        email_af.multipleLines = false
        email_af.autocapitalizationType = .none
        email_af.autocorrectionType = .no
        email_af.spellCheckingType = .no
        email_af.textContentType = .init(rawValue: "")
        email_af.keyboardType = .emailAddress
        email_af.placeholder = "Tap here"
        let emailItem = ORKFormItem(identifier: "email", text: "E-mail", answerFormat: email_af, optional: false)
        emailItem.isOptional = false
        
        let formSection = ORKFormItem(sectionTitle: "Please enter your name")
        let formSectionEmail = ORKFormItem(sectionTitle: "Your email address")
        formstep.formItems = [formSection, givemItem, familyItem, formSectionEmail, emailItem]
        formstep.isOptional = false
        
        
        let givenResult = ORKTextQuestionResult(identifier: "given")
        givenResult.textAnswer = self.signatureFirst
        let familyResult = ORKTextQuestionResult(identifier: "family")
        familyResult.textAnswer = self.signatureLast
        let emailResult = ORKTextQuestionResult(identifier: "email")
        emailResult.textAnswer = self.email
        let result = ORKStepResult(stepIdentifier: "nameForm", results: [givenResult, familyResult, emailResult])
        let vc = ORKFormStepViewController(step: formstep, result: result)
        vc.delegate = self
        return vc
    }
    
    public override func stepViewControllerResultDidChange(_ stepViewController: ORKStepViewController) {

        if stepViewController.step?.identifier == "nameForm" {
            let result = stepViewController.result
            let emailR = result?.result(forIdentifier: "email") as? ORKTextQuestionResult
            email = emailR?.textAnswer
        }
        
        super.stepViewControllerResultDidChange(stepViewController)

    }
    

    
    public override var result: ORKStepResult? {
        get {
            if let email = email {
                let res = super.result
                let emailresult = ORKTextQuestionResult(identifier: "email")
                emailresult.textAnswer = email
                res?.results?.append(emailresult)
                return res
            }
            return super.result
        }
    }
}


open class SMConsentResult {
    
    private static let CONSENT_REVIEW_STEP = "ConsentReviewStep"
  
   public internal(set) var signature: ORKConsentSignatureResult?
    
    var isConsented: Bool {
        signature?.consented ?? false
    }
    
    public internal(set) var signedPDF: Data?
    
    public internal(set) var signedPDFURL: URL?
    
    public internal(set) var email: String?
    
    public init(_ result: ORKTaskResult) {
        
        // Signature
        let consentResults = result.stepResult(forStepIdentifier: Self.CONSENT_REVIEW_STEP)?.results
        let signatureResult = consentResults?.first as? ORKConsentSignatureResult
        self.signature = signatureResult
        
        if let email = consentResults?.filter({ $0.identifier == "email" }).first as? ORKTextQuestionResult {
            self.email = email.textAnswer
        }
    }
    
    @discardableResult
    open func apply(to document: SMConsentDocument) -> Bool {
        if let signature = signature {
            signature.apply(to: document)
            return true
        }
        
        
        return false
    }
}



extension ORKConsentSignature {
    
    static let formatter = "yyyy-MM-dd'T'HH:mm:ssZ"
    
    static func sm_NewSignature() -> ORKConsentSignature {
        
        let signature = ORKConsentSignature(forPersonWithTitle: "Name of the Participant", dateFormatString: formatter, identifier: "ConsentDocumentParticipantSignature")
        return signature
    }
    
    
    func sm_signedDate() -> Date? {
        if let str = signatureDate {
            return sm_dateFromString(stringDate: str)
        }
        return nil
    }
    
    func sm_dateFromString(stringDate:String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Self.formatter
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.date(from: stringDate)
    }
}




