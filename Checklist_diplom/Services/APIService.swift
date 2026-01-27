import Foundation
import UIKit

class APIService {
    static let shared = APIService()
    private let baseURL = "http://localhost:3000/api/v1"
    private let tokenKey = "auth_token"
    private let refreshTokenKey = "refresh_token"
    
    private init() {}
    
    // MARK: - Token Management
    
    private func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    private func getRefreshToken() -> String? {
        return UserDefaults.standard.string(forKey: refreshTokenKey)
    }
    
    private func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    private func saveRefreshToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: refreshTokenKey)
    }
    
    func clearTokens() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.synchronize()
    }
    
    var isLoggedIn: Bool {
        getToken() != nil
    }
    
    // MARK: - Token Refresh
    
    private func refreshAccessToken() async throws -> String {
        guard let refreshToken = getRefreshToken() else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/auth/refresh")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                clearTokens()
                throw APIError.unauthorized
            }
            throw APIError.invalidResponse
        }
        
        let refreshResponse = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
        
        if refreshResponse.success {
            saveToken(refreshResponse.token)
            return refreshResponse.token
        } else {
            throw APIError.unauthorized
        }
    }
    // MARK: - Dashboard Stats
    func fetchDashboardStats(period: String = "all") async throws -> DashboardStats {
        let request = try createRequest(path: "/dashboard/stats?period=\(period)")
        return try await performRequestWithTokenRefresh(request)
    }

    func fetchPersonalStats(userId: Int, period: String = "all") async throws -> DashboardStats {
        let request = try createRequest(path: "/dashboard/personal_stats?user_id=\(userId)&period=\(period)")
        return try await performRequestWithTokenRefresh(request)
    }
    
    // MARK: - Request Helper with Token Refresh
    
    private func performRequestWithTokenRefresh<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            return try await performRequest(request)
        } catch APIError.unauthorized {
            // Пытаемся обновить токен и повторить запрос
            do {
                let newToken = try await refreshAccessToken()
                
                // Создаем новый запрос с обновленным токеном
                var newRequest = request
                newRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                
                // Повторяем запрос с новым токеном
                return try await performRequest(newRequest)
            } catch {
                // Если не удалось обновить токен, очищаем все токены
                clearTokens()
                throw APIError.unauthorized
            }
        } catch {
            throw error
        }
    }
    
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let urlString = request.url?.absoluteString, urlString.contains("dashboard") {
                print("📊 Dashboard API Call: \(urlString)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📊 Raw Response: \(jsonString.prefix(500))...") // первые 500 символов
                }
            }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            
            // Пытаемся прочитать сообщение об ошибке от сервера
            if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJSON["error"] as? String {
                throw APIError.serverError(errorMessage)
            }
            if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errors = errorJSON["errors"] as? [String] {
                throw APIError.serverError(errors.joined(separator: ", "))
            }
            
            throw APIError.serverError("Ошибка сервера: \(httpResponse.statusCode)")
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError
        }
    }
    
    // MARK: - Authentication
    
    func login(email: String, password: String) async throws -> LoginResponse {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)
        
        let loginResponse: LoginResponse = try await performRequest(request)
        saveToken(loginResponse.token)
        if let refreshToken = loginResponse.refreshToken {
            saveRefreshToken(refreshToken)
        }
        return loginResponse
    }
    
    func logout() async throws -> Bool {
        guard let token = getToken() else {
            clearTokens()
            return true
        }
        
        let url = URL(string: "\(baseURL)/auth/logout")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let response: AuthResponse = try await performRequest(request)
            if response.success {
                clearTokens()
            }
            return response.success
        } catch {
            // При любой ошибке очищаем токены
            clearTokens()
            return true
        }
    }
    
    // MARK: - Zones
    
    func fetchZones() async throws -> [Zone] {
        let request = try createRequest(path: "/zones")
        return try await performRequestWithTokenRefresh(request)
    }
    
    // MARK: - Checks
    
    func fetchChecks() async throws -> [Check] {
        let request = try createRequest(path: "/checks")
        return try await performRequestWithTokenRefresh(request)
    }
    
    // ИСПРАВЛЕНО: Убрал fetchDashboardStats и fetchPersonalStats - их нет в исходном коде
    
    func getAnalysis(for checkId: Int) async throws -> AnalysisResult {
        let request = try createRequest(path: "/analysis/\(checkId)")
        return try await performRequestWithTokenRefresh(request)
    }
    
    // MARK: - Request Creation
    
    private func createRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    // MARK: - Create Check (multipart form data)
    
    func createCheck(zoneId: Int, imageData: Data?) async throws -> Check {
        let url = URL(string: "\(baseURL)/checks")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if let token = getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        let fields: [String: String] = [
            "zone_id": "\(zoneId)",
            "submitted_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        for (key, value) in fields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        if let imageData = imageData {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"check_photo.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        debugPrintRequest(request)
        
        do {
            // ИЗМЕНИТЕ ТОЛЬКО ЭТУ СТРОКУ:
            let response: CheckCreateResponse = try await performRequestWithTokenRefresh(request)
            return response.check
        } catch APIError.unauthorized {
            do {
                let newToken = try await refreshAccessToken()
                var newRequest = request
                newRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                // И ЭТУ СТРОКУ:
                let response: CheckCreateResponse = try await performRequest(newRequest)
                return response.check
            } catch {
                clearTokens()
                throw APIError.unauthorized
            }
        }
    }
    
    // MARK: - Debug Helper
    
    private func debugPrintRequest(_ request: URLRequest) {
        print("=== HTTP Request ===")
        print("URL: \(request.url?.absoluteString ?? "nil")")
        print("Method: \(request.httpMethod ?? "nil")")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody {
            print("Body size: \(body.count) bytes")
        }
        print("===================")
    }
    
    // MARK: - Utility Methods
    
    func compressImageTo5MB(_ image: UIImage) -> Data? {
        var compression: CGFloat = 0.9
        let maxSize = 5 * 1024 * 1024
        
        guard var imageData = image.jpegData(compressionQuality: compression) else {
            return nil
        }
        
        while imageData.count > maxSize && compression > 0.1 {
            compression -= 0.1
            if let newData = image.jpegData(compressionQuality: compression) {
                imageData = newData
            } else {
                break
            }
        }
        
        return imageData
    }
}

// MARK: - Response Models

struct RefreshTokenResponse: Codable {
    let success: Bool
    let token: String
    let refreshToken: String?
    
    enum CodingKeys: String, CodingKey {
        case success, token
        case refreshToken = "refresh_token"
    }
}
    
    struct OverviewStats: Codable {
        let totalChecks: Int
        let approved: Int
        let rejected: Int
        let pending: Int
        let approvalRate: Double
        
        enum CodingKeys: String, CodingKey {
            case totalChecks = "total_checks"
            case approved, rejected, pending
            case approvalRate = "approval_rate"
        }
    }
    
    struct QualityStats: Codable {
        let averageScore: Double
        let checksWithPhoto: Int
        let totalPhotos: Int
        let photosPerCheck: Double
        
        enum CodingKeys: String, CodingKey {
            case averageScore = "average_score"
            case checksWithPhoto = "checks_with_photo"
            case totalPhotos = "total_photos"
            case photosPerCheck = "photos_per_check"
        }
    }
    
    struct UsersStats: Codable {
        let totalUsers: Int
        let activeUsers: Int
        let checksPerUser: Double
        
        enum CodingKeys: String, CodingKey {
            case totalUsers = "total_users"
            case activeUsers = "active_users"
            case checksPerUser = "checks_per_user"
        }
    }
    
    struct RecentCheck: Codable, Identifiable {
        let id: Int
        let userEmail: String?
        let userName: String?
        let zoneName: String
        let status: String
        let score: Double?
        let hasPhoto: Bool
        let photoUrl: String?
        let submittedAt: String
        let feedback: String?
        let confidence: Double?
        
        enum CodingKeys: String, CodingKey {
            case id
            case userEmail = "user_email"
            case userName = "user_name"
            case zoneName = "zone_name"
            case status, score
            case hasPhoto = "has_photo"
            case photoUrl = "photo_url"
            case submittedAt = "submitted_at"
            case feedback, confidence
        }
    }

// MARK: - Error Enum

enum APIError: Error, LocalizedError {
    case unauthorized
    case invalidResponse
    case decodingError
    case networkError
    case serverError(String)
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Не авторизован. Пожалуйста, войдите в систему."
        case .invalidResponse:
            return "Неверный ответ от сервера."
        case .decodingError:
            return "Ошибка обработки данных."
        case .networkError:
            return "Ошибка сети. Проверьте подключение."
        case .serverError(let message):
            return message
        case .invalidURL:
            return "Неверный URL адрес."
        }
    }
}
