//
//  ListMeasuresViewController.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 15/02/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART



open class MeasuresViewController :  UITableViewController {
    
    let searchController = UISearchController(searchResultsController: nil)
    
    open var instruments : [InstrumentResource]?
    
    open var _instruments : [InstrumentResource]? {
        didSet { instruments = _instruments }
    }
    
    open var selections = [String]()
    
    open var onSelection: (([InstrumentResource]?) ->Void)?
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsMultipleSelection = true
        self.title = "PRO-Measures"
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search PRO-Measures"
        searchController.dimsBackgroundDuringPresentation = false
        searchController.delegate = self
        tableView.tableHeaderView = searchController.searchBar
        definesPresentationContext = true
        tableView.estimatedRowHeight = UITableViewAutomaticDimension
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissModal(_:)))
        self.loadQuestionnaires()
    }
    
    
    open func markBusy() {
        self.title = "Loading.."
    }
    
    
    open func markStandby() {
        self.title = "PRO-Measures"
        self.tableView.reloadData()
    }
    
    
    open func loadQuestionnaires() {
        if nil != instruments { return }
        markBusy()
        SMARTManager.shared.getQuestionnaires { [unowned self] (questionnaires, error) in
            if let questionnaires = questionnaires {
                self._instruments = questionnaires.map { InstrumentResource($0) }
                DispatchQueue.main.async {
                    self.markStandby()
                }
            }
        }
    }
  
    
    @objc
    public func dismissModal(_ sender: AnyObject?) {
        if let onSelection = onSelection {
            if selections.count > 0, let instruments = _instruments {
                let questionnaires = instruments.filter { selections.contains($0.identifier) }
                onSelection(questionnaires)
            } else {
                onSelection(nil)
            }
        }
        dismiss(animated: nil != sender)
    }
    
    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return instruments?.count ?? 0
    }
    
    override open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        let (selected, _) = (contains(indexPath))
        cell.setSelected(selected, animated: false)

    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "MCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
            cell?.accessoryType = .detailButton
            cell?.textLabel?.numberOfLines = 0
            cell?.textLabel?.lineBreakMode = .byWordWrapping
            cell?.detailTextLabel?.textColor = UIColor.gray
        }
        let instr = instruments![indexPath.row]
        cell?.textLabel?.text = instr.title
        cell?.detailTextLabel?.text = instr.code?.code?.string ?? instr.identifier
        cell?.accessoryType = (contains(instr)) ? .checkmark : .detailButton

        
        
        
        return cell!
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        select(indexPath)
    }
    
    override open func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .detailButton
        deselect(indexPath)
    }
    
    override open func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        
        print("More info about the Measure")
        
    }
    
    func contains(_ indexPath: IndexPath) -> (contains: Bool, id: String?) {
        if let instr = instruments?[indexPath.row] {
            return (contains(instr), instr.identifier)
        }
        return (false, nil)
    }
    
    func contains(_ instr: InstrumentResource) -> Bool {
        return selections.contains(instr.identifier)
    }
    
    func select(_ indexPath: IndexPath) {
        let (selected, id) = contains(indexPath)
        if !selected, let id = id { selections.append(id) }
    }
    
    func deselect(_ indexPath: IndexPath) {
        let (selected, id) = contains(indexPath)
        if selected, let idx = selections.index(of: id!) {
            selections.remove(at: idx)
        }
    }
}

extension MeasuresViewController : UISearchControllerDelegate {
    
    public func willDismissSearchController(_ searchController: UISearchController) {
        instruments = _instruments
        tableView.reloadData()
    }
}
extension MeasuresViewController : UISearchResultsUpdating {

    public func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text?.lowercased(), !searchText.isEmpty {
            let filtered = _instruments?.filter{ $0.title.lowercased().range(of: searchText) != nil }
            instruments = filtered
        } else {
            instruments = _instruments
        }
        tableView.reloadData()
    }
}
