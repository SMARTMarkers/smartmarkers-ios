//
//  InsightsController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 24/04/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import UIKit
import SMART


open class InsightsController: UITableViewController {
    
    public var pdControllers: [PDController]?
	
	override open func viewDidLoad() {
        super.viewDidLoad()
		self.title = "PRO Insights"
		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(fetchObservations))
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
		tableView.separatorStyle = .none
		tableView.allowsSelection = false

    }
	
	@objc func done(_ sender: Any?) {
		dismiss(animated: true, completion: nil)
	}
	
	@objc
	func fetchObservations() {
		
	}

	override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

	override open func numberOfSections(in tableView: UITableView) -> Int {
        return (pdControllers?.count) ?? 0
    }

	override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		
		return 1

    }
	
	override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		
		return nil

	}

	
	override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		let cellIdentifier = "InsightsCell"
		var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
		if cell == nil {
			
			cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
			let graphView = LineGraphView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
			graphView.tag = 10
			graphView.translatesAutoresizingMaskIntoConstraints = false
			cell?.contentView.addSubview(graphView)
			cell?.backgroundColor = tableView.backgroundColor
			cell?.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[gv]-|", options: [], metrics: nil, views: ["gv": graphView]))
			cell?.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[gv]-|", options: [], metrics: nil, views: ["gv": graphView]))

		}
        
        let controller = pdControllers![indexPath.section]
        let graphView = cell?.viewWithTag(10) as? LineGraphView
        let recent = controller.reports?.reports.last?.rp_observation
        graphView?.title = controller.instrument?.sm_title
        graphView?.subtitle  = "MOST RECENT RECORDED SCORE: \(recent ?? "-")"
        if let scores = controller.reports?.reports.filter({ $0.rp_observation != nil }).map({ Double($0.rp_observation!)! }) {
            graphView?.graphPoints = scores
        }
        

        


        
		// TODO: simply this.
//        let obss = sortedObservations![indexPath.section]
//        let lastestObservation = obss.last!
//        let title = lastestObservation.code!.text!.string
//        let scores = obss.map { Double($0.valueString!.string)! }

//        graphView?.graphPoints = scores
		

        return cell!
    }
	
	override open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.preservesSuperviewLayoutMargins = false
	}
	
	override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 400
	}
	

}


/* LEGACY
 
 sortedObservations?.removeAll()
 
 SMARTManager.shared.getObservations { [unowned self] (requests, error) in
 
 guard let requests = requests else {
 if error != nil {
 print(error.debugDescription)
 }
 return
 }
 
 let crossReference = requests.reduce(into: [String: [Observation]]()) {
 if let loincCoding = $1.code?.sm_coding(for: "http://loinc.org"), let code = loincCoding.code {
 $0[code.string, default: []].append($1)
 }
 else {
 $0[$1.code!.coding!.first!.code!.string, default: []].append($1)
 }
 }
 
 var list = [[Observation]]()
 for (_,v) in crossReference {
 list.append(v.sorted { $0.effectiveDateTime!.nsDate < $1.effectiveDateTime!.nsDate })
 }
 self.sortedObservations = list
 
 DispatchQueue.main.sync {
 self.tableView.reloadData()
 }
 }
 */
