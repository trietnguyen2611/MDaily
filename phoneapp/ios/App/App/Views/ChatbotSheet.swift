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

public struct ChatbotSheet: View {
    @ObservedObject public var store: ExpenseStore
    public var onClose: () -> Void

    @State private var messages: [ChatMessageSwift] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var afmStatus: AFMStatus = AFMService.shared.checkStatus()

    private var quickPrompts: [String] {
        store.language == .en
            ? ["💡 Total spending?", "📊 Saving advice", "🍔 Food expenses?", "⚡ Highest expense?"]
            : ["💡 Tổng chi tiêu?", "📊 Lời khuyên tiết kiệm", "🍔 Chi ăn uống?", "⚡ Khoản chi lớn nhất?"]
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { msg in
                                HStack {
                                    if msg.role == "user" {
                                        Spacer()
                                        Text(msg.content)
                                            .font(.system(size: 15))
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
                                                        .font(.system(size: 14))
                                                        .foregroundColor(.secondary)
                                                }
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 10)
                                                .liquidGlass(cornerRadius: 18)
                                            } else {
                                                Text(msg.content)
                                                    .font(.system(size: 15))
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

                // Quick Suggestion Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickPrompts, id: \.self) { prompt in
                            Button {
                                sendMessage(prompt)
                            } label: {
                                Text(prompt)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .liquidGlassPill()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }

                // Input Bar
                HStack(spacing: 10) {
                    TextField(store.t("type_message"), text: $inputText)
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
            .navigationTitle("MDaily AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        resetChat()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.secondary)
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
            ? "Hey there! What are you planning to spend today? Let me help you manage and optimize your expenses!"
            : "Mở app lên làm gì đấy? Lại định phung phí tiền đúng không? Khai mau, nay mày đã tiêu bao nhiêu tiền rồi!"

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

        let expenseContext = store.expenses.prefix(20).map {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            return "\(formatter.string(from: $0.date)): \(store.categoryLabel(for: $0.category)) - \(store.formatCurrency($0.amount))\($0.note != nil ? " (\($0.note!))" : "")"
        }.joined(separator: "\n")

        Task {
            let reply = await AFMService.shared.chatWithAI(
                userMessage: userText,
                expensesContext: expenseContext,
                isEnglish: store.language == .en
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
