//
//  FoodAnalysisViewModel.swift
//  CalAI
//
//  Created by Surya Teja Nammi on 6/8/25.
//

import Foundation
import SwiftUI
import Combine
import SwiftData

class FoodAnalysisViewModel: ObservableObject {
    // Services
    private let openAIService: OpenAIService
    
    // Published properties
    @Published var foodEntry = FoodEntry()
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var analysisDone = false
    
    // Original image
    private var uiImage: UIImage?
    private var cancellables = Set<AnyCancellable>()
    
    init(image: UIImage? = nil) {
        self.openAIService = OpenAIService()
        self.uiImage = image
        if image != nil {
            self.analyzeImage()
        }
    }
    
    func analyzeImage(_ image: UIImage? = nil) {
        guard let image = self.uiImage else {
            print("No image found")
            return
        }
        print("Starting image analysis...")
        isAnalyzing = true
        analysisDone = false
        errorMessage = nil
        
        // Save the image data
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            print("Failed to compress image")
            errorMessage = "Failed to process image"
            showError = true
            isAnalyzing = false
            return
        }
        
        foodEntry.imageData = imageData
        
        print("Calling OpenAI service...")
        // Call OpenAI service
        openAIService.analyzeFood(image: image)
            .handleEvents(
                receiveSubscription: { _ in print("API call initiated") },
                receiveOutput: { response in print("Received raw response") },
                receiveCompletion: { completion in 
                    switch completion {
                    case .finished: print("API call completed successfully")
                    case .failure(let error): print("API call failed: \(error.localizedDescription)")
                    }
                },
                receiveCancel: { print("API call cancelled") }
            )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isAnalyzing = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Analysis failed: \(error.localizedDescription)"
                        self?.showError = true
                        print(self?.errorMessage)
                    }
                },
                receiveValue: { [weak self] response in
                    print("Response: \(response)")
                    self?.updateFoodEntry(with: response)
                    self?.analysisDone = true
                }
            )
            .store(in: &cancellables)
    }
    
    private func updateFoodEntry(with response: FoodAnalysisResponse) {
        // Update food entry with response data
        foodEntry.foodName = response.foodName
        foodEntry.calories = response.calories
        
        // Clear existing ingredients and add new ones
        foodEntry.ingredients.removeAll()
        
        for ingredientInfo in response.ingredients {
            let ingredient = Ingredient(
                name: ingredientInfo.name,
                total_calories: ingredientInfo.total_calories,
                calorie_per_gram: ingredientInfo.calorie_per_gram,
                total_grams: ingredientInfo.total_grams
            )
            foodEntry.ingredients.append(ingredient)
        }
    }
    
    func saveFoodEntry(in modelContext: ModelContext) {
        // Set timestamp if not already set
        if foodEntry.timestamp == Date(timeIntervalSince1970: 0) {
            foodEntry.timestamp = Date()
        }
        
        // Insert the food entry into the model context
        modelContext.insert(foodEntry)
        
        // Try to save changes
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save entry: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func updateCalories() {
        // Recalculate total calories based on ingredients
        let totalCalories = foodEntry.ingredients.reduce(0) { $0 + $1.total_calories }
        if totalCalories > 0 {
            foodEntry.calories = totalCalories
        }
    }
    
    func addIngredient() {
        let newIngredient = Ingredient(
            name: "", 
            total_calories: 0,
            calorie_per_gram: 0,
            total_grams: 0
        )
        foodEntry.ingredients.append(newIngredient)
    }
    
    func removeIngredient(at offsets: IndexSet) {
        foodEntry.ingredients.remove(atOffsets: offsets)
        updateCalories()
    }
}
