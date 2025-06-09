//
//  FoodAnalysisView.swift
//  CalAI
//
//  Created by Surya Teja Nammi on 6/8/25.
//

import SwiftUI
import SwiftData

struct FoodAnalysisView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: FoodAnalysisViewModel
    
    private let image: Image
    
    init(image: Image, uiImage: UIImage) {
        self.image = image
        _viewModel = StateObject(wrappedValue: FoodAnalysisViewModel(image: uiImage))
    }
    
    init(uiImage: UIImage) {
        self.image = Image(uiImage: uiImage)
        _viewModel = StateObject(wrappedValue: FoodAnalysisViewModel(image: uiImage))
    }
    
    init(image: Image) {
        self.image = image
        _viewModel = StateObject(wrappedValue: FoodAnalysisViewModel())
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Food image
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                // Analysis status
                if viewModel.isAnalyzing {
                    analysisLoadingView
                } else if !viewModel.analysisDone && viewModel.errorMessage == nil {
                    manualEntryPromptView
                } else {
                    // Food details form
                    foodDetailsForm
                }
            }
            .padding()
        }
        .navigationTitle("Food Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(viewModel.isAnalyzing || viewModel.foodEntry.foodName.isEmpty ? "Save" : "Close") {
                    viewModel.saveFoodEntry(in: modelContext)
                    dismiss()
                }
                .disabled(viewModel.isAnalyzing || viewModel.foodEntry.foodName.isEmpty)
            }
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { errorMessage in
            Text(errorMessage)
        }
    }
    
    // MARK: - Analysis Loading View
    private var analysisLoadingView: some View {
        HStack {
            Spacer()
            VStack(spacing: 15) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("Analyzing your food...")
                    .font(.headline)
            }
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Manual Entry Prompt
    private var manualEntryPromptView: some View {
        VStack(alignment: .center, spacing: 15) {
            Text("Enter Food Details")
                .font(.headline)
            
            Text("You can manually enter the food details below or wait for the analysis to complete.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // MARK: - Food Details Form
    private var foodDetailsForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Food name
            VStack(alignment: .leading) {
                Text("Food Name")
                    .font(.headline)
                
                TextField("Enter food name", text: $viewModel.foodEntry.foodName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Calories
            VStack(alignment: .leading) {
                Text("Calories")
                    .font(.headline)
                
                HStack {
                    TextField("Enter calories", value: Binding(
                        get: { viewModel.foodEntry.calories },
                        set: {
                            viewModel.foodEntry.calories = $0
                            viewModel.updateCalories()
                        }
                    ), format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    
                    Text("kcal")
                        .foregroundColor(.secondary)
                }
            }
            
            // Notes
            VStack(alignment: .leading) {
                Text("Notes")
                    .font(.headline)
                
                TextField("Add notes (optional)", text: Binding(
                    get: { viewModel.foodEntry.notes ?? "" },
                    set: { viewModel.foodEntry.notes = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Ingredients
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Ingredients")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.addIngredient()
                    }) {
                        Label("Add", systemImage: "plus.circle")
                    }
                }
                
                if viewModel.foodEntry.ingredients.isEmpty {
                    Text("No ingredients added")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 10)
                } else {
                    ForEach(Array(viewModel.foodEntry.ingredients.enumerated()), id: \.element.id) { index, ingredient in
                        ingredientRow(for: ingredient, at: index)
                    }
                    .onDelete { indexSet in
                        viewModel.removeIngredient(at: indexSet)
                    }
                }
            }
            
            // Total calories summary
            HStack {
                Spacer()
                VStack {
                    Text("Total Calories")
                        .font(.headline)
                    
                    Text("\(Int(viewModel.foodEntry.totalCalories)) kcal")
                        .font(.title)
                        .foregroundColor(.primary)
                }
                Spacer()
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Ingredient Row
    private func ingredientRow(for ingredient: Ingredient, at index: Int) -> some View {
        VStack {
            HStack(alignment: .top) {
                // Name
                VStack(alignment: .leading) {
                    Text("Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Ingredient", text: Binding(
                        get: { ingredient.name },
                        set: { ingredient.name = $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Total Grams
                VStack(alignment: .leading) {
                    Text("Grams")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("0", value: Binding(
                        get: { ingredient.total_grams },
                        set: { 
                            ingredient.total_grams = $0
                            viewModel.updateCalories()
                        }
                    ), format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                }
                
                // Calories per gram
                VStack(alignment: .leading) {
                    Text("Cal/g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("0", value: Binding(
                        get: { ingredient.calorie_per_gram },
                        set: { 
                            ingredient.calorie_per_gram = $0
                            viewModel.updateCalories()
                        }
                    ), format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                }
                
                // Total Calories
                VStack(alignment: .leading) {
                    Text("Total Cal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("0", value: Binding(
                        get: { ingredient.total_calories },
                        set: { 
                            ingredient.total_calories = $0
                            viewModel.updateCalories()
                        }
                    ), format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                }
            }
            
            Divider()
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    NavigationStack {
        FoodAnalysisView(image: Image(systemName: "photo"))
            .modelContainer(for: [FoodEntry.self, Ingredient.self], inMemory: true)
    }
}
