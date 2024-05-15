//
//  SubmissionsQueue.swift
//  SMARTMarkers
//
//  Created by raheel on 4/4/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

public enum SubmissionQueueStatus {
    case submitting
    case idle
}

public typealias SubmissionOperationCompletionBlock = ((_ success: Bool, _ error: Error?, _ data: Any?) -> Void)

public protocol SubmissionsQueueProtocol {
    
    init(server: Server)
    var delegate: SubmissionsDelegate? { get set }
    func status() -> SubmissionQueueStatus
    func isIdle() -> Bool
    func cancelAndReset()
    func addToQueue(data ofTask: StudyTask, withPolicy: PersistancePolicy, completion: SubmissionOperationCompletionBlock?)
    func addToQueue(name: String, resources: [DomainResource], completion: SubmissionOperationCompletionBlock?)
}

public protocol SubmissionsDelegate {
    func SubmissionFinished(with success: Bool, for task: StudyTask, error: Error?)
}


public class SubmissionsManager: SubmissionsQueueProtocol {
    
    public func addToQueue(name: String, resources: [SMART.DomainResource], completion: SubmissionOperationCompletionBlock?) {
        _status = .submitting
        
        let dataOp = ResourceOperation(name, resources, server: server, onOperationCompletion: completion)
        weak var weakOp = dataOp
        
        dataOp.completionBlock = { [weak self] in
            smLog("==========================> completionBlock == \(String(describing: name))")
            self?._status = .idle
            if let strong = weakOp {
                let success =
                strong.isFinished == true && strong.isCancelled == false && strong.error == nil
                if !success {
                    self?.queue.cancelAllOperations()
                }
                strong.onOperationCompletion?(
                    success,
                    strong.error,
                    resources
                )
            }
        }
        queue.addOperation(dataOp)
    }
    
    
    public static let DataSubmissionStatusChanged = "dataSubmissionStatusChanged"
    public unowned let server: SMART.Server
    private let queue: OperationQueue = OperationQueue()
    public var delegate: SubmissionsDelegate?
    public internal(set) var _status: SubmissionQueueStatus = .idle {
        didSet {
            callOnMainThread {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Self.DataSubmissionStatusChanged), object: status)
            }
        }
    }
   
    public func isIdle() -> Bool {
        queue.isSuspended
    }
    public func status() -> SubmissionQueueStatus {
        _status
    }
    
    required public init(server: Server) {
        self.server = server
        self.queue.maxConcurrentOperationCount = 1
        self.queue.qualityOfService = .background
        

    }
    
    public func addToQueue(
        data ofTask: StudyTask,
        withPolicy: PersistancePolicy,
        completion: SubmissionOperationCompletionBlock?) {
            
            _status = .submitting
            
            let dataOp = DataSubmissionOperation(ofTask, server: server, onOperationCompletion: completion)

            weak var weakOp = dataOp
            dataOp.completionBlock = { [weak self] in
                smLog("==========================> completionBlock == \(String(describing: weakOp?.task?.id))")
                self?._status = .idle
                self?.ended(weakOp!)
            }
 
            
            
            
            
            queue.addOperations([dataOp], waitUntilFinished: false)
        
            
        }
    
    
    public func cancelAndReset() {
        queue.cancelAllOperations()
    }
    
    
    func ended(_ op: DataSubmissionOperation) {
        
        let success =
        op.isFinished == true && op.isCancelled == false && op.error == nil
        
        // There was a problem, cancel all operations and restart?
        if !success {
            queue.cancelAllOperations()
        }
        
        //
        op.onOperationCompletion?(
            success,
            op.error,
            op.task?.result
        )
       
        // inform delegate
        if op.task != nil {
            if status() == .idle {
                delegate?.SubmissionFinished(with: success, for: op.task!, error: op.error)
            }
        }
        
        smLog(" >>> [SO]: task=\(op.task?.id ?? "nil")   Ended with Succes=\(success)")

    }
    
    
}


class DataSubmissionOperation: Operation {
    
    weak var task: StudyTask?
    weak var server: Server?
    var error: Error?
    var onOperationCompletion: SubmissionOperationCompletionBlock?

    init(_ task: StudyTask, server: Server, onOperationCompletion: SubmissionOperationCompletionBlock?) {
        self.task = task
        self.server = server
        self.onOperationCompletion = onOperationCompletion
    }
    
    override func main() {
        smLog("==========================> Begun == \(String(describing: task?.id))")

        if isCancelled {
            return
        }
        
        let backgroundTask = setBackgroundTask()
        guard backgroundTask != .invalid else {
            return
        }
        
        let sem = DispatchSemaphore(value: 0)
        submit { error in
            if let error {
                smLog(" >>> [SO] main() submit error: \(error.description)")
                self.error = error
            }
            sem.signal()
        }
        sem.wait()
        smLog(" >>> [SO] OP.completed")
        UIApplication.shared.endBackgroundTask(backgroundTask)
    }
    func submit(callback: @escaping FHIRErrorCallback) {
        
        guard let srv = server, let gd = task?.result?.fhir,let metrics = task?.result?.taskMetricsFHIR else {
            return
        }
        let count = gd.count
        
        var serr: FHIRError? = nil
        srv.ready { srvErr in
            if let srvErr {
                serr = srvErr
                callback(serr)
                return
            }
            else {
                DispatchQueue.global(qos: .background).async { [weak self] in
                    
                    let sem = DispatchSemaphore(value: 0)
                    for (i, resource) in (gd + metrics).enumerated() {
                        if self?.isCancelled == true {
                            callback(nil); return;
                        }
 
                        resource.createAndReturn(srv) { [weak self] postErr in
                            switch postErr {
                            case nil:
                                break
                            case .resourceAlreadyHasId:
                                break
                            case .requestError(let status, _):
                                self?.error = postErr
                                if status == 401 { self?.cancel() }
                                break
                            default:
                                self?.error = postErr
                            }
                            #if DEBUG
                            resource.Print(i+1, count, self?.task?.id, error: postErr)
                            #endif
                            sem.signal()
                        }
                        sem.wait()
                        #if DEBUG
                          sleep(0)
                        #endif
                    }
                    smLog(" >>> [SO] submit.end")
                    callback(serr)
                }
            }
        }
    }
    
    func setBackgroundTask() -> UIBackgroundTaskIdentifier{
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid
        backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: { [weak self] in
            
            TaskNotification.shared.dispatchNotificationForIncompleteSubmission()
            self?.cancel()
            smLog("[SubmissionOperation]: out of time, cleaning up iscancelled=\(String(describing: self?.isCancelled)) isfin=\(String(describing: self?.isFinished))")
            UIApplication.shared.endBackgroundTask(backgroundTask)
        })
        
        return backgroundTask
    }
    
    
    
    
    
}

extension DomainResource {
    func Print(_ i: Int, _ c: Int, _ tid: String?, error: Error?) {
        let has_id = self.id != nil
        let res = has_id ? "PASS" : "FAIL"
        let errmsg = error != nil ? String(describing: error!) : ""
        smLog(" >>> [SO] -\(tid ?? "-no-id-")-\(i)/\(c)]: \(res): \(sm_resourceType()) | \(id?.string ?? "") | \(errmsg)")
        
    }
}


class ResourceOperation: Operation {
    
    let id: String
    let resources: [DomainResource]
    weak var server: Server?
    var error: Error?
    var onOperationCompletion: SubmissionOperationCompletionBlock?

    init(_ id: String, _ resources:[DomainResource], server: Server, onOperationCompletion: SubmissionOperationCompletionBlock?) {
        self.resources = resources
        self.id = id
        self.server = server
        self.onOperationCompletion = onOperationCompletion
    }
    
    override func main() {
        smLog("==========================> Begun == \(String(describing: id))")

        if isCancelled {
            return
        }
        
        let backgroundTask = setBackgroundTask()
        guard backgroundTask != .invalid else {
            return
        }
        
        let sem = DispatchSemaphore(value: 0)
        submit { error in
            if let error {
                smLog(" >>> [SO] main() submit error: \(error.description)")
                self.error = error
            }
            sem.signal()
        }
        sem.wait()
        smLog(" >>> [SO] OP.completed")
        UIApplication.shared.endBackgroundTask(backgroundTask)
    }
    func submit(callback: @escaping FHIRErrorCallback) {
        
        guard let srv = server else {
            callback(nil)
            return
        }
        let count = resources.count
        
        var serr: FHIRError? = nil
        srv.ready { srvErr in
            if let srvErr {
                serr = srvErr
                callback(serr)
                return
            }
            else {
                DispatchQueue.global(qos: .background).async { [weak self] in
                    
                    let sem = DispatchSemaphore(value: 0)
                    for (i, resource) in (self?.resources ?? []).enumerated() {
                        if self?.isCancelled == true {
                            callback(nil); return;
                        }
                        resource.createAndReturn(srv) { [weak self] postErr in
                            switch postErr {
                            case nil:
                                break
                            case .resourceAlreadyHasId:
                                break
                            case .requestError(let status, _):
                                self?.error = postErr
                                if status == 401 { self?.cancel() }
                                break
                            default:
                                self?.error = postErr
                            }
                            #if DEBUG
                            resource.Print(i+1, count, self?.id, error: postErr)
                            #endif
                            sem.signal()
                        }
                        sem.wait()
                        #if DEBUG
                          sleep(0)
                        #endif
                    }
                    smLog(" >>> [SO] submit.end")
                    callback(serr)
                }
            }
        }
    }
    
    func setBackgroundTask() -> UIBackgroundTaskIdentifier{
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid
        backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: { [weak self] in
            
            TaskNotification.shared.dispatchNotificationForIncompleteSubmission()
            self?.cancel()
            smLog("[SubmissionOperation]: out of time, cleaning up iscancelled=\(String(describing: self?.isCancelled)) isfin=\(String(describing: self?.isFinished))")
            UIApplication.shared.endBackgroundTask(backgroundTask)
        })
        
        return backgroundTask
    }
    
    
    
    
    
}
