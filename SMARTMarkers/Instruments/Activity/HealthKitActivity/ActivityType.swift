//
//  ActivityType.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 10/1/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//


public enum ActivityType: CustomStringConvertible {
    
    case Step
    
    
    public var description: String {
        
        get {
            switch self {
            case .Step:
                return "StepCount"
            }
        }
    }
}

