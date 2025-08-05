//
//  ContentView.swift
//  WuKongIMExample - Unified iOS/macOS Version
//
//  Created by WuKongIM on 2024/08/04.
//

import SwiftUI
import WuKongEasySDK

struct ContentView: View {
    @StateObject private var chatManager = ChatManager()
    @State private var selectedTab = 0

    var body: some View {
        #if os(macOS)
        // macOS-specific layout to fix width expansion issues
        TabView(selection: $selectedTab) {
            // Connection Tab
            ConnectionView(chatManager: chatManager)
                .navigationTitle("Connection")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem {
                    Label("Connect", systemImage: "network")
                }
                .tag(0)

            // Messages Tab
            MessagingView(chatManager: chatManager)
                .navigationTitle("Messages")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem {
                    Label("Messages", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(1)

            // Logs Tab
            LogsView(chatManager: chatManager)
                .navigationTitle("Event Logs")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem {
                    Label("Logs", systemImage: "doc.text.magnifyingglass")
                }
                .tag(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accentColor(.blue)
        #else
        // iOS layout with NavigationView
        TabView(selection: $selectedTab) {
            // Connection Tab
            NavigationView {
                ConnectionView(chatManager: chatManager)
                    .navigationTitle("Connection")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Connect", systemImage: "network")
            }
            .tag(0)

            // Messages Tab
            NavigationView {
                MessagingView(chatManager: chatManager)
                    .navigationTitle("Messages")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Messages", systemImage: "bubble.left.and.bubble.right")
            }
            .tag(1)

            // Logs Tab
            NavigationView {
                LogsView(chatManager: chatManager)
                    .navigationTitle("Event Logs")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Logs", systemImage: "doc.text.magnifyingglass")
            }
            .tag(2)
        }
        .accentColor(.blue)
        #endif
    }
}

// MARK: - Connection View
struct ConnectionView: View {
    @ObservedObject var chatManager: ChatManager
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header Section
                VStack(spacing: 16) {
                    Image(systemName: "network")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.blue)

                    VStack(spacing: 8) {
                        Text("WuKongIM Connection")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("Configure your server connection settings")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 20)
                .frame(maxWidth: .infinity)
                
                // Configuration Card
                VStack(spacing: 24) {
                    // Server Configuration Section
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Image(systemName: "gear")
                                .font(.title3)
                                .foregroundColor(.blue)
                            Text("Server Configuration")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 16) {
                            ModernTextField(
                                icon: "server.rack",
                                placeholder: "Server URL",
                                text: $chatManager.serverUrl,
                                iconColor: .blue
                            )

                            ModernTextField(
                                icon: "person.circle",
                                placeholder: "User ID",
                                text: $chatManager.uid,
                                iconColor: .green
                            )

                            ModernTextField(
                                icon: "key.fill",
                                placeholder: "Authentication Token",
                                text: $chatManager.token,
                                iconColor: .orange,
                                isSecure: true
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                
                // Connection Status Card
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.title3)
                            .foregroundColor(.green)
                        Text("Connection Status")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 16) {
                        // Status Indicator
                        Circle()
                            .fill(chatManager.isConnected ? Color.green : Color.red)
                            .frame(width: 16, height: 16)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(chatManager.connectionStatus)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            if let error = chatManager.lastError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .lineLimit(2)
                            }
                        }

                        Spacer()

                        if chatManager.isConnecting {
                            ProgressView()
                                .scaleEffect(0.9)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                
                // Connection Button
                Button(action: {
                    isInputFocused = false
                    if chatManager.isConnected {
                        chatManager.disconnect()
                    } else {
                        Task {
                            await chatManager.connect()
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        if chatManager.isConnecting {
                            ProgressView()
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: chatManager.isConnected ? "wifi.slash" : "wifi")
                                .font(.title3)
                                .font(.headline)
                        }
                        
                        Text(chatManager.isConnecting ? "Connecting..." : 
                             chatManager.isConnected ? "Disconnect" : "Connect")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(chatManager.isConnected ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: (chatManager.isConnected ? Color.red : Color.blue).opacity(0.3),
                           radius: 8, x: 0, y: 4)
                }
                .disabled(chatManager.isConnecting)
                
                // Quick Message Section
                if chatManager.isConnected {
                    MessagingSection(chatManager: chatManager)
                }
                
                Spacer(minLength: 100) // Extra space for keyboard
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColorForPlatform())
        .onTapGesture {
            isInputFocused = false
        }
    }
    
    private func backgroundColorForPlatform() -> Color {
        #if os(iOS)
        return Color(.systemGroupedBackground)
        #else
        return Color(.controlBackgroundColor)
        #endif
    }
}

// MARK: - Modern TextField Component
struct ModernTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let iconColor: Color
    var isSecure: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 24)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.body)
            .focused($isFocused)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? iconColor : .clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Messaging Section (Legacy - for ConnectionView)
struct MessagingSection: View {
    @ObservedObject var chatManager: ChatManager
    @State private var messageText = ""
    @State private var isSending = false
    @State private var showingRecipientSelector = false
    @FocusState private var isMessageFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.title3)
                    .foregroundColor(.blue)
                Text("Quick Message")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 16) {
                // Recipient Selection
                HStack(spacing: 12) {
                    Image(systemName: chatManager.selectedChannelType == .person ? "person.circle" : "person.3")
                        .font(.title3)
                        .foregroundColor(.green)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("To: \(chatManager.targetChannelId.isEmpty ? "Select recipient" : chatManager.targetChannelId)")
                            .font(.body)
                            .foregroundColor(chatManager.targetChannelId.isEmpty ? .secondary : .primary)

                        Text(chatManager.selectedChannelType == .person ? "Person" : "Group")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: {
                        showingRecipientSelector.toggle()
                    }) {
                        Text(chatManager.targetChannelId.isEmpty ? "Select" : "Change")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Recipient Selector
                if showingRecipientSelector {
                    RecipientSelectorView(chatManager: chatManager, showingRecipientSelector: $showingRecipientSelector)
                }

                // Message Input
                ModernTextField(
                    icon: "message",
                    placeholder: "Type your message...",
                    text: $messageText,
                    iconColor: .blue
                )

                Button(action: {
                    sendMessage()
                }) {
                    HStack(spacing: 12) {
                        if isSending {
                            ProgressView()
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.title3)
                                .font(.headline)
                        }
                        Text(isSending ? "Sending..." : "Send Message")
                            .font(.headline)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        isSending ||
                        chatManager.targetChannelId.isEmpty ?
                            Color.gray : Color.blue
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending || chatManager.targetChannelId.isEmpty)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !chatManager.targetChannelId.isEmpty else { return }

        isSending = true
        isMessageFocused = false
        let text = messageText
        messageText = ""

        Task {
            await chatManager.sendMessage(text)
            await MainActor.run {
                isSending = false
            }
        }
    }
}

// MARK: - Recipient Selector View
struct RecipientSelectorView: View {
    @ObservedObject var chatManager: ChatManager
    @Binding var showingRecipientSelector: Bool
    @State private var recipientText = ""
    @FocusState private var isRecipientFocused: Bool

    private let quickRecipients = [
        ("testUser2", "Test User 2", ChannelType.person),
        ("friendUser", "Friend User", ChannelType.person),
        ("group123", "Test Group", ChannelType.group),
        ("support", "Support Team", ChannelType.group),
        ("general", "General Chat", ChannelType.group)
    ]

    var body: some View {
        VStack(spacing: 16) {
            // Channel Type Picker
            Picker("Channel Type", selection: $chatManager.selectedChannelType) {
                Text("Person").tag(ChannelType.person)
                // Text("Group").tag(ChannelType.group)
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: chatManager.selectedChannelType) { newValue in
                if newValue == .group {
                    // Reset to person and show alert for unsupported group channels
                    chatManager.selectedChannelType = .person
                    chatManager.showGroupUnsupportedAlert = true
                }
            }

            // Show message for unsupported group channels
            if chatManager.selectedChannelType == .group {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.orange)

                    Text("Group Channels Coming Soon")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("Group channel functionality is not yet available. Please use 'Person' for individual messaging.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)

                // Close Button
                Button(action: {
                    showingRecipientSelector = false
                }) {
                    Text("Close")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.secondary)
                        .cornerRadius(8)
                }
            } else {
                // Manual Input
            HStack(spacing: 12) {
                Image(systemName: chatManager.selectedChannelType == .person ? "person.circle" : "person.3")
                    .font(.title3)
                    .foregroundColor(.green)
                    .frame(width: 24)

                TextField(
                    chatManager.selectedChannelType == .person ? "Enter user ID" : "Enter group ID",
                    text: $recipientText
                )
                .focused($isRecipientFocused)
                .font(.body)
                .frame(maxWidth: .infinity)
                .onSubmit {
                    setRecipient()
                }

                Button(action: setRecipient) {
                    Text("Set")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(recipientText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(recipientText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)

            // Quick Recipients
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Recipients")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(quickRecipients.filter { $0.2 == .person }, id: \.0) { recipient in
                        Button(action: {
                            chatManager.setRecipient(channelId: recipient.0, channelType: recipient.2)
                            showingRecipientSelector = false
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: recipient.2 == .person ? "person.circle" : "person.3")
                                    .font(.caption)
                                    .foregroundColor(.green)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(recipient.1)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)

                                    Text(recipient.0)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }

            // Close Button
            Button(action: {
                showingRecipientSelector = false
            }) {
                Text("Close")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.secondary)
                    .cornerRadius(8)
            }
            } // End of else block
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            recipientText = chatManager.targetChannelId
            isRecipientFocused = true
        }
        .alert("Feature Coming Soon", isPresented: $chatManager.showGroupUnsupportedAlert) {
            Button("OK") { }
        } message: {
            Text("Group channels are not yet supported. This feature will be available in a future update.")
        }
    }

    private func setRecipient() {
        let trimmedText = recipientText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            if chatManager.selectedChannelType == .group {
                chatManager.showGroupUnsupportedAlert = true
                return
            }
            chatManager.setRecipient(channelId: trimmedText, channelType: chatManager.selectedChannelType)
            showingRecipientSelector = false
        }
    }
}

// MARK: - Messaging View
struct MessagingView: View {
    @ObservedObject var chatManager: ChatManager

    var body: some View {
        VStack(spacing: 0) {
            if !chatManager.isConnected {
                // Not Connected State
                VStack(spacing: 24) {
                    Spacer()

                    Image(systemName: "wifi.slash")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(.gray)

                    VStack(spacing: 12) {
                        Text("Not Connected")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("Please connect to the server first to start messaging")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 32)
            } else {
                // Connected State - Show Messages
                VStack(spacing: 0) {
                    // Messages List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chatManager.messages) { message in
                                MessageBubble(message: message, isFromCurrentUser: message.fromUserId == chatManager.uid)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(backgroundColorForPlatform())

                    // Message Input
                    MessageInputView(chatManager: chatManager)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColorForPlatform())
    }

    private func backgroundColorForPlatform() -> Color {
        #if os(iOS)
        return Color(.systemGroupedBackground)
        #else
        return Color(.controlBackgroundColor)
        #endif
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 8) {
                if !isFromCurrentUser {
                    Text(message.fromUserId)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }

                // Raw JSON payload display
                VStack(alignment: .leading, spacing: 8) {
                    // Direction indicator
                    HStack(spacing: 4) {
                        Image(systemName: message.isOutgoing ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundColor(message.isOutgoing ? .green : .blue)
                            .font(.caption2)
                        Text(message.isOutgoing ? "SENT" : "RECEIVED")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text("Type: \(message.messageType)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }

                    // Raw JSON payload content
                    ScrollView {
                        Text(formatPayloadAsJSON(message.payload))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(isFromCurrentUser ? .white : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxHeight: 200)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    isFromCurrentUser ?
                        Color.blue :
                        Color.gray.opacity(0.2)
                )
                .cornerRadius(12)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func formatPayloadAsJSON(_ payload: [String: Any]) -> String {
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
            return String(data: data, encoding: .utf8) ?? "Invalid JSON"
        } catch {
            return "Error formatting JSON: \(error.localizedDescription)"
        }
    }
}

// MARK: - Message Input View
struct MessageInputView: View {
    @ObservedObject var chatManager: ChatManager
    @State private var messageText = ""
    @State private var isSending = false
    @State private var showingRecipientSelector = false
    @FocusState private var isMessageFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Recipient Selection Bar
            RecipientSelectionBar(chatManager: chatManager, showingRecipientSelector: $showingRecipientSelector)

            Divider()

            HStack(spacing: 12) {
                // Recipient Button
                Button(action: {
                    showingRecipientSelector.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: chatManager.selectedChannelType == .person ? "person.circle" : "person.3")
                            .font(.caption)
                        Text(chatManager.targetChannelId.isEmpty ? "To:" : String(chatManager.targetChannelId.prefix(8)))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                }

                // Text Input
                TextField("Type a message...", text: $messageText)
                    .focused($isMessageFocused)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .frame(maxWidth: .infinity)

                // Send Button
                Button(action: sendMessage) {
                    if isSending {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.title3)
                            .font(.headline)
                    }
                }
                .frame(width: 40, height: 40)
                .background(
                    messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatManager.targetChannelId.isEmpty ?
                        Color.gray : Color.blue
                )
                .foregroundColor(.white)
                .clipShape(Circle())
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending || chatManager.targetChannelId.isEmpty)
                .animation(.easeInOut(duration: 0.2), value: messageText.isEmpty)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.05))
        }
        .frame(maxWidth: .infinity)
    }

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !chatManager.targetChannelId.isEmpty else { return }

        isSending = true
        let text = messageText
        messageText = ""
        isMessageFocused = false

        Task {
            await chatManager.sendMessage(text)
            await MainActor.run {
                isSending = false
            }
        }
    }
}

// MARK: - Recipient Selection Bar
struct RecipientSelectionBar: View {
    @ObservedObject var chatManager: ChatManager
    @Binding var showingRecipientSelector: Bool
    @State private var recipientText = ""
    @FocusState private var isRecipientFocused: Bool

    var body: some View {
        if showingRecipientSelector {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Channel Type Picker
                    Picker("Channel Type", selection: $chatManager.selectedChannelType) {
                        Text("Person").tag(ChannelType.person)
                        // Text("Group").tag(ChannelType.group)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: 200)
                    .onChange(of: chatManager.selectedChannelType) { newValue in
                        if newValue == .group {
                            // Reset to person and show alert for unsupported group channels
                            chatManager.selectedChannelType = .person
                            chatManager.showGroupUnsupportedAlert = true
                        }
                    }

                    Spacer()

                    // Close Button
                    Button(action: {
                        showingRecipientSelector = false
                        isRecipientFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }

                // Recipient Input
                HStack(spacing: 12) {
                    Image(systemName: chatManager.selectedChannelType == .person ? "person.circle" : "person.3")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(width: 24)

                    TextField(
                        chatManager.selectedChannelType == .person ? "Enter user ID or username" : "Enter group ID or name",
                        text: $recipientText
                    )
                    .focused($isRecipientFocused)
                    .font(.body)
                    .frame(maxWidth: .infinity)
                    .onSubmit {
                        if !recipientText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            chatManager.targetChannelId = recipientText.trimmingCharacters(in: .whitespacesAndNewlines)
                            showingRecipientSelector = false
                        }
                    }

                    // Set Button
                    Button(action: {
                        if !recipientText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            chatManager.targetChannelId = recipientText.trimmingCharacters(in: .whitespacesAndNewlines)
                            showingRecipientSelector = false
                        }
                    }) {
                        Text("Set")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(recipientText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(recipientText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Quick Recipients
                QuickRecipientsView(chatManager: chatManager, showingRecipientSelector: $showingRecipientSelector)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.05))
            .onAppear {
                recipientText = chatManager.targetChannelId
                isRecipientFocused = true
            }
            .alert("Feature Coming Soon", isPresented: $chatManager.showGroupUnsupportedAlert) {
                Button("OK") { }
            } message: {
                Text("Group channels are not yet supported. This feature will be available in a future update.")
            }
        }
    }
}

// MARK: - Quick Recipients View
struct QuickRecipientsView: View {
    @ObservedObject var chatManager: ChatManager
    @Binding var showingRecipientSelector: Bool

    private let defaultRecipients = [
        ("testUser2", "Test User 2", ChannelType.person),
        ("friendUser", "Friend User", ChannelType.person),
        ("group123", "Test Group", ChannelType.group),
        ("support", "Support Team", ChannelType.group),
        ("general", "General Chat", ChannelType.group)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Show message for unsupported group channels
            if chatManager.selectedChannelType == .group {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.orange)

                    Text("Group Channels Coming Soon")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("Group channel functionality is not yet available. Please select 'Person' for individual messaging.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Recent Recipients Section (Person only)
                let recentRecipients = chatManager.getSuggestedRecipients(for: .person)

                if !recentRecipients.isEmpty {
                Text("Recent Recipients")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(recentRecipients.prefix(4)) { recipient in
                        Button(action: {
                            chatManager.setRecipient(channelId: recipient.channelId, channelType: recipient.channelType)
                            showingRecipientSelector = false
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: recipient.typeIcon)
                                    .font(.caption)
                                    .foregroundColor(.blue)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(recipient.displayName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)

                                    Text(recipient.formattedLastUsed)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }

            // Default Recipients Section (Person only)
            Text(recentRecipients.isEmpty ? "Quick Recipients" : "Suggested Recipients")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(defaultRecipients.filter { $0.2 == .person }, id: \.0) { recipient in
                    Button(action: {
                        chatManager.setRecipient(channelId: recipient.0, channelType: recipient.2)
                        showingRecipientSelector = false
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: recipient.2 == .person ? "person.circle" : "person.3")
                                .font(.caption)
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(recipient.1)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)

                                Text(recipient.0)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            } // End of else block
        }
    }
}

// MARK: - Logs View
struct LogsView: View {
    @ObservedObject var chatManager: ChatManager
    @State private var showingClearAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with Clear Button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Event Logs")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("\(chatManager.eventLogs.count) events")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    showingClearAlert = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                            .font(.caption)
                        Text("Clear")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                }
                .disabled(chatManager.eventLogs.isEmpty)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.gray.opacity(0.05))

            Divider()

            // Logs List
            if chatManager.eventLogs.isEmpty {
                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(.gray)

                    VStack(spacing: 12) {
                        Text("No Events Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("Connect to the server to start seeing real-time events and logs")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 32)
                .background(backgroundColorForPlatform())
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(chatManager.eventLogs) { log in
                                LogRowView(log: log)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(backgroundColorForPlatform())
                    .onChange(of: chatManager.eventLogs.count) { _ in
                        if let lastLog = chatManager.eventLogs.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastLog.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Clear All Logs", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                chatManager.clearLogs()
            }
        } message: {
            Text("This will permanently delete all event logs. This action cannot be undone.")
        }
    }

    private func backgroundColorForPlatform() -> Color {
        #if os(iOS)
        return Color(.systemGroupedBackground)
        #else
        return Color(.controlBackgroundColor)
        #endif
    }
}

// MARK: - Log Row View
struct LogRowView: View {
    let log: EventLog
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Log Level Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(log.type.swiftUIColor)
                        .frame(width: 8, height: 8)

                    Text(log.type.displayName.uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(log.type.swiftUIColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(log.type.swiftUIColor.opacity(0.1))
                .cornerRadius(8)

                Spacer()

                // Timestamp
                Text(log.formattedTime)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }

            // Message Content
            VStack(alignment: .leading, spacing: 8) {
                Text(log.message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(isExpanded ? nil : 3)
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)

                // Expand/Collapse Button
                if log.message.count > 100 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isExpanded ? "Show Less" : "Show More")
                                .font(.caption)
                                .fontWeight(.medium)
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Extensions
extension EventLog.LogType {
    var displayName: String {
        switch self {
        case .system: return "system"
        case .info: return "info"
        case .success: return "success"
        case .error: return "error"
        case .warning: return "warning"
        case .debug: return "debug"
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .system: return .blue
        case .info: return .blue
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .debug: return .purple
        }
    }
}



#Preview {
    ContentView()
}
