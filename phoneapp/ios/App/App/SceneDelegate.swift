import UIKit
import SwiftUI
import UserNotifications

public extension Notification.Name {
    static let handleQuickAction = Notification.Name("org.mdaily.app.handleQuickAction")
    static let openExpenseDetail = Notification.Name("org.mdaily.app.openExpenseDetail")
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Register Notification Center Delegate to handle notification taps
        UNUserNotificationCenter.current().delegate = self

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: ContentView())
        self.window = window
        window.makeKeyAndVisible()

        // Handle Home Screen Quick Action on launch
        if let shortcutItem = connectionOptions.shortcutItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                NotificationCenter.default.post(name: .handleQuickAction, object: shortcutItem.type)
            }
        }

        // Handle Notification Tap on launch
        if let response = connectionOptions.notificationResponse {
            let userInfo = response.notification.request.content.userInfo
            if let linkedExpenseIdStr = userInfo["linkedExpenseId"] as? String {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    NotificationCenter.default.post(name: .openExpenseDetail, object: linkedExpenseIdStr)
                }
            }
        }
    }

    // Handle Home Screen Quick Action when app is in background / foreground
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        NotificationCenter.default.post(name: .handleQuickAction, object: shortcutItem.type)
        completionHandler(true)
    }

    // Handle notification tap when running or in background
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let linkedExpenseIdStr = userInfo["linkedExpenseId"] as? String {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .openExpenseDetail, object: linkedExpenseIdStr)
            }
        }
        completionHandler()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
