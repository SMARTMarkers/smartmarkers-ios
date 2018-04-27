//
//  InsightsController.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 24/04/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import UIKit
import SMART


open class InsightsController: UITableViewController {

	var sortedObservations : [[Observation]]?

	
	override open func viewDidLoad() {
        super.viewDidLoad()
		self.title = "PROM Insights"
		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(fetchObservations))
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
		tableView.separatorStyle = .none
		tableView.allowsSelection = false
		fetchObservations()
    }
	
	@objc func done(_ sender: Any?) {
		dismiss(animated: true, completion: nil)
	}
	
	@objc
	func fetchObservations() {
		// TODO: Simplify Extraction. It is kept so for debugging purposes.
		// sortedObservations need not have `Observation` if not required in its entirety.
		sortedObservations?.removeAll()
		SMARTManager.shared.getObservations { [unowned self] (requests, error) in
			
			guard let requests = requests else {
				if error != nil {
					print(error.debugDescription)
				}
				return
			}
	
			let crossReference = requests.reduce(into: [String: [Observation]]()) {
				$0[$1.code!.coding!.first!.code!.string, default: []].append($1)
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
	}

	override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

	override open func numberOfSections(in tableView: UITableView) -> Int {
        return (sortedObservations?.count) ?? 0
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
		// TODO: simply this.
		let obss = sortedObservations![indexPath.section]
		let lastestObservation = obss.last!
		let title = lastestObservation.code!.text!.string
		let scores = obss.map { Double($0.valueString!.string)! }
		let graphView = cell?.viewWithTag(10) as? LineGraphView
		graphView?.title = title
        graphView?.subtitle  = "MOST RECENT RECORDED SCORE: \(lastestObservation.valueString!.string)"
		graphView?.graphPoints = scores
		

        return cell!
    }
	
	override open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.preservesSuperviewLayoutMargins = false
		cell.layoutMargins = UIEdgeInsetsMake(0, 100, 0, 100)
	}
	
	override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 400
	}
	

}
