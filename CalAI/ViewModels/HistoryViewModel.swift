//
//  HistoryViewModel.swift
//  CalAI
//
//  Created by Surya Teja Nammi on 6/8/25.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

class HistoryViewModel: ObservableObject {
    // Published properties
    @Published var selectedDate: Date = Date()
    @Published var selectedTimeFrame: TimeFrame = .day
    @Published var searchText: String = ""
    
    // Time frame options
    enum TimeFrame: String, CaseIterable, Identifiable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        case all = "All"
        
        var id: String { self.rawValue }
    }
    
    // MARK: - Date Filtering
    
    func dateRange(for timeFrame: TimeFrame, from date: Date) -> (Date, Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        switch timeFrame {
        case .day:
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return (startOfDay, endOfDay)
            
        case .week:
            let weekday = calendar.component(.weekday, from: startOfDay)
            let daysToSubtract = weekday - calendar.firstWeekday
            let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: startOfDay)!
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
            return (startOfWeek, endOfWeek)
            
        case .month:
            let components = calendar.dateComponents([.year, .month], from: startOfDay)
            let startOfMonth = calendar.date(from: components)!
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            return (startOfMonth, nextMonth)
            
        case .all:
            // Return a very wide date range
            let distantPast = Date.distantPast
            let distantFuture = Date.distantFuture
            return (distantPast, distantFuture)
        }
    }
    
    // MARK: - Predicates
    
    func entriesPredicate() -> Predicate<FoodEntry> {
        let searchText = self.searchText
        let selectedTimeFrame = self.selectedTimeFrame
        let selectedDate = self.selectedDate
        
        if selectedTimeFrame == .all && searchText.isEmpty {
            return #Predicate<FoodEntry> { _ in true }
        }
        
        if selectedTimeFrame != .all {
            let (startDate, endDate) = dateRange(for: selectedTimeFrame, from: selectedDate)
            
            if !searchText.isEmpty {
                return #Predicate<FoodEntry> { entry in
//                    if entry.timestamp >= startDate && entry.timestamp < endDate {
//                        return entry.foodName.localizedStandardContains(searchText) ||
//                               (entry.notes?.localizedStandardContains(searchText) ?? false)
//                    }
                    return false
                }
            } else {
                return #Predicate<FoodEntry> { entry in
                    entry.timestamp >= startDate && entry.timestamp < endDate
                }
            }
        }
        
        return #Predicate<FoodEntry> { entry in
            entry.foodName.localizedStandardContains(searchText) ||
            (entry.notes?.localizedStandardContains(searchText) ?? false)
        }
    }
    
    // MARK: - Sort Descriptors
    
    func entriesSortDescriptors() -> [SortDescriptor<FoodEntry>] {
        return [SortDescriptor(\.timestamp, order: .reverse)]
    }
    
    // MARK: - Grouping
    
    func groupEntriesByDate(_ entries: [FoodEntry]) -> [Date: [FoodEntry]] {
        let calendar = Calendar.current
        
        return Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
    }
    
    // MARK: - Calculations
    
    func totalCalories(for entries: [FoodEntry]) -> Double {
        return entries.reduce(0) { $0 + $1.totalCalories }
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
