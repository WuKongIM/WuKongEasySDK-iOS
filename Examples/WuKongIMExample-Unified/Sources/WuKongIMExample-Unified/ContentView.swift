//
//  ContentView.swift
//  WuKongIMExample - Pure iOS Version
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
                    .navigationTitle("Connect")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
            .tabItem {
                Image(systemName: "wifi")
                Text("Connect")
            }
            .tag(0)
            
            // Logs Tab
            NavigationView {
                LogsView(chatManager: chatManager)
                    .navigationTitle("Logs")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
            .tabItem {
                Image(systemName: "list.bullet.rectangle")
                Text("Logs")
            }
            .tag(1)
        }
        .accentColor(.blue)
    }
}

// MARK: - Connection View
struct ConnectionView: View {
    @ObservedObject var chatManager: ChatManager
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Connection Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Server Configuration")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "server.rack")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            TextField("Server URL", text: $chatManager.serverUrl)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($isInputFocused)
                        }
                        
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.green)
                                .frame(width: 20)
                            TextField("User ID", text: $chatManager.uid)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($isInputFocused)
                        }
                        
                        HStack {
                            Image(systemName: "key")
                                .foregroundColor(.orange)
                                .frame(width: 20)
                            TextField("Token", text: $chatManager.token)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($isInputFocused)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Connection Status
                VStack(spacing: 12) {
                    HStack {
                        Circle()
                            .fill(chatManager.isConnected ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        
                        Text(chatManager.isConnected ? "Connected" : "Disconnected")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    
                    if chatManager.isConnecting {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Connecting...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
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
                    HStack {
                        Image(systemName: chatManager.isConnected ? "wifi.slash" : "wifi")
                        Text(chatManager.isConnected ? "Disconnect" : "Connect")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(chatManager.isConnected ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(chatManager.isConnecting)
                
                // Messaging Section (only when connected)
                if chatManager.isConnected {
                    MessagingSection(chatManager: chatManager)
                }
                
                Spacer(minLength: 100) // Extra space for keyboard
            }
            .padding()
        }
        .onTapGesture {
            isInputFocused = false
        }
    }
}

// MARK: - Messaging Section
struct MessagingSection: View {
    @ObservedObject var chatManager: ChatManager
    @State private var messageText = ""
    @State private var isSending = false
    @FocusState private var isMessageFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Send Message")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "message")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    #if os(iOS)
                    if #available(iOS 16.0, *) {
                        TextField("Enter your message", text: $messageText, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isMessageFocused)
                            .lineLimit(3...6)
                    } else {
                        TextField("Enter your message", text: $messageText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isMessageFocused)
                    }
                    #else
                    if #available(macOS 13.0, *) {
                        TextField("Enter your message", text: $messageText, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isMessageFocused)
                            .lineLimit(3...6)
                    } else {
                        TextField("Enter your message", text: $messageText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isMessageFocused)
                    }
                    #endif
                }
                
                Button(action: {
                    sendMessage()
                }) {
                    HStack {
                        if isSending {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        Text(isSending ? "Sending..." : "Send Message")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(messageText.isEmpty || isSending ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(messageText.isEmpty || isSending)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        isSending = true
        isMessageFocused = false
        
        Task {
            await chatManager.sendMessage(messageText)
            await MainActor.run {
                messageText = ""
                isSending = false
            }
        }
    }
}

// MARK: - Logs View
struct LogsView: View {
    @ObservedObject var chatManager: ChatManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Clear Button
            HStack {
                Spacer()
                Button("Clear Logs") {
                    chatManager.clearLogs()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // Logs List
            if chatManager.eventLogs.isEmpty {
                VStack {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No logs yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Connect to the server to see logs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.primary.colorInvert())
            } else {
                ScrollViewReader { proxy in
                    List {
                        ForEach(chatManager.eventLogs) { log in
                            LogRowView(log: log)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
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
    }
}

// MARK: - Log Row View
struct LogRowView: View {
    let log: EventLog
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Log Level Badge
                Text(log.type.displayName.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(log.type.swiftUIColor)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                
                // Timestamp
                Text(log.formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Message
            Text(isExpanded ? log.message : String(log.message.prefix(100)))
                .font(.system(size: 14))
                .foregroundColor(.primary)
            
            if log.message.count > 100 {
                Button(isExpanded ? "Show Less" : "Show More") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.vertical, 4)
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
