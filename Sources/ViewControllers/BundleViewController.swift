//
//  BundleViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 9/4/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import UIKit
import SMART

public class BundleViewController: UITableViewController {
    
    public final var bundle: SMART.Bundle!
    
    init(_ bundle: SMART.Bundle) {
        super.init(style: .grouped)
        self.bundle = bundle
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bundle.entry?.count ?? 0
    }

    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "bCell")

        cell.accessoryType = .disclosureIndicator
        let resource = bundle!.entry![indexPath.row]
        cell.textLabel?.text = resource.resource?.sm_resourceType()
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let resource = bundle!.entry![indexPath.row].resource!
        let view: UIViewController
        if let resource = resource as? Report {
            view = ReportViewController(resource)
        }
        else {
            view = FHIRViewController(resource)
        }

        self.show(view, sender: nil)
    }
}
