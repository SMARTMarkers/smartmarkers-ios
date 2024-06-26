//
//  InstrumentProtocol.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 3/1/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


/**
 Instrument Category Type
 */
public enum InstrumentCategoryType: String, Equatable {
    
    case Survey             = "Survey"
    case ActiveTask         = "ActiveTask"
    case Device             = "Device Generated"
    case WebRepository      = "Web Repository"
    case healthRecords      = "Health Records"
    case unknown            = "Unknown"
}

/**
Presentation Options
*/
public struct InstrumentPresenterOptions: OptionSet {
	public let rawValue: Int
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}

	public static let withoutIntroductionStep = InstrumentPresenterOptions(rawValue: 1)
	public static let withoutConclusionStep = InstrumentPresenterOptions(rawValue: 2)
	
}
/**
 Instrument Class Protocol
 Serializes all types of PGHD into a common protocol
 */
public protocol Instrument : class {
    
    /// Display friendly title for the instrument
    var sm_title: String { get set }
    
    /// Instrument identifier
    var sm_identifier: String? { get set }
    
    /// Instrument Category
    var sm_type: InstrumentCategoryType? { get set }
    
    /// Instrument ontological code in `SMART.Coding`
    var sm_code: SMART.Coding? { get set }
    
    /// Instrument Version
    var sm_version: String? { get set }
    
    /// Instrument Publisher
    var sm_publisher: String? { get set }

    /// Output resource types; can be used to fetch historical resources from the `SMART.Server`
    var sm_reportSearchOptions: [FHIRReportOptions]? { get set }
        
    /// Protocol function to create a ResearchKit's survey task controller (`ORKTaskViewController`)
	func sm_taskController(config: InstrumentPresenterOptions?, callback: @escaping ((ORKTaskViewController?, Error?) -> Void))
    
    /// Protocol Func to generate a FHIR `Bundle` of result resources. eg. QuestionnaireResponse, Observation
    func sm_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle?
    
    /// Func to offer any "settings" to offer further customization
    func sm_configure(_ settings: Any?)
    
}


/**
 Instruments with OAuth2
 
 Certain Instrument require logging into their connected Web Repositories, Such instruments have to comply with `WebInstrument` Protocol
 */

public protocol WebInstrument: class {

    func handleRedirectURL(redirectURL: URL) throws
    
}

/// Convenience Extension to fetch a set of `Instruments` from the `Server`
public extension Instrument where Self: SMART.DomainResource {
    
    static func Get(from server: Server, options: [String:String]?, callback: @escaping ((_ instrumentResources: [Self]?, _ error: Error?) -> Void)) {
        let search = Self.search(options as Any)
        search.pageCount = 100
        search.perform(server) { (bundle, error) in
            if let bundle = bundle {
                let resources = bundle.entry?.filter { $0.resource is Self }.map { $0.resource as! Self }
                callback(resources , nil)
            }
            else {
                callback(nil, error)
            }
        }
    }
    
}


extension Instrument {
    
    func introductionAndConclusionSteps() -> (intro: ORKStep, completed: ORKStep) {
        let introduction = ORKInstructionStep(identifier: "instrument_introduction", _title: sm_title, _detailText: sm_publisher)
        let completion = ORKCompletionStep(identifier: "instrument_completion")
        return (introduction, completion)
    }
    
}


/// ViewController for an Instrument
open class InstrumentViewController: UITableViewController {
    
    public var instrument: Instrument!
    
    public lazy var data : [(String, String)] = {
        return [
            ("Title",       instrument.sm_title),
            ("Identifier",  instrument.sm_identifier ?? "-NA-"),
            ("Type",        instrument.sm_type?.rawValue ?? "-NA-"),
            ("Code",        instrument.sm_code?.sm_DisplayRepresentation() ?? "-NA-"),
            ("Version",     instrument.sm_version ?? "-NA-"),
            ("Publisher",   instrument.sm_publisher ?? "-NA-")
        ]
    }()
    
    public required convenience init(_ _instrument: Instrument) {
        self.init(style: .grouped)
        instrument = _instrument
    }
    
    override open func viewDidLoad() {
        
        super.viewDidLoad()
        if navigationController != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSelf))
        }
        
    }
    
    @objc
    func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    
    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "InstrumentCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
            cell?.textLabel?.numberOfLines = 2
            cell?.textLabel?.lineBreakMode = .byWordWrapping
            cell?.detailTextLabel?.textColor = view.tintColor
        }
        
        let (title, text) = data[indexPath.row]
        cell?.textLabel?.text = text
        cell?.detailTextLabel?.text = title
        return cell!
        
    }
    
    
    
    
}
