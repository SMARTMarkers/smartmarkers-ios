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

public class ReportViewController: UITableViewController {
    
    public final var measures: [PROMeasure]?
    
    public final  var reports: [Reports]!
    
    public final weak var server: SMART.Server?
    
    public final weak var patient: Patient?
    
    public convenience init(_ measures: [PROMeasure], submitTo server: Server?, patient: Patient?) {
        
        self.init(style: .grouped)
        self.reports = measures.filter({ $0.reports != nil }).map { $0.reports! }
        self.server = server
        self.patient = patient
        self.title = "New Reports"

    }
    
    public convenience init(_ reports: [Reports], submitTo _server: Server?, patient: Patient?) {
        
        self.init(style: .grouped)
        self.server = _server
        self.reports = reports
        self.patient = patient
        self.title = "Report Submission"
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.setEditing(true, animated: false)
        navigationItem.rightBarButtonItem = editButtonItem
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 70))
        let submitBtn = UIButton.SMButton(title: "Submit", target: self, action: #selector(submitToEHR(_:)))
        view.addSubview(submitBtn)
        tableView.tableFooterView = view
        let views = ["btn" : submitBtn]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-50-[btn]-50-|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-10-[btn]-10-|", options: [], metrics: nil, views: views))
    }
    
    @objc
    func submitToEHR(_ sender: Any) {
        
        guard let selections = tableView.indexPathsForSelectedRows else {
            sm_showMsg(msg: "Select the reports to submit")
            return
        }
        
        guard let server = server, let patient = patient else {
            sm_showMsg(msg: "Server/Patient not found, Login to the FHIR server")
            return
        }
        
        var selected_reports = [Reports]()
        for ip in selections {
            selected_reports.append(reports[ip.section])
        }
        
        
        // TODO: Consent?
        
        let group = DispatchGroup()
        var errors = [Error]()

        for report in selected_reports {
            group.enter()
            report.submit(to: server, consent: true, patient: patient, request: nil) { (success, error) in
                if let error = error {
                    errors.append(error)
                }
                group.leave()
            }
           
        }
        
        group.notify(queue: .global(qos: .default)) {
            print(errors)
            self.sm_showMsg(msg: "Submission Completed")
        }
    }
    
    
    
    @objc
    func dismissSelf(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Table View
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let report = reports[section]
        let count  = report.newBundles.count
        return "\(report.instrument?.ip_title ?? " ") #\(count)"
    }
    
    override public func numberOfSections(in tableView: UITableView) -> Int {
        
        return reports.count
    }
    
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return reports[section].newBundles.count
    }
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "QCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "QCell")
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.lineBreakMode = .byWordWrapping
        cell.editingAccessoryType = .detailDisclosureButton
        
        let new = reports[indexPath.section].newBundles[indexPath.row]
        cell.textLabel?.text = ""
        cell.detailTextLabel?.text = new.sm_ContentSummary()
        return cell
    }
    
    override public func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
      
        let bundle = reports[indexPath.section].newBundles[indexPath.row]
        let bundleView = ReportBundleViewController(bundle)
        show(bundleView, sender: nil)
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
   
       
    }
    
}
