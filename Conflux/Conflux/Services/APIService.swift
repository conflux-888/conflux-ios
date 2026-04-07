import Foundation

enum ServiceError: Error, LocalizedError {
    case unauthorized
    case notFound
    case serverError(String)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Authentication required. Please log in again."
        case .notFound: return "The requested resource was not found."
        case .serverError(let msg): return msg
        case .decodingError(let err): return "Data error: \(err.localizedDescription)"
        case .networkError(let err): return "Network error: \(err.localizedDescription)"
        }
    }
}

final class APIService {
    static let shared = APIService()
    private init() {}

    private let baseURL = "http://183.90.173.180:8080/api/v1"

    // MARK: - Request Builder

    private func request(
        path: String,
        method: String = "GET",
        body: Data? = nil,
        token: String? = nil
    ) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw ServiceError.serverError("Invalid URL")
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = body
        return req
    }

    private func request(
        components: URLComponents,
        token: String? = nil
    ) -> URLRequest {
        var req = URLRequest(url: components.url!)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw ServiceError.decodingError(error)
        }
    }

    // MARK: - Auth

    func login(email: String, password: String) async throws -> LoginResponse {
        let body = try JSONEncoder().encode(["email": email, "password": password])
        let req = try request(path: "/auth/login", method: "POST", body: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        let statusCode = (resp as? HTTPURLResponse)?.statusCode ?? 0
        if statusCode == 401 { throw ServiceError.unauthorized }
        let response = try decode(APIResponse<LoginResponse>.self, from: data)
        if let result = response.data { return result }
        throw ServiceError.serverError(response.error?.message ?? "Login failed")
    }

    func register(email: String, password: String, displayName: String) async throws -> User {
        struct RegisterBody: Encodable {
            let email: String
            let password: String
            let display_name: String
        }
        let body = try JSONEncoder().encode(RegisterBody(email: email, password: password, display_name: displayName))
        let req = try request(path: "/auth/register", method: "POST", body: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        let statusCode = (resp as? HTTPURLResponse)?.statusCode ?? 0
        if statusCode == 409 { throw ServiceError.serverError("Email already registered") }
        let response = try decode(APIResponse<User>.self, from: data)
        if let result = response.data { return result }
        throw ServiceError.serverError(response.error?.message ?? "Registration failed")
    }

    // MARK: - User

    func getMe(token: String) async throws -> User {
        let req = try request(path: "/users/me", token: token)
        let (data, resp) = try await URLSession.shared.data(for: req)
        if (resp as? HTTPURLResponse)?.statusCode == 401 { throw ServiceError.unauthorized }
        let response = try decode(APIResponse<User>.self, from: data)
        if let result = response.data { return result }
        throw ServiceError.serverError(response.error?.message ?? "Failed to load profile")
    }

    func updateDisplayName(_ name: String, token: String) async throws -> User {
        let body = try JSONEncoder().encode(["display_name": name])
        let req = try request(path: "/users/me", method: "PUT", body: body, token: token)
        let (data, _) = try await URLSession.shared.data(for: req)
        let response = try decode(APIResponse<User>.self, from: data)
        if let result = response.data { return result }
        throw ServiceError.serverError(response.error?.message ?? "Update failed")
    }

    // MARK: - Events

    func getEvents(
        source: String? = nil,
        severity: String? = nil,
        page: Int = 1,
        limit: Int = 200,
        sort: String = "date_desc",
        token: String
    ) async throws -> PaginatedResponse<Event> {
        var comps = URLComponents(string: baseURL + "/events")!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sort", value: sort)
        ]
        if let source { items.append(URLQueryItem(name: "source", value: source)) }
        if let severity { items.append(URLQueryItem(name: "severity", value: severity)) }
        comps.queryItems = items

        let req = request(components: comps, token: token)
        let (data, resp) = try await URLSession.shared.data(for: req)
        if (resp as? HTTPURLResponse)?.statusCode == 401 { throw ServiceError.unauthorized }
        return try decode(PaginatedResponse<Event>.self, from: data)
    }

    func getEvent(id: String, token: String) async throws -> Event {
        let req = try request(path: "/events/\(id)", token: token)
        let (data, _) = try await URLSession.shared.data(for: req)
        let response = try decode(APIResponse<Event>.self, from: data)
        if let result = response.data { return result }
        throw ServiceError.notFound
    }

    // MARK: - Reports

    struct CreateReportRequest: Encodable {
        let event_type: String
        let severity: String
        let title: String
        let description: String?
        let latitude: Double
        let longitude: Double
        let location_name: String?
        let country: String
    }

    func createReport(_ report: CreateReportRequest, token: String) async throws -> Event {
        let body = try JSONEncoder().encode(report)
        let req = try request(path: "/reports", method: "POST", body: body, token: token)
        let (data, resp) = try await URLSession.shared.data(for: req)
        if (resp as? HTTPURLResponse)?.statusCode == 401 { throw ServiceError.unauthorized }
        let response = try decode(APIResponse<Event>.self, from: data)
        if let result = response.data { return result }
        throw ServiceError.serverError(response.error?.message ?? "Failed to submit report")
    }

    func getMyReports(page: Int = 1, limit: Int = 20, token: String) async throws -> PaginatedResponse<Event> {
        var comps = URLComponents(string: baseURL + "/reports/me")!
        comps.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        let req = request(components: comps, token: token)
        let (data, resp) = try await URLSession.shared.data(for: req)
        if (resp as? HTTPURLResponse)?.statusCode == 401 { throw ServiceError.unauthorized }
        return try decode(PaginatedResponse<Event>.self, from: data)
    }

    func deleteReport(id: String, token: String) async throws {
        let req = try request(path: "/reports/\(id)", method: "DELETE", token: token)
        let (_, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401 { throw ServiceError.unauthorized }
        if status == 404 { throw ServiceError.notFound }
    }
}
