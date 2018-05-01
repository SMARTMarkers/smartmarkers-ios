//
//  PROMeasureViewController.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 01/05/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import UIKit

open class PROMeasureViewController: UITableViewController {

	/// PROMeasures
	open var _measures : [PROMeasure2]? {
		didSet { measures = _measures }
	}
	
	open var measures : [PROMeasure2]?
	
	open var selections = [String]()
	
	open var onSelection: (([PROMeasure2]?) ->Void)?
	
	
	
	override open func viewDidLoad() {
        super.viewDidLoad()
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSelf(_:)))
		loadMeasures()
    }
	
	open func loadMeasures() {
		if nil != measures { return }
		markBusy()
		PROMeasure2.fetchPrescribingResources { [weak self] (measures, error) in
			if let m = measures {
				self?.measures = m
			}
			if let error = error {
				print(error as Any)
			}
			DispatchQueue.main.async {
				self?.markStandby()
			}
		}
		
	}
	
	open func markBusy() {
		self.title = "Loading.."
	}
	
	
	open func markStandby() {
		self.title = "PRO-Measures"
		self.tableView.reloadData()
	}
	
	@objc func dismissSelf(_ sender: Any)  {
		dismiss(animated: true, completion: nil)
	}

    // MARK: - Table view data source

    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return measures?.count ?? 0
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
		let str = """
				\(measure.identifier) || \(String(describing: measure.schedule?.currentSlotIndex)) || \(measure.schedule?.instant)
				"""
		cell?.textLabel?.text = measure.title
		cell?.detailTextLabel?.text = str
        return cell!
    }
	
	override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let measure = measures![indexPath.row]
		
		let res = measure.results?.map{ $0.valueString!.string }.joined(separator: ", ")
		let alert = UIAlertController(title: measure.title, message: res ?? "msg" , preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
		present(alert, animated: true, completion: nil)
		
	}
}
