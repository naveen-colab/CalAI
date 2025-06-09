//
//  HistoryView.swift
//  CalAI
//
//  Created by Surya Teja Nammi on 6/8/25.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HistoryViewModel()
    
    @Query private var entries: [FoodEntry]
    
    init() {
        // Initialize with default predicate and sort descriptors
        _entries = Query(
            filter: HistoryViewModel().entriesPredicate(),
            sort: HistoryViewModel().entriesSortDescriptors()
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Filter controls
                filterControls
                
                // Search bar
                searchBar
                
                // Content
                if entries.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .navigationTitle("Food History")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: viewModel.selectedDate) { updateQuery() }
            .onChange(of: viewModel.selectedTimeFrame) { updateQuery() }
            .onChange(of: viewModel.searchText) { updateQuery() }
        }
    }
    
    // MARK: - Filter Controls
    private var filterControls: some View {
        VStack(spacing: 10) {
            // Time frame picker
            Picker("Time Frame", selection: $viewModel.selectedTimeFrame) {
                ForEach(HistoryViewModel.TimeFrame.allCases) { frame in
                    Text(frame.rawValue).tag(frame)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Date picker (only show when not viewing all entries)
            if viewModel.selectedTimeFrame != .all {
                DatePicker(
                    "Select Date",
                    selection: $viewModel.selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search food or notes", text: $viewModel.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled()
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No food entries found")
                .font(.title2)
            
            if viewModel.selectedTimeFrame != .all || !viewModel.searchText.isEmpty {
                Text("Try adjusting your filters or search")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("Clear Filters") {
                    viewModel.selectedTimeFrame = .all
                    viewModel.searchText = ""
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - History List
    private var historyListView: some View {
        List {
            // Group entries by date
            let groupedEntries = viewModel.groupEntriesByDate(entries)
            let sortedDates = groupedEntries.keys.sorted(by: >)
            
            ForEach(sortedDates, id: \.self) { date in
                Section {
                    // Entries for this date
                    ForEach(groupedEntries[date] ?? []) { entry in
                        NavigationLink {
                            VStack {
                                if let imageData = entry.imageData, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: .infinity)
                                        .cornerRadius(12)
                                        .padding()
                                }
                                
                                Form {
                                    Section("Food Details") {
                                        Text(entry.foodName)
                                        Text("\(Int(entry.totalCalories)) kcal")
                                        if let notes = entry.notes {
                                            Text(notes)
                                        }
                                    }
                                    
                                    Section("Ingredients") {
                                        ForEach(entry.ingredients) { ingredient in
                                            HStack {
                                                Text(ingredient.name)
                                                Spacer()
                                                Text("\(Int(ingredient.total_grams))g")
                                                Text("\(Int(ingredient.total_calories)) cal")
                                            }
                                        }
                                    }
                                }
                            }
                            .navigationTitle(entry.foodName)
                        } label: {
                            historyRow(for: entry)
                        }
                    }
                    .onDelete { offsets in
                        deleteEntries(at: offsets, from: groupedEntries[date] ?? [])
                    }
                    
                    // Daily total
                    if let dailyEntries = groupedEntries[date] {
                        HStack {
                            Text("Total")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(Int(viewModel.totalCalories(for: dailyEntries))) kcal")
                                .font(.headline)
                        }
                    }
                } header: {
                    Text(viewModel.formattedDate(date))
                }
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - History Row
    private func historyRow(for entry: FoodEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.foodName)
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(entry.totalCalories)) kcal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            if !entry.ingredients.isEmpty {
                Text(entry.ingredients.map { $0.displayText }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Methods
    @State private var currentQuery: Query<FoodEntry, [FoodEntry]>?
    
    private func updateQuery() {
        let predicate = viewModel.entriesPredicate()
        let sortDescriptors = viewModel.entriesSortDescriptors()
        currentQuery = Query(filter: predicate, sort: sortDescriptors)
//        _entries = currentQuery ?? Query(filter: #Predicate { _ in true }, sort: [])
    }
    
    private func deleteEntries(at offsets: IndexSet, from entries: [FoodEntry]) {
        withAnimation {
            for index in offsets {
                modelContext.delete(entries[index])
            }
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [FoodEntry.self, Ingredient.self], inMemory: true)
}
