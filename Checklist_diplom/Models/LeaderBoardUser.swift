import Foundation

struct LeaderboardUser: Codable, Identifiable {
    let id: Int
    let fullName: String
    let totalChecks: Int
    let rejectedCount: Int
    let qualityScore: Double

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case totalChecks = "total_checks"
        case rejectedCount = "rejected_count"
        case qualityScore = "quality_score"
    }
}
