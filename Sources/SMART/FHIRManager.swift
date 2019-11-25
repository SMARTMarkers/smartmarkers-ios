//
//  FHIRManager.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 20/02/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import UserNotifications

/**
 Helper class to manage open or protected (SMART) FHIR servers
 */
public class FHIRManager {

    public enum UserContext {
        case Practitioner
        case Patient
        case NA
    }
    
    
    /// FHIR `Client`
    public var main: SMART.Client
    
    /// FHIR `Server`; derived from `Client`
    public var mainServer: SMART.Server {
        return main.server
    }
    
    /// weak refernce to `OAuth2` to handle callbacks; Some `Instruments` might use this
    public weak var oauthCallbacker: OAuth2?
    
    /// Context based on loggin in user; `NA` for unknown user type or open FHIR server
    public internal(set) var context: UserContext = .NA
    
    /// Callback: to calls when a `Patient` or `Practitioner` was set
    public var onProfileSet: (() -> Void)?
    
    /// Callback: to calls when a `Patient` is selected
    public var onPatientSet: (() -> Void)?

    
    /// FHIR `Patient` (either logged in or selected from a list)
    public internal(set) var patient: Patient? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.onPatientSet?()
            }
        }
    }
    
    /// FHIR `Practitioner` resource (set when the logged in profile is practitioner)
    public internal(set) var userProfileSet: DomainResource? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.onProfileSet?()
            }
        }
    }
    
    /// AssessementCenter.net API Credentials; Needed for PROMIS (computer adaptive tests)
    public var promis: PROMISClient?
    
    /**
    Designated Initializer
    */
    public init(main client: SMART.Client, promis: PROMISClient? = nil) {
        self.main = client
        self.promis = promis
    }
    
    
    /// Convinience authorizer
    public func authorize(callback: @escaping (_ success: Bool, _ name: String?, _ error: Error?) -> Void) {
        
        main.forgetClientRegistration()
        main.reset()
        main.authorize(callback: { [unowned self] (patientResource,  error) in
            
            if let p = patientResource {
                self.patient = p
            }
            
            if let idToken = self.mainServer.idToken, let decoded = self.base64UrlDecode(idToken) {
                
                guard let profile = decoded["profile"] as? String ?? decoded["fhirUser"] as? String else {
                    callback(self.patient != nil, nil, nil)
                    return
                }
                
                let components = profile.components(separatedBy: "/")
                let resourceType = components[0]
                let resourceId   = components[1]
                if resourceType == "Practitioner" {
                    Practitioner.read(resourceId, server: self.mainServer, callback: { (resource, ferror) in
                        if let practitioner = resource as? Practitioner {
                            self.userProfileSet = practitioner
                            self.context = .Practitioner
                            callback(true, practitioner.name?.first?.human, nil)
                        }
                    })
                }
                else if resourceType == "Patient" {
                    Patient.read(resourceId, server: self.mainServer, callback: { (resource, ferror) in
                        if let userPatient = resource as? Patient {
                            //User Resource
                            //TODO: Support multiple user modes. (eg. guardian)
                            //self.patient = patient
                            self.userProfileSet = userPatient
                            self.context = .Patient
                            if self.patient == nil || self.patient!.id != userPatient.id {
                                self.patient = userPatient
                            }
                            callback(self.patient != nil, userPatient.name?.first?.human, nil)
                        }
                    })
                }
                else {
                    self.context = .NA
                    callback(self.patient != nil, nil, SMError.proserverUserNotPractitionerOrPatient(profileType: resourceType))
                }
            }
            else {
                callback(error == nil, nil, error)
            }
        })
    }
    
    
    @discardableResult
    public func showPatientSelector(context: UIViewController? = nil) -> Bool {
        
        guard let root = context ?? UIApplication.shared.keyWindow?.rootViewController else {
                return false
        }
        
        let search = FHIRSearch(query: [])
        let query = PatientListQuery(search: search)
        let patientList = PatientList(query: query)
        let picker = PatientListViewController(list: patientList, server: mainServer)
        picker.onPatientSelect = { (patient) in
            self.patient = patient
        }
        let navigationController = UINavigationController(rootViewController: picker)
        navigationController.modalPresentationStyle = .pageSheet
        root.present(navigationController, animated: true, completion: nil)
        return true
    }
    
}


extension FHIRManager {
    
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
        
        if let json = try? JSONSerialization.jsonObject(with: data!, options: []),
            let payload = json as? [String: Any]  {
            return payload
        }
        return nil
    }
}
