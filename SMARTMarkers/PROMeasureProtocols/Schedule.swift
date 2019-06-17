//
//  Schedule.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 01/05/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation

public enum SlotStatus : String {
	
	case due                    = "due"
	case upcoming               = "upcoming"
	case overdue                 = "overdue"
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
