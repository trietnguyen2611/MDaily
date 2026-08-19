import SwiftUI

public struct ChatMessageSwift: Identifiable, Sendable {
    public let id: String
    public let role: String
    public var content: String

    public init(id: String = UUID().uuidString, role: String, content: String) {
        self.id = id
        self.role = role
        self.content = content
    }
}

@MainActor
public struct ChatbotSheet: View {
    @ObservedObject public var store: ExpenseStore
    public var onClose: () -> Void

    @State private var messages: [ChatMessageSwift] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var afmStatus: AFMStatus = AFMService.shared.checkStatus()

    public init(store: ExpenseStore, onClose: @escaping () -> Void) {
        self.store = store
        self.onClose = onClose
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // AFM Status Banner
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.purple)
                    Text("Apple Intelligence AFM")
                        .font(.appFont(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .liquidGlassPill()
                .padding(.top, 8)
                .padding(.bottom, 4)

                // Messages List
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { msg in
                                HStack {
                                    if msg.role == "user" {
                                        Spacer()
                                        Text(msg.content)
                                            .font(.appFont(size: 15, weight: .regular))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                LinearGradient(
                                                    colors: [Color.blue, Color(red: 0, green: 0.4, blue: 0.9)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    } else {
                                        HStack(alignment: .top, spacing: 8) {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.blue, Color.purple],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 28, height: 28)
                                                .overlay(
                                                    Image(systemName: "sparkles")
                                                        .font(.system(size: 13))
                                                        .foregroundColor(.white)
                                                )

                                            if msg.content == "..." {
                                                HStack(spacing: 6) {
                                                    ProgressView()
                                                    Text(store.t("ai_thinking"))
                                                        .font(.appFont(size: 14, weight: .medium))
                                                        .foregroundColor(.secondary)
                                                }
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 10)
                                                .liquidGlass(cornerRadius: 18)
                                            } else {
                                                Text(msg.content)
                                                    .font(.appFont(size: 15, weight: .regular))
                                                    .foregroundColor(.primary)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .liquidGlass(cornerRadius: 18)
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                                .id(msg.id)
                            }
                        }
                        .padding(16)
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastId = messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input Bar
                HStack(spacing: 10) {
                    TextField(store.t("type_message"), text: $inputText)
                        .font(.appFont(size: 15, weight: .regular))
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 22))

                    Button {
                        sendMessage(inputText)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 34))
                            .foregroundColor(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary.opacity(0.4) : .blue)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
            }
            .scrollDismissesKeyboard(.interactively)
            .hideKeyboardOnTap()
            .navigationTitle("Apple Intelligence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        resetChat()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    LiquidGlassCloseButton(size: 32) {
                        onClose()
                    }
                }
            }
            .onAppear {
                if messages.isEmpty {
                    resetChat()
                }
            }
        }
    }

    private func resetChat() {
        let initialGreeting = store.language == .en
            ? "Hello! I am Apple Intelligence on MDaily. I analyze your on-device expense data privately. How can I assist you today?"
            : "Chào bạn! Tôi là trợ lý Apple Intelligence (AFM) trên MDaily. Dữ liệu chi tiêu được phân tích hoàn toàn an toàn trên thiết bị của bạn. Bạn cần tư vấn hay thống kê tài chính gì hôm nay?"

        messages = [
            ChatMessageSwift(role: "assistant", content: initialGreeting)
        ]
    }

    private func sendMessage(_ text: String) {
        let userText = text.trimmingCharacters(in: .whitespaces)
        guard !userText.isEmpty && !isLoading else { return }

        let userMsg = ChatMessageSwift(role: "user", content: userText)
        let typingMsg = ChatMessageSwift(role: "assistant", content: "...")
        messages.append(userMsg)
        messages.append(typingMsg)
        inputText = ""
        isLoading = true

        let currentExpenses = store.expenses
        let currentCategories = store.categories
        let currentSymbol = store.currencySymbol
        let isEn = store.language == .en

        Task {
            let reply = await AFMService.shared.chatWithAI(
                userMessage: userText,
                expenses: currentExpenses,
                categories: currentCategories,
                currencySymbol: currentSymbol,
                isEnglish: isEn
            )

            await MainActor.run {
                isLoading = false
                if let lastIdx = messages.indices.last {
                    messages[lastIdx] = ChatMessageSwift(role: "assistant", content: reply)
                }
            }
        }
    }
}
