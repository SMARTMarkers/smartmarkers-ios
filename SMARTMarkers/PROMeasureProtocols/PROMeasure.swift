//
//  PROMeasure.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 6/27/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


public protocol InstrumentResolver: class {
    
    func resolveInstrument(from pro: PROMeasure) -> Instrument?
    
    func resolveInstrument(in controller: PDController) -> Instrument?
    
}


public final class PDController: NSObject {
    
    public var request: Request?
    
    public var instrument: Instrument? {
        didSet {
            if instrument != nil {
                reports = Reports(instrument!, for: nil, request: request)
            }
        }
    }
    
    public internal(set) final var reports: Reports?
    
    public weak var instrumentResolver: InstrumentResolver?
    
    public var onSessionCompletion: ((_ reports: SubmissionBundle?, _ error: Error?) -> Void)?
    
    public lazy var schedule: Schedule? = {
        return request?.rq_schedule
    }()
    
    convenience public init(_ _instrument: Instrument) {
        
        self.init()
        self.instrument = _instrument
    }
    
    convenience public init(_ _request: Request) {
        
        self.init()
        self.request = _request
    }
    
    public func prepareSession(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        guard let instrument = self.instrument else {
            callback(nil, SMError.promeasureOrderedInstrumentMissing)
            return
        }
        
        instrument.sm_taskController { (taskViewController, error) in
            taskViewController?.delegate = self
            callback(taskViewController, error)
        }
    }
    
    public func instrument(callback: @escaping ((_ instrument: Instrument?, _ error: Error?) -> Void)) {
        
        if let instr = self.instrument {
            callback(instr, nil)
            return
        }
        
        if let resolver = instrumentResolver, let instr = resolver.resolveInstrument(in: self) {
            callback(instr, nil)
            return
        }

        request?.rq_instrumentResolve(callback: callback)
    }
    
    public func updateRequest(_ _results: [ReportType]?, callback: @escaping ((_ success: Bool) -> Void)) {
        
        guard request != nil, let res = _results else {
            return
        }
        
        if let completed = schedule?.update(with: res.map{ $0.rp_date }) {
            request?.rq_updated(completed, callback:callback)
        }
    }
    
    // MARK: Fetch Requests
    
    public class func Get<T: DomainResource & Request>(requestType: T.Type, for patient: Patient, server: Server, instrumentResolver: InstrumentResolver?, options: [String: String]? = nil, callback: @escaping ([PDController]?, Error?) -> Void) {
        
        var searchParams =  T.rq_fetchParameters ?? [String:String]()
        searchParams["subject"] = patient.id!.string
        
        if let options = options {
            for (k,v) in options {
                searchParams[k] = v
            }
        }
        
        T.Requests(from: server, options: searchParams) { (requests, error) in
            if let requests = requests {
                let controllers = requests.map({ (request) -> PDController in
                    let controller = PDController(request)
                    controller.instrumentResolver = instrumentResolver
                    return controller
                })
                
                let group = DispatchGroup()
                controllers.forEach({ (controller) in
                    group.enter()
                    controller.instrument(callback: { (resolved, error) in
                        controller.instrument = resolved
                        group.leave()
                    })
                    group.enter()
                    controller.reports(for: patient, server: server, callback: { (_, _) in
                        group.leave()
                    })
                })

                group.notify(queue: .main, execute: {
                    callback(controllers, nil)
                })

            }
            else {
                callback(nil, error)
            }
        }
    }
    
    // MARK: Report Collection
    
    public func reports(for patient: Patient, server: Server, callback : ((_ success: Bool, _ error: Error?) -> Void)?) {
        
        guard let reports = reports else {
            callback?(false, SMError.promeasureFetchLinkedResources)
            return
        }
        
        
        reports.fetch(for: patient, server: server, searchParams: nil) { (results, error) in
            callback?(results != nil, error)
        }
    }
    

    

}


extension PDController: ORKTaskViewControllerDelegate {
    
    func dismiss(taskViewController: ORKTaskViewController) {
        
        if let navigationController = taskViewController.navigationController {
            if navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            }
        }
        else {
            taskViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        
        // ***
        // Bug :Premature firing before conclusion step
        // ***
        let stepIdentifier = taskViewController.currentStepViewController!.step!.identifier
        if stepIdentifier.contains("range.of.motion") { return }
        // ***
        
        if reason == .discarded, reason == .failed  {

        }
        
        if reason == .completed {
            
            if let bundle = instrument?.ip_generateResponse(from: taskViewController.result, task: taskViewController.task!) {
                let gr = reports?.addNewReports(bundle, taskId: taskViewController.taskRunUUID.uuidString)
                onSessionCompletion?(gr, nil)
            }
            else {
                onSessionCompletion?(nil, SMError.instrumentResultBundleNotCreated)
            }
        }
        
        dismiss(taskViewController: taskViewController)
        
    }
    
}



public protocol PROMeasureProtocol: NSObject  {
    
    var request: Request? { get set }
    
    var instrument: Instrument? { get set }
    
    var reports: Reports? { get set }
    
    func instrument(callback: @escaping ((_ instrument: Instrument?, _ error: Error?) -> Void))
 
    var server: Server? { get }
    
    var patient: Patient? { get set }
    
    func fetchReports(from server: Server, callback : ((_ success: Bool, _ error: Error?) -> Void)?)
    
    func prepareSession(callback: @escaping ((ORKTaskViewController?, Error?) -> Void))
    
    func create(on server: SMART.Server, for instrument: Instrument, patient: Patient, practitioner: Practitioner, callback: @escaping ((_ request: Request?, _ error: Error?) -> Void))
    
}

public final class PROMeasure : NSObject, PROMeasureProtocol {
    
    
    public weak var instrumentResolver: InstrumentResolver?

    public typealias RequestType = Request
    
    public var patient: Patient?
    
    public var request: RequestType?
    
    public var oauthSettings: [String:Any]? 
    
    public var instrument: Instrument? {
        didSet {
            if let instr = instrument {
                reports = Reports(instr, for: patient, request: request)
            }
        }
    }
    
    public var reports: Reports?
    
    public lazy var schedule: Schedule? = {
        return request?.rq_schedule
    }()
    
    public var teststatus: String = ""
    

    
    public weak var _sessionController: SessionController?
    
    public weak var server: Server?
    
    public static var instrumentLibrary: [Instrument]?
    
    public var onSessionCompletion: ((_ reports: SubmissionBundle?, _ error: Error?) -> Void)?

    
    public var submissionBundle: [SubmissionBundle]? {
        return reports?.submissionBundle
    }
    
    public convenience init(request: Request) {
        self.init()
        self.request = request
    }
    
    open func instrument(callback: @escaping ((_ instrument: Instrument?, _ error: Error?) -> Void)) {
        
        if let instr = self.instrument {
            callback(instr, nil)
            return
        }
        
        if let instrumentResolver = instrumentResolver, let instr = instrumentResolver.resolveInstrument(from: self) {
            callback(instr, nil)
            return
        }
        
        request?.rq_instrumentResolve(callback: callback)
    }
    
    public convenience init(instrument: Instrument) {
        
        self.init()
        self.instrument = instrument
        self.reports = Reports(instrument, for: patient, request: request)
    }
    
    public override init() { }
    
    

    /// Class functions to build `PROMeasure`s
    public class func Fetch<T:DomainResource & Request>(requestType: T.Type, server: Server, options: [String:String]? = nil, instrumentResolver: InstrumentResolver? = nil, callback: @escaping (([PROMeasure]? , Error?) -> Void)) {

        var searchParams =  T.rq_fetchParameters ?? [String:String]()
        
        if let options = options {
            for (k,v) in options {
                searchParams[k] = v
            }
        }
      
        T.Requests(from: server, options: searchParams) { (requests, error) in
            if let requests = requests {
                let proMeasures = requests.map({ (request) -> PROMeasure in
                    let pro = PROMeasure(request: request)
                    pro.instrumentResolver = instrumentResolver
                    return pro
                })
                callback(proMeasures, nil)
            }
            callback(nil, error)
        }
    }
    
    public class func Fetch<T:DomainResource & Instrument>(instrumentType: T.Type, server: Server, options: [String:String]? = nil, callback: @escaping (([PROMeasure]? , Error?) -> Void)) {
        
        T.Instruments(from: server, options: options) { (instruments, error) in
            if let instruments = instruments {
                let proMeasures = instruments.map { PROMeasure(instrument: $0) }
                callback(proMeasures, nil)
            }
            callback(nil, error)
        }
    }
    
    public func fetchReports(from server: Server, callback : ((_ success: Bool, _ error: Error?) -> Void)?) {
        
        guard let reports = reports else {
            callback?(false, SMError.promeasureFetchLinkedResources)
            return
        }
        
        reports.fetch(for: patient, server: server, searchParams: nil) { (results, error) in
            callback?(results != nil, error)
        }
    }
    
    public func prepareSession(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        guard let instrument = self.instrument else {
            callback(nil, SMError.promeasureOrderedInstrumentMissing)
            return
        }
        
        instrument.ip_taskController(for: self) { (taskViewController, error) in
            taskViewController?.delegate = self
            callback(taskViewController, error)
        }
    }


    public func updateRequest(_ _results: [ReportType]?, callback: @escaping ((_ success: Bool) -> Void)) {
        
        guard request != nil, let res = _results else {
            return
        }
        
        if let completed = schedule?.update(with: res.map{ $0.rp_date }) {
            request?.rq_updated(completed, callback:callback)
        }
    }
    
    
    public func create(on server: Server, for instrument: Instrument, patient: Patient, practitioner: Practitioner, callback: @escaping ((Request?, Error?) -> Void)) {
        
        
        
        
    }
    
    
    
    
   
    
}




extension PROMeasure : ORKTaskViewControllerDelegate {
    
    public func dismiss(_ taskViewController: ORKTaskViewController) {
        
        taskViewController.navigationController?.popViewController(animated: true)
    }
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error serror: Error?) {
        
        // ***
        // Bug :Premature firing before conclusion step
        // ***
        let stepIdentifier = taskViewController.currentStepViewController!.step!.identifier
        if stepIdentifier.contains("range.of.motion") { return }
        // ***
        
        
//        _sessionController?.delegate?.sessionEnded(taskViewController, taskViewController: <#ORKTaskViewController#>, reason: reason, error: serror)

        
        if reason == .discarded {
            
            taskViewController.navigationController?.popViewController(animated: true)
            return
        }
        
        if reason == .failed {
            
            taskViewController.navigationController?.popViewController(animated: true)
            return
        }
        
        if reason == .completed {
            
            if let bundle = instrument?.ip_generateResponse(from: taskViewController.result, task: taskViewController.task!) {
                
                let gr = reports?.addNewReports(bundle, taskId: taskViewController.taskRunUUID.uuidString)

                onSessionCompletion?(gr, nil)
            }
            else {
                onSessionCompletion?(nil, SMError.instrumentResultBundleNotCreated)
            }
            taskViewController.navigationController?.popViewController(animated: true)
        }
    }
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, recorder: ORKRecorder, didFailWithError error: Error) {
    }
    
    public func taskViewControllerShouldConfirmCancel(_ taskViewController: ORKTaskViewController) -> Bool {
        return true
    }
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, shouldPresent step: ORKStep) -> Bool {
        return true
    }
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, stepViewControllerWillAppear stepViewController: ORKStepViewController) {
        if stepViewController.title == nil {
            stepViewController.title = patient?.humanName ?? "Session #\(taskViewController.task!.identifier)"
        }
    }
    
    
    
}


