import Foundation

struct Check: Codable, Identifiable, Hashable {
    let id: Int
    let userId: Int?
    let zoneId: Int
    let notes: String?
    let status: Int
    let score: Double?
    let submittedAt: String
    let createdAt: String
    let updatedAt: String?
    let zone: Zone?
    let analysisResult: AnalysisResult?
    
    var statusText: String {
        switch status {
        case 0: return "Создана"
        case 1: return "В обработке"
        case 2: return "Одобрена"
        case 3: return "Отклонена"
        default: return "Неизвестно"
        }
    }
    
    var statusColor: String {
        switch status {
        case 2: return "green"
        case 3: return "red"
        default: return "gray"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Check, rhs: Check) -> Bool {
        lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, notes, status, score
        case userId = "user_id"
        case zoneId = "zone_id"
        case submittedAt = "submitted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case zone, analysisResult = "analysis_result"
    }
}

struct CreateCheckRequest: Codable {
    let zoneId: Int
    let submittedAt: String
    
    enum CodingKeys: String, CodingKey {
        case zoneId = "zone_id"
        case submittedAt = "submitted_at"
    }
}

struct CheckCreateResponse: Codable {
    let success: Bool
    let check: Check
    let message: String
}
