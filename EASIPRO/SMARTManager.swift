//
//  SMARTManager.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 20/02/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


public enum UserType : Int {
    case Provider
    case Patient
}

public class SMARTManager : NSObject {
    
    
    public var client: SMART.Client
    public static let shared = SMARTManager()
    public internal(set) var practitioner: Practitioner? = nil {
        didSet {
            DispatchQueue.main.async {
                self.onPractitionerSelected?()
            }
        }
    }

    
    public  internal(set) var patient : Patient? = nil {
        didSet {
            measures = nil
            DispatchQueue.main.async {
                self.onPatientSelected?()
            }
        }
    }
    
    public var measures: [PROMeasure]? = nil
    
    class func smartClient() -> Client {
        
//        let baseURL = URL(string: "https://launch.smarthealthit.org/v/r3/sim/eyJoIjoiMSIsImIiOiIyZTI3YzcxZS0zMGM4LTRjZWItOGMxYy01NjQxZTA2NmMwYTQsZWIzMjcxZTEtYWUxYi00NjQ0LTkzMzItNDFlMzJjODI5NDg2IiwiaSI6IjEiLCJlIjoic21hcnQtUHJhY3RpdGlvbmVyLTcxMDgxMzMyIn0/fhir")!
		
		let baseURL = URL(string: "https://launch.smarthealthit.org/v/r3/sim/eyJoIjoiMSIsImkiOiIxIiwiZSI6InNtYXJ0LVByYWN0aXRpb25lci03MTAzMjcwMiJ9/fhir")!
        //openid profile user/*.* patient/*.* launch/encounter launch/patient
        let settings = [ "client_name" : "EASIPRO",
                         "redirect"    : "easipro2://callback",
                         "scope"       : "openid profile user/*.*",
                         "client_id"   : "7c5dc7c9-74ca-451a-bd3d-eeb21bb66e93",
                         
                         ]
        
        let client = Client(baseURL: baseURL, settings: settings)
        client.authProperties.embedded = true
        client.authProperties.granularity = .tokenOnly
        let logger = OAuth2DebugLogger.init()
        logger.level = .trace
        client.server.logger = logger
        
        return client
    }
    
    public var onPatientSelected : (() -> Void)?
    
    public var onPractitionerSelected : (() -> Void)?

    
    required override public init() {
        client = SMARTManager.smartClient()
        super.init()
    }
    
    public func resetClient() {
        client.reset()
    }
    
    public var shouldSelectPatient : Bool {
        get { return patient == nil }
    }
    
    
    public func showLoginController(over viewController: UIViewController) {
        
        let loginViewController = EHRLoginController()
		
        viewController.present(loginViewController, animated: true, completion: nil)
        
    }
    
    public func loginController() -> EHRLoginController {
        return EHRLoginController()
    }
    
    public func authorize(callback: @escaping (_ success: Bool) -> Void) {
        
        client.authorize(callback: { [unowned self] (patient,  error) in
            
            if let patient = patient {
                self.patient = patient
                if  let idToken = self.client.server.idToken,
                    let decoded = self.base64UrlDecode(idToken),
                    let userProfile = decoded["profile"] as? String {
                    let practitionerId = userProfile.components(separatedBy: "/")[1]
                    Practitioner.read(practitionerId, server: self.client.server, callback: { (practitioner, error) in
                        if let practitioner = practitioner as? Practitioner {
                            self.practitioner = practitioner
                        }
                        callback(true)
                    })
                    
                } else {
                    callback(false)
                }
			} else if let idToken = self.client.server.idToken,
				let decoded = self.base64UrlDecode(idToken),
				let userProfile = decoded["profile"] as? String {
				let practitionerId = userProfile.components(separatedBy: "/")[1]
				Practitioner.read(practitionerId, server: self.client.server, callback: { (practitioner, error) in
					if let practitioner = practitioner as? Practitioner {
						self.practitioner = practitioner
					}
					callback(true)
				})
			}
            else if nil != error {
                
                print(error.debugDescription)
                callback(false)
            }
        })
    }
    
    // MARK: FHIR Fetch Resource
    
    func fetch<T: DomainResource>(type domainResource: T.Type, resourceIdentifier: String, callback: @escaping (_ resource: T?, _ error: Error?) -> Void) {
        client.ready(callback: { [unowned self] (error) in
            if nil != error {
                callback(nil, error)
            }
            domainResource.read(resourceIdentifier, server: self.client.server, callback: { (resource, ferror) in
                callback(resource as? T, ferror)
            })
        })
    }
    
    // MARK: FHIR Search Resources
    
    public func getPatients(callback: @escaping(_ patients: [Patient]?, _ error: Error?) -> Void ){
        search(type: Patient.self, params: [:], callback: callback)
    }
    
    public func getQuestionnaires(callback: @escaping(_ questionnaires: [Questionnaire]?, _ error: Error?) -> Void) {
        search(type: Questionnaire.self, params: [:], callback: callback)
    }
    
    private func search<T: DomainResource>(type domainResource: T.Type, params: [String: String], callback : @escaping (_ resources: [T]?, _ serror : Error?) -> Void) {
        client.ready { [unowned self] (rerror) in
            if nil != rerror { callback(nil, rerror) }
            domainResource.search(params).perform(self.client.server, callback: { (bundle, fhirError) in
                if let bundle = bundle {
                    let resources = bundle.entry?.filter{ $0.resource is T}.map{ $0.resource as! T}
                    if let count = resources?.count, count > 0 {
                        callback(resources, fhirError)
                    }
                    else {
                        callback(nil, fhirError)
                    }
                }
                else {
                    callback(nil, fhirError)
                }
            })
        }
    }
    
    
    private func base64UrlDecode(_ value: String) -> [String: Any]? {
        let comps = value.components(separatedBy: ".")
        var base64 = comps[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 += padding
        }
        let data =  Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
        guard let json = try? JSONSerialization.jsonObject(with: data!, options: []), let payload = json as? [String: Any] else {
            print("error decoding")
            return nil
        }
        return payload
    }
    
    // MARK: Patient/Measures Selectors
    
    public func switchPatient(over viewController: UIViewController) {
        
        let allPatientList = PatientListAll()
        let patientListViewController = PatientListViewController(list: allPatientList, server: client.server)
        patientListViewController.title = "Select Patient"
        patientListViewController.onPatientSelect = { (patient) in
            self.patient = patient
        }
        let navigationController = UINavigationController(rootViewController: patientListViewController)
        viewController.present(navigationController, animated: true, completion: nil)
        
    }
    
    

    public func selectMeasures(callback: @escaping ((_ measuresPicker: UIViewController) -> Void)) {
        let measuresViewController = MeasuresViewController()
        measuresViewController.onSelection = { measures in
            self.measures = measures
        }
        let navigationController = UINavigationController(rootViewController: measuresViewController)
        callback(navigationController)
    }
    
    
    public func selectPatient(callback: @escaping ((_ patientPicker: UIViewController) -> Void)) {
        
		let patientPickerViewController = EPPatientListViewController(server: client.server)
        patientPickerViewController.onPatientSelect = { [unowned self] (patient) in
            self.patient = patient
        }
        let navigationController = UINavigationController(rootViewController: patientPickerViewController)
        callback(navigationController)
    }
    
    /**
     
     - selectPatient
     - selectMeasures
     - beginSession
     - completeSession
     - completeSession:[session], result:[acscore]
     -
 
    */
    
    
    
    
    // MARK: EASIPRO FHIR METHODS
    
    func writeProcedureRequest(for measures: [Any], callback: @escaping (_ pRequest: ProcedureRequest?, _ error: Error?) -> Void) {
        
        let pr = ProcedureRequest()
        pr.status = RequestStatus.active
        pr.intent = RequestIntent.plan
        
        
    }
    
    public func writePR(for measure: PROMeasure, callback: @escaping (_ procedureRequest: ProcedureRequest?, _ error :  Error?) -> Void) {
        
        guard let patient = patient, let practitioner = practitioner else {
            print("login")
            callback(nil, nil)
            return
        }
        
        guard let pr = ProcedureRequest.ep_instant(for: patient, measure: measure, practitioner: practitioner) else {
            callback(nil, nil)
            return
        }
        pr.createAndReturn(client.server, callback: { (ferror) in
            if nil == ferror {
                callback(pr, nil)
            }
            else {
                callback(nil, ferror)
            }
        })
    }
    

    

    public func demo() {
        
        
        
    }
    
    
    
    
    
    
}



