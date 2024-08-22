//
//  Processor.swift
//  SMARTMarkers
//
//  Created by raheel on 4/16/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

public struct DeIdentifiedResource {
    
    let resource: DomainResource
}

/**
 Protocol to process newly generated FHIR resources before storage or submission to a FHIR server
 */
public protocol PreProcessorProtocol {
    
    /// consent policy to abide by
    var consent: SignedConsent? { get }
    
    /// Prepare enrollment
    func prepareEnrollment(participant: any Participant)
   
    /// Prepare Any Resource
    func prepareForPersistance(resource: DomainResource, for participant: (any Participant)?)
    
    /// Prepares a bundle for storage
    func prepareForPersistance(result: StudyTaskResult, for participant: (any Participant)?)
    
    /// Should the participant and its conents be deIdentified
    func mustDeIdentifyParticipant() -> Bool
    
}

public extension PreProcessorProtocol {
    
    func prepareForPersistance(task: StudyTask, participant: (any Participant)?) {
        if let rb = task.result {
            prepareForPersistance(result: rb, for: participant)
        }
    }
}


private let kDevice_associated_identifier = "ppm.device_synthetic_identifier"

open class PreProcessor: PreProcessorProtocol {
    
    public let device_associated_identifier: String

    public var consent: SignedConsent?
    
    public init() {
        
        if let deviceId = Self.getFromKeychain(kDevice_associated_identifier) {
            self.device_associated_identifier = deviceId
        }
        else {
            self.device_associated_identifier = UUID().uuidString
            Self.saveToKeychain(key: kDevice_associated_identifier, data: self.device_associated_identifier)
        }
    }
    
    open func prepareEnrollment(participant: any Participant) {
        
        
        var pt_identifers = participant.fhirPatient.identifier ?? [Identifier]()
        let deviceIden = SMART.Identifier()
        deviceIden.system = FHIRURL("http://dbmi.hms.harvard.edu/fhir/device-synthetic-identifier")
        deviceIden.value = device_associated_identifier.fhir_string
        pt_identifers.append(deviceIden)
        participant.fhirPatient.identifier = pt_identifers
        smLog("[Enrollment]: found device_synthetic_identifer=\(device_associated_identifier)")
        
    }
    
    open func prepareForPersistance(resource: DomainResource, for participant: (any Participant)?) {
        
        guard let participant else {
           return
        }
            if let resource = resource as? Report {
                if false == resource.sm_assign(patient: participant.fhirPatient) {
                    print("Could not assign participant to the resource")
                }
                // Nollify the resource.id; else submission will be rejected by the FHIR Server
                // This is necessary for "Exchange" FHIR Resources
                resource.id = nil
                
                if let resource = resource as? Observation {
                    smLog(resource.subject?.reference)
                }
            }
            else {
                print("FHIR Resource could not be casted as a SMARTMarkers.Report")
                smLog(try? resource.asJSON())
                #if DEBUG
                fatalError()
                #endif
            }
    }

    
    open func prepareForPersistance(result: StudyTaskResult, for participant: (any Participant)?) {
        
        for resource in result.fhir ?? [] + (result.taskMetricsFHIR) {
            prepareForPersistance(resource: resource, for: participant)
        }
        
    }
    
    open func mustDeIdentifyParticipant() -> Bool {
        false
    }
    // Mark: -- keychain
    static func saveToKeychain(key: String, data: String) {
        
        // Set username and password
        let password = data.data(using: .utf8)!
        // Set attributes
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: password,
        ]
        // Add user
        if SecItemAdd(attributes as CFDictionary, nil) == noErr {
            smLog("User saved successfully in the keychain")
        } else {
            smLog("Something went wrong trying to save the user in the keychain")
        }
    }
    
    static func getFromKeychain(_ key: String) -> String? {
        // Set query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
        ]
        var item: CFTypeRef?
        // Check if user exists in the keychain
        if SecItemCopyMatching(query as CFDictionary, &item) == noErr {
            // Extract result
            if let existingItem = item as? [String: Any],
               let username = existingItem[kSecAttrAccount as String] as? String,
               let passwordData = existingItem[kSecValueData as String] as? Data,
               let password = String(data: passwordData, encoding: .utf8)
            {
                smLog(username)
                smLog(password)
                return password
            }
        } else {
            smLog("Something went wrong trying to find the user in the keychain")
            return nil
        }
        return nil
    }
    
}
