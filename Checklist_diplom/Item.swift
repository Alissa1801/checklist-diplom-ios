//
//  Item.swift
//  Checklist_diplom
//
//  Created by Alice on 25.01.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
