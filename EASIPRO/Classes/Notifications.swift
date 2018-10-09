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

let currentCenter = UNUserNotificationCenter.current()
let options : UNAuthorizationOptions = [.badge, .alert, .sound]
let kPRODueNotificationCategory = "DUEPRO"


public class PRONotifications: NSObject {
    

    
    public class func requestAuthorization(_ callback: @escaping (_ success: Bool) -> Void) {
        
        
        currentCenter.requestAuthorization(options: options) { (success, error) in
            if !success {
                callback(false)
            }
            else {
                let hiddenPreviewsPlaceholder = "%u PRO is due now"
                let proCategory = UNNotificationCategory(identifier: kPRODueNotificationCategory, actions: [], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: hiddenPreviewsPlaceholder, options: [])
                currentCenter.setNotificationCategories([proCategory])
                callback(true)
            }
        }
    }
    
    public class func getSettings(_ callback: @escaping (_ settings: UNNotificationSettings?) -> Void) {
        currentCenter.getNotificationSettings { (settings) in
            print(settings)
        }
        
        currentCenter.getNotificationCategories { (categories) in
            print(categories)
        }
        
        currentCenter.getPendingNotificationRequests { (pendings) in
            print(pendings)
        }
        
    }
    
    
    public class func dispatchNotification(title: String, msg: String) {
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = msg
        content.sound = UNNotificationSound.default()
        
        
    }
    
    
    public class func createNotifications(for request: PrescribingResource_Protocol, callback: ((_ success: Bool) -> Void)?)  {
        
        guard let slots = request.getSchedule()?.slots else {
            callback?(false)
            return
        }
        
        currentCenter.requestAuthorization(options: options) { (success, error) in
            if !success {
                callback?(false)
            }
            else {
                
                let content = UNMutableNotificationContent()
                content.title = "Survey Session Due"
                content.subtitle = request.pro_title!
                content.body = "A PRO Session is due today"
                content.sound = UNNotificationSound.default()
                content.categoryIdentifier = kPRODueNotificationCategory
                content.threadIdentifier = request.pro_identifier!
                let availableSlots = slots.filter({ $0.hasPassed == false })
                let notificationRequests = availableSlots.map({ (slot) -> UNNotificationRequest in
                    let date = slot.period.start
                    let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second], from: date)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                    return UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                })
                
                
                for nreq in notificationRequests {
                    
                    currentCenter.add(nreq, withCompletionHandler: { (error) in
                        if let error = error { print(error as Any); callback?(false) }
                        callback?(true)
                    })
                    
                    
                }
            }
        }
                

                /*
                let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: date)
                
                
                let date = Date(timeIntervalSinceNow: 10)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
//                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)

                
                let identifier = requestId!
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                currentCenter.add(request, withCompletionHandler: { (error) in
                    if let error = error {
                        // Something went wrong
                        callback?(false)
                    }
                    else {
                        callback?(true)
                    }
                })
                
                callback?(true)
            }
 */
        
        
        
        
        
        
        
        
        
    }
    
    
    

}

extension PRONotifications : UNUserNotificationCenterDelegate {
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        
    }
    
}
