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
            VStack(spacing: 0) {
                // Top Bar (always visible)
                TopBarView(gameState: gameState)
                
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
            .navigationBarHidden(true)
        }
        .onAppear {
            gameState.startGame()
        }
    }
}

// MARK: - Top Bar View
struct TopBarView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        HStack {
            // Left - Settings
            Button(action: {
                // Settings action
            }) {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Center - Player Name, Level, Objectives
            VStack(spacing: 2) {
                Text(gameState.playerName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text("Level \(gameState.playerLevel)")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    // Level progress bar
                    ProgressView(value: Double(gameState.playerXP), total: 100.0)
                        .frame(width: 60)
                        .tint(.green)
                    
                    Button(action: {
                        // Objectives action
                    }) {
                        Image(systemName: "target")
                            .foregroundColor(.white)
                    }
                }
            }
            
            Spacer()
            
            // Right - Currency
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("\(gameState.currency)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
}

// MARK: - Header View (for location info)
struct HeaderView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 8) {
            Text(gameState.currentLocation.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text("\(gameState.currentLocation.system) • \(gameState.currentLocation.kind.rawValue)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                ForEach(gameState.resources.prefix(5), id: \.type) { resource in
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
            Text("Construction Bays")
                .font(.headline)
            
            if gameState.constructionBays.isEmpty {
                Text("No construction bays available")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(gameState.constructionBays) { bay in
                    ConstructionBayRow(bay: bay, gameState: gameState)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Construction Bay Row
struct ConstructionBayRow: View {
    let bay: ConstructionBay
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(bay.size.rawValue) Bay")
                    .fontWeight(.medium)
                
                Spacer()
                
                if bay.currentConstruction != nil {
                    Text("In Use")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Empty")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            if let construction = bay.currentConstruction {
                HStack {
                    VStack(alignment: .leading) {
                        Text(construction.recipe.name)
                            .fontWeight(.medium)
                        Text("Time remaining: \(Int(construction.timeRemaining))s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    ProgressView(value: construction.progress)
                        .frame(width: 100)
                }
            } else {
                Button("Start Construction") {
                    gameState.showConstructionMenu = true
                }
                .buttonStyle(.bordered)
                .disabled(!bay.isUnlocked)
            }
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
            Button("Shop") {
                gameState.showShop = true
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("Construction") {
                gameState.showConstructionMenu = true
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("Star Map") {
                gameState.showLocations = true
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("Resources") {
                // Resources are already shown in main view
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
            StarMapView(gameState: gameState)
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
                ForEach(ConstructionRecipe.allRecipes, id: \.id) { recipe in
                    Button(action: {
                        gameState.startConstruction(recipe: recipe)
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(recipe.name)
                                    .fontWeight(.medium)
                                Text(recipe.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Required: \(recipe.requiredBaySize.rawValue) Bay")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(Int(recipe.duration))s")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Cost: \(recipe.cost.count) items")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .disabled(!gameState.canAffordConstruction(recipe: recipe))
                }
            }
            .navigationTitle("Construction Recipes")
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
struct StarMapView: View {
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
                            VStack(alignment: .leading) {
                                Text(location.name)
                                    .fontWeight(.medium)
                                Text("\(location.system) • \(location.kind.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if location.id == gameState.currentLocation.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Star Map")
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

