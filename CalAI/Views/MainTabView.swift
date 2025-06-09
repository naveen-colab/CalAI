//
//  MainTabView.swift
//  CalAI
//
//  Created by Surya Teja Nammi on 6/8/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                CameraView()
                    .navigationTitle("Capture Food")
            }
            .tabItem {
                Label("Camera", systemImage: "camera")
            }
            .tag(0)
            
            NavigationStack {
                HistoryView()
                    .navigationTitle("History")
            }
            .tabItem {
                Label("History", systemImage: "calendar")
            }
            .tag(1)
            
//            NavigationStack {
//                SettingsView()
//                    .navigationTitle("Settings")
//            }
//            .tabItem {
//                Label("Settings", systemImage: "gear")
//            }
//            .tag(2)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [FoodEntry.self, Ingredient.self], inMemory: true)
}
