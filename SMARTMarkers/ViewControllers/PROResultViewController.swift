//
//  PROResultViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 6/28/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import UIKit

public class PROResultViewController: UITableViewController {
    
    public var result: ReportProtocol!
    
    public lazy var data : [(String, String)] = {
        return [
            ("Type",        result.rp_resourceType),
            ("FHIR ID",     result.rp_identifier ?? "-NA-"),
            ("Date",        result.rp_date.shortDate),
            ("Description", result.rp_description ?? ""),
            ("Title",       result.rp_title ?? ""),
            ("ResultValue", result.rp_observation ?? "")
        ]
    }()

    public required convenience init(_ _result: ReportProtocol) {
        self.init(style: .grouped)
        result = _result
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSelf))

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
