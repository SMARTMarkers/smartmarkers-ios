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
	case missed                 = "missed"
	case unknown                = "unkown"
    case completed              = "completed"
	
}


public struct PeriodBound : Equatable {
	
	public let start   :   Date
	public let end     :   Date
	let calender = PROCalender.shared.calender
	
	public static func == (lhs: PeriodBound, rhs: PeriodBound) -> Bool {
		return (lhs.start == rhs.start) && (lhs.end == rhs.end)
	}
	
	public static func > (lhs: PeriodBound, rhs: PeriodBound) -> Bool {
		return (lhs.start > rhs.end)
	}
	
	func contains(_ date:Date) -> Bool {
		
		let startDateOrder = calender.compare(date, to: start, toGranularity: .day)
		let endDateOrder = calender.compare(date, to: end, toGranularity: .day)
		
		let validStartDate = (startDateOrder == .orderedDescending) || (startDateOrder == .orderedSame)
		let validEndDate = endDateOrder == .orderedAscending || endDateOrder == .orderedSame
		
		
//        print("\(validStartDate) || \(validEndDate)")
		
		return validStartDate && validEndDate
	}
    
    func description() -> String {
        return "\(start.shortDate) –- \(end.shortDate)"
    }
	
	init(_ start: Date, _ end: Date) {
		self.start = start
		self.end   = end
	}
	
	init(duration: UInt64, from date: Date) {
        // TODO
		// calculate duration from date: Date
		// based on number o
		self.init(Date(), Date())
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
            hasPassed = !current && (today > period.start)
        
        if current {
            status = .due
        }
        if future {
            status = .upcoming
        }
        if hasPassed {
            status = .due
        }
        
    }
    
    
    mutating func satisfied(_ date: Date, _ freq: Frequency?) -> Bool {
        
        //todo:
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
	
	
	let calendar = PROCalender.shared.calender
	
	/// Today's date
	let now = Date()
	
	/// Instant Date if applicable
	let instantDate : Date? 
	
	var instant : Bool {
		get { return (instantDate == nil) ? false : true }
	}
    
    
	
	/// Calculated or set value
	var periodBound : PeriodBound?
	
	/// Slots available for PRO Measurement
	public var slots : [Slot]?
	
	
	var slotCount : Int? {
		get { return slots?.count }
	}
	
    //TODO: Frequency per slot calculation?
    // Default is Frequency: 1
	/// Frequency of a repeating measurement
	let frequency: Frequency?
	

    var instantStatus : SlotStatus = .unknown
    
    public var status: SlotStatus {
        get {
            //TODO : instant items can be same day slots.
            // Enddate could be optional?
            if instant {
                return instantStatus
            }
            return currentSlot?.status ?? nextSlot?.status ?? previousSlot?.status ?? .unknown
        }
    }
    
	
	/// for Internal use, current slot index in slots.array
	public internal(set) var currentSlotIndex = -1
	
	
	/// next Slot
	public var nextSlot : Slot? {
		get {
			guard let slots = slots, currentSlotIndex < slots.endIndex else { return nil
			}
			
			let nextIdx = slots.index(after: currentSlotIndex)
			return slots[nextIdx]
		}
	}
	
	/// Previous Slot
	public var previousSlot : Slot? {
		get {
            guard let slots = slots else { return nil }
            if currentSlotIndex > slots.startIndex { return slots.last }
			let previousIdx = slots.index(before: currentSlotIndex)
			return slots[previousIdx]
		}
	}
	
	
	/// Current slot, based on `now`: today's date
	public var currentSlot : Slot? {
		get {
			guard let slots = slots else {
				return nil
			}
			for slot in slots {
				if slot.current { return slot }
			}
			return nil
		}
	}
    
    // TODO: streamline Due Slots
    public var dueDate: Date? {
        get {
            return instantDate ?? currentSlot?.period.start ?? nextSlot?.period.start ?? previousSlot?.period.start ?? nil
        }
    }
    
	
	
	init(period: PeriodBound, freq: Frequency) {
		self.periodBound = period
		self.frequency = freq
		self.instantDate = nil
		self.slots = configureSlots()
		
	}
	
	init(dueDate: Date) {
		self.instantDate = dueDate
		self.periodBound = nil
		self.frequency = nil
        if now > dueDate || calendar.isDateInToday(dueDate) {
            instantStatus = .due
        } else { instantStatus = .upcoming }
	}
	
	
	
	
	/// Requires repeating elements `PeriodBound` and `Frequency`
	mutating func configureSlots() -> [Slot]? {
		
		guard let period = periodBound, let frequency = frequency else {
			return nil
		}
		
		let diffComponents = calendar.dateComponents([.day], from: period.start, to: period.end)
		let slotCount = (diffComponents.day! / frequency.unitDays)
		if slotCount == 0 { return nil }
		
		
		//Create Slots
		var startSlotDate	= Date()
		var endSlotDate		= Date()
		var newSlots		= [Slot]()
		
		for i in 1...slotCount {
			startSlotDate = (i == 1) ? period.start : endSlotDate.addDays(days: 1)
			endSlotDate = startSlotDate.addDays(days: frequency.unitDays - 1)
			
			let slotPeriod = PeriodBound.init(startSlotDate, endSlotDate)
			let slot = Slot(period: slotPeriod)
			if slot.current {
				currentSlotIndex = i-1
			}
			
			newSlots.append(slot)
		}
		return newSlots
	}
    
	
	
	/// Updates completion status of the slots with corresponding dates
    public mutating func update(with scoredDates: [Date]) {
        
        
        
        
        if slots == nil {
            
            //TODO
            if instant {
                instantStatus = .completed
            }
            return
        }
        
        scoredDates.forEach { (date) in
            for i in slots!.indices {
                // TODO: Check schedule satisfied wth Frequency
                if slots![i].satisfied(date, frequency) {
                    slots![i].newStatus(.completed)
                    break
                }
                if slots![i].hasPassed {
                    slots![i].newStatus(.missed)
                }
            }
        }
	}
    
    public func periodString() -> String? {
        if instant  { return instantDate!.shortDate }
        if let p = periodBound { return p.description() }
        return nil
    }
}


class PROCalender {
	
	static var shared = PROCalender()
	
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
//        formatter.dateFormat = "EEEE, MMMM dd, yyyy"
        formatter.dateStyle = .short
		formatter.calendar = PROCalender.shared.calender
		return formatter
	}()
	
	public var shortDate : String {
		return Date.dateFormat.string(from: self)
	}
	
    
    
	
	func addDays(days: Int) -> Date {
		let calender = PROCalender.shared.calender
		return calender.date(byAdding: .day, value: days, to: self)!
	}
}
