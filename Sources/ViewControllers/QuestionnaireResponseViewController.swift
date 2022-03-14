//
//  QuestionnaireResponseViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 22/02/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

open class QuestionnaireResponseViewController: UITableViewController {
    
    public let questionnaireResponse: QuestionnaireResponse!
		
	private let items: [QuestionnaireResponseItem]?
	
    /**
	Designated Initializer
	
	- parameter response: `QuestionnaireResponse`
	- parameter questionnaire: `Questionnaire`
	*/
	public required init(_ response: QuestionnaireResponse) {
        questionnaireResponse = response
		items = response.sm_allItems()?.filter({ $0.item == nil })
		if #available(iOS 13.0, *) {
			super.init(style: .insetGrouped)
		}
		else {
			super.init(style: .grouped)
		}
		
		if let qtitle = questionnaireResponse.rp_title {
			title = qtitle
		}
		else
		if let date = questionnaireResponse.authored?.nsDate.shortDate {
			title = "Completed on " + date
		}
		
    }
    
	required public init?(coder aDecoder: NSCoder) {
        fatalError("a coder not implemented")
    }
    
    override open func viewDidLoad() {

		if #available(iOS 13.0, *) {
			if self.isModalInPresentation {
				navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSelf))
			}
		}
//		else {
//			// Fallback on earlier versions
//		}
		
	}
    
    @objc
    open func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    // MARK: - Table view data source
    
    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (section == 0) ? (items?.count ?? 0) : 1
    }
    
    override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return (section == 0) ? "Questions & Answers" : ""
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        
        let item = items![indexPath.row]
        let (question, answer) = item.sm_QuestionAndAnswer()
        cell?.textLabel?.text = answer
        cell?.detailTextLabel?.text = question
		cell?.accessoryType = (answer == "") ? .none : .checkmark
        return cell!
    }
    
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            show(FHIRViewController(questionnaireResponse), sender: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    
    
}



// MARK - Parse QuestionnaireResponse.item to get answers and question strings

public extension QuestionnaireResponseItem {
    
    func sm_QuestionAndAnswer() -> (String, String) {
		var questionAnswerTuple = (text?.string ?? String(), sm_getAnswer(answer))
		
        questionAnswerTuple = item?.reduce(into: questionAnswerTuple, { (tup, itm) in
			
            tup.0.append(contentsOf: (itm.text != nil) ? "- \(itm.text!.string)" : "")
            let answer = self.sm_getAnswer(itm.answer)
            tup.1.append(contentsOf: answer)
		}) ?? (text?.string ?? String(), sm_getAnswer(answer) )
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
			if let valueBool = itemAnswer.valueBoolean {
				answerStrings.append(valueBool.description)
			}
			if let valueInteger = itemAnswer.valueInteger {
				answerStrings.append(String(valueInteger))
			}
			if let valueDate = itemAnswer.valueDate {
				answerStrings.append(valueDate.nsDate.shortDate)
			}
			if let valueDateTime = itemAnswer.valueDateTime {
				answerStrings.append(valueDateTime.description)
			}
			
        })
        return answerStrings.joined(separator: " + ")
    }
    
}
