import ResearchKit
import SMART


public class WithDrawal {
    
    static private let areYouSure = "withdrawal.areyousure"
    
    /*
    class func createWithdrawnDocument(for participant: Participant, withdrawnTaskResult: ORKTaskResult) throws -> DocumentReference {

        guard let areyousure = withdrawnTaskResult.stepResult(forStepIdentifier: Self.areYouSure)?.results?.first as? ORKBooleanQuestionResult,
              areyousure.booleanAnswer?.boolValue == true
              else {
            throw SMError.undefined(description: "[Withdrawal] ERROR: are you sure == false")
        }
    
        
        let date = Date()
        let doc = DocumentReference()
        doc.date = date.fhir_asInstant()
        doc.status = .current
        doc.docStatus = .final
        doc.subject = try participant.patientResource.asRelativeReference()
        doc.type = Coding.ppmg_ResearchStudyConsent.sm_asCodeableConcept("PPMG Research Study Consent Document")
        
        // Participant
        
        // Withdrawn Code
        let cc_Withdrawn = Coding.ppmg_ResearchSubjectStatus(code: .withdrawn)
            .sm_asCodeableConcept("Participant Withdrawn from Study")
        let context = DocumentReferenceContext()
        context.event = [cc_Withdrawn]
        doc.context = context
        
        // TODO: Withdrawn Questionnaire Attachment
        let attachment = Attachment()
        attachment.contentType = "text/html"
        let html_data = "<h1>WithDrawal Document</h1>".data(using: .utf8)
        attachment.data = Base64Binary(value: html_data!.base64EncodedString())
        attachment.title = "Withdrawal Document"
        attachment.creation = date.fhir_asDateTime()
        let content = DocumentReferenceContent(attachment: attachment)
        doc.content = [content]
        
        return doc
    }
    */
        
    public static func Controller(manager: StudyManger, title: String? = nil, message: String? = nil) -> ORKTaskViewController {
        let task = WithdrawalTask(studyManager: manager, title: title, message: message)
        let taskController = ORKTaskViewController(task: task, taskRun: UUID())
        return taskController
        
    }
    class WithdrawalTask: ORKNavigableOrderedTask {
        
        var withdrawn = false
        
        init(studyManager: StudyManger, title: String? = nil, message: String? = nil) {
        
            let _title = title ?? "Withdrawing...\nPlease wait"
            
            let intro = PPMGInstructionStep(identifier: "withdraw.intro")
            intro.title = "Withdrawing from this study"
            intro.text = "Your participation in this study will end after you withdraw from this study and your data contained in this app will be removed."
            intro.attributedBodyString = message?.sm_htmlToNSAttributedString()
            if #available(iOS 13.0, *) {
                intro.iconImage = UIImage(systemName: "pip.remove")
            } else {
                // Fallback on earlier versions
            }
            intro.continueButtonTitle = "Continue"
            
            
            let question = PPMGQuestionStep(identifier: "withdrawal.areyousure")
            question.title = "Withdrawing from this study"
            question.question = "Are you sure about withdrawing from this study?"
            question.answerFormat = .booleanAnswerFormat()
            question.isOptional = false
            
            let estep = WithdrawalWaitStep(manager: studyManager, title: _title)
            let completionstep = NoBackButtonCompletionStep(identifier: "withdrawal.conclusion")
            
            let passcodecheck =  ORKPasscodeViewController.isPasscodeStoredInKeychain() ? ORKPasscodeStep(identifier: "check", passcodeFlow: .authenticate) : nil
        
            super.init(identifier: "withdrawal.task", steps: [
                intro,
                question,
                passcodecheck,
                estep,
                completionstep
            ].compactMap { $0 }
            )
            
            estep.task = self
            completionstep.task = self
            self.setStepModifier(WithdrawalConclusionStepModifier(), forStepIdentifier: completionstep.identifier)
            let resultSelector = ORKResultSelector(resultIdentifier: "withdrawal.areyousure")
            let abortPredicate = ORKResultPredicate.predicateForBooleanQuestionResult(with: resultSelector, expectedAnswer: false)
            let skipRule = ORKPredicateSkipStepNavigationRule(resultPredicate: abortPredicate)
            setSkip(skipRule, forStepIdentifier: estep.identifier)
            if ORKPasscodeViewController.isPasscodeStoredInKeychain() {
                setSkip(skipRule, forStepIdentifier: "check")
            }
            setSkip(skipRule, forStepIdentifier: completionstep.identifier)
            
            
            
            
        }
        
        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
   
    
    
    class WithdrawalConclusionStepModifier: ORKStepModifier {
        
        
        override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
            
            let task = step.task as! WithdrawalTask
            if task.withdrawn {
                    step.title = "Withdrawal complete"
                    step.text = "You have been withdrawn from this study."
            }
            else {
                step.title = "Issue"
                step.text = "There was an issue withdrawing you from the study. Please try again later or contact the research team"
            }
        }
    }
    
    
    class WithdrawalWaitStep: ORKWaitStep {
     
     unowned let manager: StudyManger
     
     required init(manager: StudyManger, title: String? = nil) {
         self.manager = manager
         super.init(identifier: "ppmg.withdrawal.waitstep")
        self.title = text ?? "Withdrawing from study\nPlease wait..."
     }
     required init(coder aDecoder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }
     override func stepViewControllerClass() -> AnyClass {
         WithdrawalWaitStepViewController.self
     }
 }

 class WithdrawalWaitStepViewController: ORKWaitStepViewController {
     
     var manager: StudyManger {
         (step as! WithdrawalWaitStep).manager
     }
     
     override func viewDidAppear(_ animated: Bool) {

         super.viewDidAppear(animated)
        
        guard let withdrawlResult = self.taskViewController?.result
        else {
            smLog("[Withdrawal]: Cannot find results")
            return
        }
        
     // abort any operations and start withdrawing
        manager.persistor?.submissions?.cancelAndReset()
        let group = DispatchGroup()
        group.enter()
        
        manager.withdrawParticipantFromStudy(basedOn: withdrawlResult) { (error) in
            if nil == self.manager.participant {
                (self.step!.task as! WithdrawalTask).withdrawn = true
            }
            group.leave()
        }
         
         group.notify(queue: .main) {
             self.goForward()
         }
     }
     
     
 }
    
    
    
}
