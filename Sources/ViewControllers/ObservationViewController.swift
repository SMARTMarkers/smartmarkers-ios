//
//  ObservationViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 3/18/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

open class ObservationViewController: UITableViewController {
    
    public var observation: Observation!
    
    public var attachments: [SMImageAttachemnt]?
    
    public var scrollView: UIScrollView!
    
    public var pageControl: UIPageControl!
    
    public required convenience init(_ _observation: Observation) {
        self.init(style: .grouped)
        observation = _observation
        configure()
    }
    
    override open func viewDidLoad() {
        title = "Observation \(observation.id?.string ?? "")"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSelf))
        self.scrollView = UIScrollView(frame: CGRect(x:0, y:0, width:self.view.frame.width, height:400))
        let scrollViewWidth:CGFloat = self.scrollView.frame.width
        let scrollViewHeight:CGFloat = self.scrollView.frame.height
        
		if let attachements = attachments {
			for (i, attach) in attachements.enumerated() {
				let view = UIImageView(image: attach.image)
				view.frame = CGRect(x: CGFloat(i) * scrollViewWidth, y:0,width:scrollViewWidth, height:scrollViewHeight)
				view.contentMode = .scaleAspectFit
				self.scrollView.addSubview(view)
			}
			self.scrollView.contentSize = CGSize(width:self.scrollView.frame.width * CGFloat(attachements.count), height:self.scrollView.frame.height)
			self.scrollView.isPagingEnabled = true
			self.pageControl = UIPageControl()
			self.pageControl.numberOfPages = attachements.count
			self.pageControl.currentPage = 0
			self.scrollView.addSubview(pageControl)
			self.scrollView.delegate = self
			self.tableView.tableHeaderView = scrollView
			self.scrollView.setNeedsDisplay()
		}
        
    }
    
    @objc
    func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    func configure() {
        if let components = observation.component {
//            self.attachments = components.compactMap({ $0.sm_ImageAttachment() })
        }
    }
    
    
    override open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            // Test the offset and calculate the current page after scrolling ends
            let pageWidth:CGFloat = scrollView.frame.width
            let currentPage:CGFloat = floor((scrollView.contentOffset.x-pageWidth/2)/pageWidth)+1
            self.pageControl.currentPage = Int(currentPage);
    }
    
    
    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Date: \(observation.effectiveDateTime?.nsDate.shortDate ?? "-") "
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "OCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .value2, reuseIdentifier: cellIdentifier)
        }
        
        let c : String
        let v : String
        switch indexPath.row {
        case 0:
            let category = observation.category?.first?.coding?.first
            c = "Category"
            v = (category != nil) ? "\(category!.code!.string) | \(category!.system!.absoluteString)" : "-"
            break
        case 1:
            let code = observation.code?.coding?.first
            c = "Code"
            v = (code != nil) ? "\(code!.code!.string) | \(code!.system!.absoluteString)" : "-"
            break
        default:
            c = ""
            v = ""
            break
        }
   
        cell?.textLabel?.text = c
        cell?.detailTextLabel?.text = v

        return cell!
    }
        
        

    
}


public struct SMImageAttachemnt {
    
    var image: UIImage
    
    var title: String?
    
    var date: Date?
    
}





