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
			
			print(self.sortedObservations!.count)
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
        return 1
    }

	override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		
		return (sortedObservations?.count) ?? 0

    }

	
	override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		let cellIdentifier = "InsightsCell"
		var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
		if cell == nil {
			cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
			cell?.accessoryType = .detailButton
			cell?.textLabel?.numberOfLines = 2
			cell?.textLabel?.lineBreakMode = .byWordWrapping
			let graphView = LineGraphView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
			graphView.tag = 10
			cell?.contentView.addSubview(graphView)
		}
		
		let obss = sortedObservations![indexPath.item]
		let lastestObservation = obss.last!
		let title = lastestObservation.code!.text!.string
		let scores = obss.map { Double($0.valueString!.string)! }

		let graphView = cell?.viewWithTag(10) as? LineGraphView
		graphView?.graphPoints = scores
		graphView?.title = title
		
		cell?.textLabel?.text = "HEYA"

        return cell!
    }
	
	override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 300
	}
	
	
	override open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.preservesSuperviewLayoutMargins = false
		cell.layoutMargins = UIEdgeInsetsMake(0, 100, 0, 100)
		cell.separatorInset = UIEdgeInsetsMake(0, 100, 0, 100)
	}

}
