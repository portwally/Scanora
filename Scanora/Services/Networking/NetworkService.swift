import Foundation

// MARK: - Network Service Protocol

protocol NetworkServiceProtocol: Sendable {
    func fetch<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
    func fetchData(_ endpoint: APIEndpoint) async throws -> Data
}

// MARK: - Network Service

final class NetworkService: NetworkServiceProtocol, Sendable {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder
    }

    /// Create a configured URLSession with appropriate timeouts
    static func makeSession(timeoutInterval: TimeInterval = 30) -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeoutInterval
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .reloadRevalidatingCacheData
        return URLSession(configuration: configuration)
    }

    // MARK: - Fetch Methods

    func fetch<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let data = try await fetchData(endpoint)

        do {
            return try decoder.decode(T.self, from: data)
        } catch let decodingError {
            throw NetworkError.decodingFailed(decodingError)
        }
    }

    func fetchData(_ endpoint: APIEndpoint) async throws -> Data {
        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = 30

        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw mapURLError(error)
        } catch {
            throw NetworkError.unknown(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        try validateHTTPResponse(httpResponse)

        return data
    }

    // MARK: - Response Validation

    private func validateHTTPResponse(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 404:
            throw NetworkError.productNotFound
        case 429:
            throw NetworkError.rateLimitExceeded
        case 500...599:
            throw NetworkError.serverError(response.statusCode)
        default:
            throw NetworkError.httpError(response.statusCode)
        }
    }

    // MARK: - Error Mapping

    private func mapURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkUnavailable
        case .timedOut:
            return .timeout
        case .cancelled:
            return .cancelled
        default:
            return .unknown(error)
        }
    }
}

// MARK: - Rate Limiter

/// Simple rate limiter using token bucket algorithm
actor RateLimiter {
    private let requestsPerMinute: Int
    private var tokens: Int
    private var lastRefill: Date

    init(requestsPerMinute: Int) {
        self.requestsPerMinute = requestsPerMinute
        self.tokens = requestsPerMinute
        self.lastRefill = Date()
    }

    /// Wait until a request can be made (non-blocking where possible)
    func waitForPermission() async throws {
        refillIfNeeded()

        while tokens <= 0 {
            // Calculate wait time until next token
            let timeSinceLastRefill = Date().timeIntervalSince(lastRefill)
            let secondsPerToken = 60.0 / Double(requestsPerMinute)
            let waitTime = max(0, secondsPerToken - timeSinceLastRefill)

            try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            refillIfNeeded()
        }

        tokens -= 1
    }

    private func refillIfNeeded() {
        let now = Date()
        let timeSinceLastRefill = now.timeIntervalSince(lastRefill)

        if timeSinceLastRefill >= 60 {
            // Full refill after a minute
            tokens = requestsPerMinute
            lastRefill = now
        } else {
            // Partial refill based on time elapsed
            let tokensToAdd = Int(timeSinceLastRefill * Double(requestsPerMinute) / 60.0)
            if tokensToAdd > 0 {
                tokens = min(requestsPerMinute, tokens + tokensToAdd)
                lastRefill = now
            }
        }
    }
}

// MARK: - Network Monitor

import Network

@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.scanora.networkmonitor")

    private(set) var isConnected = true
    private(set) var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi
        case cellular
        case wired
        case unknown
    }

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }

    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wired
        }
        return .unknown
    }

    deinit {
        monitor.cancel()
    }
}
