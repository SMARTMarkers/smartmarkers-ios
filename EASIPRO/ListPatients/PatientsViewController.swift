//
//  PatientsViewController.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 15/02/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART



class SearchList : PatientList {
	
	public init(_ searchQuery: Any) {
		let search = FHIRSearch(query: searchQuery)
		search.pageCount = 50
		super.init(query: PatientListQuery(search: search))
	}
	
}




class EPPatientListViewController : PatientListViewController {
	
	let appointmentList : PatientList
	
	let searchController = UISearchController(searchResultsController: nil)
	
	unowned let server = SMARTManager.shared.client.server
	
	let todayDate: String = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "YYYY-MM-dd"
		return dateFormatter.string(from: Date())
	}()
	
	
	override init(list: PatientList, server srv: Server) {
		
		self.appointmentList = PatientList(query: PatientListQuery(search: FHIRSearch(query:
			["_has:Appointment:patient:date"		: todayDate])))
		
		super.init(list: list, server: srv)
		title = "Select Patient"

	}

	convenience init(server: Server) {
		
		self.init(list: PatientListAll(), server: server)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		searchController.searchResultsUpdater = self
		searchController.searchBar.placeholder = "Search Patients"
		searchController.dimsBackgroundDuringPresentation = false
		searchController.delegate = self
		searchController.searchBar.showsSearchResultsButton = true
		searchController.searchBar.showsBookmarkButton = true
		searchController.hidesNavigationBarDuringPresentation     = false
		searchController.searchBar.delegate = self
		searchController.searchBar.scopeButtonTitles = ["Patient Name", "MR Number"]
		let appointmentsItem = UIBarButtonItem(title: "Appointments", style: .plain, target: self, action: #selector(searchTodayAppointments(_:)))
		let allPatientsItem = UIBarButtonItem(title: "All-Patients", style: .plain, target: self, action: #selector(allPatientsSearch(_:)))
		navigationItem.rightBarButtonItems = [allPatientsItem, appointmentsItem]
		navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
		definesPresentationContext = false

		
	}
	
	@objc
	func searchTodayAppointments(_ sender: Any?) {
		
		let appointmentSearch = Appointment.search(["date" : todayDate])
		appointmentSearch.perform(server) { [weak self] (bundle, error) in
			if error == nil {
				let date = self?.todayDate
				let appointments = bundle?.entry?.filter {$0.resource is Appointment }.map{$0.resource as! Appointment}
					let fhirIds = appointments?.flatMap { $0.ep_patientReferences() }.flatMap { $0 }
					if let fhirIds = fhirIds {
						let searchparam = fhirIds.joined(separator: ",")
						let search = FHIRSearch(query: ["_id" : searchparam])
						let patientQuery = PatientListQuery(search: search)
						let pList = PatientList(query: patientQuery)
						DispatchQueue.main.async {
							self?.selectList(list: pList)
							self?.title = "Appointments on \(String(describing: date!))"
						}
					}
				else {
					// No Appointments with Patients today
						let alertController = UIAlertController(title: "No Appointments", message: "No Appointments with patients on \(String(describing: date!))", preferredStyle: UIAlertControllerStyle.alert)
						alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
						self?.present(alertController, animated: true, completion: nil)
					
				}
				
			}
		}
	}
	
	
	
	
	
	@objc
	func allPatientsSearch(_ sender: Any?) {
		selectList(list: PatientListAll())
	}
	
	override open func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
		searchController.isActive = false
		super.dismiss(animated: flag)
	}
	
	func selectList(list: PatientList) {
		print("Number of patients: ", list.actualNumberOfPatients)
		patientList = list
		if 0 == patientList?.actualNumberOfPatients {
			patientList?.retrieve(fromServer: server)
		}
	}
	
	
	
}

extension EPPatientListViewController : UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
	
	public func willDismissSearchController(_ searchController: UISearchController) {
	}
	
	func updateSearchResults(for searchController: UISearchController) {
	}
	
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		
		guard let searchText = searchBar.text else {
			return
		}
		self.title = "Select Patients"
		
		if searchBar.selectedScopeButtonIndex == 0 {
			selectList(list: SearchList(["name" : ["$contains" : searchText]]))
		}
		else {
			selectList(list: SearchList(["identifier" : searchText]))
		}
	}
	
	func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
	}
	
	
	func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
		searchBar.placeholder = (selectedScope == 0) ? "Search by Patient Name" : "Search by MR Number"
	}
	
	
	
	
	
	
	
	
}
/*
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
*/
