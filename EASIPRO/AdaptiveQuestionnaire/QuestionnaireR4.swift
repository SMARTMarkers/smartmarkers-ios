//
//  QuestionnaireR4.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 1/25/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


/**
 Temporary class for supporting Questionnarire R4
 */



open class QuestionnaireR4: DomainResource {
    
    override open class var resourceType: String {
        get { return "Questionnaire" }
    }
    
    /// Logical URI to reference this questionnaire (globally unique).
    public var url: FHIRURL?
    
    /// Name for this questionnaire (human friendly).
    public var title: FHIRString?
    
    /// The status of this questionnaire. Enables tracking the life-cycle of the content.
    public var status: PublicationStatus?
    
    /// Resource that can be subject of QuestionnaireResponse.
    public var subjectType: [FHIRString]?
    
    /// Additional identifier for the questionnaire.
    public var identifier: [Identifier]?

    /// Concept that represents the overall questionnaire.
    public var code: [Coding]?
    
    /// Business version of the questionnaire.
    public var version: FHIRString?
    
    public var item: [QuestionnaireItemR4]?
    
    


   
    
    override open func populate(from json: FHIRJSON, context instCtx: inout FHIRInstantiationContext) {
        
        super.populate(from: json, context: &instCtx)
        
        identifier = createInstances(of: Identifier.self, for: "identifier", in: json, context: &instCtx, owner: self) ?? identifier
        
        code = createInstances(of: Coding.self, for: "code", in: json, context: &instCtx, owner: self) ?? code
        
        status = createEnum(type: PublicationStatus.self, for: "status", in: json, context: &instCtx) ?? status
        
        if nil == status && !instCtx.containsKey("status") {
            instCtx.addError(FHIRValidationError(missing: "status"))
        }

        subjectType = createInstances(of: FHIRString.self, for: "subjectType", in: json, context: &instCtx, owner: self) ?? subjectType
        
        
        title = createInstance(type: FHIRString.self, for: "title", in: json, context: &instCtx, owner: self) ?? title
        
        
        url = createInstance(type: FHIRURL.self, for: "url", in: json, context: &instCtx, owner: self) ?? url
        
        version = createInstance(type: FHIRString.self, for: "version", in: json, context: &instCtx, owner: self) ?? version
        
        
        item = createInstances(of: QuestionnaireItemR4.self, for: "item", in: json, context: &instCtx, owner: self)

    }
    
    
    override open func decorate(json: inout FHIRJSON, errors: inout [FHIRValidationError]) {
        
        super.decorate(json: &json, errors: &errors)
       

        
        
        
        
        arrayDecorate(json: &json, withKey: "code", using: self.code, errors: &errors)
        
        
        

        arrayDecorate(json: &json, withKey: "identifier", using: self.identifier, errors: &errors)
        arrayDecorate(json: &json, withKey: "item", using: self.item, errors: &errors)

        
        
        
        
        self.status?.decorate(json: &json, withKey: "status", errors: &errors)
        if nil == self.status {
            errors.append(FHIRValidationError(missing: "status"))
        }
        
        
        arrayDecorate(json: &json, withKey: "subjectType", using: self.subjectType, errors: &errors)
        
        
        self.title?.decorate(json: &json, withKey: "title", errors: &errors)
        self.url?.decorate(json: &json, withKey: "url", errors: &errors)

        self.version?.decorate(json: &json, withKey: "version", errors: &errors)
        
        //bugWorkaround(json: &json)
        

        
    }
    
    func bugWorkaround(json: inout FHIRJSON) {
        
        json["subjectType"] = "Patient"
        
        
    }
    
    
    
    
    
}



extension QuestionnaireR4 {
    
    
    public func next_q(server: FHIRMinimalServer, questionnaireResponse: QuestionnaireResponseR4?, options: FHIRRequestOption = [], callback: @escaping FHIRResourceErrorCallback) {
        
        guard let id = id, let questionnaireResponse = questionnaireResponse else {
            callback(nil, FHIRError.requestNotSent("Questionnaire has no id"))
            return
        }
        guard var handler = server.handlerForRequest(withMethod: .POST, resource: questionnaireResponse) else {
            callback(nil, FHIRError.noRequestHandlerAvailable(.POST))
            return
        }
        
        handler.options.insert(.lenient)

        
        let path = "Questionnaire/\(id.string)/next-q"
        
        
        
        server.performRequest(against: path, handler: handler) { (response) in
            
            if nil == response.error {
                self._server = server
                do {
                    let resource = try response.responseResource(ofType: QuestionnaireResponseR4.self)
                    resource._server = server
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


