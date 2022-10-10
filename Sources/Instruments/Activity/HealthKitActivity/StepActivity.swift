//
//  StepActivity.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 10/1/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import HealthKit

open class StepActivity: Activity {
    
    public var store: HKHealthStore?
    
    static let hkSampleType = HKSampleType.quantityType(forIdentifier: .stepCount)!
 
    public var type: ActivityType = .Step
    
    public var period: ActivityPeriod?
    
    public var value: Any?
    
    public var showDateSelector: Bool = true

    public lazy var queryPredicate: NSPredicate? = {
        
        guard let period = period else {
            return nil
        }
        return HKQuery.predicateForSamples(withStart: period.start, end: nil, options: [])
    }()
    
    public lazy var sortDiscriptor: NSSortDescriptor = {
        return NSSortDescriptor.init(key: HKSampleSortIdentifierStartDate, ascending: true)
    }()
    
    public init(_ period: ActivityPeriod) {
        self.period = period
    }
    
    public convenience init(start: Date, end: Date?) {
        
        let period = ActivityPeriod(start: start, end: end)
        self.init(period)
    }
    
    public func fetch(_ _store: HKHealthStore? = nil, callback: @escaping ((Any?, Error?) -> Void)) {
        
        store = _store
        store?.requestAuthorization(toShare: nil, read: Set([StepActivity.hkSampleType]), completion: { (success, error) in
            
            if !success {
                callback(nil, error)
            }
            else {
                self.executeQuery(callback: callback)
            }
        })
        
    }
    
    public func executeQuery(callback: @escaping ((_ sample: Any?, _ error: Error?) -> Void)) {
    
        
        let calendar = Calendar.current
        var interval = DateComponents()
        interval.day = 1

         var anchorComponents = calendar.dateComponents([.day, .month, .year], from: Date())
         anchorComponents.hour = 0
         let anchorDate = calendar.date(from: anchorComponents)

         // Define 1-day intervals starting from 0:00
        let query = HKStatisticsCollectionQuery(
            quantityType: Self.hkSampleType,
            quantitySamplePredicate: queryPredicate,
            options: .cumulativeSum,
            anchorDate: anchorDate!,
            intervalComponents: interval)

         // Set the results handler
         query.initialResultsHandler = {query, results, error in
//             let endDate = NSDate()
//             let startDate = calendar.date(byAdding: .day, value: -7, to: endDate as Date, wrappingComponents: false)
             if let myResults = results {
                 callback(myResults, nil)
//                 myResults.enumerateStatistics(from: self.period!.start!, to: self.period!.end!) { statistics, stop in
//                     callback(statistics, nil)
//                 } //end block
             } //end if let
             else {
                 callback(nil, nil)
             }
         }
        
        
//        let query = HKSampleQuery(
//            sampleType: StepActivity.hkSampleType,
//            predicate: queryPredicate,
//            limit: 100,
//            sortDescriptors: [sortDiscriptor]) { (query, samples, error) in
//
//            if let samples = samples as? [HKQuantitySample] {
//                callback(samples, nil)
//            }
//            else {
//                callback(nil, SMError.undefined(description: "No Samples Found"))
//            }
//        }
        
        store?.execute(query)
    }
    
}




