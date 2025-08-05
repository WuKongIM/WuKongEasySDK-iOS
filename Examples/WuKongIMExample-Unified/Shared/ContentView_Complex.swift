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
        TabView(selection: $selectedTab) {
            // Connection Tab
            NavigationView {
                ConnectionView(chatManager: chatManager)
                    .navigationTitle("Connection")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.large)
                    #endif
            }
            .tabItem {
                Label("Connect", systemImage: "network")
            }
            .tag(0)
            
            // Messages Tab
            NavigationView {
                MessagingView(chatManager: chatManager)
                    .navigationTitle("Messages")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.large)
                    #endif
            }
            .tabItem {
                Label("Messages", systemImage: "bubble.left.and.bubble.right")
            }
            .tag(1)
            
            // Logs Tab
            NavigationView {
                LogsView(chatManager: chatManager)
                    .navigationTitle("Event Logs")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.large)
                    #endif
            }
            .tabItem {
                Label("Logs", systemImage: "doc.text.magnifyingglass")
            }
            .tag(2)
        }
        #if os(iOS)
        .tint(.blue)
        #else
        .accentColor(.blue)
        #endif
    }
}

// MARK: - Connection View
struct ConnectionView: View {
    @ObservedObject var chatManager: ChatManager
    @FocusState private var isInputFocused: Bool
    @State private var showingConnectionAnimation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header Section
                VStack(spacing: 16) {
                    Image(systemName: "network")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.blue.gradient)
                        .scaleEffect(showingConnectionAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: showingConnectionAnimation)
                    
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
                .onAppear {
                    showingConnectionAnimation = true
                }
                
                // Configuration Card
                VStack(spacing: 24) {
                    // Server Configuration Section
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Image(systemName: "gear")
                                .font(.title3)
                                .foregroundStyle(.blue.gradient)
                            Text("Server Configuration")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
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
                    }
                }
                .padding(24)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                
                // Connection Status Card
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.title3)
                            .foregroundStyle(.green.gradient)
                        Text("Connection Status")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    HStack(spacing: 16) {
                        // Status Indicator
                        ZStack {
                            Circle()
                                .fill(chatManager.isConnected ? .green.gradient : .red.gradient)
                                .frame(width: 16, height: 16)
                            
                            if chatManager.isConnecting {
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                                    .frame(width: 16, height: 16)
                                    .rotationEffect(.degrees(showingConnectionAnimation ? 360 : 0))
                                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: showingConnectionAnimation)
                            }
                        }
                        
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
                                .tint(.blue)
                        }
                    }
                }
                .padding(20)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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
                                .tint(.white)
                        } else {
                            Image(systemName: chatManager.isConnected ? "wifi.slash" : "wifi")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        
                        Text(chatManager.isConnecting ? "Connecting..." : 
                             chatManager.isConnected ? "Disconnect" : "Connect")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: chatManager.isConnected ? 
                                [.red, .red.opacity(0.8)] : 
                                [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: (chatManager.isConnected ? .red : .blue).opacity(0.3), 
                           radius: 8, x: 0, y: 4)
                    .scaleEffect(chatManager.isConnecting ? 0.98 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: chatManager.isConnecting)
                }
                .disabled(chatManager.isConnecting)
                .buttonStyle(PlainButtonStyle())
                
                // Quick Message Section
                if chatManager.isConnected {
                    MessagingSection(chatManager: chatManager)
                }
                
                Spacer(minLength: 100) // Extra space for keyboard
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(
            #if os(iOS)
            Color(.systemGroupedBackground).ignoresSafeArea()
            #else
            Color(.controlBackgroundColor).ignoresSafeArea()
            #endif
        )
        .onTapGesture {
            isInputFocused = false
        }
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
                .foregroundStyle(iconColor.gradient)
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
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
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
    @FocusState private var isMessageFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.title3)
                    .foregroundStyle(.blue.gradient)
                Text("Quick Message")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            VStack(spacing: 16) {
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
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        Text(isSending ? "Sending..." : "Send Message")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending ?
                            .gray.gradient : .blue.gradient
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .blue.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

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

// MARK: - Messaging View
struct MessagingView: View {
    @ObservedObject var chatManager: ChatManager
    @State private var messageText = ""
    @State private var isSending = false
    @FocusState private var isMessageFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if !chatManager.isConnected {
                // Not Connected State
                VStack(spacing: 24) {
                    Spacer()

                    Image(systemName: "wifi.slash")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.gray.gradient)

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

                    Spacer()
                }
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
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                    .background(
                        #if os(iOS)
                        Color(.systemGroupedBackground)
                        #else
                        Color(.controlBackgroundColor)
                        #endif
                    )

                    // Message Input
                    MessageInputView(
                        messageText: $messageText,
                        isSending: $isSending,
                        isMessageFocused: $isMessageFocused,
                        onSend: {
                            sendMessage()
                        }
                    )
                }
            }
        }
        .background(
            #if os(iOS)
            Color(.systemGroupedBackground).ignoresSafeArea()
            #else
            Color(.controlBackgroundColor).ignoresSafeArea()
            #endif
        )
    }

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

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

                Text(message.content)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        isFromCurrentUser ?
                            .blue.gradient :
                            .regularMaterial,
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                    .foregroundColor(isFromCurrentUser ? .white : .primary)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Message Input View
struct MessageInputView: View {
    @Binding var messageText: String
    @Binding var isSending: Bool
    @FocusState.Binding var isMessageFocused: Bool
    let onSend: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                // Text Input
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $messageText)
                        .focused($isMessageFocused)
                }
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))

                // Send Button
                Button(action: onSend) {
                    if isSending {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                .frame(width: 40, height: 40)
                .background(
                    messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                        .gray.gradient : .blue.gradient
                )
                .foregroundColor(.white)
                .clipShape(Circle())
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                .animation(.easeInOut(duration: 0.2), value: messageText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
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
                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(chatManager.eventLogs.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.regularMaterial)

            Divider()

            // Logs List
            if chatManager.eventLogs.isEmpty {
                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.gray.gradient)

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

                    Spacer()
                }
                .padding(.horizontal, 32)
                .background(
                    #if os(iOS)
                    Color(.systemGroupedBackground)
                    #else
                    Color(.controlBackgroundColor)
                    #endif
                )
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(chatManager.eventLogs) { log in
                                LogRowView(log: log)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(
                        #if os(iOS)
                        Color(.systemGroupedBackground)
                        #else
                        Color(.controlBackgroundColor)
                        #endif
                    )
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
        .alert("Clear All Logs", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                chatManager.clearLogs()
            }
        } message: {
            Text("This will permanently delete all event logs. This action cannot be undone.")
        }
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
                .background(log.type.swiftUIColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

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
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
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
