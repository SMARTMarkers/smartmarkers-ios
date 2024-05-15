//
//  TaskStatus.swift
//  SMARTMarkers
//
//  Created by raheel on 4/17/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation

public struct TaskStatus {
    
    public struct State {
        public let dueDate: Date
        public let isApplicable: Bool
        public let satisfiedOrderRequirement: Bool
        public let fulfilled: Bool
        
        public var status: Status {
            if fulfilled {
                return .Completed
            }
            else {
                if satisfiedOrderRequirement && isApplicable {
                    if Calendar.current.isDateInToday(dueDate) {
                        return .Due
                    }
                    else {
                        return .Due
                    }
                }
                else if satisfiedOrderRequirement == false {
                    return .Later
                }
                else if isApplicable == false {
                    return .NotApplicable
                }
                else {
                    return .Later
                }
            }
        }
    }
    
    
    public enum Status: Int, Comparable {
        
        public static func < (lhs: TaskStatus.Status, rhs: TaskStatus.Status) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
        
        case Due
        case Later
        case Completed
        case NotApplicable
        case Undetermined
    }
    
    
    private var dict = [String: TaskStatus.State]()
    unowned var manager: StudyManger
    
    init(tasks: [StudyTask], manager: StudyManger) {
        self.dict = tasks.reduce(into: [String: TaskStatus.State](), { partialResult, task in
            partialResult[task.id] = TaskStatus.State(dueDate: Date(), isApplicable: true, satisfiedOrderRequirement: true, fulfilled: false)
        })
        self.manager = manager
    }
    
    func state(for task: StudyTask) -> TaskStatus.State {
        dict[task.id]!
    }
    
    public var due:  [String]? {
        let fi = dict.filter({ $0.value.status == .Due })
        return Array(fi.keys)
    }
    
    public func numberOfDueTasks() -> Int {
        let fi = dict.filter({ $0.value.status <= .Later })
        return fi.keys.count
        
    }
    
    mutating func update(from tasks: [StudyTask]) {
        
        for task in tasks {
           
            let is_completed = task.interpreted?.fulfilled() ?? task.fulfilled
            let has_conditions = task.requiresSatisfyingApplicabilityConditions
            var is_applicable = has_conditions == false
            var satisfied_dependencies = true
            var dueDate = Date()
            var offsetByDays = 0

            
            // APPLICABILITY
            if has_conditions {
                let conditions = task.activity.applicabilityConditions()!
                var bools = [Bool]()
                for cond in conditions {
                    if let answer = manager.activityDelegate?.resolve(condition: [cond], for: task.activity) {
//                    if let answer = manager.resolve(condition: cond, for: task)  {
                        guard let applicabl = answer as? Bool else {
                            fatalError("Manager.resolve expects boolean, but got \(type(of: answer)))")
                        }
                        bools.append(applicabl)
                    }
                }
                is_applicable = bools.contains(false) == false
            }
            
            //
            if let relatedActions = task.activity.relatedAction {
                var fulfillments = [Bool]()
                var relatedDueDates = [Date]()
                for action in relatedActions {
                    let aID = action.actionId!.string
                    let rel = action.relationship!
                    let offsetDuration = action.offsetDuration
                    if let relatedTask = tasks.filter({ $0.id == aID }).first {
                        fulfillments.append(relatedTask.fulfilled)
                        if let offsetDuration, let conclusionDate = relatedTask.result?.result.first?.metric.endTime {
                            let OffsetNumeber = offsetDuration.value!.decimal as NSDecimalNumber
                            let offsetDateComponents = DateComponents(day: OffsetNumeber.intValue)
                            if let dueDt = Calendar.current.date(byAdding: offsetDateComponents, to: conclusionDate) {
                                relatedDueDates.append(dueDt)
                            }
                        }
                    }
                    else {
                        fatalError("Cannot find task with id=\(aID) from task.relatedActions=\(task.id)")
                    }
                }
                if relatedDueDates.count > 0 {
                    relatedDueDates.sort()
                    dueDate = relatedDueDates.last!
                }

                // satisifed relatedAction constraint?
                satisfied_dependencies = !fulfillments.contains(false) && fulfillments.count == relatedActions.count
                smLog(dueDate)
            }
            
            let state = TaskStatus.State(
                dueDate: dueDate,
                isApplicable: is_applicable,
                satisfiedOrderRequirement: satisfied_dependencies,
                fulfilled: is_completed
            )
            
            dict[task.id] = state
        }
        
        
        for d in dict {
            smLog("\(d.key): \(d.value.status); \(d.value)")
        }
    }
}
