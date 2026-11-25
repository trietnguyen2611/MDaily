import SwiftUI

@MainActor
public struct ChatbotView: View {
    @ObservedObject public var store: FinanceStore
    public var onClose: () -> Void

    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var afmStatus: AFMStatus = AFMService.shared.checkStatus()
    @State private var showClearConfirmation: Bool = false
    @FocusState private var isInputFocused: Bool

    public init(store: FinanceStore, onClose: @escaping () -> Void) {
        self.store = store
        self.onClose = onClose
    }

    private var isEnglish: Bool { store.language == .en }

    private var quickPrompts: [String] {
        if isEnglish {
            return [
                "Income & expense this month?",
                "Top spending category?",
                "Savings tips",
                "Net cashflow summary"
            ]
        } else {
            return [
                "Tổng thu chi tháng này?",
                "Danh mục nào tốn nhất?",
                "Gợi ý tiết kiệm",
                "Tóm tắt dòng tiền"
            ]
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            topHeader

            Divider().overlay(Color.mdailyHairline)

            messagesScrollView

            quickPromptStrip

            inputBar
        }
        .background(Color.mdailyCanvas.ignoresSafeArea())
        .onAppear {
            afmStatus = AFMService.shared.checkStatus(lang: store.language)
            if store.chatMessages.isEmpty {
                resetChat()
            }
        }
        .alert(
            isEnglish ? "Clear chat history?" : "Xoá lịch sử trò chuyện?",
            isPresented: $showClearConfirmation
        ) {
            Button(isEnglish ? "Clear" : "Xoá", role: .destructive) {
                resetChat()
            }
            Button(isEnglish ? "Cancel" : "Huỷ", role: .cancel) {}
        } message: {
            Text(isEnglish
                 ? "All messages in this session will be removed."
                 : "Toàn bộ tin nhắn trong cuộc trò chuyện hiện tại sẽ bị xoá.")
        }
    }

    // MARK: - Top Header

    private var topHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.mdailyActionBlue.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.mdailyActionBlue)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("MDaily AI")
                    .font(MDailyTypography.bodyStrong)
                    .foregroundStyle(Color.mdailyInk)
                Text(afmStatus.model)
                    .font(MDailyTypography.microLegal)
                    .foregroundStyle(afmStatus.available ? Color.mdailyIncomeGreen : Color.mdailyMutedInk)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                showClearConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.mdailyDestructiveRed)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.mdailyDestructiveRed.opacity(0.10)))
            }
            .buttonStyle(MDailyPressButtonStyle())
            .accessibilityLabel(isEnglish ? "Clear chat" : "Xoá hội thoại")

            MDailyCloseButton(accessibilityLabel: isEnglish ? "Close" : "Đóng") {
                onClose()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.mdailyCanvas)
    }

    // MARK: - Messages

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach($store.chatMessages) { $msg in
                        messageRow(message: $msg)
                            .id(msg.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .onChange(of: store.chatMessages.count) { _, _ in
                scrollToLatest(proxy: proxy)
            }
            .onChange(of: isInputFocused) { _, focused in
                if focused {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        scrollToLatest(proxy: proxy)
                    }
                }
            }
        }
    }

    private func scrollToLatest(proxy: ScrollViewProxy) {
        if let lastId = store.chatMessages.last?.id {
            withAnimation(.easeOut(duration: 0.22)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }

    @ViewBuilder
    private func messageRow(message: Binding<ChatMessageSwift>) -> some View {
        let msg = message.wrappedValue
        HStack(alignment: .top, spacing: 8) {
            if msg.role == "user" {
                Spacer(minLength: 40)
                Text(msg.content)
                    .font(MDailyTypography.caption)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.mdailyActionBlue)
                    )
            } else {
                ZStack {
                    Circle()
                        .fill(Color.mdailyParchment)
                        .frame(width: 26, height: 26)
                        .overlay(Circle().strokeBorder(Color.mdailyHairline, lineWidth: 1))
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.mdailyActionBlue)
                }
                .padding(.top, 2)

                if msg.content == "..." {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(isEnglish ? "Analyzing on-device..." : "Đang phân tích trên thiết bị...")
                            .font(MDailyTypography.caption)
                            .foregroundStyle(Color.mdailyMutedInk)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .mdailyCard(cornerRadius: 16, background: .mdailyParchment)
                } else {
                    Text(msg.content)
                        .font(MDailyTypography.caption)
                        .foregroundStyle(Color.mdailyInk)
                        .textSelection(.enabled)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .mdailyCard(cornerRadius: 16, background: .mdailyParchment)
                }

                Spacer(minLength: 32)
            }
        }
    }

    // MARK: - Quick Prompt Chips

    private var quickPromptStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickPrompts, id: \.self) { prompt in
                    Button {
                        sendMessage(prompt)
                    } label: {
                        Text(prompt)
                            .font(MDailyTypography.finePrint)
                            .foregroundStyle(Color.mdailyActionBlue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .mdailyCard(cornerRadius: MDailyRadius.pill, background: .mdailyCardSurface)
                    }
                    .buttonStyle(MDailyPressButtonStyle())
                    .disabled(isLoading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let isDisabled = trimmed.isEmpty || isLoading

        return HStack(spacing: 10) {
            TextField(
                isEnglish ? "Ask MDaily AI about your finances..." : "Hỏi MDaily AI về thu chi của bạn...",
                text: $inputText,
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .font(MDailyTypography.caption)
            .lineLimit(1...4)
            .focused($isInputFocused)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .onSubmit {
                if !isDisabled {
                    sendMessage(inputText)
                }
            }

            Button {
                sendMessage(inputText)
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isDisabled ? Color.mdailyMutedInk : Color.white)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(isDisabled ? Color.mdailyParchment : Color.mdailyActionBlue)
                    )
            }
            .buttonStyle(MDailyPressButtonStyle())
            .disabled(isDisabled)
            .padding(.trailing, 6)
        }
        .mdailyCard(cornerRadius: 22, background: .mdailyCardSurface)
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .padding(.top, 4)
    }

    // MARK: - Actions

    private func resetChat() {
        let greeting = isEnglish
            ? "Hello! I am MDaily AI. Your income and expense data stays private on-device. How can I help today?"
            : "Chào bạn! Tôi là trợ lý MDaily AI. Toàn bộ dữ liệu thu chi của bạn được phân tích riêng tư trên thiết bị. Bạn muốn kiểm tra gì hôm nay?"

        store.chatMessages = [
            ChatMessageSwift(role: "assistant", content: greeting, animate: false)
        ]
    }

    private func sendMessage(_ rawText: String) {
        let userText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty, !isLoading else { return }

        let userMsg = ChatMessageSwift(role: "user", content: userText)
        let typingMsg = ChatMessageSwift(role: "assistant", content: "...")
        store.chatMessages.append(userMsg)
        store.chatMessages.append(typingMsg)
        inputText = ""
        isLoading = true

        let snapshotTransactions = store.transactions
        let snapshotCategories = store.categories
        let snapshotCurrency = store.currencySymbol
        let snapshotEnglish = isEnglish
        let history = store.chatMessages

        Task {
            let reply = await AFMService.shared.chatWithAI(
                userMessage: userText,
                chatHistory: history,
                transactions: snapshotTransactions,
                categories: snapshotCategories,
                currencySymbol: snapshotCurrency,
                isEnglish: snapshotEnglish
            )

            await MainActor.run {
                isLoading = false
                if let lastIdx = store.chatMessages.indices.last {
                    store.chatMessages[lastIdx] = ChatMessageSwift(
                        role: "assistant",
                        content: reply,
                        animate: false
                    )
                }
            }
        }
    }
}
