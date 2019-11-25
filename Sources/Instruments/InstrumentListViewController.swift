//
//  ListMeasuresViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 15/02/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART



open class InstrumentListViewController :  UITableViewController {
    
    public var server: SMART.Server?
    
	open internal(set) var  _title: String?
	
	open internal(set) var instruments : [Instrument]?
    
    open internal(set) var _instruments : [Instrument]? {
        didSet { instruments = _instruments }
    }

    open var selections = [String]()
    
    open var onSelection: (([Instrument]?) ->Void)?
    
    let searchController = UISearchController(searchResultsController: nil)
    
    let activityIndicator = UIActivityIndicatorView(style: .gray)
    
    public required init(server: Server?) {
        self.server = server
        super.init(style: .grouped)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func viewDidLoad() {
        title = "Questionnaires"
        super.viewDidLoad()
        tableView.allowsMultipleSelection = true
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search Instruments"
        searchController.dimsBackgroundDuringPresentation = false
        searchController.delegate = self
        tableView.tableHeaderView = searchController.searchBar
        definesPresentationContext = true
        tableView.estimatedRowHeight = UITableView.automaticDimension
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissModal(_:)))
        let activityItem = UIBarButtonItem(customView: activityIndicator)
        navigationItem.leftBarButtonItem = activityItem
        self.loadQuestionnaires()
    }
    
    
    open func markBusy() {
		_title = title
        title = "Loading.."
        activityIndicator.startAnimating()
    }
    
    
    open func markStandby() {
        tableView.reloadData()
		title = _title
        activityIndicator.stopAnimating()
    }
	
	open func set(_ instruments: [Instrument]?) {
		_instruments = instruments
	}
    
    
    open func loadQuestionnaires() {
		
        guard nil == instruments, let server = server else {
            return
        }
        markBusy()
        Questionnaire.Get(from: server, options: [:]) { [unowned self] (questionnaires, error) in
            
            if let error = error {
                print(error)
            }
            if let questionnaires = questionnaires {
				self.set(questionnaires)
            }
            
            DispatchQueue.main.async {
                self.markStandby()
            }
        }
    }
  
    
    @objc
    public func dismissModal(_ sender: AnyObject?) {
        if let onSelection = onSelection {
            if selections.count > 0, let instruments = _instruments {
                let questionnaires = instruments.filter { selections.contains($0.sm_identifier!) }
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
        cell?.textLabel?.text = instr.sm_title
        cell?.detailTextLabel?.text = instr.sm_code?.code?.string ?? instr.sm_identifier
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
            return (contains(instr), instr.sm_identifier)
        }
        return (false, nil)
    }

    func contains(_ instr: Instrument) -> Bool {
        return selections.contains(instr.sm_identifier!)
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

extension InstrumentListViewController : UISearchControllerDelegate {
    
    public func willDismissSearchController(_ searchController: UISearchController) {
        instruments = _instruments
        tableView.reloadData()
    }
}
extension InstrumentListViewController : UISearchResultsUpdating {

    public func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text?.lowercased(), !searchText.isEmpty {
            let filtered = _instruments?.filter{ $0.sm_title.lowercased().range(of: searchText) != nil }
            instruments = filtered
        } else {
            instruments = _instruments
        }
        tableView.reloadData()
    }
}
