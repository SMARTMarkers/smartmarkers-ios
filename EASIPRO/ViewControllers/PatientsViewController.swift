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
                let fhirIds = appointments?.compactMap { $0.ep_patientReferences() }.flatMap { $0 }
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
                        let alertController = UIAlertController(title: "No Appointments", message: "No Appointments with patients on \(String(describing: date!))", preferredStyle: UIAlertController.Style.alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
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
