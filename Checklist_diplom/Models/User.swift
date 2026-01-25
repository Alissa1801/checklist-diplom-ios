import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let firstName: String
    let lastName: String
    let phone: String?
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case firstName = "first_name"
        case lastName = "last_name"
        case phone
    }
}

struct LoginResponse: Codable {
    let success: Bool
    let token: String
    let user: User
}

struct AuthResponse: Codable {
    let success: Bool
    let message: String?
}