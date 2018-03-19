//
//  PatientsViewController.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 15/02/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

open class PatientsViewController : UITableViewController {
    
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var _patients : [Patient]? {
        didSet {
            patients = _patients
        }
    }
    
    var patients : [Patient]?
    
    
    public final var onSelection: ((Patient?, PatientsViewController) ->Void)?
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsMultipleSelection = false
        self.title = "Patients"
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search Patients"
        searchController.dimsBackgroundDuringPresentation = false
        searchController.delegate = self
        tableView.tableHeaderView = searchController.searchBar
        definesPresentationContext = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissModal(_:)))
        loadPatients()
    }
    
    
    func markBusy() {
        self.title = "Loading.."
    }
    
    
    func markStandby() {
        self.title = "Patients"
        self.tableView.reloadData()
    }
    
    
    func loadPatients() {
        if nil != patients { return }
        markBusy()
        SMARTManager.shared.getPatients { [unowned self] (patients, error) in
            if let patients = patients {
                self._patients = patients
                DispatchQueue.main.async {
                    self.markStandby()
                }
            }
        }
    }
    
    
    @objc
    public func dismissModal(_ sender: AnyObject?) {
        if let onSelection = onSelection {
            if let selectedIdx = tableView.indexPathForSelectedRow {
                let patient = patients![selectedIdx.row]
                onSelection(patient, self)
            }
            onSelection(nil, self)
        }
        dismiss(animated: nil != sender)
    }
    
    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return patients?.count ?? 0
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "MCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
            cell?.accessoryType = .detailButton
        }
        let patient = patients![indexPath.row]
        cell?.textLabel?.text = patient.humanName
        cell?.detailTextLabel?.text = "EHR Server"
        return cell!
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
    override open func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        
        print("More info about the Measure")
        
    }
    
    
    
    
}
extension PatientsViewController : UISearchControllerDelegate {
    
    public func willDismissSearchController(_ searchController: UISearchController) {
        patients = _patients
        tableView.reloadData()
    }
}
extension PatientsViewController : UISearchResultsUpdating {
    
    
    public func updateSearchResults(for searchController: UISearchController) {
        
        if let searchText = searchController.searchBar.text?.lowercased(), !searchText.isEmpty {
            let filtered = _patients?.filter{ $0.humanName?.lowercased().range(of: searchText) != nil }
            patients = filtered
            
        } else {
            patients = _patients
        }
        
        tableView.reloadData()
    }
    
    
}
