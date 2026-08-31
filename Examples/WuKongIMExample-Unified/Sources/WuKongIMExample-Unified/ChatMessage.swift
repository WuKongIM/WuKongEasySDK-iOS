import Foundation
import WuKongEasySDK

/// A message rendered by the example UI.
struct ChatMessage: Identifiable, Hashable {
    let id: String
    let content: String
    let fromUserId: String
    let channelId: String
    let channelType: ChannelType
    let timestamp: Date
    let payload: [String: Any]
    let isOutgoing: Bool

    var messageType: Int {
        payload["type"] as? Int ?? 1
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }

    var payloadDescription: String {
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted) else {
            return "Invalid payload"
        }
        return String(data: data, encoding: .utf8) ?? "Invalid payload"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

/// A lifecycle entry rendered in the example's event log.
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
            case .system, .debug: return "blue"
            case .info: return "primary"
            case .success: return "green"
            case .error: return "red"
            case .warning: return "orange"
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

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: EventLog, rhs: EventLog) -> Bool {
        lhs.id == rhs.id
    }
}
