//
//  SMARTManager.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 20/02/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import UserNotifications


public enum UserContextMode  {
    case Practitioner
    case Patient
    case Unknown
}

public class SMARTManager : NSObject {
    
    public weak var callbackHandler: OAuth2?
    
    public var client: SMART.Client
    
    public static let shared = SMARTManager()
    
    public internal(set) var usageMode : UserContextMode = .Unknown
    
    public internal(set) var practitioner: Practitioner? = nil {
        didSet {
            DispatchQueue.main.async {
                self.onPractitionerSelected?()
            }
        }
    }
    
    
    public  internal(set) var patient : Patient? = nil {
        didSet {
			onPatientSelected?()
        }
    }
    
    
    
    public class func client(with baseURL: URL, settings: [String:String]) -> Client {
        let client = Client(baseURL: baseURL, settings: settings)
        client.authProperties.embedded = true
        client.authProperties.granularity = .launchContext
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
        print(e)
	}
    
    
    public func showLoginController(over viewController: UIViewController) {
        
        let loginViewController = SMARTLoginViewController()
        viewController.present(loginViewController, animated: true, completion: nil)
        
    }
    
    public func loginController() -> SMARTLoginViewController {
        return SMARTLoginViewController()
    }
    
    // TODO:
    // Verify IdToken
    
    public func authorize(callback: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        
        client.authorize(callback: { [unowned self] (patientResource,  error) in
            
            if let p = patientResource {
                self.patient = p
            }
            
            if let idToken = self.client.server.idToken, let decoded = self.base64UrlDecode(idToken) {
                
                guard let profile = decoded["profile"] as? String ?? decoded["fhirUser"] as? String else {
                    callback(self.patient != nil, nil)
                    return
                }

                print(decoded)
                
                let components = profile.components(separatedBy: "/")
                let resourceType = components[0]
                let resourceId   = components[1]
                if resourceType == "Practitioner" {
                    Practitioner.read(resourceId, server: self.client.server, callback: { (resource, ferror) in
                        if let practitioner = resource as? Practitioner {
                            self.practitioner = practitioner
                            self.usageMode = .Practitioner
                            callback(true, nil)
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
                            callback(self.patient != nil, nil)
                        }
                    })
                }
                else {
                    callback(self.patient != nil, SMError.proserverUserNotPractitionerOrPatient(profileType: resourceType))
                }
            }
            else {

                callback(error == nil, error)
            }
        })
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
    
    
    public func selectPatient(callback: @escaping ((_ patientPicker: UIViewController) -> Void)) {
        
		let patientPickerViewController = EPPatientListViewController(server: client.server)
        patientPickerViewController.onPatientSelect = { [unowned self] (patient) in
            self.patient = patient
        }
        let navigationController = UINavigationController(rootViewController: patientPickerViewController)
        callback(navigationController)
    }
}

extension SMARTManager  {
    
    public func didReceiveLocalNotification(notification: UNNotificationResponse) {
        
    }
}

