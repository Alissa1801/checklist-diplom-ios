import Foundation

struct AnalysisResult: Codable, Hashable {
    let id: Int
    let checkId: Int
    let confidenceScore: Double?
    let isApproved: Bool?
    let detectedObjects: [DetectedObject]?
    let issues: [String]?
    let feedback: String?
    let mlModelVersion: String
    let createdAt: String
    let updatedAt: String
    
    var confidencePercentage: String {
        guard let score = confidenceScore else { return "N/A" }
        return "\(Int(score))%"
    }
    
    var approvedText: String {
        isApproved == true ? "Одобрено" : "Отклонено"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AnalysisResult, rhs: AnalysisResult) -> Bool {
        lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case checkId = "check_id"
        case confidenceScore = "confidence_score"
        case isApproved = "is_approved"
        case detectedObjects = "detected_objects"
        case issues, feedback
        case mlModelVersion = "ml_model_version"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct DetectedObject: Codable, Hashable {
    let name: String
    let count: Int
    let confidence: Double
}
