import Foundation
import UserNotifications

@MainActor
final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    @Published var isAuthorized = false

    override private init() {
        super.init()
    }

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            if granted {
                scheduleWeeklyReminder()
            }
        } catch {}
    }

    // MARK: - Local Notifications
    func scheduleNewRecommendationNotification() {
        let content = UNMutableNotificationContent()
        content.title = "FlickMatch"
        content.body = "عندك توصيات جديدة! شوف وش ممكن يعجبك 🍿"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "new_recommendation", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleFollowNotification(followerName: String) {
        let content = UNMutableNotificationContent()
        content.title = "FlickMatch"
        content.body = "\(followerName) بدأ يتابعك! 🎬"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "new_follow_\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleWeeklyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "FlickMatch"
        content.body = "قيّم أفلام جديدة وحسّن توصياتك! ⭐"
        content.sound = .default

        // Every Sunday at 8 PM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1
        dateComponents.hour = 20
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
