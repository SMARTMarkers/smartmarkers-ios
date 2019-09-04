//
//  ReportViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 9/4/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import UIKit
import SMART

class ReportViewController: UITableViewController {
    
    public final var reports: [ReportType]!
    
    public final var server: SMART.Server?
    
    public convenience init(_ reports: [ReportType], submitTo _server: Server?) {
        
        self.init(style: .grouped)
        self.server = _server
        self.reports = reports
        self.title = "New Reports"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSelf(_:)))
        navigationItem.leftBarButtonItem  = UIBarButtonItem(title: "Submit", style: .plain, target: self, action: #selector(submitToEHR(_:)))
    }
    
    @objc
    func submitToEHR(_ sender: Any) {
        
        guard let server = server else {
            sm_showMsg(msg: "Server not found, Login to the FHIR server")
            return
        }
        
        let group = DispatchGroup()
        for report in reports {
            group.enter()
            report.create(server) { (error) in
                if let error = error {
                    print(error)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.sm_showMsg(msg: "Submission Complete")
            self.tableView.reloadData()
        }
        
    }
    @objc
    func dismissSelf(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Table View
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Completed"
    }
    
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return reports != nil ? 1 : 0
    }
    
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reports?.count ?? 0
        
    }
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "QCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "QCell")
        
        cell.accessoryType = .detailDisclosureButton
        let report = reports![indexPath.row]
        cell.textLabel?.text = report.rp_resourceType
        cell.detailTextLabel?.text = "\(report.rp_identifier ?? "") \(report.rp_date.shortDate)"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let qr = reports![indexPath.row]
        let fhirViewer = FHIRViewController(qr)
        navigationController?.pushViewController(fhirViewer, animated: true)
    }
    
}
