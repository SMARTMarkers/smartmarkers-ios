//
//  Persistor.swift
//  SMARTMarkers
//
//  Created by raheel on 3/29/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import Security





public enum PersistancePolicy {
    case replace
    case queue
}


public protocol PersistorProtocol  {
    
    var preProcessor: (any PreProcessorProtocol)? { get set }
    
    var server: Server? { get set }
    
    var submissions: SubmissionsQueueProtocol? { get set }
    
    func persist(data ofTask: StudyTask, for participant: (any Participant)?) throws
    
    func persist(participant: any Participant) throws
    
    func load<T: Participant>(participant participantType: T.Type, study: Study) -> T?
    
    func load(data forTask: StudyTask) throws
    
    func purge(data ofTask: StudyTask) throws
    
    func purgeAndReset() throws
    
    func resumeSubmissionOperationsIfNeeded(for task: StudyTask) -> Bool
    
}





public class Persistor: PersistorProtocol {
    
    
    public func resumeSubmissionOperationsIfNeeded(for task: StudyTask) -> Bool {
        
        guard let data = task.result?.result else {
            return false
        }
        
        for report in data {
            if report.status == .readyToSubmit {
                dispatchSubmissionOperation(task: task)
                return true
            }
        }
        return false
    }
    
    
    let protected = [FileAttributeKey.protectionKey: FileProtectionType.complete]
    public var server: SMART.Server?
    public var preProcessor: (any PreProcessorProtocol)?
    public var submissions: (any SubmissionsQueueProtocol)?
    let studyDirectory: URL
    
    
    public init(_ studyDirectory: URL, 
                server: SMART.Server? = nil,
                preProcessor: (any PreProcessorProtocol)? = nil,
                submissions: (any SubmissionsQueueProtocol)? = nil) throws {
        
        self.server = server
        
        self.submissions = submissions
        self.preProcessor = preProcessor
        self.studyDirectory = studyDirectory
        
        try createDirectories(at: studyDirectory)
        
    }
    
    func createDirectories(at dir: URL) throws {
        
        let fm = FileManager()
        var isDir: ObjCBool = false
        let protected = [FileAttributeKey.protectionKey: FileProtectionType.complete]
        
        smLog(studyDirectory.path)
        
        if !fm.fileExists(atPath: dir.path, isDirectory: &isDir) || !isDir.boolValue {
            smLog("[PERSISTOR]: CANNOT FIND DIRECTORY; creating new: \(dir.path)")
            try fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: protected)
        }
        
        // Todo:
        // Tasks
        // create directors for tasks
        
        
        /*
         for ftype in DataType.allCases {
         let directoryPath = dir.appendingPathComponent(ftype.rawValue)
         if !fm.fileExists(atPath: directoryPath.path, isDirectory: &isDir) || !isDir.boolValue {
         dLog("[PERSISTOR]: creating directory at path \(directoryPath.absoluteString)")
         try fm.createDirectory(at: directoryPath, withIntermediateDirectories: true, attributes: protected)
         }
         } */
    }
    
    func createDirIfNeeded(dirName: String) throws -> URL  {
        
        let dirURL = studyDirectory.appendingPathComponent(dirName)
        var isDir: ObjCBool = false
        if !FileManager().fileExists(atPath: dirURL.path, isDirectory: &isDir) || !isDir.boolValue {
            try FileManager().createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: protected)
        }
        return dirURL
    }
    
    
    
    public func persist(data ofTask: StudyTask, for participant: (any Participant)?) throws {
        
        guard let gb = ofTask.result else {
            // Nothing to persist
            return
        }
        
        // Preprocessing resources //
        preProcessor?.prepareForPersistance(result: gb, for: participant)
        
      
        // TODO: check here if gb is empty.
        // if empty? then, maybe forget about upload?
        // Save locally - on device
        try saveOnDevice(ofTask)
        
        // launch a submit-to-server operation
        dispatchSubmissionOperation(task: ofTask)
    }
    
    func dispatchSubmissionOperation(task: StudyTask) {
        // Ready for submission
        guard let submissions, let _ = task.result?.fhir else {
            return
        }
        
        smLog("[Persistor]: Dispatch for submission: \(task.id) ")
        weak var tsk = task
        submissions.addToQueue(
            data: task,
            withPolicy: .replace) { [weak self] success, err, data in
                if let t = tsk {
                    smLog("[Persistor]: operationOfTask=\(t.id) submission=\(success), saving to device ")
                    try? self?.saveOnDevice(t)
                }
                // TODO: Need a way to report failure back to manager to restard submission later..
            }
    }
    
    public func load<T>(participant participantType: T.Type, study: Study) -> T? where T : Participant {
        
        do {
            
            let ptURL = try createDirIfNeeded(dirName: "patient")
                .fileURLsInDir().first
            
            let cURL = try createDirIfNeeded(dirName: "consent_document")
                .appendingPathComponent("Consent.json")
            
            let partURL = try createDirIfNeeded(dirName: "participant")
                .appendingPathComponent("ResearchSubject.json")
            
            
            if let ptURL, let pt = readResource(file: ptURL, type: Patient.self),
               let consent = readResource(file: cURL, type: Consent.self),
               let sub = readResource(file: partURL, type: ResearchSubject.self) {
                
                return T.init(patient: pt, for: study, consent: consent, subject: sub)
            }
            return nil
        }
        catch {
            smLog(String(describing: error))
            #if DEBUG
//            fatalError()
            #endif
            return nil
        }
    }
    
    public func persist(participant: any Participant) throws {
        
        let ptDir = try createDirIfNeeded(dirName: "patient")
        let consentDir = try createDirIfNeeded(dirName: "consent_document")
        let partDir = try createDirIfNeeded(dirName: "participant")
        
        guard let _ = participant.identifier,
              let _ = participant.fhirResourceId else {
            throw SMError.undefined(description: "[Persistor]: Patient has no fhirResource or SynthIdentifier")
        }
        
        guard let consent = participant.smConsent else {
            throw SMError.undefined(description: "[Persistor]: Cannot find Consent for the Participant, should Include Consent")
        }
        
        
        let pFileURL = ptDir.appendingPathComponent("patient.json")
        let cFileURL = consentDir.appendingPathComponent("Consent.json")
        let rFIleURL = partDir.appendingPathComponent("ResearchSubject.json")
        
        try write(json: try participant.fhirPatient.asJSON(), to: pFileURL)
        try write(json: try consent.consentResource.asJSON(), to: cFileURL)
        try write(json: try participant.fhirResearchSubject.asJSON(), to: rFIleURL)
        
    }
    
    
    
    
    
    public func purge(data ofTask: StudyTask) throws {
        
    }
    
    open func purgeAndReset() throws {
        try removeContentsInDirectory(url: studyDirectory)
        try FileManager.default.removeItem(at: studyDirectory)
        try createDirectories(at: studyDirectory)
    }
    
    private func removeContentsInDirectory(url: URL) throws {
        
        smLog("[PERSISTOR]: removing directory at \(url.absoluteString)")
        let fileManager = FileManager.default
        var fileURLs: [URL]
        if #available(iOS 13.0, *) {
            fileURLs = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [], options: [.skipsHiddenFiles,.includesDirectoriesPostOrder])
        } else {
            fileURLs = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [])
        }
        for fileURL in fileURLs {
            try? fileManager.removeItem(at: fileURL)
        }
    }
    
    
    // Mark: Serialize / Populate  -------------------------
    public func saveOnDevice(_ task: StudyTask) throws {
        
        var errs: [any Error]? = [any Error]()
        guard let serialized = try task.serialize(errors: &errs) else {
            return
        }
        
        let id = task.id
        let filename = "\(id)_serialized.json"
        let saveURL = try createDirIfNeeded(dirName: id)
            .appendingPathComponent(filename)
        smLog("SaveOnDevice: \(saveURL.absoluteString)")
        try write(json: serialized, to: saveURL)
        
        #if DEBUG
        for fhir in task.result?.fhir ?? [] {
            let js = try fhir.asJSON()
            let surl = try createDirIfNeeded(dirName: id).appendingPathComponent("\(fhir.sm_resourceType()).json")
            try write(json: js, to: surl)
        }
        #endif
    }
    
    public func load(data forTask: StudyTask) throws {
        let id = forTask.id
        let filename = "\(id)_serialized.json"
        let saveURL = try createDirIfNeeded(dirName: id)
            .appendingPathComponent(filename)
        if let json = readJson(file: saveURL) {
            try forTask.populate(from: json)
        }
        smLog(saveURL.absoluteString)
    }
    
}


public protocol DataPersistor {
    
    func persist(participant: any Participant) throws
}



extension Persistor {
    
    func write(json: [String: Any], to url: URL) throws {
        let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        var url_ = url
        try data.write(to: url_, options: [.atomic, .completeFileProtection])
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url_.setResourceValues(resourceValues)
    }
    
    func readJson(file atURL: URL) -> [String: Any]? {
        
        if let data = try? Data(contentsOf: atURL),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] {
            return json
        }
        return nil
    }
    
    func readResource<T: DomainResource>(file atURL: URL, type: T.Type) -> T? {
        
        if let data = readJson(file: atURL) {
            var context = FHIRInstantiationContext.init(strict: false)
            return FHIRAbstractResource.instantiate(from: data, owner: nil, context: &context) as? T
        }
        return nil
    }
    
    private func readFHIRResources<T: DomainResource>(of type: T.Type, at dir: URL) throws -> [T]? {
    
        let fileURLs = try dir.fileURLsInDir()
        
        let resources = try fileURLs.map { (fileURL) -> T in
            let data = try Data(contentsOf: fileURL)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            var context = FHIRInstantiationContext.init(strict: false)
                return FHIRAbstractResource.instantiate(from: json, owner: nil, context: &context) as! T
        }
        
        return resources.count > 0 ? resources : nil
    }
}

extension URL {
    
    func fileURLsInDir() throws -> [URL] {
        
        if !isFileURL {
            throw SMError.undefined(description: "URL is not fileURL")
        }
        
        if !hasDirectoryPath {
            throw SMError.undefined(description: "URL is not Directory")
        }
        
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: self,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )
        
        return fileURLs
    }
}
