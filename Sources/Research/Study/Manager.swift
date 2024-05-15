//
//  Manager.swift
//  SMARTMarkers
//
//  Created by raheel on 4/1/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit

public let TaskDidConcludeNotification = Notification.Name("TaskDidConclude")
public let TaskDidCompleteResolving = Notification.Name("TaskDidConclude")
public let DidChangeProfileNotification = Notification.Name("ParticipantDidChangeNotification")
public let ParticipantStatusDidChangeNotification = Notification.Name("ParticipantStatusDidChangeNotification")

open class StudyManger {
    
    public let study: Study
    public let writeServer: Server?
    public internal(set) var persistor: (any PersistorProtocol)?
    public internal(set) var participant: (any Participant)?
    public internal(set) var interpreters: [String: any TaskResultInterpreterProtocol.Type]?
    public internal(set) var tasks: [StudyTask]?
    open var taskStatus: TaskStatus?
    public var activityDelegate: ActivityTaskDelegate?
    
    public init(_ study: Study,
                writeServer: Server?,
                persistor: (any  PersistorProtocol)?,
                participantType: (any Participant.Type),
                interpreters: [String: any TaskResultInterpreterProtocol.Type]? = nil) {
        self.study = study
        self.writeServer = writeServer
        self.persistor = persistor
        self.interpreters = interpreters
        
        if let participant = self.persistor?.load(participant: participantType, study: study) {
            assign(participant)
        }
    }
   
 
    open func newEnroll(participant: any Participant) throws {
        assign(participant)
        try persistor?.persist(participant: participant)
    }
    
    open func assign(_ _participant: any Participant) {
        self.persistor?.submissions?.delegate = self
        self.participant = _participant
        self.postProfileDidChange()
    }
    
    
    
    open func initializeTasks(callback: @escaping ((_ error: Error?) -> Void)) {
        
        // 1. get protocol
        // Only One PlanDefintion is accepted
        guard let studyProtocol = study.study_protocol else {
            callback(SMError.undefined(description: "Cannot initalize tasks: Research Study does not have activity definitions"))
            return
        }
        guard let studyActivities = studyProtocol.activities else {
            callback(SMError.undefined(description: "Cannot initalize tasks: Protocol has no activities"))
            return
        }
        
        self.tasks = studyActivities.map({ aD in
            let t = StudyTask(aD, interpreterType: self.interpreters?[aD.resource.id!.string])
            t.delegate = self.activityDelegate
            return t
        })
        
        guard let tasks else {
            callback(SMError.undefined(description: "Cannot initalize tasks: Protocol has no activities"))
            return
        }
        
        self.taskStatus = TaskStatus(tasks: tasks, manager: self)

        let group = DispatchGroup()
        var errors = [Error]()
        for tsk in tasks {
            weak var weakTsk = tsk
            tsk.onTaskCompletion = { [unowned self] sessionResult in
                if let weakTsk {
                    self.taskSessionDidConclude(task: weakTsk, sessionResult: sessionResult)
                }
            }
            group.enter()
            tsk.prepare { error in
                if let e = error {
                    errors.append(e)
                }
                group.leave()
            }
        }
        group.notify(queue: .main) { [self] in
            
            self.tasks?.forEach({
                try? persistor?.load(data: $0)
            })
            self.taskStatus?.update(from: tasks)
            self.updateParticipationStatusIfNeeded()

            smLog("Protocol derived tasks initialization complete, errors=\(errors)")
            if !errors.isEmpty {
                smLog(errors.description)
                fatalError()
            }
            callback(
                (errors.isEmpty) ? nil : SMError.undefined(description: "Issues creating tasks could not be generated")
            )
        }
        
    }
    
    // MARK: TaskDidComplete
    open func taskSessionDidConclude(task: StudyTask, sessionResult: StudyTaskResult) {
        
        guard !sessionResult.discarded else {
            // Submit metrics to server
            if let submissions = persistor?.submissions {
                let obs = sessionResult.taskMetrics.map { $0.inFHIR(participant: self.participant!) }
                submissions.addToQueue(name: "Task-Metrics",
                                      resources: obs,
                                      completion: nil)
            }
            return
        }
        
        
        
        do {
            
            
            // persist data
            try self.persistor?.persist(data: task, for: self.participant)
            
            // update status
            self.taskStatus?.update(from: self.tasks!)
            
            // reset task completion status
            self.participant?.taskDidConclude(task: task)
            
            // update participation status
            self.updateParticipationStatusIfNeeded()
            
            // post notification
            self.postTaskSessionDidConcludeNotification(task.id)
        }
        catch {
            smLog(error)
        }
    }
    
    // MARK: NOTIFICATIONS ---------------------------------
    
    func postTaskSessionDidConcludeNotification(_ taskId: String) {
        NotificationCenter.default.post(
            name: TaskDidConcludeNotification,
            object: taskId
        )
    }
    func postProfileDidChange() {
        NotificationCenter.default.post(
            name: DidChangeProfileNotification,
            object: self
        )
    }
    func postDidResolveTasks() {
        NotificationCenter.default.post(
            name: TaskDidCompleteResolving,
            object: self
        )
    }

    // MARK: Task Sequence methods -------------------------------------
   
    public func dueTaskIndex() -> Int {
        guard let due = taskStatus?.due else { return -1 }
        for (i, t) in (tasks ?? []).enumerated() {
            if due.contains(t.id) {
                return i
            }
        }
        return -1
    }
    
    public func getTaskState(_ forTask: StudyTask) -> TaskStatus.State {
        self.taskStatus!.state(for: forTask)
    }
    
    public func numberOfDueTasks() -> Int {
        self.taskStatus?.numberOfDueTasks() ?? 0
    }
    
    open func updateParticipationStatus() -> ResearchSubjectStatus {
        
        if numberOfDueTasks() == 0 {
            TaskNotification.shared.removeAllNotifications()
            return .offStudy
        }
       
        return .onStudy
    }
    
    private func updateParticipationStatusIfNeeded() {
        
        guard let participant else { return }
       
        let currStatus = participant.status
        let newStatus = updateParticipationStatus()
    
        assignNotifications(for: newStatus)
        
        guard newStatus != currStatus else {
            return
        }
        
        participant.status = newStatus
        try? self.persistor?.persist(participant: participant)
        participant.updateStatusIfNeeded1(to: writeServer) { error in
            if nil == error {
                try? self.persistor?.persist(participant: participant)
            }
        }
        NotificationCenter.default.post(
            name: ParticipantStatusDidChangeNotification,
            object: self
        )
    }
    
    
    // MARK: FlagContact
    open func createFlagForContact(preference: Bool?, email: String?) -> Flag? {
        fatalError("Sublcasses must implement this method")
    }

    // MARK: Withdraw From Study routines
    
    private var withdrawal: WithDrawal?
    public func doWithdraw() throws {
        self.participant = nil
        try self.persistor?.purgeAndReset()
        self.tasks = nil
        if ORKPasscodeViewController.isPasscodeStoredInKeychain() {
            ORKPasscodeViewController.removePasscodeFromKeychain()
        }
        postProfileDidChange()
        TaskNotification.shared.removeAllNotifications()
        smLog("[Manager]: Participation withdrawn..")
    }
    func withdrawParticipantFromStudy(basedOn: Any?, callback: @escaping (_ error: Error?) -> Void) {
        
        participant?.status = .withdrawn
        participant?.updateStatusIfNeeded1(to: writeServer, callback: { error in
            do {
                try self.doWithdraw()
                callback(nil)
            }
            catch {
                callback(error)
            }
        })
    }
    
    
    open func assignNotifications(for participantStatus: ResearchSubjectStatus) {
        
        if participantStatus == .offStudy {
            TaskNotification.shared.removeAllNotifications()
        }
        else if participantStatus == .withdrawn {
            TaskNotification.shared.removeAllNotifications()
        }
        else if participantStatus == .onStudy {
            if let du = taskStatus?.due?.first, let t = tasks?.filter({ $0.id == du }).first {
                TaskNotification.shared.DueTask(t)
            }
        }
    }
    

    
    
    // MARK: Handle app lifecycle
    
    open func handleAppWillTerminate() {
    }
    
    open func handleAppLaunch() {
    }
    
    open func resumeSubmissionOperationsIfNeeded() {
        guard participant != nil, let tasks, let persistor = persistor, let _ = persistor.submissions else {
            smLog("[Manager]: cannot resume submissions check; no participant or persistor or submissions")
            return
        }
        
        for task in tasks {
            let _ = persistor.resumeSubmissionOperationsIfNeeded(for:  task)
        }
    }
}



extension StudyManger: SubmissionsDelegate  {
    
    public func SubmissionFinished(with success: Bool, for task: StudyTask, error: (any Error)?) {
        guard success == false || error != nil else {
            smLog("[SO-delegate]: submissionConcluded with no errros")
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [unowned self] in
            let appstate = UIApplication.shared.applicationState
            if appstate == .background {
                TaskNotification.shared.dispatchNotificationForIncompleteSubmission()
                smLog("[SO-del]: found errors, cannot resume, dispatching notification")
            }
            else {
                let status = persistor?.submissions?.status()
                smLog(status!)
                
                if status == .idle {
                    smLog("XXXXXX IDLE STATUS XXXXXX ")
                    smLog("[SO-del]: found errors, re-attempting submission")
                    resumeSubmissionOperationsIfNeeded()
                }
                else {
                    smLog("sssssss BUSY STATUS ssss ")
                }
            }
        }
    }
}
