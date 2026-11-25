import SwiftUI

@main
public struct MDailyApp: App {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            AdaptiveRootView()
        }
        #if os(macOS)
        .defaultSize(width: 1180, height: 760)
        .windowResizability(.contentMinSize)
        #endif
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Transaction") {
                    NotificationCenter.default.post(name: .mdailyNewTransaction, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Quick Receipt Capture") {
                    NotificationCenter.default.post(name: .mdailyQuickCapture, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }

            CommandGroup(after: .textEditing) {
                Button("Search Transactions") {
                    NotificationCenter.default.post(name: .mdailyFocusSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
            }

            CommandMenu("Navigate") {
                Button("Dashboard") {
                    NotificationCenter.default.post(name: .mdailySwitchTab, object: AppTab.dashboard)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Add Transaction") {
                    NotificationCenter.default.post(name: .mdailySwitchTab, object: AppTab.addTransaction)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Reports") {
                    NotificationCenter.default.post(name: .mdailySwitchTab, object: AppTab.reports)
                }
                .keyboardShortcut("3", modifiers: .command)

                Button("Settings") {
                    NotificationCenter.default.post(name: .mdailySwitchTab, object: AppTab.settings)
                }
                .keyboardShortcut("4", modifiers: .command)

                Divider()

                Button("MDaily AI") {
                    NotificationCenter.default.post(name: .mdailyToggleAIChat, object: nil)
                }
                .keyboardShortcut("j", modifiers: .command)
            }
        }
    }
}
