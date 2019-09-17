//
//  InstrumentProtocol.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 3/1/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


public protocol Instrument : class {
    
    /// Display friendly title for the instrument
    var ip_title: String { get }
    
    /// Instrument identifier
    var ip_identifier: String? { get }
    
    /// Instrument ontological code in `SMART.Coding`
    var ip_code: SMART.Coding? { get }
    
    /// Instrument Version
    var ip_version: String? { get }
    
    /// Publisher
    var ip_publisher: String? { get }
    
    /// Output resource types; can be used to fetch historical resources from the `SMART.Server`
    var ip_resultingFhirResourceType: [FHIRSearchParamRelationship]? { get }
    
    /// Protocol Func to generate ResearchKit's `ORKTaskViewController`
    func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void))
    
    /// Protocol Func to generate a FHIR `Bundle` of result resources. eg. QuestionnaireResponse, Observation
    func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle?
    
}


public extension Instrument where Self: SMART.DomainResource {
    
    static func Instruments(from server: Server, options: [String:String]?, callback: @escaping ((_ instrumentResources: [Self]?, _ error: Error?) -> Void)) {
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


public extension Instrument {
    
    func asPROMeasure() -> PROMeasure {
        return PROMeasure(instrument: self)
    }
    
}



public class InstrumentViewController: UITableViewController {
    
    public var instrument: Instrument!
    
    public lazy var data : [(String, String)] = {
        return [
            ("Title",       instrument.ip_title),
            ("Identifier",  instrument.ip_identifier ?? "-NA-"),
            ("Version",     instrument.ip_version ?? "-NA-"),
            ("Publisher",   instrument.ip_publisher ?? "-NA-")
        ]
    }()
    
    public required convenience init(_ _instrument: Instrument) {
        self.init(style: .grouped)
        instrument = _instrument
    }
    
    override public func viewDidLoad() {
        
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
    
    override public func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return data.count
    }
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
