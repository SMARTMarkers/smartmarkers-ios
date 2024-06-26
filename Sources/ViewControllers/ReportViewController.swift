//
//  ReportViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 6/28/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import UIKit
import SMART

public class ReportViewController: UITableViewController {
    
    public var report: Report!
    
    public var viewFHIRResource: Bool = true
    
    public var contained: [Report]?
    
    public lazy var data : [(String, String)] = {
        return [
            ("Title",               report.rp_title ?? ""),
            ("FHIR Resource Type",  report.rp_resourceType),
            ("FHIR ID",             report.rp_identifier ?? "-NA-"),
			("Ontology",            "\(report.rp_code?.code?.string ?? report.rp_code?.code?.string ?? "-") \(report.rp_code?.system?.absoluteString ?? "-")"),
            ("Date",                report.rp_date?.shortDate ?? "-"),
            ("Description",         report.rp_description ?? ""),
            ("ResultValue",         report.rp_observation ?? "")
        ]
    }()

    public required convenience init(_ report: Report) {
        self.init(style: .grouped)
        self.report = report
        self.title = "\(report.rp_title ?? "")"
        
        self.contained = (self.report as? DomainResource)?.contained?.compactMap({ $0 as? Report })
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        let isPresented = (presentingViewController?.presentedViewController == self || parent?.isBeingPresented == true)
        if isPresented {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSelf))
        }
    }
    
    @objc
    func showFHIR(_ sender: Any?) {
        let fhirViewController = FHIRViewController(report)
        show(fhirViewController, sender: sender)
    }
    
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override public func numberOfSections(in tableView: UITableView) -> Int {
        return viewFHIRResource ? 3 : 2
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return data.count
        }
        if section == 1 {
            return contained?.count ?? 0
        }
        
        return 1
    }
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "Contained FHIR Resources"
        }
        return nil
    }
    
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "ReportCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
            cell?.textLabel?.numberOfLines = 2
            cell?.textLabel?.lineBreakMode = .byWordWrapping
            cell?.detailTextLabel?.textColor = UIColor.gray
        }
        
        if indexPath.section == 0 {
            cell?.accessoryType = .none
            let (title, text) = data[indexPath.row]
            cell?.textLabel?.text = text
            cell?.detailTextLabel?.text = title
        }
        
        else if indexPath.section == 1  {
            
            cell?.accessoryType = .none
            let re = contained![indexPath.row]
            let title = contained![indexPath.row].rp_title
            cell?.textLabel?.text = re.rp_title ?? re.sm_resourceType()
            cell?.detailTextLabel?.text = re.sm_resourceType()
        }
        
        else {
            cell?.accessoryType = .disclosureIndicator
            cell?.textLabel?.text = "FHIR Resource"
            cell?.detailTextLabel?.text = ""
        }
        return cell!
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 2 {
            showFHIR(nil)
        }
        
        if indexPath.section == 1 {
            let rep = contained![indexPath.row]
            self.navigationController?.pushViewController(ReportViewController(rep), animated: true)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
