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
    
    public lazy var queryPredicate: NSPredicate? = {
        
        guard let period = period else {
            return nil
        }
        return HKQuery.predicateForSamples(withStart: period.start, end: period.end, options: [.strictEndDate, .strictEndDate])
    }()
    
    public lazy var sortDiscriptor: NSSortDescriptor = {
        return NSSortDescriptor.init(key: HKSampleSortIdentifierStartDate, ascending: true)
    }()
    
    
    public init(_ period: ActivityPeriod) {
        self.period = period

    }
    
    public convenience init(_ start: Date, _ end: Date?) {
        
        let period = ActivityPeriod(start: start, end: end)
        self.init(period)
    }
    
    public func fetch(_ _store: HKHealthStore? = nil, callback: @escaping ((Any?, Error?) -> Void)) {
        
        store = _store
        
        store?.requestAuthorization(toShare: nil, read: Set([StepActivity.hkSampleType]), completion: { (success, error) in
            
            if !success {
                callback(nil, error)
            }
            self.executeQuery(callback: callback)
        })
        
    }
    
    public func executeQuery(callback: @escaping ((_ sample: Any?, _ error: Error?) -> Void)) {
        
        let query = HKSampleQuery(sampleType: StepActivity.hkSampleType, predicate: queryPredicate, limit: 100, sortDescriptors: [sortDiscriptor]) { (query, samples, error) in
            
            if let samples = samples as? [HKQuantitySample] {
                callback(samples, nil)
            }
            
            callback(nil, SMError.undefined(description: "No Samples Found"))
        }
        
        store?.execute(query)
    }
    
}



