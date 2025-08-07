//
//  WuKongError.swift
//  WuKongEasySDK
//
//  Created by WuKongIM on 2024/08/04.
//  Copyright © 2024 WuKongIM. All rights reserved.
//

import Foundation

/// WuKongIM SDK Error types
public enum WuKongError: Error, LocalizedError, Equatable {
    
    // MARK: - Connection Errors
    
    /// Failed to establish connection to server
    case connectionFailed(String)
    /// Authentication failed with server
    case authFailed(String)
    /// Not connected to server
    case notConnected
    /// Connection timeout
    case connectionTimeout
    /// Server disconnected unexpectedly
    case serverDisconnected(Int, String)
    /// Network error occurred
    case networkError(String)
    
    // MARK: - Message Errors
    
    /// Invalid channel ID or type
    case invalidChannel(String)
    /// Message payload is invalid
    case invalidPayload(String)
    /// Message too large to send
    case messageTooLarge
    /// Message send timeout
    case sendTimeout
    /// Message send failed
    case sendFailed(String)
    
    // MARK: - Configuration Errors
    
    /// Invalid configuration provided
    case invalidConfiguration(String)
    /// Missing required parameters
    case missingParameters([String])
    /// Invalid server URL
    case invalidServerURL
    
    // MARK: - Protocol Errors
    
    /// JSON-RPC protocol error
    case protocolError(Int, String)
    /// Invalid JSON received
    case invalidJSON(String)
    /// Unexpected response format
    case unexpectedResponse(String)
    
    // MARK: - General Errors
    
    /// Unknown error occurred
    case unknown(String)
    /// Operation cancelled
    case cancelled
    /// SDK not initialized
    case notInitialized
    
    // MARK: - LocalizedError Implementation
    
    public var errorDescription: String? {
        switch self {
        // Connection Errors
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .authFailed(let message):
            return "Authentication failed: \(message)"
        case .notConnected:
            return "Not connected to server. Please connect first."
        case .connectionTimeout:
            return "Connection timeout. Please check your network and try again."
        case .serverDisconnected(let code, let reason):
            return "Server disconnected (Code: \(code)): \(reason)"
        case .networkError(let message):
            return "Network error: \(message)"
            
        // Message Errors
        case .invalidChannel(let message):
            return "Invalid channel: \(message)"
        case .invalidPayload(let message):
            return "Invalid message payload: \(message)"
        case .messageTooLarge:
            return "Message is too large to send. Please reduce the content size."
        case .sendTimeout:
            return "Message send timeout. Please try again."
        case .sendFailed(let message):
            return "Failed to send message: \(message)"
            
        // Configuration Errors
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .missingParameters(let parameters):
            return "Missing required parameters: \(parameters.joined(separator: ", "))"
        case .invalidServerURL:
            return "Invalid server URL. Please provide a valid WebSocket URL."
            
        // Protocol Errors
        case .protocolError(let code, let message):
            return "Protocol error (Code: \(code)): \(message)"
        case .invalidJSON(let message):
            return "Invalid JSON format: \(message)"
        case .unexpectedResponse(let message):
            return "Unexpected response format: \(message)"
            
        // General Errors
        case .unknown(let message):
            return "Unknown error: \(message)"
        case .cancelled:
            return "Operation was cancelled"
        case .notInitialized:
            return "SDK not initialized. Please initialize the SDK first."
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .connectionFailed(_):
            return "Unable to establish connection to the WuKongIM server"
        case .authFailed(_):
            return "Server rejected the authentication credentials"
        case .notConnected:
            return "No active connection to the server"
        case .connectionTimeout:
            return "Connection attempt exceeded the timeout limit"
        case .serverDisconnected(_, _):
            return "Server terminated the connection"
        case .networkError(_):
            return "Network connectivity issue"
        case .invalidChannel(_):
            return "Channel information is invalid or malformed"
        case .invalidPayload(_):
            return "Message payload does not meet the required format"
        case .messageTooLarge:
            return "Message exceeds the maximum allowed size"
        case .sendTimeout:
            return "Message send operation exceeded the timeout limit"
        case .sendFailed(_):
            return "Server rejected the message or send operation failed"
        case .invalidConfiguration(_):
            return "SDK configuration contains invalid values"
        case .missingParameters(_):
            return "Required configuration parameters are missing"
        case .invalidServerURL:
            return "Server URL is not a valid WebSocket URL"
        case .protocolError(_, _):
            return "Communication protocol error with server"
        case .invalidJSON(_):
            return "Received data is not valid JSON"
        case .unexpectedResponse(_):
            return "Server response format is unexpected"
        case .unknown(_):
            return "An unexpected error occurred"
        case .cancelled:
            return "Operation was cancelled by user or system"
        case .notInitialized:
            return "SDK has not been properly initialized"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .connectionFailed(_), .connectionTimeout, .networkError(_):
            return "Check your internet connection and server URL, then try again."
        case .authFailed(_):
            return "Verify your user ID and authentication token are correct."
        case .notConnected:
            return "Call connect() method to establish connection before sending messages."
        case .serverDisconnected(_, _):
            return "The SDK will attempt to reconnect automatically."
        case .invalidChannel(_):
            return "Ensure the channel ID and type are valid for your use case."
        case .invalidPayload(_):
            return "Check that your message payload is a valid JSON object."
        case .messageTooLarge:
            return "Reduce the message content size and try again."
        case .sendTimeout, .sendFailed(_):
            return "Check your connection and try sending the message again."
        case .invalidConfiguration(_), .missingParameters(_):
            return "Review your SDK configuration and provide all required parameters."
        case .invalidServerURL:
            return "Provide a valid WebSocket URL (e.g., ws://example.com:5200)."
        case .protocolError(_, _), .invalidJSON(_), .unexpectedResponse(_):
            return "This may be a server compatibility issue. Contact support if it persists."
        case .unknown(_):
            return "Try the operation again. Contact support if the problem persists."
        case .cancelled:
            return "Restart the operation if needed."
        case .notInitialized:
            return "Initialize the SDK with proper configuration before use."
        }
    }
    
    // MARK: - Error Code Mapping
    
    /// Error code for categorizing errors
    public var code: Int {
        switch self {
        // Connection Errors (1000-1099)
        case .connectionFailed(_): return 1001
        case .authFailed(_): return 1002
        case .notConnected: return 1003
        case .connectionTimeout: return 1004
        case .serverDisconnected(_, _): return 1005
        case .networkError(_): return 1006
            
        // Message Errors (1100-1199)
        case .invalidChannel(_): return 1101
        case .invalidPayload(_): return 1102
        case .messageTooLarge: return 1103
        case .sendTimeout: return 1104
        case .sendFailed(_): return 1105
            
        // Configuration Errors (1200-1299)
        case .invalidConfiguration(_): return 1201
        case .missingParameters(_): return 1202
        case .invalidServerURL: return 1203
            
        // Protocol Errors (1300-1399)
        case .protocolError(let code, _): return 1300 + code
        case .invalidJSON(_): return 1301
        case .unexpectedResponse(_): return 1302
            
        // General Errors (1400-1499)
        case .unknown(_): return 1401
        case .cancelled: return 1402
        case .notInitialized: return 1403
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Check if error is related to connection issues
    public var isConnectionError: Bool {
        switch self {
        case .connectionFailed(_), .authFailed(_), .notConnected, .connectionTimeout, .serverDisconnected(_, _), .networkError(_):
            return true
        default:
            return false
        }
    }
    
    /// Check if error is recoverable (can retry)
    public var isRecoverable: Bool {
        switch self {
        case .connectionFailed(_), .connectionTimeout, .networkError(_), .sendTimeout, .sendFailed(_):
            return true
        case .authFailed(_), .invalidChannel(_), .invalidPayload(_), .messageTooLarge, .invalidConfiguration(_), .missingParameters(_), .invalidServerURL:
            return false
        default:
            return true
        }
    }
}

// MARK: - Error Creation Helpers

extension WuKongError {
    
    /// Create error from URLError
    static func from(urlError: URLError) -> WuKongError {
        switch urlError.code {
        case .timedOut:
            return .connectionTimeout
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkError("No internet connection")
        case .cannotConnectToHost, .cannotFindHost:
            return .connectionFailed("Cannot reach server")
        case .cancelled:
            return .cancelled
        default:
            return .networkError(urlError.localizedDescription)
        }
    }
    
    /// Create error from JSON parsing error
    static func from(jsonError: Error) -> WuKongError {
        return .invalidJSON(jsonError.localizedDescription)
    }
    
    /// Create error from WebSocket error
    static func from(webSocketError: URLSessionWebSocketTask.CloseCode, reason: Data?) -> WuKongError {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown reason"
        return .serverDisconnected(webSocketError.rawValue, reasonString)
    }
}

// MARK: - Starscream Error Handling

#if canImport(Starscream)
import Starscream

extension WuKongError {
    /// Create error from Starscream WSError
    static func from(wsError: WSError) -> WuKongError {
        switch wsError.type {
        case .compressionError:
            return .networkError("WebSocket compression error: \(wsError.message)")
        case .securityError:
            return .connectionFailed("WebSocket security error: \(wsError.message)")
        case .protocolError:
            return .protocolError(Int(wsError.code), wsError.message)
        case .serverError:
            return .serverDisconnected(Int(wsError.code), wsError.message)
        @unknown default:
            return .networkError("WebSocket error: \(wsError.message)")
        }
    }
}
#endif
