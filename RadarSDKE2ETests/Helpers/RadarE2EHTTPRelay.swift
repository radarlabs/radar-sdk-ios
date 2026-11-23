import Foundation
import Network

/// Forwards the SDK's loopback HTTP requests to the configured API and records track traffic.
final class RadarE2EHTTPRelay: @unchecked Sendable {
    struct TrackExchange {
        let body: Data
        var statusCode: Int?
    }

    private let upstream: URL
    private let listener: NWListener
    private let queue = DispatchQueue(label: "io.radar.e2e.http-relay")
    private let session = URLSession(configuration: .ephemeral)
    private var trackExchanges: [TrackExchange] = []
    private static let maxRequestBytes = 1_048_576

    var tracks: [TrackExchange] { queue.sync { trackExchanges } }
    var host: String { "http://127.0.0.1:\(listener.port?.rawValue ?? 0)" }

    init(upstream: URL) throws {
        self.upstream = upstream
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
        listener = try NWListener(using: parameters)

        let ready = DispatchSemaphore(value: 0)
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready, .failed, .cancelled: ready.signal()
            default: break
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            guard let self else {
                connection.cancel()
                return
            }
            connection.start(queue: self.queue)
            self.readRequest(from: connection)
        }
        listener.start(queue: queue)
        guard ready.wait(timeout: .now() + 5) == .success, listener.port != nil else {
            stop()
            throw URLError(.cannotConnectToHost)
        }
    }

    func stop() {
        listener.cancel()
        session.invalidateAndCancel()
    }

    private func readRequest(from connection: NWConnection, buffered: Data = Data()) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, complete, error in
            guard let self, error == nil else {
                connection.cancel()
                return
            }
            let bytes = buffered + (data ?? Data())
            do {
                guard bytes.count <= Self.maxRequestBytes else { throw URLError(.dataLengthExceedsMaximum) }
                if let request = try HTTPRequest(bytes: bytes, upstream: self.upstream) {
                    self.forward(request, to: connection)
                } else if complete {
                    connection.cancel()
                } else {
                    self.readRequest(from: connection, buffered: bytes)
                }
            } catch {
                Self.send(statusCode: 400, body: Data(), to: connection)
            }
        }
    }

    private func forward(_ request: HTTPRequest, to connection: NWConnection) {
        let trackIndex = trackExchanges.count
        let isTrack = request.urlRequest.httpMethod == "POST" && request.urlRequest.url?.path == "/v1/track"
        if isTrack {
            trackExchanges.append(.init(body: request.body))
        }
        session.dataTask(with: request.urlRequest) { [weak self] data, response, _ in
            guard let self else {
                connection.cancel()
                return
            }
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? 502
            let headers = (httpResponse?.allHeaderFields ?? [:]).reduce(into: [String: String]()) { result, field in
                if let name = field.key as? String, let value = field.value as? String {
                    result[name] = value
                }
            }
            self.queue.async {
                if isTrack {
                    self.trackExchanges[trackIndex].statusCode = statusCode
                }
                Self.send(statusCode: statusCode, headers: headers, body: data ?? Data(), to: connection)
            }
        }.resume()
    }

    private static func send(statusCode: Int, headers: [String: String] = [:], body: Data, to connection: NWConnection) {
        let filteredHeaders = headers.compactMap { key, value -> String? in
            guard !["connection", "content-encoding", "content-length", "transfer-encoding"].contains(key.lowercased()) else { return nil }
            return "\(key): \(value)\r\n"
        }.joined()
        let header = "HTTP/1.1 \(statusCode) Upstream\r\nContent-Length: \(body.count)\r\nConnection: close\r\n\(filteredHeaders)\r\n"
        connection.send(content: Data(header.utf8) + body, completion: .contentProcessed { _ in connection.cancel() })
    }
}

private struct HTTPRequest {
    let urlRequest: URLRequest
    let body: Data

    init?(bytes: Data, upstream: URL) throws {
        guard let separator = bytes.range(of: Data("\r\n\r\n".utf8)) else { return nil }
        let lines = String(bytes: bytes.prefix(upTo: separator.lowerBound), encoding: .utf8)?.components(separatedBy: "\r\n") ?? []
        let requestLine = lines.first?.split(separator: " ") ?? []
        guard requestLine.count == 3, requestLine[1].hasPrefix("/"), !requestLine[1].hasPrefix("//"),
            let url = URL(string: String(requestLine[1]), relativeTo: upstream)?.absoluteURL
        else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = String(requestLine[0])
        var contentLength = 0
        for line in lines.dropFirst() {
            guard let colon = line.firstIndex(of: ":") else { throw URLError(.cannotParseResponse) }
            let name = String(line[..<colon])
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            switch name.lowercased() {
            case "content-length":
                guard let length = Int(value), length >= 0 else { throw URLError(.cannotParseResponse) }
                contentLength = length
            case "host", "connection", "accept-encoding":
                break
            case "transfer-encoding":
                throw URLError(.cannotParseResponse)
            default:
                request.addValue(value, forHTTPHeaderField: name)
            }
        }
        let availableBody = bytes.suffix(from: separator.upperBound)
        guard availableBody.count >= contentLength else { return nil }
        body = Data(availableBody.prefix(contentLength))
        request.httpBody = body.isEmpty ? nil : body
        urlRequest = request
    }
}
