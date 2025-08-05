//
//  ChatMessage.swift
//  WuKongIMExample
//
//  Created by WuKongIM on 2024/08/04.
//  Copyright © 2024 WuKongIM. All rights reserved.
//

import Foundation
import WuKongEasySDK

/// Represents a chat message in the UI
struct ChatMessage: Identifiable, Hashable {
    let id: String
    let content: String
    let fromUserId: String
    let channelId: String
    let channelType: ChannelType
    let timestamp: Date
    let payload: [String: Any]
    let isOutgoing: Bool
    
    // MARK: - Computed Properties
    
    var messageType: Int {
        return payload["type"] as? Int ?? 1
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
    
    var payloadDescription: String {
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
            return String(data: data, encoding: .utf8) ?? "Invalid payload"
        } catch {
            return "Error formatting payload: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Hashable Implementation
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Event log entry for the event log display
struct EventLog: Identifiable, Hashable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let type: LogType
    
    enum LogType {
        case system
        case info
        case success
        case error
        case warning
        case debug

        var color: String {
            switch self {
            case .system: return "blue"
            case .info: return "primary"
            case .success: return "green"
            case .error: return "red"
            case .warning: return "orange"
            case .debug: return "blue"
            }
        }

        var icon: String {
            switch self {
            case .system: return "gear"
            case .info: return "info.circle"
            case .success: return "checkmark.circle"
            case .error: return "exclamationmark.triangle"
            case .warning: return "exclamationmark.circle"
            case .debug: return "ladybug"
            }
        }
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: timestamp)
    }

    var timestampString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "[HH:mm:ss]"
        return formatter.string(from: timestamp)
    }
    
    // MARK: - Hashable Implementation
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: EventLog, rhs: EventLog) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Message template for quick sending
struct MessageTemplate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let payload: [String: Any]
    
    var payloadJson: String {
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{}"
        }
    }
    
    // MARK: - Hashable Implementation
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MessageTemplate, rhs: MessageTemplate) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Predefined Templates
    
    static let templates: [MessageTemplate] = [
        MessageTemplate(
            name: "Simple Text",
            description: "Basic text message",
            payload: [
                "type": 1,
                "content": "Hello from iOS!"
            ]
        ),
        MessageTemplate(
            name: "Rich Text",
            description: "Text with metadata",
            payload: [
                "type": 1,
                "content": "Hello with metadata! 🎉",
                "metadata": [
                    "platform": "iOS",
                    "timestamp": Date().timeIntervalSince1970,
                    "version": "1.0.0"
                ]
            ]
        ),
        MessageTemplate(
            name: "Image Message",
            description: "Simulated image message",
            payload: [
                "type": 2,
                "content": "Check out this image!",
                "image": [
                    "url": "https://example.com/image.jpg",
                    "width": 1920,
                    "height": 1080,
                    "size": 245760
                ]
            ]
        ),
        MessageTemplate(
            name: "Location Message",
            description: "Location sharing message",
            payload: [
                "type": 3,
                "content": "I'm here!",
                "location": [
                    "latitude": 37.7749,
                    "longitude": -122.4194,
                    "address": "San Francisco, CA"
                ]
            ]
        ),
        MessageTemplate(
            name: "Custom Action",
            description: "Custom action message",
            payload: [
                "type": 100,
                "action": "user_typing",
                "user_id": "testUser",
                "timestamp": Date().timeIntervalSince1970
            ]
        ),
        MessageTemplate(
            name: "File Message",
            description: "File sharing message",
            payload: [
                "type": 4,
                "content": "Shared a file",
                "file": [
                    "name": "document.pdf",
                    "size": 1024000,
                    "url": "https://example.com/files/document.pdf",
                    "mime_type": "application/pdf"
                ]
            ]
        )
    ]
}

/// Represents recipient information for quick access
struct RecipientInfo: Identifiable, Hashable, Codable {
    let id = UUID()
    let channelId: String
    let channelType: ChannelType
    let displayName: String
    let lastUsed: Date

    // MARK: - Computed Properties

    var typeIcon: String {
        return channelType == .person ? "person.circle" : "person.3"
    }

    var formattedLastUsed: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUsed, relativeTo: Date())
    }

    // MARK: - Hashable Implementation

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: RecipientInfo, rhs: RecipientInfo) -> Bool {
        return lhs.id == rhs.id
    }
}
