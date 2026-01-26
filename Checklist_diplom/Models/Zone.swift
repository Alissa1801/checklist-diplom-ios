import Foundation

struct Zone: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let description: String
    let standardItemsCount: Int?
    let standardObjects: [StandardObject]?
    let checklistPoints: [String]?
    
    // Для Hashable достаточно id, так как он уникален
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Zone, rhs: Zone) -> Bool {
        lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case standardItemsCount = "standard_items_count"
        case standardObjects = "standard_objects"
        case checklistPoints = "checklist_points"
    }
}

struct StandardObject: Codable, Hashable {
    let name: String
    let count: Int
}
