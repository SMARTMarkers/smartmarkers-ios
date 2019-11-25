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
    
    /**
     Designated Initializer
     */
    public required init(_ qr: QuestionnaireResponse) {
        questionnaireResponse = qr
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
        return (section == 0) ? (questionnaireResponse.item?.count ?? 0) : 1
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
        
        let item = questionnaireResponse.item![indexPath.row]
        let (question, answer) = item.sm_QuestionAndAnswer()
        cell?.textLabel?.text = answer
        cell?.detailTextLabel?.text = question
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

// MARK - Parse QuestionnaireResponse.item to get answers and question strings

extension QuestionnaireResponseItem {
    
    func sm_QuestionAndAnswer() -> (String, String) {
        var questionAnswerTuple = (text?.string ?? String(),String())
        questionAnswerTuple = item?.reduce(into: questionAnswerTuple, { (tup, itm) in
            tup.0.append(contentsOf: (itm.text != nil) ? "- \(itm.text!.string)" : "")
            let answer = self.sm_getAnswer(itm.answer)
            tup.1.append(contentsOf: answer)
        }) ?? ("", "")
        return questionAnswerTuple
        
    }
    
    func sm_getAnswer(_ answer: [QuestionnaireResponseItemAnswer]?) -> String {
        guard let answer = answer else { return "" }
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
        return answerStrings.joined(separator: " + ")
    }
    
}
