//
//  QuestionnaireResponseViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 22/02/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

public class QuestionnaireResponseViewController: UITableViewController {
    
    public var questionnaireResponse: QuestionnaireResponse!
    
    private var qrItems: [QuestionnaireResponseItem]!
    
    public required convenience init(_ qr: QuestionnaireResponse) {
        self.init(style: .grouped)
        questionnaireResponse = qr
        qrItems = qr.item
    }
    
    override public func viewDidLoad() {
        if let date = questionnaireResponse.authored?.nsDate.shortDate {
            title = "Completed on " + date
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSelf))
    }
    
    @objc
    func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    // MARK: - Table view data source
    
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (section == 0) ? qrItems.count : 1
    }
    
    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return (section == 0) ? "Questions & Answers" : ""
    }
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "SCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
            cell?.textLabel?.numberOfLines = 2
            cell?.textLabel?.lineBreakMode = .byWordWrapping
            cell?.detailTextLabel?.numberOfLines = 0
            cell?.detailTextLabel?.textColor = UIColor.gray
        }
        
        if indexPath.section == 1 {
            cell?.accessoryType = .disclosureIndicator
            cell?.textLabel?.text = "FHIR Resource"
            cell?.detailTextLabel?.text = ""
            return cell!
        }
        
        
        
        if let answer = qrItems[indexPath.row].answer {
            var answerStrings = [String]()
            answer.forEach({ (itemAnswer) in
                if let valueCoding = itemAnswer.valueCoding {
                    let displayString = valueCoding.display?.string ?? valueCoding.code!.string
                    answerStrings.append(displayString)
                }
                if let valueString = itemAnswer.valueString {
                    answerStrings.append(valueString.string)
                }
            })
            cell?.textLabel?.text = answerStrings.joined(separator: " + ")
        }
        
        cell?.detailTextLabel?.text = qrItems[indexPath.row].text?.string
        cell?.accessoryType = .checkmark
        return cell!
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            show(FHIRViewController(questionnaireResponse), sender: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
