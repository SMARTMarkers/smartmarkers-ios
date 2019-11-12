//
//  InstrumentFactory.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 3/15/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


public enum Instruments {
    
    public enum HealthKit: String, CaseIterable, CustomStringConvertible {
        
        case StepCount                  = "stepCount"
        case HealthRecords              = "healthRecords"
        
        public var description: String {
            switch self {
            case .HealthRecords:
                return "iOS Health Records"
            case .StepCount:
                return "HealthKit Step Count"
            }
        }
        
        public var instrument: Instrument {
            switch self {
            case .StepCount:
                return StepReport()
            case .HealthRecords:
                return SMHealthKitRecords()
            }
        }
    }
    
   
    public enum Web: String, CaseIterable {
        
        case omronBloodPressure             = "omronBloodPressure"
        
        public func instrument(authSettings: [String: Any]) -> Instrument {
            switch self {
            case .omronBloodPressure:
                return OMRON(authSettings: authSettings)
            }
        }
        
        public var coding: Coding {
            switch self {
            case .omronBloodPressure:
                return Coding.sm_Coding(self.rawValue, "http://omronhealthcare.com", "Omron Blood Pressure")
            }
        }
    }
    
    
    public enum ActiveTasks: String, CaseIterable, CustomStringConvertible {
            
            case amslerGrid                     = "amslergrid"
            case towerOfHanoi                   = "towerOfHanoi"
            case nineHolePegTest                = "holePegTest"
            case psat_2                         = "psat-2"
//            case psat_3                         = "psat-3"
            case rangeOfMotion_shoulder_right   = "rangeofmotion.shoulder.right"
            case rangeOfMotion_shoulder_left    = "rangeofmotion.shoulder.left"
            case rangeOfMotion_knee_right       = "rangeofmotion.knee.right"
            case rangeOfMotion_knee_left        = "rangeofmotion.knee.left"
            case FingerTappingSpeed             = "fingertappingspeed.both"
            case FingerTappingSpeed_Left        = "fingertappingspeed.left"
            case FingerTappingSpeed_Right       = "fingertappingspeed.right"
            case spatialSpanMemory              = "spatialSpanMemory"
            case StroopTest                     = "stroopTest"
            
            
            public var instrument: Instrument {
                switch self {
                    case .amslerGrid:
                        return AmslerGrid()
                    case .nineHolePegTest:
                        return NineHolePegTest()
                    case .psat_2:
                        return PASAT()
//                    case .psat_3:
//                        fatalError()
                    case .towerOfHanoi:
                        return TowerOfHanoi()
                    case .rangeOfMotion_shoulder_left:
                        return ShoulderRangeOfMotion(limbOption: .left)
                    case .rangeOfMotion_shoulder_right:
                        return ShoulderRangeOfMotion(limbOption: .right)
                    case .rangeOfMotion_knee_left:
                        return KneeRangeOfMotion(limbOption: .left)
                    case .rangeOfMotion_knee_right:
                        return KneeRangeOfMotion(limbOption: .right)
                    case .FingerTappingSpeed:
                        return TappingSpeed(hand: .both)
                    case .FingerTappingSpeed_Left:
                        return TappingSpeed(hand: .left)
                    case .FingerTappingSpeed_Right:
                        return TappingSpeed(hand: .right)
                    case .spatialSpanMemory:
                        return SpatialSpanMemory()
                    case .StroopTest:
                        return SMARTMarkers.StroopTest()
                }
            }
            
            public var description: String {
                //TODO
                return self.rawValue
            }
            
            
            public var coding: Coding {
                switch self {
                default:
                    return Coding.sm_ResearchKit(self.rawValue, self.description)
                }
        }
    }
}
