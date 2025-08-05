//
//  WuKongEventManager.swift
//  WuKongEasySDK
//
//  Created by WuKongIM on 2024/08/04.
//  Copyright © 2024 WuKongIM. All rights reserved.
//

import Foundation

// MARK: - Event Listener Protocol

/// Protocol for event listeners that can be removed
public protocol EventListener: AnyObject {
    /// Unique identifier for the listener
    var id: String { get }
}

// MARK: - Internal Event Listener Implementation

internal class WuKongEventListener: EventListener {
    let id: String
    let callback: (Any) -> Void
    
    init(id: String = UUID().uuidString, callback: @escaping (Any) -> Void) {
        self.id = id
        self.callback = callback
    }
}

// MARK: - Event Manager

/// Thread-safe event management system for WuKongEasySDK
internal class WuKongEventManager {
    
    // MARK: - Properties
    
    private let queue = DispatchQueue(label: "com.wukongim.easysdk.eventmanager", attributes: .concurrent)
    private var listeners: [WuKongEvent: [WeakEventListener]] = [:]
    private let config: WuKongConfig
    
    // MARK: - Initialization
    
    init(config: WuKongConfig) {
        self.config = config
        
        // Initialize empty listener arrays for all events
        for event in WuKongEvent.allCases {
            listeners[event] = []
        }
    }
    
    // MARK: - Event Listener Management
    
    /// Add an event listener for a specific event
    /// - Parameters:
    ///   - event: The event to listen for
    ///   - callback: The callback to execute when the event occurs
    /// - Returns: EventListener that can be used to remove the listener
    func addListener(for event: WuKongEvent, callback: @escaping (Any) -> Void) -> EventListener {
        let listener = WuKongEventListener(callback: callback)
        let weakListener = WeakEventListener(listener: listener)
        
        queue.async(flags: .barrier) {
            self.listeners[event]?.append(weakListener)
            self.cleanupWeakReferences(for: event)
        }
        
        logDebug("Added listener for event: \(event.rawValue), ID: \(listener.id)")
        return listener
    }
    
    /// Remove a specific event listener
    /// - Parameter listener: The listener to remove
    func removeListener(_ listener: EventListener) {
        queue.async(flags: .barrier) {
            for event in WuKongEvent.allCases {
                self.listeners[event]?.removeAll { weakListener in
                    weakListener.listener?.id == listener.id
                }
            }
        }
        
        logDebug("Removed listener with ID: \(listener.id)")
    }
    
    /// Remove all listeners for a specific event
    /// - Parameter event: The event to remove listeners for
    func removeAllListeners(for event: WuKongEvent) {
        queue.async(flags: .barrier) {
            self.listeners[event]?.removeAll()
        }
        
        logDebug("Removed all listeners for event: \(event.rawValue)")
    }
    
    /// Remove all listeners for all events
    func removeAllListeners() {
        queue.async(flags: .barrier) {
            for event in WuKongEvent.allCases {
                self.listeners[event]?.removeAll()
            }
        }
        
        logDebug("Removed all listeners for all events")
    }
    
    // MARK: - Event Emission
    
    /// Emit an event to all registered listeners
    /// - Parameters:
    ///   - event: The event to emit
    ///   - data: The data to pass to listeners
    func emit(_ event: WuKongEvent, data: Any) {
        queue.async {
            let eventListeners = self.listeners[event] ?? []
            let validListeners = eventListeners.compactMap { $0.listener }
            
            self.logDebug("Emitting event: \(event.rawValue) to \(validListeners.count) listeners")
            
            // Execute callbacks on main queue for UI updates
            DispatchQueue.main.async {
                for listener in validListeners {
                    listener.callback(data)
                }
            }
            
            // Clean up weak references after emission
            DispatchQueue.main.async {
                self.queue.async(flags: .barrier) {
                    self.cleanupWeakReferences(for: event)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Clean up weak references that are no longer valid
    /// - Parameter event: The event to clean up references for
    private func cleanupWeakReferences(for event: WuKongEvent) {
        listeners[event]?.removeAll { $0.listener == nil }
    }
    
    /// Get the number of listeners for a specific event
    /// - Parameter event: The event to count listeners for
    /// - Returns: Number of active listeners
    func listenerCount(for event: WuKongEvent) -> Int {
        return queue.sync {
            cleanupWeakReferences(for: event)
            return listeners[event]?.count ?? 0
        }
    }
    
    /// Get the total number of listeners across all events
    /// - Returns: Total number of active listeners
    func totalListenerCount() -> Int {
        return queue.sync {
            var total = 0
            for event in WuKongEvent.allCases {
                cleanupWeakReferences(for: event)
                total += listeners[event]?.count ?? 0
            }
            return total
        }
    }
    
    // MARK: - Logging
    
    private func logDebug(_ message: String) {
        guard config.logLevel.rawValue >= LogLevel.debug.rawValue else { return }
        print("[WuKongEasySDK][EventManager][DEBUG] \(message)")
    }
    
    private func logError(_ message: String) {
        guard config.logLevel.rawValue >= LogLevel.error.rawValue else { return }
        print("[WuKongEasySDK][EventManager][ERROR] \(message)")
    }
}

// MARK: - Weak Event Listener Wrapper

/// Wrapper to hold weak references to event listeners
private class WeakEventListener {
    weak var listener: WuKongEventListener?
    
    init(listener: WuKongEventListener) {
        self.listener = listener
    }
}

// MARK: - Type-Safe Event Listener Extensions

extension WuKongEventManager {
    
    /// Add a connect event listener
    /// - Parameter callback: Callback with ConnectResult
    /// - Returns: EventListener for removal
    func onConnect(_ callback: @escaping (ConnectResult) -> Void) -> EventListener {
        return addListener(for: .connect) { data in
            if let connectResult = data as? ConnectResult {
                callback(connectResult)
            }
        }
    }
    
    /// Add a disconnect event listener
    /// - Parameter callback: Callback with DisconnectInfo
    /// - Returns: EventListener for removal
    func onDisconnect(_ callback: @escaping (DisconnectInfo) -> Void) -> EventListener {
        return addListener(for: .disconnect) { data in
            if let disconnectInfo = data as? DisconnectInfo {
                callback(disconnectInfo)
            }
        }
    }
    
    /// Add a message event listener
    /// - Parameter callback: Callback with Message
    /// - Returns: EventListener for removal
    func onMessage(_ callback: @escaping (Message) -> Void) -> EventListener {
        return addListener(for: .message) { data in
            if let message = data as? Message {
                callback(message)
            }
        }
    }
    
    /// Add an error event listener
    /// - Parameter callback: Callback with Error
    /// - Returns: EventListener for removal
    func onError(_ callback: @escaping (Error) -> Void) -> EventListener {
        return addListener(for: .error) { data in
            if let error = data as? Error {
                callback(error)
            }
        }
    }
    
    /// Add a send acknowledgment event listener
    /// - Parameter callback: Callback with SendResult
    /// - Returns: EventListener for removal
    func onSendAck(_ callback: @escaping (SendResult) -> Void) -> EventListener {
        return addListener(for: .sendAck) { data in
            if let sendResult = data as? SendResult {
                callback(sendResult)
            }
        }
    }
    
    /// Add a reconnecting event listener
    /// - Parameter callback: Callback with reconnection info
    /// - Returns: EventListener for removal
    func onReconnecting(_ callback: @escaping ([String: Any]) -> Void) -> EventListener {
        return addListener(for: .reconnecting) { data in
            if let reconnectInfo = data as? [String: Any] {
                callback(reconnectInfo)
            }
        }
    }

    /// Add a JSON data log event listener
    /// - Parameter callback: Callback with JSONDataLogEvent
    /// - Returns: EventListener for removal
    func onJsonDataLog(_ callback: @escaping (JSONDataLogEvent) -> Void) -> EventListener {
        return addListener(for: .jsonDataLog) { data in
            if let logEvent = data as? JSONDataLogEvent {
                callback(logEvent)
            }
        }
    }
}

// MARK: - Event Emission Extensions

extension WuKongEventManager {
    
    /// Emit connect event
    /// - Parameter result: Connect result
    func emitConnect(_ result: ConnectResult) {
        emit(.connect, data: result)
    }
    
    /// Emit disconnect event
    /// - Parameter info: Disconnect information
    func emitDisconnect(_ info: DisconnectInfo) {
        emit(.disconnect, data: info)
    }
    
    /// Emit message event
    /// - Parameter message: Received message
    func emitMessage(_ message: Message) {
        emit(.message, data: message)
    }
    
    /// Emit error event
    /// - Parameter error: Error that occurred
    func emitError(_ error: Error) {
        emit(.error, data: error)
    }
    
    /// Emit send acknowledgment event
    /// - Parameter result: Send result
    func emitSendAck(_ result: SendResult) {
        emit(.sendAck, data: result)
    }
    
    /// Emit reconnecting event
    /// - Parameters:
    ///   - attempt: Current attempt number
    ///   - delay: Delay before next attempt
    func emitReconnecting(attempt: Int, delay: TimeInterval) {
        let info: [String: Any] = [
            "attempt": attempt,
            "delay": delay
        ]
        emit(.reconnecting, data: info)
    }

    /// Emit JSON data log event
    /// - Parameter logEvent: JSON data log event
    func emitJsonDataLog(_ logEvent: JSONDataLogEvent) {
        emit(.jsonDataLog, data: logEvent)
    }
}
