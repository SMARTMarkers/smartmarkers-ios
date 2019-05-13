//
//  Notifications.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 10/1/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import UIKit
import UserNotifications
import SwiftFHIR

let kPRODueNotificationCategory = "DUE_PRO"


public class PRONotification: NSObject {
    
    public static let shared = PRONotification()
    
    override public init() {
        super.init()

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
            print(settings)
        }
        
        UNUserNotificationCenter.current().getNotificationCategories { (categories) in
            print(categories)
        }
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { (pendings) in
            print(pendings)
        }
        
    }
    
    
    public class func dispatchNotification(title: String, msg: String) {
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = msg
        content.sound = UNNotificationSound.default
        
        
    }
    

    
    
    public class func createNotifications(for request: RequestProtocol, callback: ((_ success: Bool) -> Void)?)  {
        
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
                let availableSlots = slots.filter({ $0.hasPassed == false })
                let notificationRequests = availableSlots.map({ (slot) -> UNNotificationRequest in
                    let date = slot.period.start
                    let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second], from: date)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                    return UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                })
                
                notificationRequests.forEach({ (req) in
                    UNUserNotificationCenter.current().add(req, withCompletionHandler: { (error) in
                        if let error = error { print(error as Any); callback?(false) }
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
            if let error = error { print(error as Any) }
        })

    }
    
    class func registerActionsForCategoryDuePRO() {
        
        let startAction = UNNotificationAction(identifier: "START_SURVEY", title: "Start", options: [.foreground,.authenticationRequired])
        let duePROCategory = UNNotificationCategory(identifier: kPRODueNotificationCategory, actions: [startAction], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "%u PRO is due now", options: .customDismissAction)
        UNUserNotificationCenter.current().setNotificationCategories([duePROCategory])
        
        
    }
    
    
    

}

extension PRONotification : UNUserNotificationCenterDelegate {
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        
        
        completionHandler()
    }
    
}
