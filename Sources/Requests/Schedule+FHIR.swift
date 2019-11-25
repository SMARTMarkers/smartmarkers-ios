//
//  Schedule+FHIR.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 11/25/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


extension TaskSchedule {
    
    func occuranceTiming() -> SMART.Timing? {
        
        guard let fhir_period = occurancePeriod(), let freq = frequency else { return nil }
        
        let timingRepeat = TimingRepeat()
        timingRepeat.boundsPeriod = fhir_period

        timingRepeat.frequency = FHIRInteger(integerLiteral: freq.times)
        timingRepeat.periodUnit = freq.periodType.fhir_string
        timingRepeat.period = FHIRDecimal(freq.numberOfPeriods)
    
        let timing = Timing()
        timing.repeat_fhir = timingRepeat
        return timing
    }
    
    func occurancePeriod() -> SMART.Period? {
        guard let activityPeriod = activityPeriod else { return nil }
        let period = SMART.Period()
        period.end = activityPeriod.end.fhir_asDateTime()
        period.start = activityPeriod.start.fhir_asDateTime()
        return period
    }
    
    convenience init?(occuranceTiming: SMART.Timing) {
        
        if let freqValue = occuranceTiming.repeat_fhir?.frequency?.int,
            let periodUnit = occuranceTiming.repeat_fhir?.periodUnit?.string,
            let numberOfPeriods = occuranceTiming.repeat_fhir?.period?.decimal,
            let bounds = occuranceTiming.repeat_fhir?.boundsPeriod
            
        {
            self.init(occurancePeriod: bounds)
            self.frequency = Frequency(times: freqValue, periodType: periodUnit, numberOfPeriods: numberOfPeriods)
        }
        return nil
    }
    
    convenience init?(occurancePeriod: SMART.Period) {
        
        if let start = occurancePeriod.start?.nsDate, let end = occurancePeriod.end?.nsDate {
            self.init(start: start, end: end, frequency: nil)
        }
        return nil
    }
}
