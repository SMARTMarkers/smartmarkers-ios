//
//  Schedule.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 01/05/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation

/*
 
 TODO:
 - ServiceRequest.status accounting in TaskSchedule; show complete if "cancelled/completed"
 
 */
public class TaskSchedule: CustomStringConvertible {
   
    static let now = Date()

    public struct Slot2 {
        
        public enum SlotStatus : String {
            case Fulfilled
            case unFulfilled
            case unknown
        }
        
        public enum Tense {
            case Past, Current, Future, Unknown
        }
        
        public let period: Period
        
        public var status: Slot2.SlotStatus = .unknown
        
        public var timeStatus: Tense
        
        init(_ period: Period) {
            
            self.period = period
            
            if period.contains(TaskSchedule.now) {
                timeStatus = .Current
            }
            else if TaskSchedule.now < period.start {
                timeStatus = .Future
                status = .unFulfilled
            }
            else if TaskSchedule.now > period.end {
                timeStatus = .Past
            }
            else {
                timeStatus = .Unknown
            }
        }
        
        public mutating func updateIfSatisfied(by completionDate: Date) -> Bool {
            if period.contains(completionDate) {
                status = .Fulfilled
                return true
            }
            return false
        }
    }
    
    public struct Period: Equatable, CustomStringConvertible {
        let start:      Date
        let end:        Date
        let calender:   Calendar
        
        public var description: String {
            return "\(start.shortDate) –- \(end.shortDate)"
        }
        
        public static func == (lhs: Period, rhs: Period) -> Bool {
            return (lhs.start == rhs.start) && (lhs.end == rhs.end)
        }
        
        public static func > (lhs: Period, rhs: Period) -> Bool {
            return (lhs.start > rhs.start)
        }
        
        public func slots(of frequency: Frequency) -> [TaskSchedule.Slot2]? {
            
            let diffComponents = calender.dateComponents([.day], from: start, to: end)
            let slotCount = (diffComponents.day! / frequency.unitDays)
            if slotCount == 0 { return nil }

            var startSlotDate    = Date()
            var endSlotDate      = Date()
            var newSlots         = [Slot2]()
            
            for i in 1...slotCount {
                startSlotDate = (i == 1) ? start : calender.date(byAdding: .day, value: 1, to: endSlotDate)!
                endSlotDate = calender.date(byAdding: .day, value: frequency.unitDays - 1, to: startSlotDate)!
                let slotPeriod = Period(start: startSlotDate, end: endSlotDate, calender: calender)
                let slot = TaskSchedule.Slot2(slotPeriod)
                newSlots.append(slot)
            }
            return newSlots
        }
        
        public func contains(_ date: Date) -> Bool {
            let startDateOrder = calender.compare(date, to: start, toGranularity: .day)
            let endDateOrder = calender.compare(date, to: end, toGranularity: .day)
            let validStartDate = (startDateOrder == .orderedDescending) || (startDateOrder == .orderedSame)
            let validEndDate = endDateOrder == .orderedAscending || endDateOrder == .orderedSame
            return validStartDate && validEndDate
        }
    }
 
    public enum ActivityStatus: String, CaseIterable {
        case Due
        case Completed
        case Overdue
        case Upcoming
        case Unknown
        case RequestInactive
    }
    
    public struct Frequency {
        let value   : Int
        let unit    : String
        let unitDays  : Int
        
        init(value: Int, unit: String) {
            self.value = value
            self.unit  = unit
            self.unitDays = (unit == "wk") ? 7 : 1
        }
        
        public func numberOfDays() -> UInt {
            return 7 //TODO
        }
    }
    
    /// Activity Date; (DueDate)
    public internal(set) var activityDate: Date?
    
    /// Activity Period;
    public internal(set) var activityPeriod: Period?
    
    /// Frequency
    var frequency: Frequency?
    
    /// Slots; (if any); dependent on acitivtyPeriod
    public lazy var slots: [TaskSchedule.Slot2]? = {
        if let f = frequency {
            return activityPeriod?.slots(of: f)
        }
        return nil
    }()
    
    /// Current Slot in schedule;
    public var currentSlot: TaskSchedule.Slot2? {
        return slots?.first(where: { ($0.timeStatus == .Current) })
    }
    
    /// DUE Slot
    public var dueSlot: TaskSchedule.Slot2? {
        return slots?.first(where: { ($0.timeStatus == .Current || $0.timeStatus == .Future) && $0.status != .Fulfilled })
    }
    
    /// current Due Date
    public var dueDate: Date? {
        return activityDate ?? dueSlot?.period.start
    }
    
    /// Overall activity status
    public var status: ActivityStatus = .Unknown
    
    @discardableResult
    public func calculateStatus() -> ActivityStatus {

        let now = TaskSchedule.now

        // No DueDate; either activity-inactive
        guard let dueDate = dueDate else {
            
            if let end = activityPeriod?.end, now > end  {
                status = .RequestInactive
            }
            else {
                status = .Unknown
            }
            return status
        }
        
     
        if currentSlot?.status == .Fulfilled {
            status = .Completed
        }
        else if now >= dueDate {
            status = .Due
        }
        else if dueDate > now {
            status = .Upcoming
        }
        else { //PAST
            status = .Unknown
        }
        
        return status
    }
    
    
    /**
     Initializer
     
     When a date range is available, optionally a frequency
    */
    init(period: Period, frequency: Frequency?) {
        self.activityPeriod = period
        self.frequency = frequency
        calculateStatus()
    }
    
    /**
     Initializer
     
     Instant dueDate
     */
    init(dueDate: Date) {
        self.activityDate = dueDate
        calculateStatus()
    }
    
    @discardableResult
    public func update(with completionDates:[Date]) -> Bool {
        var didUpdate = false
        if slots != nil  {
            for completedDate in completionDates {
                for i in slots!.indices {
                    if slots![i].updateIfSatisfied(by: completedDate) {
                        didUpdate = true
                    }
                }
            }
        }
        if didUpdate {
            calculateStatus()
        }
        return didUpdate
    }
    
    
    public var description: String {
        return  """
        activityDate: \(activityDate?.shortDate ?? "-")
        activityPeriod: \(activityPeriod?.description ?? "-")
        slots: \(slots?.description ?? "")
        Status: \(status)
        DueDate: \(dueDate?.shortDate ?? "-")
        """
    }
    
}
/*

public enum SlotStatus : String {
	
	case due                    = "due"
	case upcoming               = "upcoming"
	case overdue                = "overdue"
	case unknown                = "unkown"
    case completed              = "completed"
	
}



///::: More testing Needed.

public struct PeriodBound : Equatable {
	
	public let start   :   Date
	public let end     :   Date?
	let calender = UTCCalender.shared.calender
	
    
	public static func == (lhs: PeriodBound, rhs: PeriodBound) -> Bool {
		return (lhs.start == rhs.start) && (lhs.end == rhs.end)
	}
	public static func > (lhs: PeriodBound, rhs: PeriodBound) -> Bool {
        let comparableDate = (rhs.end == nil) ? rhs.start : rhs.end!
		return (lhs.start > comparableDate)
	}
	
	func contains(_ date:Date) -> Bool {
        
        guard let end = end else {
            print("No end date to compare, resorting to start date")
            return (date < start)
        }
		
		let startDateOrder = calender.compare(date, to: start, toGranularity: .day)
		let endDateOrder = calender.compare(date, to: end, toGranularity: .day)
		
		let validStartDate = (startDateOrder == .orderedDescending) || (startDateOrder == .orderedSame)
		let validEndDate = endDateOrder == .orderedAscending || endDateOrder == .orderedSame
		
		return validStartDate && validEndDate
	}
    
    func description() -> String {
        return "\(start.shortDate) –- \(end?.shortDate ?? "-noEndDate--")"
    }
	
	init(_ start: Date, _ end: Date?) {
		self.start = start
		self.end   = end
	}

    
}



public struct Frequency {
	let value   : Int
	let unit    : String
	let unitDays  : Int
	
	init(value: Int, unit: String) {
		self.value = value
		self.unit  = unit
		self.unitDays = (unit == "wk") ? 7 : 1
	}
	
	
}





public struct Slot {
	
	public let period : PeriodBound
    public var status : SlotStatus = .unknown
    public var fulfilledDates = [Date]()
    public var current: Bool = false
    public var hasPassed : Bool = false
    public var future: Bool {
        get {
            return !current && !hasPassed
        }
    }
    
	init(period: PeriodBound) {
        let today = Date()
        self.period = period
        current = period.contains(today)
        hasPassed = !current && (today > (period.end ?? period.start))
        if current {
            status = .due
        }
        if future {
            status = .upcoming
        }
        if hasPassed {
            status = .overdue
        }
        
    }
    
    
    mutating func satisfied(_ date: Date, _ freq: Frequency?) -> Bool {
        
        //::: Add Frequency
        if period.contains(date) {
            status = .completed
            return true
        }
        return false
    }
    
    mutating func newStatus(_ s: SlotStatus) {
        status = s
    }
}


public struct Schedule {
    
    /// UTC Calender
    let calender = UTCCalender.shared.calender
    
    /// Today
    let now = Date()
    
    
    /// Activity Duration of the PRO
    var period: PeriodBound?
    
    /// Calculated Slots for PROSession Activity
    public var slots: [Slot]?
    
    public lazy var slotCount: Int = {
        return slots?.count ?? 0
    }()
    
    /// Current Slot for
    public lazy var _currentSlot: Slot? = {
        return slots?.filter({$0.current == true}).first
    }()
    
    
    var currentSlotIdx: Int?
    
    /// Super Status
    public var superStatus: SlotStatus?
    
    /// Current Due Date
    public var dueDate: Date?
    
    /// Repeating Frequency associated with PROSession Activity
    public var frequency: Frequency?
    
    public var status: SlotStatus = .unknown
    
    init(period: PeriodBound, frequency: Frequency?, overrideStatus: SlotStatus? = nil) {
        self.period = period
        self.frequency = frequency
        self.superStatus = overrideStatus
        self.slots = generateSlots()
        self.dueDate = _currentSlot?.period.start ?? slots?.last?.period.start
        resetStatus()
    }
    
    mutating func resetStatus() {
        if slots != nil {
            self.status = superStatus ?? _currentSlot?.status ?? slots?.last?.status ?? .unknown
        }
    }

    @discardableResult
    public mutating func update(with completionDates:[Date]) -> Bool {
        var didUpdate = false
        if slots != nil {
            for compDate in completionDates {
                for i in slots!.indices {
                    if slots![i].satisfied(compDate, frequency) {
                        slots![i].newStatus(.completed)
                        didUpdate = true
                        break
                    }
                }
            }
        }
        resetStatus()
        return didUpdate
    }
    
    
    mutating func generateSlots() -> [Slot]? {
        
        if period?.end == nil {
            let slot = Slot(period: period!)
            return [slot]
        }
        
        guard let period = period, let frequency = frequency else {
            return nil
        }
   

        let diffComponents = calender.dateComponents([.day], from: period.start, to: period.end!)
        let slotCount = (diffComponents.day! / frequency.unitDays)
        if slotCount == 0 { return nil }
        //Create Slots
        var startSlotDate    = Date()
        var endSlotDate      = Date()
        var newSlots         = [Slot]()
        
        for i in 1...slotCount {
            startSlotDate = (i == 1) ? period.start : endSlotDate.sm_addDays(days: 1)
            endSlotDate = startSlotDate.sm_addDays(days: frequency.unitDays - 1)
            let slotPeriod = PeriodBound(startSlotDate, endSlotDate)
            let slot = Slot(period: slotPeriod)
            if slot.current {
                currentSlotIdx = i-1
            }
            newSlots.append(slot)
        }
        
        return newSlots

    }
}
    
 */

class UTCCalender {
	
	static var shared = UTCCalender()
	
	let calender : Calendar
	init() {
		let utc = TimeZone(abbreviation: "UTC")!
		var _calender = Calendar.current
		_calender.timeZone = utc
		//        let et = TimeZone.current
		//        _calender.timeZone = et
		calender = _calender
	}
}




extension Date {
	
	
	private static let dateFormat: DateFormatter = {
		let formatter = DateFormatter()
        //formatter.dateFormat = "EEEE, MMMM dd, yyyy"
        formatter.dateStyle = .short
		formatter.calendar = UTCCalender.shared.calender
		return formatter
	}()
	
	public var shortDate : String {
		return Date.dateFormat.string(from: self)
	}
	
	func sm_addDays(days: Int) -> Date {
		let calender = UTCCalender.shared.calender
		return calender.date(byAdding: .day, value: days, to: self)!
	}
}
