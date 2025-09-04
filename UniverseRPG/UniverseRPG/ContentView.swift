//
//  ContentView.swift
//  UniverseRPG
//
//  Created by Adam Epstein on 9/3/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header with current location and resources
                HeaderView(gameState: gameState)
                
                // Main game area
                ScrollView {
                    VStack(spacing: 16) {
                        // Current location view
                        LocationView(gameState: gameState)
                        
                        // Construction area
                        ConstructionView(gameState: gameState)
                        
                        // Resources display
                        ResourcesView(gameState: gameState)
                    }
                    .padding()
                }
                
                // Bottom navigation
                BottomNavigationView(gameState: gameState)
            }
            .navigationTitle("Universe RPG")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            gameState.startGame()
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 8) {
            Text(gameState.currentLocation.name)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                ForEach(gameState.resources, id: \.type) { resource in
                    ResourceBadge(resource: resource)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Location View
struct LocationView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Current Location")
                .font(.headline)
            
            // Tap to collect resources
            Button(action: {
                gameState.tapLocation()
            }) {
                VStack {
                    Image(systemName: "globe")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Tap to Collect")
                        .font(.caption)
                }
                .frame(width: 120, height: 120)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(20)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Resources: \(gameState.currentLocation.availableResources)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Construction View
struct ConstructionView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Constructions")
                .font(.headline)
            
            if gameState.activeConstructions.isEmpty {
                Text("No active constructions")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(gameState.activeConstructions) { construction in
                    ConstructionRow(construction: construction, gameState: gameState)
                }
            }
            
            // Add new construction button
            Button("Start New Construction") {
                gameState.showConstructionMenu = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .sheet(isPresented: $gameState.showConstructionMenu) {
            ConstructionMenuView(gameState: gameState)
        }
    }
}

// MARK: - Construction Row
struct ConstructionRow: View {
    let construction: Construction
    @ObservedObject var gameState: GameState
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(construction.name)
                    .fontWeight(.medium)
                Text("Time remaining: \(Int(construction.timeRemaining))s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            ProgressView(value: construction.progress)
                .frame(width: 100)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Resources View
struct ResourcesView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resources")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(gameState.resources, id: \.type) { resource in
                    ResourceCard(resource: resource)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Resource Card
struct ResourceCard: View {
    let resource: Resource
    
    var body: some View {
        VStack {
            Image(systemName: resource.icon)
                .font(.title2)
                .foregroundColor(resource.color)
            
            Text(resource.type.rawValue)
                .font(.caption)
                .fontWeight(.medium)
            
            Text("\(resource.amount)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

// MARK: - Resource Badge
struct ResourceBadge: View {
    let resource: Resource
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: resource.icon)
                .foregroundColor(resource.color)
            Text("\(resource.amount)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Bottom Navigation
struct BottomNavigationView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        HStack {
            Button("Locations") {
                gameState.showLocations = true
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("Shop") {
                gameState.showShop = true
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("Cards") {
                gameState.showCards = true
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .sheet(isPresented: $gameState.showLocations) {
            LocationsView(gameState: gameState)
        }
        .sheet(isPresented: $gameState.showShop) {
            ShopView(gameState: gameState)
        }
        .sheet(isPresented: $gameState.showCards) {
            CardsView(gameState: gameState)
        }
    }
}

// MARK: - Construction Menu
struct ConstructionMenuView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(ConstructionType.allCases, id: \.self) { type in
                    Button(action: {
                        gameState.startConstruction(type: type)
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(type.name)
                                    .fontWeight(.medium)
                                Text("Cost: \(type.cost) Energy")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(type.duration)s")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(!gameState.canAffordConstruction(type: type))
                }
            }
            .navigationTitle("Start Construction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Placeholder Views
struct LocationsView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(gameState.availableLocations, id: \.id) { location in
                    Button(action: {
                        gameState.changeLocation(to: location)
                        dismiss()
                    }) {
                        HStack {
                            Text(location.name)
                            Spacer()
                            if location.id == gameState.currentLocation.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ShopView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Shop Coming Soon!")
                .navigationTitle("Shop")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct CardsView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Cards Coming Soon!")
                .navigationTitle("Cards")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
