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
            isEnglish ? "Clear chat?" : "Xoá hội thoại?",
            isPresented: $showClearConfirmation
        ) {
            Button(isEnglish ? "Clear" : "Xoá", role: .destructive) {
                resetChat()
            }
            Button(isEnglish ? "Cancel" : "Huỷ", role: .cancel) {}
        }
    }

    // MARK: - Top Header

    private var topHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.mdailyActionBlue)
                .frame(width: 32, height: 32)
                .mdailyGlassSurface(in: Circle(), interactive: false)

            VStack(alignment: .leading, spacing: 1) {
                Text("MDaily AI")
                    .font(MDailyTypography.bodyStrong)
                    .foregroundStyle(Color.mdailyInk)
                Circle()
                    .fill(afmStatus.available ? Color.mdailyIncomeGreen : Color.mdailyMutedInk)
                    .frame(width: 6, height: 6)
            }

            Spacer()

            Button {
                showClearConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.mdailyDestructiveRed)
                    .frame(width: 30, height: 30)
            }
            .mdailyGlassButton(prominent: false)
            .accessibilityLabel(isEnglish ? "Clear chat" : "Xoá hội thoại")

            MDailyCloseButton(accessibilityLabel: isEnglish ? "Close" : "Đóng") {
                onClose()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Messages

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach($store.chatMessages) { $msg in
                        messageRow(message: $msg)
                            .id(msg.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .mdailySoftScrollEdges()
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
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.mdailyActionBlue)
                    .frame(width: 26, height: 26)
                    .mdailyGlassSurface(in: Circle(), interactive: false)
                    .padding(.top, 2)

                if msg.content == "..." {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .mdailyGlassSurface(
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous),
                            interactive: false
                        )
                } else {
                    Text(msg.content)
                        .font(MDailyTypography.caption)
                        .foregroundStyle(Color.mdailyInk)
                        .textSelection(.enabled)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .mdailyGlassSurface(
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous),
                            interactive: false
                        )
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
                    Button(prompt) {
                        sendMessage(prompt)
                    }
                    .font(MDailyTypography.finePrint)
                    .mdailyGlassButton(prominent: false)
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

        return HStack(spacing: 8) {
            TextField(
                isEnglish ? "Ask MDaily AI..." : "Hỏi MDaily AI...",
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
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 30, height: 30)
            }
            .mdailyGlassButton(prominent: !isDisabled)
            .disabled(isDisabled)
            .padding(.trailing, 6)
        }
        .mdailyGlassSurface(in: RoundedRectangle(cornerRadius: 22, style: .continuous), interactive: true)
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .padding(.top, 4)
    }

    // MARK: - Actions

    private func resetChat() {
        let greeting = isEnglish
            ? "Hi! Ask me about your income, expenses, or savings."
            : "Chào bạn! Hỏi tôi về thu chi, danh mục hoặc tiết kiệm."

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
