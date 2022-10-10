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

    public struct Slot {
        
        public enum SlotStatus : String {
            case Fulfilled
            case unFulfilled
            case unknown
        }
        
        public enum Tense {
            case Past, Current, Future, Unknown
        }
        
        public let period: Period
        
        public var status: Slot.SlotStatus = .unknown
        
        public var timeStatus: Tense
        
        public init(_ period: Period) {
            
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
        
        
        public init(_ start: Date, _ end: Date, _ calender: Calendar) {
            self.start = start
            self.end = end
            self.calender = calender
        }
        
        
        
        public var description: String {
            return "\(start.shortDate) –- \(end.shortDate)"
        }
        
        public static func == (lhs: Period, rhs: Period) -> Bool {
            return (lhs.start == rhs.start) && (lhs.end == rhs.end)
        }
        
        public static func > (lhs: Period, rhs: Period) -> Bool {
            return (lhs.start > rhs.start)
        }
        
        public func slots(of frequency: Frequency) -> [TaskSchedule.Slot]? {
            
            let diffComponents = calender.dateComponents([.day], from: start, to: end)
            let slotCount = (diffComponents.day! / frequency.unitDaysPerPeriod)
            if slotCount == 0 { return nil }

            var startSlotDate    = Date()
            var endSlotDate      = Date()
            var newSlots         = [Slot]()
            
            for i in 1...slotCount {
                startSlotDate = (i == 1) ? start : calender.date(byAdding: .day, value: 1, to: endSlotDate)!
                endSlotDate = calender.date(byAdding: .day, value: frequency.unitDaysPerPeriod - 1, to: startSlotDate)!
                let slotPeriod = Period(startSlotDate, endSlotDate, calender)
                let slot = TaskSchedule.Slot(slotPeriod)
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
        case Inactive
    }
    
    public struct Frequency {
        
        // Eg: Event occures x(times) per y(numberofPeriods) periodType
        
        let times:              Int     //Frequency
        let periodType:         String  //periodUnit
        let numberOfPeriods:    Decimal     //numberOfPeriods
        let unitDaysPerPeriod:  Int
        
        public init(times: Int, periodType: String, numberOfPeriods: Decimal) {
            self.times = times
            self.periodType  = periodType
            self.numberOfPeriods = numberOfPeriods

            if periodType == "wk" {
                self.unitDaysPerPeriod = 7
            }
            else if periodType == "mo" {
                self.unitDaysPerPeriod = 30
            }
            else {
                self.unitDaysPerPeriod = 1
            }
        }
    }
    
    /// Activity Date; (DueDate)
    public internal(set) var activityDate: Date?
    
    /// Activity Period;
    public internal(set) var activityPeriod: Period?
    
    /// Frequency
    var frequency: Frequency?
    
    /// Slots; (if any); dependent on acitivtyPeriod
    public lazy var slots: [TaskSchedule.Slot]? = {
        if let f = frequency {
            return activityPeriod?.slots(of: f)
        }
        return nil
    }()
    
    /// Current Slot in schedule;
    public var currentSlot: TaskSchedule.Slot? {
        return slots?.first(where: { ($0.timeStatus == .Current) })
    }
    
    /// DUE Slot
    public var dueSlot: TaskSchedule.Slot? {
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
                status = .Inactive
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
    
    public init(start: Date, end: Date, calender: Calendar? = nil, frequency: Frequency?) {
        self.activityPeriod = Period(start, end, calender ?? Calendar.current)
        self.frequency = frequency
        calculateStatus()
    }
    
    /**
     Initializer
     
     When a date range is available, optionally a frequency
    */
    public init(period: Period, frequency: Frequency?) {
        self.activityPeriod = period
        self.frequency = frequency
        calculateStatus()
    }
    
    /**
     Initializer
     
     Instant dueDate
     */
    public init(dueDate: Date) {
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
	
	public func sm_addDays(days: Int) -> Date {
		let calender = UTCCalender.shared.calender
		return calender.date(byAdding: .day, value: days, to: self)!
	}
}
