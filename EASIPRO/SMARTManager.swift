//
//  SMARTManager.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 20/02/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


public enum UsageMode  {
    case Practitioner
    case Patient
}

public class SMARTManager : NSObject {
    
    
    public var client: SMART.Client
    
    public static let shared = SMARTManager()
    
    public internal(set) var usageMode : UsageMode?
    
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
			onPatientSelected?()
        }
    }
    
    public var measures: [PROMeasure2]? = nil
    
    
    public class func client(with baseURL: URL, settings: [String:String]) -> Client {
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
	
	public var onLoggedOut : (() -> Void)?
	
	/**
	SMART.Client settings taken from wrapper app's Info.plist;
	TODO: Allow override
	*/
    override private init() {
		
		let infoDict = Bundle.main.infoDictionary!
		let base 		= infoDict["SMART_BASE_URI"] as! String
		let scope		= infoDict["SMART_SCOPE"] as! String
		let clientid	= infoDict["SMART_CLIENT_ID"] as! String
		let clientname 	= infoDict["SMART_CLIENT_NAME"] as! String
		let callback 	= infoDict["SMART_CLIENT_CALLBACK_URI"] as! String
		let httpschema 	= infoDict["SMART_BASE_HTTP_SCHEMA"] as! String
		let baseURL = URL(string: "\(httpschema)://\(base)")!
		let settings = [ "client_name" : clientname,
						 "redirect"    : "\(callback)://callback",
						 "scope"       : scope,
						 "client_id"   : clientid,
						 ]
		client = SMARTManager.client(with: baseURL, settings: settings)
    }
    
    public func resetClient() {
        client.reset()
    }
    
    public var shouldSelectPatient : Bool {
        get { return patient == nil }
    }
	
	func clientNotReady(_ e:Error ) {
		print("Not ready")
	}
    
    
    public func showLoginController(over viewController: UIViewController) {
        
        let loginViewController = EHRLoginController()
		
        viewController.present(loginViewController, animated: true, completion: nil)
        
    }
    
    public func loginController() -> EHRLoginController {
        return EHRLoginController()
    }
    
    public func authorize(callback: @escaping (_ success: Bool) -> Void) {
        
        client.authorize(callback: { [unowned self] (patientResource,  error) in
            
            
            if let p = patientResource {
                self.patient = p
            }
            if  let idToken = self.client.server.idToken,
                let decoded = self.base64UrlDecode(idToken),
                let userProfile = decoded["profile"] as? String {
                let components = userProfile.components(separatedBy: "/")
                let resourceType = components[0]
                let resourceId   = components[1]
                if resourceType == "Practitioner" {
                    Practitioner.read(resourceId, server: self.client.server, callback: { (resource, ferror) in
                        if let practitioner = resource as? Practitioner {
                            self.practitioner = practitioner
                            self.usageMode = .Practitioner
                            callback(true)
                        }
                    })
                }
                else if resourceType == "Patient" {
                    Patient.read(resourceId, server: self.client.server, callback: { (resource, ferror) in
                        if let patient = resource as? Patient {
                            //User Resource
                            //TODO: Support multiple user modes. (eg. guardian)
                            //self.patient = patient
                            if self.patient == nil || self.patient!.id != patient.id {
                                self.patient = patient
                            }
                            self.usageMode = .Patient
                            callback(true)
                        }
                    })
                }
                else {
                    //Error
                    if let e = error {
                        print(e.localizedDescription)
                    }
                    callback(error != nil)
                }
                
            }
        })
    }
    
    // MARK: FHIR Fetch Resource
    
    func fetch<T: DomainResource>(type domainResource: T.Type, resource identifier: String, callback: @escaping (_ resource: T?, _ error: Error?) -> Void) {
        client.ready(callback: { [unowned self] (error) in
            if let error = error {
				self.clientNotReady(error)
                callback(nil, error)
				
            }
            domainResource.read(identifier, server: self.client.server, callback: { (resource, ferror) in
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
	
	public func getQuestionnaireResponses(callback: @escaping(_ questionnaires: [QuestionnaireResponse]?, _ error: Error?) -> Void) {
		search(type: QuestionnaireResponse.self, params: [:], callback: callback)
	}
	
	public func getObservations(callback: @escaping(_ observations: [Observation]?, _ error: Error?) -> Void) {
		guard let patient = patient else {
			print("Select Patient")
			callback(nil, nil)
			return
		}
		search(type: Observation.self, params: ["category":"survey", "patient": patient.id!.string], callback: callback)
	}
    
    public func search<T: DomainResource>(type domainResource: T.Type, params: [String: String], callback : @escaping (_ resources: [T]?, _ serror : Error?) -> Void) {
        client.ready { [unowned self] (rerror) in
            if nil != rerror {
				self.clientNotReady(rerror!)
				callback(nil, rerror)
			}
			let search = domainResource.search(params)
			// TODO: Decide Appropriate Number
			search.pageCount = 100
            search.perform(self.client.server, callback: { (bundle, fhirError) in
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
	
	
	
    
    
    
    
    
}



