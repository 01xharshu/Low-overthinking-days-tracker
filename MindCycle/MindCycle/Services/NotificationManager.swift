// NotificationManager.swift
// MindCycle
//
// Manages local notifications to remind users when a predicted low window is approaching.

import Foundation
import UserNotifications

/// Handles scheduling and managing local notifications for predicted low windows.
@Observable
final class NotificationManager {
    
    var isAuthorized = false
    var notificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "notificationsEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "notificationsEnabled")
            if newValue {
                requestAuthorization()
            } else {
                removeAllPending()
            }
        }
    }
    
    /// Days before predicted window to send the notification.
    var reminderDaysBefore: Int {
        get { UserDefaults.standard.integer(forKey: "reminderDaysBefore").clamped(to: 1...7) }
        set { UserDefaults.standard.set(newValue, forKey: "reminderDaysBefore") }
    }
    
    init() {
        // Default reminder days if not set
        if UserDefaults.standard.object(forKey: "reminderDaysBefore") == nil {
            UserDefaults.standard.set(2, forKey: "reminderDaysBefore")
        }
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if let error {
                    print("Notification authorization error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Scheduling
    
    /// Schedule a notification for an upcoming predicted low window.
    func scheduleNotification(for prediction: PredictionResult) {
        guard notificationsEnabled, isAuthorized else { return }
        
        // Remove old pending notifications first
        removeAllPending()
        
        let calendar = Calendar.current
        guard let notifyDate = calendar.date(
            byAdding: .day,
            value: -reminderDaysBefore,
            to: prediction.startDate
        ) else { return }
        
        // Only schedule if the notification date is in the future
        guard notifyDate > .now else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "MindCycle – Heads Up 💙"
        content.body = "A low window may be approaching around \(prediction.formattedWindow). Remember your coping strategies and be gentle with yourself."
        content.sound = .default
        content.categoryIdentifier = "LOW_WINDOW_APPROACHING"
        
        // Schedule for 9:00 AM on the notify date
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: notifyDate)
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "mindcycle.prediction.\(prediction.startDate.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Cleanup
    
    func removeAllPending() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - Comparable Helpers

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
