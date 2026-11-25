import Foundation
import UserNotifications

public final class NotificationService: @unchecked Sendable {
    public static let shared = NotificationService()

    private init() {}

    private var hasNotificationCenterBundle: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    // MARK: - Permission
    public func requestPermission() async -> Bool {
        guard hasNotificationCenterBundle else { return false }
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    public func checkPermission() async -> Bool {
        guard hasNotificationCenterBundle else { return false }
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Schedule Recurring Transaction Notification
    public func scheduleRecurringNotification(
        for recurring: RecurringTransaction,
        currencySymbol: String,
        isEnglish: Bool
    ) {
        guard hasNotificationCenterBundle else { return }
        let center = UNUserNotificationCenter.current()

        let identifier = "recurring_\(recurring.id.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard recurring.isActive, recurring.repeatInterval != .none else { return }

        let content = UNMutableNotificationContent()

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        let amountStr = "\(formatter.string(from: NSNumber(value: Int(recurring.amount))) ?? "\(Int(recurring.amount))") \(currencySymbol)"

        let defaultTitle = recurring.kind == .income
            ? (isEnglish ? "Income" : "Thu nhập")
            : (isEnglish ? "Payment" : "Thanh toán")
        let noteName = recurring.note ?? defaultTitle

        if recurring.kind == .income {
            content.title = isEnglish ? "Income Reminder" : "Nhắc thu nhập"
            content.body = isEnglish
                ? "\(noteName): +\(amountStr) is scheduled today."
                : "\(noteName): +\(amountStr) đến lịch nhận hôm nay."
        } else {
            content.title = isEnglish ? "Payment Reminder" : "Nhắc thanh toán"
            content.body = isEnglish
                ? "\(noteName): -\(amountStr) is due today."
                : "\(noteName): -\(amountStr) đến hạn thanh toán hôm nay."
        }

        content.sound = .default
        content.categoryIdentifier = "RECURRING_TRANSACTION"

        var userInfo: [String: Any] = [
            "recurringId": recurring.id.uuidString,
            "kind": recurring.kind.rawValue
        ]
        if let txId = recurring.linkedTransactionId {
            userInfo["linkedTransactionId"] = txId
        }
        content.userInfo = userInfo

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
            if let error {
                print("[NotificationService] Failed to schedule: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Cancel
    public func cancelNotification(for recurringId: UUID) {
        guard hasNotificationCenterBundle else { return }
        let identifier = "recurring_\(recurringId.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    public func cancelAllNotifications() {
        guard hasNotificationCenterBundle else { return }
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    public func rescheduleAll(
        recurring: [RecurringTransaction],
        currencySymbol: String,
        isEnglish: Bool
    ) {
        for item in recurring where item.isActive {
            scheduleRecurringNotification(for: item, currencySymbol: currencySymbol, isEnglish: isEnglish)
        }
    }
}
