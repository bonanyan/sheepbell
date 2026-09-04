import Foundation

enum HerdrSocketError: Error, Sendable, LocalizedError {
    case connectFailed(String)
    case writeFailed(String)
    case readFailed(String)
    case closed
    case unexpectedFrame
    case missingResult
    case serverError(code: String, message: String)

    var errorDescription: String? {
        switch self {
        case .connectFailed(let detail): "connect failed: \(detail)"
        case .writeFailed(let detail): "write failed: \(detail)"
        case .readFailed(let detail): "read failed: \(detail)"
        case .closed: "connection closed"
        case .unexpectedFrame: "unexpected frame on socket"
        case .missingResult: "response missing result"
        case .serverError(let code, let message): "herdr error \(code): \(message)"
        }
    }
}

private func posixConnect(path: String) throws -> Int32 {
    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    guard fd >= 0 else {
        throw HerdrSocketError.connectFailed(String(cString: strerror(errno)))
    }
    var addr = sockaddr_un()
    addr.sun_family = sa_family_t(AF_UNIX)
    let pathBytes = path.utf8CString
    let capacity = MemoryLayout.size(ofValue: addr.sun_path)
    guard pathBytes.count <= capacity else {
        close(fd)
        throw HerdrSocketError.connectFailed("socket path too long")
    }
    pathBytes.withUnsafeBytes { (rawBuffer: UnsafeRawBufferPointer) in
        withUnsafeMutablePointer(to: &addr.sun_path) { pointer in
            UnsafeMutableRawPointer(pointer).copyMemory(from: rawBuffer.baseAddress!, byteCount: rawBuffer.count)
        }
    }
    let result = withUnsafePointer(to: &addr) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
            connect(fd, sockaddrPointer, socklen_t(MemoryLayout<sockaddr_un>.size))
        }
    }
    guard result == 0 else {
        let detail = String(cString: strerror(errno))
        close(fd)
        throw HerdrSocketError.connectFailed(detail)
    }
    return fd
}

private func posixWrite(fd: Int32, data: Data) throws {
    try data.withUnsafeBytes { (rawBuffer: UnsafeRawBufferPointer) in
        var written = 0
        while written < rawBuffer.count {
            let result = write(fd, rawBuffer.baseAddress!.advanced(by: written), rawBuffer.count - written)
            if result < 0 {
                if errno == EINTR { continue }
                throw HerdrSocketError.writeFailed(String(cString: strerror(errno)))
            }
            written += result
        }
    }
}

private func posixReadLine(fd: Int32, buffer: inout Data) throws -> Data? {
    while true {
        if let index = buffer.firstIndex(of: 0x0A) {
            let line = buffer.subdata(in: buffer.startIndex..<index)
            buffer.removeSubrange(buffer.startIndex...index)
            return line
        }
        var chunk = [UInt8](repeating: 0, count: 65536)
        let count = read(fd, &chunk, chunk.count)
        if count < 0 {
            if errno == EINTR { continue }
            throw HerdrSocketError.readFailed(String(cString: strerror(errno)))
        }
        if count == 0 {
            if buffer.isEmpty { return nil }
            let remainder = buffer
            buffer.removeAll()
            return remainder
        }
        buffer.append(contentsOf: chunk[0..<count])
    }
}

private final class SubscriptionState: @unchecked Sendable {
    private let lock = NSLock()
    private var fd: Int32 = -1
    private var isCancelled = false

    func set(_ value: Int32) {
        lock.lock()
        defer { lock.unlock() }
        fd = value
    }

    func peek() -> Int32 {
        lock.lock()
        defer { lock.unlock() }
        return fd
    }

    func take() -> Int32 {
        lock.lock()
        defer { lock.unlock() }
        let value = fd
        fd = -1
        return value
    }

    func cancel() {
        lock.lock()
        isCancelled = true
        let value = fd
        lock.unlock()
        if value >= 0 {
            shutdown(value, SHUT_RDWR)
        }
    }

    var cancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isCancelled
    }
}

actor HerdrSocket {
    let path: String
    private let ioQueue = DispatchQueue(label: "dev.herdr.bell.socket.io")

    init(path: String) {
        self.path = path
    }

    func ping() async throws -> PingResult {
        try await requestResult("ping", as: PingResult.self)
    }

    func sessionSnapshot() async throws -> SessionSnapshot {
        try await requestResult("session.snapshot", as: SnapshotResult.self).snapshot
    }

    func agentList() async throws -> [AgentInfo] {
        try await requestResult("agent.list", as: AgentListResult.self).agents
    }

    func agentFocus(target: String) async throws {
        _ = try await request("agent.focus", params: .object(["target": .string(target)]))
    }

    func request(_ method: String, params: JSONValue = .object([:])) async throws -> JSONValue? {
        let id = "req_" + UUID().uuidString
        let requestLine = try Wire.encodeRequest(id: id, method: method, params: params)
        let responseLine = try await runBlocking { path in
            let fd = try posixConnect(path: path)
            defer { close(fd) }
            try posixWrite(fd: fd, data: requestLine)
            var buffer = Data()
            guard let line = try posixReadLine(fd: fd, buffer: &buffer) else {
                throw HerdrSocketError.closed
            }
            return line
        }
        guard case .response(let response) = try Wire.parseFrame(responseLine) else {
            throw HerdrSocketError.unexpectedFrame
        }
        if let error = response.error {
            throw HerdrSocketError.serverError(code: error.code, message: error.message)
        }
        return response.result
    }

    func subscribe(_ subscriptions: [JSONValue]) -> AsyncThrowingStream<HerdrEventEnvelope, Error> {
        let path = self.path
        let queue = self.ioQueue
        return AsyncThrowingStream { continuation in
            let state = SubscriptionState()
            queue.async {
                do {
                    let fd = try posixConnect(path: path)
                    state.set(fd)
                    let requestLine = try Wire.encodeRequest(
                        id: "req_sub",
                        method: "events.subscribe",
                        params: .object(["subscriptions": .array(subscriptions)])
                    )
                    try posixWrite(fd: fd, data: requestLine)
                    var buffer = Data()
                    guard let first = try posixReadLine(fd: fd, buffer: &buffer) else {
                        throw HerdrSocketError.closed
                    }
                    guard case .response(let response) = try Wire.parseFrame(first) else {
                        throw HerdrSocketError.unexpectedFrame
                    }
                    if let error = response.error {
                        throw HerdrSocketError.serverError(code: error.code, message: error.message)
                    }
                    while !state.cancelled {
                        guard let line = try posixReadLine(fd: fd, buffer: &buffer) else { break }
                        if case .event(let event) = try Wire.parseFrame(line) {
                            continuation.yield(event)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
                let fd = state.take()
                if fd >= 0 {
                    close(fd)
                }
            }
            continuation.onTermination = { _ in
                state.cancel()
            }
        }
    }

    private func requestResult<T: Decodable>(_ method: String, params: JSONValue = .object([:]), as type: T.Type) async throws -> T {
        guard let result = try await request(method, params: params) else {
            throw HerdrSocketError.missingResult
        }
        return try Wire.decodeResult(result, as: T.self)
    }

    private func runBlocking<T: Sendable>(_ body: @escaping @Sendable (String) throws -> T) async throws -> T {
        let path = self.path
        return try await withCheckedThrowingContinuation { continuation in
            ioQueue.async {
                do {
                    continuation.resume(returning: try body(path))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
