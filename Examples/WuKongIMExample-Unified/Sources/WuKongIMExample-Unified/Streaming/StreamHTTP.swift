import Foundation

/// Fixed public errors avoid surfacing credential-bearing URLs or upstream bodies.
enum StreamFailure: Error { case invalidAddress, http, limit, malformed, model, eventWrite, check(String) }

/// Ephemeral, bounded HTTP transport; redirects never forward model credentials.
final class StreamHTTP: NSObject, URLSessionTaskDelegate {
    private let timeout: TimeInterval
    private let resourceTimeout: TimeInterval
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = resourceTimeout
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    init(timeout: TimeInterval = 15, resourceTimeout: TimeInterval = 30) {
        self.timeout = timeout; self.resourceTimeout = resourceTimeout
    }
    func bytes(_ request: URLRequest) async throws -> URLSession.AsyncBytes {
        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw StreamFailure.http }
        return bytes
    }
    func json(_ request: URLRequest) async throws -> [String: Any] {
        var data = Data()
        let stream = try await bytes(request)
        defer { stream.task.cancel() }
        for try await byte in stream {
            guard data.count < 2 * 1024 * 1024 else { throw StreamFailure.limit }
            data.append(byte)
        }
        guard let value = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              value["status"] == nil || number(value["status"]) == 200 else { throw StreamFailure.http }
        return value
    }
    func close() { session.invalidateAndCancel() }
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) { completionHandler(nil) }
}

/// Direct management access is for this writable development demo, not production clients.
final class StreamAPI {
    let base: URL
    private let http = StreamHTTP()
    init(_ address: String) throws {
        guard let url = URL(string: address), ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              url.host != nil, url.user == nil, url.password == nil, url.query == nil, url.fragment == nil else { throw StreamFailure.invalidAddress }
        base = url
    }
    func post(_ path: String, _ body: [String: Any]) async throws -> [String: Any] {
        var request = URLRequest(url: base.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))))
        request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await http.json(request)
    }
    func route(_ uid: String) async throws -> String {
        var components = URLComponents(url: base.appendingPathComponent("route"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "uid", value: uid)]
        let value = try await http.json(URLRequest(url: components.url!))
        let address = (value["wss_addr"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? value["ws_addr"] as? String ?? ""
        guard address.hasPrefix("ws://") || address.hasPrefix("wss://") else { throw StreamFailure.invalidAddress }
        return address
    }
    func close() { http.close() }
}

struct StreamModelConfig: CustomStringConvertible {
    let url: String
    let model: String
    let key: String
    var description: String { "StreamModelConfig(<redacted>)" }
}

/// Text-only Chat Completions SSE reader with byte, line, event and reply limits.
final class StreamModel {
    private let http = StreamHTTP(timeout: 30, resourceTimeout: 180)
    func cancel() { http.close() }
    func consume(_ config: StreamModelConfig, context: [[String: String]], emit: (String) async throws -> Void) async throws {
        guard var url = URLComponents(string: config.url), ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              url.host != nil, url.user == nil, url.password == nil, url.fragment == nil, !config.model.isEmpty else { throw StreamFailure.invalidAddress }
        if !url.path.hasSuffix("/chat/completions") { url.path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")); url.path = "/" + (url.path.isEmpty ? "" : url.path + "/") + "chat/completions" }
        guard let endpoint = url.url else { throw StreamFailure.invalidAddress }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        if !config.key.isEmpty { request.setValue("Bearer " + config.key, forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONSerialization.data(withJSONObject: ["model": config.model, "messages": context, "stream": true])
        guard request.httpBody!.count <= 131072 else { throw StreamFailure.limit }
        var line: [UInt8] = [], event: [String] = []
        var total = 0, eventSize = 0, textSize = 0
        let stream = try await http.bytes(request)
        defer { stream.task.cancel() }
        for try await byte in stream {
            total += 1
            guard total <= 4 * 1024 * 1024 else { throw StreamFailure.limit }
            if byte != 10 {
                guard line.count < 65536 else { throw StreamFailure.limit }
                line.append(byte); continue
            }
            if line.last == 13 { line.removeLast() }
            guard let value = String(bytes: line, encoding: .utf8) else { throw StreamFailure.malformed }
            line.removeAll(keepingCapacity: true)
            if value.isEmpty {
                if !event.isEmpty {
                    let data = event.joined(separator: "\n")
                    event.removeAll(keepingCapacity: true); eventSize = 0
                    if data == "[DONE]" { return }
                    guard let object = try JSONSerialization.jsonObject(with: Data(data.utf8)) as? [String: Any], object["error"] == nil else { throw StreamFailure.model }
                    for choice in object["choices"] as? [[String: Any]] ?? [] where number(choice["index"]) == 0 {
                        if let delta = (choice["delta"] as? [String: Any])?["content"] as? String, !delta.isEmpty {
                            textSize += delta.utf16.count
                            guard textSize <= 16384 else { throw StreamFailure.limit }
                            try await emit(delta)
                        }
                    }
                }
            } else if value.hasPrefix("data:") {
                var data = String(value.dropFirst(5)); if data.first == " " { data.removeFirst() }
                eventSize += data.utf8.count + 1
                guard eventSize <= 65536 else { throw StreamFailure.limit }
                event.append(data)
            }
        }
        // A clean transport EOF without [DONE] is still an incomplete model reply.
        throw StreamFailure.model
    }
}
