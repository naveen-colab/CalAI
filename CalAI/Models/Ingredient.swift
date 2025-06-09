//
//  Ingredient.swift
//  CalAI
//
//  Created by Surya Teja Nammi on 6/8/25.
//

import Foundation
import SwiftData

@Model
final class Ingredient {
    var name: String
    var total_calories: Double
    var calorie_per_gram: Double
    var total_grams: Double
    
    @Relationship(inverse: \FoodEntry.ingredients)
    var foodEntry: FoodEntry?
    
    init(name: String = "", 
         total_calories: Double = 0,
         calorie_per_gram: Double = 0,
         total_grams: Double = 0) {
        self.name = name
        self.total_calories = total_calories
        self.calorie_per_gram = calorie_per_gram
        self.total_grams = total_grams
    }
    
    var displayText: String {
        return "\(name) - \(Int(total_grams))g (\(Int(total_calories)) cal, \(String(format: "%.1f", calorie_per_gram)) cal/g)"
    }
}
