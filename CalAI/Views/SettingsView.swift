//
//  SettingsView.swift
//  CalAI
//
//  Created by Surya Teja Nammi on 6/8/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("openai_api_key") private var apiKey = ""
    @State private var showingKeyAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("API Configuration")) {
                HStack {
                    SecureField("OpenAI API Key", text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.none)
                    
                    Button(action: {
                        showingKeyAlert = true
                    }) {
                        Image(systemName: "info.circle")
                    }
                }
                
                Text("The API key is stored securely on your device only.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Link(destination: URL(string: "https://platform.openai.com/api-keys")!) {
                    Label("Get OpenAI API Key", systemImage: "key")
                }
                
                Link(destination: URL(string: "https://github.com/AppsClicks/CalAI")!) {
                    Label("View Documentation", systemImage: "book")
                }
            }
            
            Section {
                HStack {
                    Spacer()
                    Text("CalAI v1.0")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .navigationTitle("Settings")
        .alert("API Key Information", isPresented: $showingKeyAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your OpenAI API key is required for food analysis. It will be used only for processing your food images and is stored securely on your device.")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
