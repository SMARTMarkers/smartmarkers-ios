//
//  WebFetchStep.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 3/14/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART


open class WebFetchStepViewController: ORKTableStepViewController {
    
    public var wfStep: WebFetchStep {
        return step as! WebFetchStep
    }
    
    
    public var needsAuthorization: Bool {
        return wfStep.needsAuthorization
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.title = wfStep.title
        wfStep.stepViewController = self
        wfStep.onSuccessCallback = { (result, json) in
            if let result = result {
                self.addResult(result)
            }
        }
        
        wfStep.fetch { (success) in
            if success == false {
                DispatchQueue.main.async {
                    self.continueButtonTitle = "Needs Authorization"
                    self.updateButtonStates()
                }
            }
        }
    }
    
    override open func goForward() {
        if wfStep.hasResult {
            super.goForward()
        }
        
        if wfStep.needsAuthorization {
            wfStep.authorize { [weak  self] (success) in
                if success {
                    self?.wfStep.fetch(callback: { (success) in
                        
                    })
                }
            }
        }
    }
    
    
}


open class WebFetchStep: ORKTableStep {
    
    public var auth: SMART.OAuth2?
    
    public weak var stepViewController: ORKStepViewController?
    
    public var request: URLRequest?
    
    public var fetchedJSON: [String: Any]?
    
    public var onSuccessCallback: ((_ stepResult: ORKResult?, _ json: [String: Any]?) -> Void)?
    
    public init(_ identifier: String, title: String?, authSettings: [String: Any]?) {
        super.init(identifier: identifier)
        if let authSettings = authSettings {
            self.auth = OAuth2CodeGrant(settings: authSettings)
            self.auth?.logger = OAuth2DebugLogger(.trace)
        }
        self.title = title
        self.isBulleted = true
    }
    
    open func fetchedResults(json: [String: Any]?) {
        self.fetchedJSON = json
        onSuccessCallback?(resultFromFetch(json: json), json)
    }
    
    
    
    open func resultFromFetch(json: [String: Any]?) -> ORKResult? {
        return nil
    }
    
    open var needsAuthorization: Bool {
        if let auth = auth {
            return !auth.hasUnexpiredAccessToken()
        }
        return false
    }
    
    open var hasResult: Bool {
        return fetchedJSON != nil
    }
    
    
    open func authorize(callback: @escaping ((_ success: Bool)->Void)) {
        SMARTManager.shared.callbackHandler = auth
        auth!.authConfig.authorizeContext = stepViewController
        auth!.authConfig.authorizeEmbedded = true
        auth!.authorize(callback: { [weak self] (json, error) in
            if nil == error {
                self?.performFetch(callback: callback)
            }
        })
    }
    
    
    open func fetch(callback: @escaping ((_ success: Bool)-> Void)) {
        
        if let auth = auth {
            //Already Has Tokens: Call results
            if auth.hasUnexpiredAccessToken() {
                performFetch { (_success) in
                    callback(_success)
                }
            }
            else {
                callback(false)
            }
        }
    }
    
    open func performFetch(callback: @escaping ((_ success: Bool) -> Void)) {
        
        guard let _request = request, let auth = auth else {
            callback(false)
            return
        }
        var req = auth.request(forURL: _request.url!)
        req.httpBody = _request.httpBody
        req.httpMethod = _request.httpMethod
        self.performRequest(request: req, callback: { [weak self] (json, error) in
            if let json = json {
                DispatchQueue.main.async {
                    self?.fetchedResults(json: json)
                    callback(true)
                }
            }
            else {
                callback(false)
            }
        })
    }
    
    open func performRequest(request: URLRequest, callback: @escaping ((_ json: [String: Any]?, _ error: Error?)->Void)) {
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, resp, error) in
            if let data = data {
                do {
                    let decodedJSON = try JSONSerialization.jsonObject(with: data, options: [])
                    if let decodedJSON = decodedJSON as? [String:Any] {
                        callback(decodedJSON, nil)
                    }
                }
                catch {
                    callback(nil, error)
                }
            }
            else {
                callback(nil, error)
            }
        })
        task.resume()
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override open func stepViewControllerClass() -> AnyClass {
        return WebFetchStepViewController.self
    }
    
    
}
