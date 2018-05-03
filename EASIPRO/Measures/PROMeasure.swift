//
//  PROMeasure.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 28/02/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


public enum PROMeasureStatus {
	case completed
	case aborted
	case cancelled
	case active
	case unknown
}

public enum PROSessionStatus : String {
    case upcoming = "UPCOMING"
    case due       = "DUE TODAY"
    case planConcluded    = "CONCLUDED"
    case completedCurrent = "COMPLETED CURRENT SLOT"
    case unknown  = "---"
}
public protocol PROMProtocol {
	
	associatedtype PrescribingResourceType
	
	associatedtype MeasurementResourceType
	
	var prescribingResource : PrescribingResourceType? { get set }
	
	var measure: AnyObject? { get set }
	
	var measureStatus: PROMeasureStatus { get set }
	
	var results : [MeasurementResourceType]? { get set }
	
	var title : String { get set }
	
	var identifier : String { get set }
    
    var sessionStatus: PROSessionStatus { get set }
	
	static func fetchPrescribingResources(callback: @escaping (_ resource: [Self]?, _ error: Error?) -> Void)
	
	func fetchMeasurementResources(callback: ((_ success: Bool) -> Void)?)
	
	func status(of prescriber: PrescribingResourceType) -> PROMeasureStatus
}


public final class PROMeasure2 : PROMProtocol {
	
	public typealias MeasurementResource = Observation
	
	public typealias PrescribingResource = ProcedureRequest

	public var prescribingResource: ProcedureRequest? {
		didSet {
			if let pr = prescribingResource {
				self.schedule = Schedule.initialise(prescribing: pr)
				self.measureStatus   = status(of: pr)
			}
		}
	}
	
	public var measure: AnyObject?
	
	public var measureStatus: PROMeasureStatus = .unknown
    
    public var sessionStatus: PROSessionStatus = .unknown
    
    public var scores : [Double]?
	
	public var results: [Observation]? {
        didSet {
            results = results?.sorted { $0.effectiveDateTime!.nsDate < $1.effectiveDateTime!.nsDate }
            filterObservations()
        }
	}
	
    
    
	
	public var title: String
	
	public var identifier: String
	
	public var schedule: Schedule?
	
	init(title: String, identifier: String) {
		self.title = title
		self.identifier = identifier
	}
	

	public static func fetchPrescribingResources(callback: @escaping (_ resource: [PROMeasure2]?, _ error: Error?) -> Void) {
		
		guard let patient = SMARTManager.shared.patient else {
			callback(nil, nil)
			return
		}
		let searchParams = ["patient": patient.id!.string]
		SMARTManager.shared.search(type: ProcedureRequest.self, params: searchParams) { (requests, error) in
			if nil != error {
				callback(nil, error)
				return
			}
			
			if let requests = requests {
				let promeasures = requests.map({ (procedureRequest) -> PROMeasure2 in
					let title = procedureRequest.ep_titleCode ?? procedureRequest.ep_titleCategory ?? procedureRequest.id!.string
					let identifier = procedureRequest.id!.string
					let prom = PROMeasure2(title: title, identifier: identifier)
                    prom.prescribingResource = procedureRequest
					return prom
				})
				callback(promeasures, nil)
			}
		}
		
	}


	
	
	public func fetchMeasurementResources(callback:  ((Bool) -> Void)?) {

		guard let patient = SMARTManager.shared.patient, let pr = prescribingResource else {
			callback?(false)
			return
		}
		let param = ["patient" : patient.id!.string,
					 "based-on": pr.id!.string]
		SMARTManager.shared.search(type: Observation.self, params: param) { [weak self] (observations, error) in
			if nil != error {
				callback?(false)
			}
			self?.results = observations
			callback?(self?.results != nil)
			
		}
	}
	
	public func status(of prescriber: ProcedureRequest) -> PROMeasureStatus {
		
		guard let pstatus = prescriber.status else {
			return .unknown
		}
		switch pstatus {
			case .completed:
				return .completed
			case .cancelled:
				return .cancelled
			case .active:
				return .active
			default:
				return .unknown
		}
	}
    
    
    func filterObservations() {
        if let res = results {
            scores = res.map { Double($0.valueString!.string)! }
        }
        
        // if Scheduled, then check slots
        // TODO: associate results with slotIntervals
        // Each slot --->> [Observations]
        if let _ = schedule?.slots {
            
            
            
            
            
            
        }
        
        if measureStatus == .completed || measureStatus == .aborted {
            sessionStatus = .planConcluded
        } else if measureStatus == .active {
            // Compare Observations and things here:
            // Check if Current Slot is due
            let hasNext     = schedule?.nextSlot != nil
            let dueToday    = schedule?.currentSlot != nil
            let latestScore = results?.last?.effectiveDateTime?.nsDate
            
            if !dueToday && !hasNext { sessionStatus = .planConcluded }

            else if dueToday {
                if latestScore == nil { sessionStatus = .due }
                if let latestScore = latestScore, schedule!.currentSlot!.period.contains(latestScore) {
                    sessionStatus = (hasNext) ? .completedCurrent : .planConcluded
                } else {
                    sessionStatus = .due
                }
            }
            else if hasNext { sessionStatus = .upcoming }
            
            
            
            
        } else { sessionStatus = .unknown }
        
    }

}


open class PROMeasure {
	
    public enum Status {
		
		case upcoming
        case completed
        case pending
        case missed
		
    }
	
	open var prescribingResource: DomainResource?
	open var measure: AnyObject?
	open var status : Status = .pending
	open var results : [DomainResource]?
	open var schedule : Schedule?
	
    
    public init(measure: AnyObject) {
        self.measure = measure
    }
    
    open var title : String {
        get { return getTitle() }
    }
    
    open var identifier: String {
        get { return getIdentifier() }
    }
    
    open func getTitle() -> String {
        return measure?.description ?? "---"
    }
    
    open func getIdentifier() -> String {
        return "---"
    }
    
    
}

extension PROMeasure : Equatable {
	
	public static func ==(lhs: PROMeasure, rhs: PROMeasure) -> Bool {
		return (lhs.identifier == rhs.identifier)
	}
}


open class PROQuestionnaire: PROMeasure {
    
    override open func getTitle() -> String {
        if let measure = measure as? Questionnaire {
            return measure.ep_displayTitle()
        }
        else {
            return "FHIR Questionnaire"
        }
    }
    
    override open func getIdentifier() -> String {

		if let measure = measure as? Questionnaire {
            return measure.id!.string
        }
        else {
            return "FHIR Identifier"
        }
    }
}


extension Questionnaire {
    
    /// Best possible title for the Questionnaire
    public func ep_displayTitle() -> String {
        
        if let title = self.title {
            return title.string
        }
        
        if let identifier = self.identifier {
            for iden in identifier {
                if let value = iden.value {
                    return value.string
                }
            }
        }
        
        if let codes = self.code {
            for code in codes {
                if let display = code.display {
                    return display.string
                }
            }
        }
        
        return self.id!.string
    }
    
    
}
