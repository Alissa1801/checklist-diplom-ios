import Foundation

struct DashboardStats: Codable {
    let success: Bool
    let stats: StatsData
    
    struct StatsData: Codable {
        let overview: OverviewStats
        let quality: QualityStats
        let users: UsersStats?
        let leaderboard: [LeaderboardUser]
        let recentChecks: [RecentCheck]
        let timestamp: String
        
        enum CodingKeys: String, CodingKey {
            case overview, quality, users, timestamp, leaderboard
            case recentChecks = "recent_checks"
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
        let totalPhotos: Int?
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
        let userEmail: String
        let userName: String
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
}
