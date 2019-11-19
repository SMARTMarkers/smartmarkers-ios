//
//  QuestionnaireR4.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 1/25/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


open class AdaptiveQuestionnaire: Questionnaire {
    
    lazy var answers: [QuestionnaireResponse] =  {
        return [QuestionnaireResponse]()
    }()
    
    var finalResponse: QuestionnaireResponse?
    
    var currentResponse: QuestionnaireResponse? {
        return answers.last
    }
    
    var currentQuestionnaire: Questionnaire? {
        return currentResponse?.contained?.first as? Questionnaire
    }
    
    var currentQuestionLinkId: String? {
        
        print(currentQuestionnaire?.item?.map { $0.linkId?.string })
        
        return currentQuestionnaire?.item?.first?.linkId?.string
    }
    
    func stepBack() {
        answers.removeLast()
    }
    
    func reset() {
        answers.removeLast()
        completedFlag = false
    }
    
    public internal(set) var completedFlag: Bool = false
    
    var onCompletion: ((_ response: QuestionnaireResponse?, _ error: Error?) -> Void)?
    
    public func next_q2(server: FHIRServer, answer: QuestionnaireResponseItem?, forQuestionnaireItemLinkId: String?, options: FHIRRequestOption, for currResponse: QuestionnaireResponse? = nil,callback: @escaping (_ resource: QuestionnaireResponse?, _ error: Error?) -> Void) {
        
        let response = currResponse ?? self.ResponseBody(responseIdentifier: "session-raheel")
        
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
            callback(nil, FHIRError.requestNotSent("Handler could not be created"))
            return
        }
        
        let path = url.absoluteString + "/next-q"
        
        server.performRequest(against: path, handler: handler) { [weak self] (response) in
            

            
            if nil == response.error {
                self?._server = server
                do {
                    let resource = try response.responseResource(ofType: QuestionnaireResponse.self)
                    resource._server = server
                    if resource.status == .completed {
                        self?.completedFlag = true
                    }
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
}
