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
    
    open var _measures : [PROMeasure2]? {
        didSet { measures = _measures }
    }
    
    open var measures : [PROMeasure2]?
    
    open var selections = [String]()
    
    open var onSelection: (([PROMeasure2]?) ->Void)?
    
    
    
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
        if nil != measures { return }
        markBusy()
        SMARTManager.shared.getQuestionnaires { [unowned self] (questionnaires, error) in
            if let questionnaires = questionnaires {

				self._measures = questionnaires.map({ (q) -> PROMeasure2 in
					let measure = PROMeasure2(title: q.ep_displayTitle(), identifier: q.id!.string)
					measure.measure = q
					return measure
				})
                DispatchQueue.main.async {
                    self.markStandby()
                }
            }
        }
    }
  
    
    @objc
    public func dismissModal(_ sender: AnyObject?) {
        if let onSelection = onSelection {
            if selections.count > 0, let m = _measures {
                let questionnaires = m.filter { selections.contains($0.identifier) }
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
        
        return measures?.count ?? 0
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
            cell?.textLabel?.numberOfLines = 2
            cell?.textLabel?.lineBreakMode = .byWordWrapping
        }
        
        let measure = measures![indexPath.row]
        let selected = (contains(measure))
            cell?.accessoryType = (selected) ? .checkmark : .detailButton
            cell?.textLabel?.text = measure.title
            cell?.detailTextLabel?.text = measure.identifier.lowercased()
            cell?.setSelected(selected, animated: false)
        

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
        if let measure = measures?[indexPath.row] {
            return (contains(measure), measure.identifier)
        }
        return (false, nil)
    }
    
    func contains(_ measure: PROMeasure2) -> Bool {
        return selections.contains(measure.identifier)
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
        measures = _measures
        tableView.reloadData()
    }
}
extension MeasuresViewController : UISearchResultsUpdating {

    public func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text?.lowercased(), !searchText.isEmpty {
            let filtered = _measures?.filter{ $0.title.lowercased().range(of: searchText) != nil }
            measures = filtered
        } else {
            measures = _measures
        }
        tableView.reloadData()
    }
}
