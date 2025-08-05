//
//  WuKongConfig.swift
//  WuKongEasySDK
//
//  Created by WuKongIM on 2024/08/04.
//  Copyright © 2024 WuKongIM. All rights reserved.
//

import Foundation

/// Configuration class for WuKongEasySDK
public class WuKongConfig {
    
    // MARK: - Required Properties
    
    /// WebSocket server URL (e.g., "ws://your-server.com:5200")
    public let serverUrl: String
    
    /// User ID for authentication
    public let uid: String
    
    /// Authentication token
    public let token: String
    
    // MARK: - Optional Properties
    
    /// Device ID (auto-generated if not provided)
    public let deviceId: String
    
    /// Device flag indicating the type of device
    public let deviceFlag: DeviceFlag
    
    // MARK: - Connection Settings
    
    /// Connection timeout in seconds (default: 30)
    public let connectionTimeout: TimeInterval
    
    /// Request timeout in seconds (default: 15)
    public let requestTimeout: TimeInterval
    
    /// Ping interval in seconds (default: 25)
    public let pingInterval: TimeInterval
    
    /// Pong timeout in seconds (default: 10)
    public let pongTimeout: TimeInterval
    
    // MARK: - Reconnection Settings
    
    /// Maximum number of reconnection attempts (default: 5)
    public let maxReconnectAttempts: Int
    
    /// Initial reconnection delay in seconds (default: 1)
    public let initialReconnectDelay: TimeInterval
    
    /// Maximum reconnection delay in seconds (default: 30)
    public let maxReconnectDelay: TimeInterval
    
    /// Whether to enable automatic reconnection (default: true)
    public let autoReconnect: Bool
    
    // MARK: - Logging Settings

    /// Whether to enable debug logging (default: false)
    public let enableDebugLogging: Bool

    /// Log level for SDK operations
    public let logLevel: LogLevel

    /// Whether to enable JSON data logging for debugging (default: true)
    public let enableJsonLogging: Bool
    
    // MARK: - Initialization
    
    /// Initialize WuKongConfig with required parameters
    /// - Parameters:
    ///   - serverUrl: WebSocket server URL
    ///   - uid: User ID for authentication
    ///   - token: Authentication token
    ///   - deviceId: Optional device ID (auto-generated if nil)
    ///   - deviceFlag: Device type flag (default: .app)
    ///   - connectionTimeout: Connection timeout in seconds (default: 30)
    ///   - requestTimeout: Request timeout in seconds (default: 15)
    ///   - pingInterval: Ping interval in seconds (default: 25)
    ///   - pongTimeout: Pong timeout in seconds (default: 10)
    ///   - maxReconnectAttempts: Maximum reconnection attempts (default: 5)
    ///   - initialReconnectDelay: Initial reconnection delay in seconds (default: 1)
    ///   - maxReconnectDelay: Maximum reconnection delay in seconds (default: 30)
    ///   - autoReconnect: Enable automatic reconnection (default: true)
    ///   - enableDebugLogging: Enable debug logging (default: false)
    ///   - logLevel: Log level (default: .info)
    ///   - enableJsonLogging: Enable JSON data logging (default: true)
    public init(
        serverUrl: String,
        uid: String,
        token: String,
        deviceId: String? = nil,
        deviceFlag: DeviceFlag = .app,
        connectionTimeout: TimeInterval = 30,
        requestTimeout: TimeInterval = 15,
        pingInterval: TimeInterval = 25,
        pongTimeout: TimeInterval = 10,
        maxReconnectAttempts: Int = 5,
        initialReconnectDelay: TimeInterval = 1,
        maxReconnectDelay: TimeInterval = 30,
        autoReconnect: Bool = true,
        enableDebugLogging: Bool = false,
        logLevel: LogLevel = .info,
        enableJsonLogging: Bool = true
    ) throws {
        // Validate required parameters
        guard !serverUrl.isEmpty else {
            throw WuKongError.missingParameters(["serverUrl"])
        }
        
        guard !uid.isEmpty else {
            throw WuKongError.missingParameters(["uid"])
        }
        
        guard !token.isEmpty else {
            throw WuKongError.missingParameters(["token"])
        }
        
        // Validate server URL format
        guard Self.isValidWebSocketURL(serverUrl) else {
            throw WuKongError.invalidServerURL
        }
        
        // Validate timeout values
        guard connectionTimeout > 0 else {
            throw WuKongError.invalidConfiguration("connectionTimeout must be greater than 0")
        }
        
        guard requestTimeout > 0 else {
            throw WuKongError.invalidConfiguration("requestTimeout must be greater than 0")
        }
        
        guard pingInterval > 0 else {
            throw WuKongError.invalidConfiguration("pingInterval must be greater than 0")
        }
        
        guard pongTimeout > 0 else {
            throw WuKongError.invalidConfiguration("pongTimeout must be greater than 0")
        }
        
        // Validate reconnection settings
        guard maxReconnectAttempts >= 0 else {
            throw WuKongError.invalidConfiguration("maxReconnectAttempts must be >= 0")
        }
        
        guard initialReconnectDelay > 0 else {
            throw WuKongError.invalidConfiguration("initialReconnectDelay must be greater than 0")
        }
        
        guard maxReconnectDelay >= initialReconnectDelay else {
            throw WuKongError.invalidConfiguration("maxReconnectDelay must be >= initialReconnectDelay")
        }
        
        // Assign values
        self.serverUrl = serverUrl
        self.uid = uid
        self.token = token
        self.deviceId = deviceId ?? Self.generateDeviceId()
        self.deviceFlag = deviceFlag
        self.connectionTimeout = connectionTimeout
        self.requestTimeout = requestTimeout
        self.pingInterval = pingInterval
        self.pongTimeout = pongTimeout
        self.maxReconnectAttempts = maxReconnectAttempts
        self.initialReconnectDelay = initialReconnectDelay
        self.maxReconnectDelay = maxReconnectDelay
        self.autoReconnect = autoReconnect
        self.enableDebugLogging = enableDebugLogging
        self.logLevel = logLevel
        self.enableJsonLogging = enableJsonLogging
    }
    
    // MARK: - Validation Helpers
    
    /// Validate if the provided URL is a valid WebSocket URL
    /// - Parameter urlString: URL string to validate
    /// - Returns: true if valid WebSocket URL, false otherwise
    private static func isValidWebSocketURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else {
            return false
        }
        
        guard let scheme = url.scheme?.lowercased() else {
            return false
        }
        
        return scheme == "ws" || scheme == "wss"
    }
    
    /// Generate a unique device ID
    /// - Returns: Generated device ID string
    private static func generateDeviceId() -> String {
        return UUID().uuidString.lowercased()
    }
    
    // MARK: - Computed Properties
    
    /// Get authentication options for connection
    public var authOptions: AuthOptions {
        return AuthOptions(
            uid: uid,
            token: token,
            deviceId: deviceId,
            deviceFlag: deviceFlag
        )
    }
    
    /// Get server URL as URL object
    public var serverURL: URL? {
        return URL(string: serverUrl)
    }
    
    /// Check if debug logging is enabled
    public var isDebugEnabled: Bool {
        return enableDebugLogging || logLevel == .debug
    }
}

// MARK: - Log Level Enum

/// Log level for SDK operations
public enum LogLevel: Int, CaseIterable {
    /// No logging
    case none = 0
    /// Error messages only
    case error = 1
    /// Warning and error messages
    case warning = 2
    /// Info, warning, and error messages
    case info = 3
    /// All messages including debug
    case debug = 4
    
    /// String representation of log level
    public var description: String {
        switch self {
        case .none: return "NONE"
        case .error: return "ERROR"
        case .warning: return "WARNING"
        case .info: return "INFO"
        case .debug: return "DEBUG"
        }
    }
}

// MARK: - Configuration Builder

/// Builder pattern for creating WuKongConfig
public class WuKongConfigBuilder {
    private var serverUrl: String = ""
    private var uid: String = ""
    private var token: String = ""
    private var deviceId: String?
    private var deviceFlag: DeviceFlag = .app
    private var connectionTimeout: TimeInterval = 30
    private var requestTimeout: TimeInterval = 15
    private var pingInterval: TimeInterval = 25
    private var pongTimeout: TimeInterval = 10
    private var maxReconnectAttempts: Int = 5
    private var initialReconnectDelay: TimeInterval = 1
    private var maxReconnectDelay: TimeInterval = 30
    private var autoReconnect: Bool = true
    private var enableDebugLogging: Bool = false
    private var logLevel: LogLevel = .info
    
    public init() {}
    
    @discardableResult
    public func serverUrl(_ url: String) -> WuKongConfigBuilder {
        self.serverUrl = url
        return self
    }
    
    @discardableResult
    public func uid(_ uid: String) -> WuKongConfigBuilder {
        self.uid = uid
        return self
    }
    
    @discardableResult
    public func token(_ token: String) -> WuKongConfigBuilder {
        self.token = token
        return self
    }
    
    @discardableResult
    public func deviceId(_ deviceId: String?) -> WuKongConfigBuilder {
        self.deviceId = deviceId
        return self
    }
    
    @discardableResult
    public func deviceFlag(_ flag: DeviceFlag) -> WuKongConfigBuilder {
        self.deviceFlag = flag
        return self
    }
    
    @discardableResult
    public func connectionTimeout(_ timeout: TimeInterval) -> WuKongConfigBuilder {
        self.connectionTimeout = timeout
        return self
    }
    
    @discardableResult
    public func requestTimeout(_ timeout: TimeInterval) -> WuKongConfigBuilder {
        self.requestTimeout = timeout
        return self
    }
    
    @discardableResult
    public func pingInterval(_ interval: TimeInterval) -> WuKongConfigBuilder {
        self.pingInterval = interval
        return self
    }
    
    @discardableResult
    public func pongTimeout(_ timeout: TimeInterval) -> WuKongConfigBuilder {
        self.pongTimeout = timeout
        return self
    }
    
    @discardableResult
    public func maxReconnectAttempts(_ attempts: Int) -> WuKongConfigBuilder {
        self.maxReconnectAttempts = attempts
        return self
    }
    
    @discardableResult
    public func initialReconnectDelay(_ delay: TimeInterval) -> WuKongConfigBuilder {
        self.initialReconnectDelay = delay
        return self
    }
    
    @discardableResult
    public func maxReconnectDelay(_ delay: TimeInterval) -> WuKongConfigBuilder {
        self.maxReconnectDelay = delay
        return self
    }
    
    @discardableResult
    public func autoReconnect(_ enabled: Bool) -> WuKongConfigBuilder {
        self.autoReconnect = enabled
        return self
    }
    
    @discardableResult
    public func enableDebugLogging(_ enabled: Bool) -> WuKongConfigBuilder {
        self.enableDebugLogging = enabled
        return self
    }
    
    @discardableResult
    public func logLevel(_ level: LogLevel) -> WuKongConfigBuilder {
        self.logLevel = level
        return self
    }
    
    public func build() throws -> WuKongConfig {
        return try WuKongConfig(
            serverUrl: serverUrl,
            uid: uid,
            token: token,
            deviceId: deviceId,
            deviceFlag: deviceFlag,
            connectionTimeout: connectionTimeout,
            requestTimeout: requestTimeout,
            pingInterval: pingInterval,
            pongTimeout: pongTimeout,
            maxReconnectAttempts: maxReconnectAttempts,
            initialReconnectDelay: initialReconnectDelay,
            maxReconnectDelay: maxReconnectDelay,
            autoReconnect: autoReconnect,
            enableDebugLogging: enableDebugLogging,
            logLevel: logLevel
        )
    }
}
