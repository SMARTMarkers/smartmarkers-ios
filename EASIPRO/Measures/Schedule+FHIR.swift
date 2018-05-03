//
//  Schedule+FHIR.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 01/05/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

extension Schedule {
	
	static func initialise(prescribing resource: ProcedureRequest) -> Schedule? {
		if let occuranceDate = resource.ep_dateTime {
			return Schedule.init(dueDate: occuranceDate)
		}
		else if let (start, end, fValue, fUnit) = resource.ep_period_frequency {
			let period = PeriodBound(start, end)
			let frequency = Frequency(value: fValue, unit: fUnit)
			let schedule = Schedule(period: period, freq: frequency)
			return schedule
		}
		return nil
	}
	
	func setStatus(measuring resources: [Observation]) {
        
        
		
	}
}






extension ProcedureRequest {
	
	var ep_period_frequency : (start: Date, end:Date, freqValue:Int, freqUnit: String)? {
		guard let timing = self.occurrenceTiming else {
			return nil
		}
		let start = timing.repeat_fhir!.boundsPeriod!.start!.nsDate
		let end = timing.repeat_fhir!.boundsPeriod!.end!.nsDate
		let freqUnit = timing.repeat_fhir!.periodUnit!.string
		let freqValue = timing.repeat_fhir!.frequency!.int
		return (start, end, freqValue, freqUnit)
	}
	
	var ep_dateTime : Date? {
		guard let dateTime = self.occurrenceDateTime else {
			return nil
		}
		
		let dueDate = dateTime.nsDate
		return dueDate
	}
	
	
}
