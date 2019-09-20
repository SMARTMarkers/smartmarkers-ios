//
//  RequestViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 6/28/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import UIKit

public class RequestViewController: UITableViewController {

    public var request: Request?
    
    public required convenience init(_ request: Request? = nil) {
        self.init(style: .grouped)
        self.request = request
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        
    }

    // MARK: - Table view data source

    override public func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    
}
