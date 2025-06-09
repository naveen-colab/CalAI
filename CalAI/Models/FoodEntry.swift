//
//  FoodEntry.swift
//  CalAI
//
//  Created by Surya Teja Nammi on 6/8/25.
//

import Foundation
import SwiftData

@Model
final class FoodEntry {
    var id: UUID
    var timestamp: Date
    var imageData: Data?
    var foodName: String
    var calories: Double
    var notes: String?
    
    @Relationship(deleteRule: .cascade)
    var ingredients: [Ingredient] = []
    
    init(id: UUID = UUID(), timestamp: Date = Date(), imageData: Data? = nil, foodName: String = "", calories: Double = 0, notes: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.imageData = imageData
        self.foodName = foodName
        self.calories = calories
        self.notes = notes
    }
    
    var totalCalories: Double {
        // Sum of all ingredient calories or the manually set calories
        let ingredientTotal = ingredients.reduce(into: 0) { $0 + $1.total_calories }
        return ingredientTotal > 0 ? ingredientTotal : calories
    }
}
