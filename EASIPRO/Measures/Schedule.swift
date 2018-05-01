//
//  Schedule.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 01/05/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation



public enum SlotStatus : String {
	
	case due = "due"
	case upcoming = "upcoming"
	case missed   = "missed"
	case completedAllSessions = "completed"
	case unknown  = "unkown"
	
}


public struct PeriodBound : Equatable {
	
	let start   :   Date
	let end     :   Date
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
		
		
		print("\(validStartDate) || \(validEndDate)")
		
		return validStartDate && validEndDate
	}
	
	init(_ start: Date, _ end: Date) {
		self.start = start
		self.end   = end
	}
	
	init(duration: UInt64, from date: Date) {
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
	
	let period : PeriodBound
	let status : SlotStatus = .unknown
	var current: Bool = false
	
	init(period: PeriodBound) {
		self.period = period
		self.current = period.contains(Date())
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
	var slots : [Slot]?
	
	
	var slotCount : Int? {
		get { return slots?.count }
	}
	
	
	/// Frequency of a repeating measurement
	let frequency: Frequency?
	
	/// Current status of the current slot
	var currentStatus : SlotStatus? {
		get { return currentSlot?.status }
	}
	
	/// for Internal use, current slot index in slots.array
	public internal(set) var currentSlotIndex = -1
	
	
	/// next Slot
	public var nextSlot : Slot? {
		get {
			guard let slots = slots, currentSlotIndex < slots.endIndex else { return nil }
			let nextIdx = slots.index(after: currentSlotIndex)
			return slots[nextIdx]
		}
	}
	
	/// Previous Slot
	public var previousSlot : Slot? {
		get {
			guard let slots = slots, currentSlotIndex > slots.startIndex else { return nil }
			let previousIdx = slots.index(before: currentSlotIndex)
			return slots[previousIdx]
		}
	}
	
	
	/// Current slot, based on `now`: today's date
	var currentSlot : Slot? {
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
	public func update(with scores: [Double]?) {
		
		
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
		formatter.dateFormat = "EEEE, MMMM dd, yyyy"
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
