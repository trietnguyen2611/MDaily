import Foundation
import UserNotifications

public final class NotificationService: @unchecked Sendable {
    public static let shared = NotificationService()

    private init() {}

    // MARK: - Request Permission
    public func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    public func checkPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Schedule Recurring Expense Notification
    public func scheduleRecurringNotification(for recurring: RecurringExpense, currencySymbol: String, isEnglish: Bool) {
        let center = UNUserNotificationCenter.current()

        // Remove existing notifications for this recurring expense
        let identifier = "recurring_\(recurring.id.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard recurring.isActive, recurring.repeatInterval != .none else { return }

        let content = UNMutableNotificationContent()

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        let amountStr = "\(formatter.string(from: NSNumber(value: Int(recurring.amount))) ?? "\(Int(recurring.amount))") \(currencySymbol)"

        let noteName = recurring.note ?? (isEnglish ? "Payment" : "Thanh toán")

        content.title = isEnglish ? "💰 Payment Reminder" : "💰 Nhắc thanh toán"
        content.body = isEnglish
            ? "\(noteName): \(amountStr) is due today."
            : "\(noteName): \(amountStr) đến hạn thanh toán hôm nay."
        content.sound = .default
        content.categoryIdentifier = "RECURRING_EXPENSE"
        
        var userInfo: [String: Any] = ["recurringId": recurring.id.uuidString]
        if let expenseId = recurring.linkedExpenseId {
            userInfo["linkedExpenseId"] = expenseId.uuidString
        }
        content.userInfo = userInfo

        // Build trigger based on repeat interval
        let calendar = Calendar.current
        let dateComponents: DateComponents

        switch recurring.repeatInterval {
        case .daily:
            dateComponents = calendar.dateComponents([.hour, .minute], from: recurring.reminderDate)
        case .weekly:
            dateComponents = calendar.dateComponents([.weekday, .hour, .minute], from: recurring.reminderDate)
        case .monthly:
            dateComponents = calendar.dateComponents([.day, .hour, .minute], from: recurring.reminderDate)
        case .yearly:
            dateComponents = calendar.dateComponents([.month, .day, .hour, .minute], from: recurring.reminderDate)
        case .none:
            return
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("[NotificationService] Failed to schedule: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Cancel Notification
    public func cancelNotification(for recurringId: UUID) {
        let center = UNUserNotificationCenter.current()
        let identifier = "recurring_\(recurringId.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Cancel All
    public func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Reschedule All Active
    public func rescheduleAll(recurring: [RecurringExpense], currencySymbol: String, isEnglish: Bool) {
        for item in recurring where item.isActive {
            scheduleRecurringNotification(for: item, currencySymbol: currencySymbol, isEnglish: isEnglish)
        }
    }
}
