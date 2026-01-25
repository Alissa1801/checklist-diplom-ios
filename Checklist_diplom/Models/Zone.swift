import Foundation

struct Zone: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let standardItemsCount: Int?
    let standardObjects: [StandardObject]?
    let checklistPoints: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case standardItemsCount = "standard_items_count"
        case standardObjects = "standard_objects"
        case checklistPoints = "checklist_points"
    }
}

struct StandardObject: Codable {
    let name: String
    let count: Int
}
