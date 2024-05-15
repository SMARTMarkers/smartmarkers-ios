//
//  Notifications.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 10/1/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import UIKit
import UserNotifications
import SMART



public struct NotificationMessage {
    
    let title: String
    let message: String
    let action: Any?
}
/*
- Frequency
- Period (staring ... end after 6months)
-
*/

public enum NotificationFrequency {
    case daily
    case weekly
    case monthly
}

public class TaskNotification  {
    
    public static let shared = TaskNotification()
    public weak var manager: StudyManger?
    static let category = "DueStudyTask"
    public let center = UNUserNotificationCenter.current()
    
    public func ready(callback: @escaping (_ error: Error?) -> Void) {
        let options : UNAuthorizationOptions = [.badge, .alert, .sound]
        center.requestAuthorization(options: options) { (success, error) in
            callback(error)
        }
    }
    
    
    open func DueTask(_ task: StudyTask, callback: ((_ error: Error?) -> Void)? = nil) {
        var dateInfo = DateComponents()
        dateInfo.hour = 11
        dateInfo.minute = 30
        dateInfo.weekday = 1
        dateInfo.timeZone = .autoupdatingCurrent
        let weeklyTrigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: true)
        TaskNotification.shared.set(for: task , trigger: weeklyTrigger)
        #if DEBUG
        let threeHourly = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(60 * 60 * 3), repeats: true)
        TaskNotification.shared.set(for: task, trigger: threeHourly)
        #endif
    }
    
   
    private func set(for task: StudyTask, trigger: UNNotificationTrigger, callback: ((_ error: Error?) -> Void)? = nil) {

        ready { [self] error in
            
            if nil == error {
                
                let body = """
                Please complete the task to conclude your participation in \(manager?.study.name ?? "the study").
                """
                let con = content(due: task, body: body)
                
                
                let request = UNNotificationRequest(
                    identifier: task.id,
                    content: con,
                    trigger: trigger
                )

                // Schedule the request with the system.
                center.add(request) { (error) in
                    
                    if let e = error {
                        smLog(e.localizedDescription)
                    }
                    smLog("[NOTIFICATION] Notification set for task: \(task.id), trigged on: \(trigger.description)")
                    callback?(error)
                }
            }
        }
    }
    
    /// Removes all notifications, both delivered and pending
    func removeAllNotifications() {
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
    }

    
    func content(due task: StudyTask, body: String) -> UNMutableNotificationContent {
        
        let content = UNMutableNotificationContent()
        let msg = task.title != nil ? "Task is due: \"\(task.title!)\"" : "Study task is due"
        
        content.title = msg
        content.body = body
        content.sound = .default
        content.categoryIdentifier = Self.category
        return content
    }
    
    
    public func dispatchNotificationForIncompleteSubmission() {
        let content = UNMutableNotificationContent()
        content.title = "Some data could not be sent"
        content.body = "Please relaunch the app to complete the data submission process.\nThank you"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger.init(
            timeInterval: 5,
            repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "pending_submission",
            content: content,
            trigger: trigger
        )
        
        ready { (error) in
            if nil == error {
                self.center.add(request) { (e) in
                    smLog("[NOTIFICATIONS]: DISPATCHED REQUEST \(request.description)")
                }
            }
        }
    }
}







let kPRODueNotificationCategory = "DUE_PRO"

public class PRONotification: NSObject {
    
    public static let shared = PRONotification()
    
    override public init() {
        super.init()
    }
	
	

	public class func requestAuthorization2(_ task: TaskController, callback: @escaping (_ success: Bool) -> Void) {
		
		let options : UNAuthorizationOptions = [.badge, .alert, .sound]
		UNUserNotificationCenter.current().requestAuthorization(options: options) { (success, error) in
			if !success {
				callback(false)
			}
			else {
				scheduleNotification(task: task)
				callback(true)
			}
		}
	}
	

    public class func requestAuthorization(_ callback: @escaping (_ success: Bool) -> Void) {
        
        let options : UNAuthorizationOptions = [.badge, .alert, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (success, error) in
            if !success {
                callback(false)
            }
            else {
                registerActionsForCategoryDuePRO()
                callback(true)
            }
        }
    }
    
    public func getSettings(_ callback: @escaping (_ settings: UNNotificationSettings?) -> Void) {
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            smLog(settings)
        }
        
        UNUserNotificationCenter.current().getNotificationCategories { (categories) in
            smLog(categories)
        }
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { (pendings) in
            smLog(pendings)
        }
        
    }
    
    
    public class func dispatchNotification(title: String, msg: String) {
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = msg
        content.sound = UNNotificationSound.default
    }
    

	
    
    
    public class func createNotifications(for request: Request, callback: ((_ success: Bool) -> Void)?)  {
        
        guard let slots = request.rq_schedule?.slots else {
            callback?(false)
            return
        }
        
        requestAuthorization { (success) in
            if success {
                let content = UNMutableNotificationContent()
                content.title = "Survey Session Due"
                content.subtitle = request.rq_title!
                content.body = "A PRO Session is due today"
                content.sound = UNNotificationSound.default
                content.categoryIdentifier = kPRODueNotificationCategory
                content.threadIdentifier = request.rq_identifier
                let availableSlots = slots.filter({ $0.timeStatus == .Past })
                let notificationRequests = availableSlots.map({ (slot) -> UNNotificationRequest in
                    let date = slot.period.start
                    let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second], from: date)
					
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                    return UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                })
                
                notificationRequests.forEach({ (req) in
                    UNUserNotificationCenter.current().add(req, withCompletionHandler: { (error) in
                        if let error = error { smLog(error as Any); callback?(false) }
                        callback?(true)
                    })
                })
                
                demoNotification(id: UUID().uuidString, content: content)
            }
        }
    }
    
    
    class func demoNotification(id: String, content: UNNotificationContent) {

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            if let error = error { smLog(error as Any) }
        })

    }
    
	class func registerActionsForCategoryDuePRO() {
        
        let startAction = UNNotificationAction(
			identifier: "START_SURVEY",
			title: "Start",
			options: [.foreground,.authenticationRequired]
		)
		
        let duePROCategory = UNNotificationCategory(identifier: kPRODueNotificationCategory, actions: [startAction], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "%u PRO is due now", options: .customDismissAction)
        UNUserNotificationCenter.current().setNotificationCategories([duePROCategory])
        
        
    }
    
    
	class func scheduleNotification(task: TaskController) {
	  // 2
	  let content = UNMutableNotificationContent()
		content.title = task.instrument!.sm_title
	  content.body = "Gentle reminder for your task!"

	  // 3
	  var trigger: UNNotificationTrigger?
		switch task.instrument!.sm_type {
		case .Survey:
				trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(integerLiteral: 60), repeats: true)
	  default:
		return
	  }

	  // 4
	  if let trigger = trigger {
		let request = UNNotificationRequest(
			identifier: "133",
		  content: content,
		  trigger: trigger)
		// 5
		UNUserNotificationCenter.current().add(request) { error in
		  if let error = error {
			smLog(error)
		  }
		}
	  }
	}

}

extension PRONotification : UNUserNotificationCenterDelegate {
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
}
