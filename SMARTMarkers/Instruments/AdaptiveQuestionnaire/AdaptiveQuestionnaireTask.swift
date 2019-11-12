//
//  AdaptiveOperation.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 10/15/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART


open class AdaptiveQuestionnaire: Questionnaire {
    
    lazy var answers: [QuestionnaireResponse] =  {
       return [QuestionnaireResponse]()
    }()
    
    var currentResponse: QuestionnaireResponse? {
        return answers.last
    }
    
    var onCompletion: ((_ response: QuestionnaireResponse?, _ error: Error?) -> Void)?
    
    
    public func next_q2(server: FHIRMinimalServer, answer: QuestionnaireResponseItem?, forQuestionnaireItemLinkId: String?, options: FHIRRequestOption, callback: @escaping FHIRResourceErrorCallback) {
        
        let response = currentResponse ?? self.ResponseBody(responseIdentifier: "session-raheel")
        
        if let answer = answer {
            var items = response?.item ?? [QuestionnaireResponseItem]()
            items.append(answer)
            response?.item = items
        }
        
        
        guard let url = url else {
            callback(nil, FHIRError.requestNotSent("Questionnaire has no url"))
            return
        }
        
        guard var handler = server.handlerForRequest(withMethod: .POST, resource: response) else {
            return
        }
        
        let path = url.absoluteString + "/next-q"
        
        server.performRequest(against: path, handler: handler) { [weak self] (response) in
            
            print(response.error)
            print(response.outcome)
            print(response.body)
            
            if nil == response.error {
                self?._server = server
                do {
                    let resource = try response.responseResource(ofType: QuestionnaireResponse.self)
                    resource._server = server
                    self?.answers.append(resource)
                    callback(resource, nil)
                    
                }
                catch {
                    callback(nil, error.asFHIRError)
                }
            }
            else {
                
                callback(nil, response.error)
            }
        }
    }
    
    override open func populate(from json: FHIRJSON, context: inout FHIRInstantiationContext) {
        super.populate(from: json, context: &context)
    }
    
}

open class AdaptiveQuestionnaireTask2: ORKNavigableOrderedTask {
    
    public final let adaptiveQuestionnaire: Questionnaire
    
    var _responses = [QuestionnaireResponse]()
    
    var latestResponse: QuestionnaireResponse? {
        return _responses.last
    }
    
    public init(_ adaptiveQuestionnaire: Questionnaire) throws {
        
        self.adaptiveQuestionnaire = adaptiveQuestionnaire
        
        let identifier = adaptiveQuestionnaire.sm_identifier ?? UUID().uuidString
        
        super.init(identifier: identifier, steps: nil)
        

    
    
    }
    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    
    @discardableResult
    private func addIncoming(_ questionnaireResponse: QuestionnaireResponse) -> QuestionnaireResponse {
        
        _responses.append(questionnaireResponse)
        return questionnaireResponse
    }
    
    func getNextQuestion(callback: @escaping ((_ questionnaireResponse: QuestionnaireResponse?, _ error: Error?) -> Void)) {
        
        //addincoming
        
        //setNavigationRule
        
        
        callback(nil, nil)
        
    }
    
    
    open override func step(after step: ORKStep?, with result: ORKTaskResult) -> ORKStep? {
        return super.step(after: step, with: result)
    }
    
    
    open override func step(before step: ORKStep?, with result: ORKTaskResult) -> ORKStep? {
        return super.step(after: step, with: result)
    }
    
}
