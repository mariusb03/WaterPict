//
//  NotificationManager.swift
//  WaterPict
//
//  Created by Marius Bringsvor Rusten on 08/01/2025.
//


import UserNotifications
import Foundation

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {} // Make the initializer private to enforce singleton usage

    // Request notification permission
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error requesting notification permission: \(error.localizedDescription)")
                }
                completion(granted)
            }
        }
    }

    // Schedule notifications
    func scheduleNotifications(startHour: Int, endHour: Int, interval: Int) {
        let center = UNUserNotificationCenter.current()

        // Remove all existing notifications
        center.removeAllPendingNotificationRequests()

        let calendar = Calendar.current

        for hour in stride(from: startHour, to: endHour, by: interval) {
            let content = UNMutableNotificationContent()
            content.sound = .default

            // First notification of the day
            if hour == startHour {
                content.title = "Good Morning! 🌅"
                content.body = "Drink some water to start the day right! 💦"
            }
            // Last notification of the day
            else if hour + interval >= endHour {
                content.title = "Reminder! 🌙"
                content.body = "Drink some water before bed! 💦"
            }
            // Regular notifications
            else {
                content.title = "Stay Hydrated! 💧"
                content.body = "Don't forget to drink water! 💦"
            }

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let identifier = "WaterNotification-\(hour)"

            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            center.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
        }
    }
}