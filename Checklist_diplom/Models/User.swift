// Models/User.swift
import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let firstName: String
    let lastName: String
    let phone: String?
    let admin: Bool
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case firstName = "first_name"
        case lastName = "last_name"
        case phone
        case admin
    }
}

struct LoginResponse: Codable {
    let success: Bool
    let token: String
    let refreshToken: String?
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case success, token, user
        case refreshToken = "refresh_token"
    }
}

struct AuthResponse: Codable {
    let success: Bool
    let message: String?
}
