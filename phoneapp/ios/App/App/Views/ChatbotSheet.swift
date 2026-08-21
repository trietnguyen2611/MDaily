import SwiftUI

public struct ChatMessageSwift: Identifiable, Sendable {
    public let id: String
    public let role: String
    public var content: String
    public var animate: Bool

    public init(id: String = UUID().uuidString, role: String, content: String, animate: Bool = false) {
        self.id = id
        self.role = role
        self.content = content
        self.animate = animate
    }
}

@MainActor
public struct ChatbotSheet: View {
    @ObservedObject public var store: ExpenseStore
    public var onClose: () -> Void

    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var afmStatus: AFMStatus = AFMService.shared.checkStatus()
    @State private var showDeleteConfirmation = false
    
    @FocusState private var isInputFocused: Bool

    public init(store: ExpenseStore, onClose: @escaping () -> Void) {
        self.store = store
        self.onClose = onClose
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach($store.chatMessages) { $msg in
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
                                                TypewriterText(message: $msg)
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
                    .mask {
                        VStack(spacing: 0) {
                            LinearGradient(
                                colors: [.clear, .black],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 16)

                            Rectangle()

                            LinearGradient(
                                colors: [.black, .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 24)
                        }
                    }
                    .onChange(of: store.chatMessages.count) { _, _ in
                        if let lastId = store.chatMessages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isInputFocused) { _, isFocused in
                        if isFocused {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                                if let lastId = store.chatMessages.last?.id {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        proxy.scrollTo(lastId, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                }

                // Liquid Glass Input Bar
                liquidGlassInputBar
            }
            .background(AmbientBackgroundView())
            .scrollDismissesKeyboard(.interactively)
            .hideKeyboardOnTap()
            .navigationTitle("MDaily AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    LiquidGlassCloseButton(size: 32) {
                        onClose()
                    }
                }
            }
            .onAppear {
                if store.chatMessages.isEmpty {
                    resetChat()
                }
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text(store.t("clear_chat_confirm_title")),
                    message: Text(store.t("clear_chat_confirm_desc")),
                    primaryButton: .destructive(Text(store.t("delete"))) {
                        resetChat()
                    },
                    secondaryButton: .cancel(Text(store.t("cancel")))
                )
            }
        }
    }

    // MARK: - Liquid Glass Input Bar
    private var liquidGlassInputBar: some View {
        HStack(spacing: 12) {
            // Text input
            TextField(store.t("type_message"), text: $inputText)
                .font(.appFont(size: 15, weight: .regular))
                .focused($isInputFocused)
                .padding(.horizontal, 4)
                .padding(.vertical, 12)

            // Send button with liquid glass effect
            Button {
                sendMessage(inputText)
            } label: {
                let isEmpty = inputText.trimmingCharacters(in: .whitespaces).isEmpty
                ZStack {
                    if isEmpty {
                        Circle()
                            .fill(Color.secondary.opacity(0.12))
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color(red: 0.3, green: 0.1, blue: 0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.blue.opacity(0.35), radius: 6, x: 0, y: 2)
                    }

                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isEmpty ? .secondary.opacity(0.5) : .white)
                }
                .frame(width: 38, height: 38)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isEmpty)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            .liquidGlassButton()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .liquidGlass(cornerRadius: 24)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private func resetChat() {
        let initialGreeting = store.language == .en
            ? "Hello! I am MDaily AI. I analyze your on-device expense data privately. How can I assist you today?"
            : "Chào bạn! Tôi là trợ lý MDaily AI. Dữ liệu chi tiêu được phân tích hoàn toàn an toàn trên thiết bị của bạn. Bạn cần tư vấn hay thống kê tài chính gì hôm nay?"

        store.chatMessages = [
            ChatMessageSwift(role: "assistant", content: initialGreeting, animate: true)
        ]
    }

    private func sendMessage(_ text: String) {
        let userText = text.trimmingCharacters(in: .whitespaces)
        guard !userText.isEmpty && !isLoading else { return }

        let userMsg = ChatMessageSwift(role: "user", content: userText)
        let typingMsg = ChatMessageSwift(role: "assistant", content: "...")
        store.chatMessages.append(userMsg)
        store.chatMessages.append(typingMsg)
        inputText = ""
        isLoading = true

        let currentExpenses = store.expenses
        let currentCategories = store.categories
        let currentSymbol = store.currencySymbol
        let isEn = store.language == .en

        Task {
            let currentChatHistory = store.chatMessages
            let reply = await AFMService.shared.chatWithAI(
                userMessage: userText,
                chatHistory: currentChatHistory,
                expenses: currentExpenses,
                categories: currentCategories,
                currencySymbol: currentSymbol,
                isEnglish: isEn
            )

            await MainActor.run {
                isLoading = false
                if let lastIdx = store.chatMessages.indices.last {
                    store.chatMessages[lastIdx] = ChatMessageSwift(role: "assistant", content: reply, animate: true)
                }
            }
        }
    }
}

public struct TypewriterText: View {
    @Binding var message: ChatMessageSwift
    @State private var displayedText: String = ""
    @State private var isFinished: Bool = false
    @State private var typewriterTimer: Timer? = nil
    
    public var body: some View {
        Text(isFinished || !message.animate ? message.content : displayedText)
            .animation(.easeIn(duration: 0.1), value: displayedText)
            .onAppear {
                if !message.animate {
                    isFinished = true
                } else if !isFinished {
                    typeText()
                }
            }
            .onChange(of: message.content) { _, _ in
                if message.animate {
                    displayedText = ""
                    isFinished = false
                    typeText()
                }
            }
            .onDisappear {
                // Battery optimization: invalidate timer when view disappears
                typewriterTimer?.invalidate()
                typewriterTimer = nil
            }
    }
    
    private func typeText() {
        typewriterTimer?.invalidate()
        let characters = Array(message.content)
        var currentIndex = 0
        typewriterTimer = Timer.scheduledTimer(withTimeInterval: 0.015, repeats: true) { timer in
            DispatchQueue.main.async {
                if currentIndex < characters.count {
                    displayedText.append(characters[currentIndex])
                    currentIndex += 1
                } else {
                    isFinished = true
                    timer.invalidate()
                    typewriterTimer = nil
                    message.animate = false
                }
            }
        }
    }
}
