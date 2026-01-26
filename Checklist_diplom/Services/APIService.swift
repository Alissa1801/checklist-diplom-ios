import Foundation
import UIKit

class APIService {
    static let shared = APIService()
    private let baseURL = "http://localhost:3000/api/v1"
    private let tokenKey = "auth_token"
    
    private init() {}
    
    // MARK: - Authentication
    
    func login(email: String, password: String) async throws -> LoginResponse {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
        saveToken(loginResponse.token)
        return loginResponse
    }
    
    func logout() async throws -> Bool {
        guard let token = getToken() else { return false }
        
        let url = URL(string: "\(baseURL)/auth/logout")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)
        
        if response.success {
            clearToken()
        }
        
        return response.success
    }
    
    // MARK: - Zones
    
    func fetchZones() async throws -> [Zone] {
        guard let token = getToken() else { throw APIError.unauthorized }
        
        let url = URL(string: "\(baseURL)/zones")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode([Zone].self, from: data)
    }
    
    // MARK: - Checks
    
    func fetchChecks() async throws -> [Check] {
        guard let token = getToken() else { throw APIError.unauthorized }
        
        let url = URL(string: "\(baseURL)/checks")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode([Check].self, from: data)
    }
    
    func createCheck(zoneId: Int, imageData: Data?) async throws -> Check {
        guard let token = getToken() else { throw APIError.unauthorized }
        
        let url = URL(string: "\(baseURL)/checks")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Добавляем текстовые поля
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
        
        // Для отладки
        debugPrintRequest(request)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Для отладки
        if let responseString = String(data: data, encoding: .utf8) {
            print("=== Server Response ===")
            print("Response: \(responseString)")
            print("======================")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("Status Code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 201 {
            print("✅ Server returned 201 - Success!")
            
            // Сначала распечатаем сырой ответ
            if let responseString = String(data: data, encoding: .utf8) {
                print("=== RAW RESPONSE ===")
                print(responseString)
                print("=== END RAW RESPONSE ===")
            }
            
            do {
                // Парсим JSON
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("❌ Failed to parse JSON")
                    throw APIError.decodingError
                }
                
                print("✅ JSON parsed successfully")
                print("Top-level keys: \(json.keys)")
                
                // Проверяем структуру
                guard let success = json["success"] as? Bool, success == true else {
                    print("❌ success field missing or false")
                    throw APIError.decodingError
                }
                
                guard let checkDict = json["check"] as? [String: Any] else {
                    print("❌ check field missing")
                    print("Available keys: \(json.keys)")
                    throw APIError.decodingError
                }
                
                print("✅ Check dict found")
                print("Check dict keys: \(checkDict.keys)")
                
                // Распечатаем содержимое checkDict
                print("=== CHECK DICT CONTENTS ===")
                for (key, value) in checkDict {
                    print("  \(key): \(value)")
                }
                print("=== END CHECK DICT ===")
                
                // Проверяем есть ли user_id
                if let userId = checkDict["user_id"] {
                    print("✅ user_id found: \(userId)")
                } else {
                    print("❌ user_id NOT FOUND in check dict!")
                }
                
                // Конвертируем в Data для декодирования
                let checkJSONData = try JSONSerialization.data(withJSONObject: checkDict)
                
                // Декодируем
                let decoder = JSONDecoder()
              //  decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                do {
                    let check = try decoder.decode(Check.self, from: checkJSONData)
                    print("✅ Check decoded successfully!")
                    print("Decoded check ID: \(check.id)")
                    print("Decoded check userId: \(String(describing: check.userId))")
                    print("Decoded check zoneId: \(check.zoneId)")
                    return check
                } catch let decodingError {
                    print("❌ Failed to decode Check: \(decodingError)")
                    print("Decoding error type: \(type(of: decodingError))")
                    
                    if let error = decodingError as? DecodingError {
                        switch error {
                        case .keyNotFound(let key, let context):
                            print("Missing key: \(key.stringValue)")
                            print("Coding path: \(context.codingPath)")
                            print("Debug: \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            print("Type mismatch: \(type)")
                            print("Context: \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            print("Value not found: \(type)")
                            print("Context: \(context.debugDescription)")
                        case .dataCorrupted(let context):
                            print("Data corrupted: \(context.debugDescription)")
                        @unknown default:
                            print("Unknown decoding error")
                        }
                    }
                    throw APIError.decodingError
                }
                
            } catch {
                print("❌ JSON parsing error: \(error)")
                throw APIError.decodingError
            }
        } else {
            // Читаем сообщение об ошибке
            if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let errorMessage = errorJSON["error"] as? String {
                    throw APIError.serverError(errorMessage)
                }
                if let errors = errorJSON["errors"] as? [String] {
                    throw APIError.serverError(errors.joined(separator: ", "))
                }
            }
            
            throw APIError.invalidResponse
        }
    }
    
    // MARK: - Analysis
    
    func getAnalysis(for checkId: Int) async throws -> AnalysisResult {
        guard let token = getToken() else { throw APIError.unauthorized }
        
        let url = URL(string: "\(baseURL)/analysis/\(checkId)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(AnalysisResult.self, from: data)
    }
    
    // MARK: - Dashboard
    
    func fetchDashboardStats() async throws -> DashboardStats {
        guard let token = getToken() else { throw APIError.unauthorized }
        
        let url = URL(string: "\(baseURL)/dashboard/stats")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(DashboardStats.self, from: data)
    }
    
    // MARK: - Token Management
    
    private func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    private func getToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }
    
    private func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
    
    var isLoggedIn: Bool {
        getToken() != nil
    }
    
    // MARK: - Debug Helper
    
    private func debugPrintRequest(_ request: URLRequest) {
        print("=== HTTP Request ===")
        print("URL: \(request.url?.absoluteString ?? "nil")")
        print("Method: \(request.httpMethod ?? "nil")")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody {
            print("Body size: \(body.count) bytes")
            // Показываем только начало body для отладки
            if body.count > 1000 {
                if let bodyString = String(data: body, encoding: .utf8) {
                    let preview = String(bodyString.prefix(500))
                    print("Body preview (first 500 chars): \(preview)...")
                }
            }
        }
        print("===================")
    }
    
    // MARK: - Utility Methods
    
    func compressImageTo5MB(_ image: UIImage) -> Data? {
        var compression: CGFloat = 0.9
        let maxSize = 5 * 1024 * 1024 // 5MB в байтах
        
        guard var imageData = image.jpegData(compressionQuality: compression) else {
            return nil
        }
        
        // Уменьшаем качество, пока не достигнем нужного размера
        while imageData.count > maxSize && compression > 0.1 {
            compression -= 0.1
            if let newData = image.jpegData(compressionQuality: compression) {
                imageData = newData
            } else {
                break
            }
        }
        
        print("Compressed image: \(Double(imageData.count) / 1024 / 1024) MB")
        return imageData
    }
}

enum APIError: Error, LocalizedError {
    case unauthorized
    case invalidResponse
    case decodingError
    case networkError
    case serverError(String)
    
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
        }
    }
}
