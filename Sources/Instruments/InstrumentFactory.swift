//
//  InstrumentFactory.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 3/15/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

/**
 Convenience enums to list all available instruments supported natively by SMART Markers.
 
 Can be used to instantiate instruments by `Instruments.<type>.<name>.instance`
 Example: `Instruments.ActiveTasks.AmslerGrid.instance`
 */
public enum Instruments {
    
    /// ActiveTasks: FHIR-ized versions of active measurements from ResearchKit
    public enum ActiveTasks: String, CaseIterable, CustomStringConvertible {
        
        case AmslerGrid                     = "amslergrid"
        case TowerOfHanoi                   = "towerOfHanoi"
        case NineHolePegTest                = "holePegTest"
        case PSAT_2                         = "psat-2"
        case PSAT_3                         = "psat-3"
        case RangeOfMotion_shoulder_right   = "rangeofmotion.shoulder.right"
        case RangeOfMotion_shoulder_left    = "rangeofmotion.shoulder.left"
        case RangeOfMotion_knee_right       = "rangeofmotion.knee.right"
        case RangeOfMotion_knee_left        = "rangeofmotion.knee.left"
        case FingerTappingSpeed             = "fingertappingspeed.both"
        case FingerTappingSpeed_Left        = "fingertappingspeed.left"
        case FingerTappingSpeed_Right       = "fingertappingspeed.right"
        case SpatialSpanMemory              = "spatialSpanMemory"
        case StroopTest                     = "stroopTest"
        
        
        public var instance: Instrument {
            switch self {
            case .AmslerGrid:
                return SMARTMarkers.AmslerGrid()
            case .NineHolePegTest:
                return SMARTMarkers.NineHolePegTest()
            case .PSAT_2:
                return SMARTMarkers.PASAT(interStimulusInterval: 2.0)
            case .PSAT_3:
                return SMARTMarkers.PASAT(interStimulusInterval: 3.0)
            case .TowerOfHanoi:
                return SMARTMarkers.TowerOfHanoi()
            case .RangeOfMotion_shoulder_left:
                return SMARTMarkers.ShoulderRangeOfMotion(limbOption: .left)
            case .RangeOfMotion_shoulder_right:
                return SMARTMarkers.ShoulderRangeOfMotion(limbOption: .right)
            case .RangeOfMotion_knee_left:
                return SMARTMarkers.KneeRangeOfMotion(limbOption: .left)
            case .RangeOfMotion_knee_right:
                return SMARTMarkers.KneeRangeOfMotion(limbOption: .right)
            case .FingerTappingSpeed:
                return SMARTMarkers.TappingSpeed(hand: .both)
            case .FingerTappingSpeed_Left:
                return SMARTMarkers.TappingSpeed(hand: .left)
            case .FingerTappingSpeed_Right:
                return SMARTMarkers.TappingSpeed(hand: .right)
            case .SpatialSpanMemory:
                return SMARTMarkers.SpatialSpanMemory()
            case .StroopTest:
                return SMARTMarkers.StroopTest()
            }
        }
        
        public var description: String {
            switch self {
            case .AmslerGrid:
                return "Amsler Grid"
            case .NineHolePegTest:
                return "9 Hole Peg Test"
            case .PSAT_2:
                return "Paced Serial Addition test (2sec)"
            case .PSAT_3:
                return "Paced Serial Addition test (3sec)"
            case .TowerOfHanoi:
                return "Tower of Hanoi"
            case .RangeOfMotion_shoulder_left:
                return "Left Shoulder Range of Motion"
            case .RangeOfMotion_shoulder_right:
                return "Right Shoulder Range of Motion"
            case .RangeOfMotion_knee_left:
                return "Left Knee Range of Motion"
            case .RangeOfMotion_knee_right:
                return "Right Knee Range of Motion"
            case .FingerTappingSpeed:
                return "Finger Tapping Speed"
            case .FingerTappingSpeed_Left:
                return "Finger Tapping Speed (Left)"
            case .FingerTappingSpeed_Right:
                return "Finger Tapping Speed (Right)"
            case .SpatialSpanMemory:
                return "Spatiel Span Memory"
            case .StroopTest:
                return "Stroop Test"
            }
        }
        
        
        public var coding: Coding {
            switch self {
            default:
                return Coding.sm_ResearchKit(self.rawValue, self.description)
            }
        }
    }
    
    /// HealthKit: Instruments modules that retrieve data from iPhone's HealthKit repository.
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
        
        public var instance: Instrument {
            switch self {
            case .StepCount:
                return StepReport()
            case .HealthRecords:
                return SMARTMarkers.HealthRecords()
            }
        }
    }
    
    /// Web repository Instruments. (Omron Blood Pressure)
    public enum Web: String, CaseIterable {
        
        case OmronBloodPressure             = "omronBloodPressure"
        
        public func instance(authSettings: [String: Any], callbackManager: inout CallbackManager) -> Instrument {
            switch self {
            case .OmronBloodPressure:
                return OMRON(authSettings: authSettings, callbackManager: &callbackManager)
            }
        }
        
        public var coding: Coding {
            switch self {
            case .OmronBloodPressure:
                return Coding.sm_Coding(self.rawValue, "http://omronhealthcare.com", "Omron Blood Pressure")
            }
        }
    }
}
