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
            ZStack {
                VStack(spacing: 0) {
                    // Top Bar (always visible)
                    TopBarView(gameState: gameState)
                    
                    // Location name header
                    HStack {
                        Spacer()
                        Text(gameState.currentLocation.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                    
                    // Main game area
                    LocationView(gameState: gameState)
                    
                    // Bottom navigation
                    BottomNavigationView(gameState: gameState)
                    
                    // Black area below navigation
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 20)
                }
                
                // Resource pop out positioned above bottom navigation
                VStack {
                    Spacer()
                    
                    if gameState.showLocationResources {
                        HStack(alignment: .bottom, spacing: 0) {
                            Spacer()
                            
                            // Toggle button on left side of resource box when open
                            Button(action: {
                                gameState.showLocationResources.toggle()
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                                    .cornerRadius(6)
                            }
                            
                            // Resource box
                            LocationResourceListView(gameState: gameState)
                                .frame(width: UIScreen.main.bounds.width * 0.5)
                        }
                        .padding(.trailing, 0)
                        .padding(.bottom, 100) // Position above bottom navigation
                    } else {
                        HStack {
                            Spacer()
                            
                            // Toggle button on right side of screen when closed
                            Button(action: {
                                gameState.showLocationResources.toggle()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.trailing, 0)
                        .padding(.bottom, 100) // Position above bottom navigation
                    }
                }
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
                        gameState.showObjectives.toggle()
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
            
            // Tap counter with reset button
            HStack {
                Text("Taps: \(gameState.currentLocationTapCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Reset") {
                    gameState.resetCurrentLocationTapCount()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            HStack {
                ForEach(gameState.resources.filter { $0.amount > 0 }.prefix(5), id: \.type) { resource in
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
        ZStack {
            // Full screen background
            Color.clear
            
            VStack {
                // Tap counter and reset button at top
                HStack {
                    Text("Taps: \(gameState.currentLocationTapCount)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("Reset") {
                        gameState.resetCurrentLocationTapCount()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Centered clickable location
                ZStack {
                    Button(action: {
                        gameState.tapLocation()
                    }) {
                        VStack {
                            Image(systemName: "globe")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Tap to Collect")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .frame(width: 120, height: 120)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Collection feedback
                    if gameState.showCollectionFeedback, let resource = gameState.lastCollectedResource {
                        VStack {
                            Text("+1")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            
                            Text(resource.rawValue)
                                .font(.caption)
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                        }
                        .padding(8)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                        .offset(y: -80)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: gameState.showCollectionFeedback)
                    }
                }
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Location Resource List View
struct LocationResourceListView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Available Resources")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.bottom, 2)
            
            ForEach(gameState.getLocationDropTable(), id: \.0) { resourceType, percentage in
                HStack(spacing: 2) {
                    // Resource icon
                    Image(systemName: getResourceIcon(for: resourceType))
                        .foregroundColor(getResourceColor(for: resourceType))
                        .frame(width: 16)
                        .font(.caption)
                    
                    // Resource name
                    Text(resourceType.rawValue)
                        .font(.caption2)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Percentage
                    Text("\(Int(percentage))%")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.vertical, 1)
            }
        }
        .padding(8)
        .background(Color.black)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray, lineWidth: 1)
        )
        .cornerRadius(6)
    }
    
    private func getResourceIcon(for type: ResourceType) -> String {
        switch type {
        case .ironOre: return "cube.fill"
        case .silicon: return "diamond.fill"
        case .water: return "drop.fill"
        case .oxygen: return "wind"
        case .carbon: return "circle.fill"
        case .nitrogen: return "n.circle.fill"
        case .phosphorus: return "p.circle.fill"
        case .sulfur: return "s.circle.fill"
        case .calcium: return "c.circle.fill"
        case .magnesium: return "m.circle.fill"
        case .helium3: return "h.circle.fill"
        case .titanium: return "t.circle.fill"
        case .aluminum: return "a.circle.fill"
        case .nickel: return "n.circle.fill"
        case .cobalt: return "c.circle.fill"
        case .chromium: return "c.circle.fill"
        case .vanadium: return "v.circle.fill"
        case .manganese: return "m.circle.fill"
        case .plasma: return "bolt.fill"
        case .element: return "atom"
        case .isotope: return "circle.dotted"
        case .energy: return "bolt.fill"
        case .radiation: return "waveform"
        case .heat: return "flame.fill"
        case .light: return "sun.max.fill"
        case .gravity: return "arrow.down.circle.fill"
        case .magnetic: return "magnet"
        case .solar: return "sun.max.fill"
        }
    }
    
    private func getResourceColor(for type: ResourceType) -> Color {
        switch type {
        case .ironOre: return .gray
        case .silicon: return .purple
        case .water: return .blue
        case .oxygen: return .cyan
        case .carbon: return .black
        case .nitrogen: return .green
        case .phosphorus: return .orange
        case .sulfur: return .yellow
        case .calcium: return .white
        case .magnesium: return .pink
        case .helium3: return .blue
        case .titanium: return .gray
        case .aluminum: return .gray
        case .nickel: return .gray
        case .cobalt: return .blue
        case .chromium: return .gray
        case .vanadium: return .green
        case .manganese: return .purple
        case .plasma: return .red
        case .element: return .blue
        case .isotope: return .green
        case .energy: return .yellow
        case .radiation: return .orange
        case .heat: return .red
        case .light: return .yellow
        case .gravity: return .purple
        case .magnetic: return .blue
        case .solar: return .yellow
        }
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
        VStack(spacing: 4) {
            if resource.amount > 0 {
                Image(systemName: resource.icon)
                    .font(.title2)
                    .foregroundColor(resource.color)
                
                Text("\(Int(resource.amount))")
                    .font(.caption)
                    .foregroundColor(.white)
            } else {
                // Empty slot - show nothing or a placeholder
                Image(systemName: "square")
                    .font(.title2)
                    .foregroundColor(.clear)
                
                Text("")
                    .font(.caption)
            }
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(Color.black)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray, lineWidth: 1)
        )
        .cornerRadius(8)
    }
}

// MARK: - Empty Resource Card (placeholder for future resources)
struct EmptyResourceCard: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "questionmark.square")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("???")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
        )
        .cornerRadius(8)
    }
}

// MARK: - Blank Resource Card (for uncollected resources)
struct BlankResourceCard: View {
    var body: some View {
        VStack(spacing: 4) {
            // Completely blank - no icon or text
            Spacer()
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
        )
        .cornerRadius(8)
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
            Button(action: {
                gameState.showShop = true
            }) {
                Image(systemName: "cart.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: {
                gameState.showConstructionPage = true
            }) {
                Image(systemName: "hammer.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: {
                gameState.showLocations = true
            }) {
                Image(systemName: "globe")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: {
                gameState.showResourcesPage = true
            }) {
                Image(systemName: "cube.box.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: {
                gameState.showCards = true
            }) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 16) // Equal padding above and below icons
        .background(Color.gray.opacity(0.3))
        .sheet(isPresented: $gameState.showLocations) {
            StarMapView(gameState: gameState)
        }
        .sheet(isPresented: $gameState.showShop) {
            ShopView(gameState: gameState)
        }
        .sheet(isPresented: $gameState.showConstructionPage) {
            ConstructionPageView(gameState: gameState)
        }
        .sheet(isPresented: $gameState.showResourcesPage) {
            ResourcesPageView(gameState: gameState)
        }
        .sheet(isPresented: $gameState.showCards) {
            CardsView(gameState: gameState)
        }
        .sheet(isPresented: $gameState.showObjectives) {
            ObjectivesView(gameState: gameState)
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

// MARK: - Construction Page View
struct ConstructionPageView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Construction Bays
                    ForEach(gameState.constructionBays) { bay in
                        ConstructionBayRow(bay: bay, gameState: gameState)
                    }
                    
                    // Add new bay button (placeholder)
                    Button("Unlock New Bay") {
                        // TODO: Implement bay unlocking
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(true) // Disabled for now
                }
                .padding()
            }
            .navigationTitle("Construction Bays")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $gameState.showConstructionMenu) {
            ConstructionMenuView(gameState: gameState)
        }
    }
}

// MARK: - Resources Page View
struct ResourcesPageView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                    // Show 30 rows (150 total items) - existing resources + empty placeholders
                    ForEach(0..<150, id: \.self) { index in
                        if index < ResourceType.allCases.count {
                            // Show existing resource types
                            let resourceType = ResourceType.allCases[index]
                            if let resource = gameState.resources.first(where: { $0.type == resourceType }), resource.amount > 0 {
                                // Show resource card only if player has collected this resource
                                ResourceCard(resource: resource)
                            } else {
                                // Show blank placeholder for uncollected resources
                                BlankResourceCard()
                            }
                        } else {
                            // Show empty placeholder for future resources
                            EmptyResourceCard()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Resources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Test") {
                        gameState.printDropTableTestResults(taps: 100)
                    }
                }
            }
        }
    }
    
    private func getResourceIcon(for type: ResourceType) -> String {
        switch type {
        case .ironOre: return "cube.fill"
        case .silicon: return "diamond.fill"
        case .water: return "drop.fill"
        case .oxygen: return "wind"
        case .carbon: return "circle.fill"
        case .nitrogen: return "n.circle.fill"
        case .phosphorus: return "p.circle.fill"
        case .sulfur: return "s.circle.fill"
        case .calcium: return "c.circle.fill"
        case .magnesium: return "m.circle.fill"
        case .helium3: return "h.circle.fill"
        case .titanium: return "t.circle.fill"
        case .aluminum: return "a.circle.fill"
        case .nickel: return "n.circle.fill"
        case .cobalt: return "c.circle.fill"
        case .chromium: return "c.circle.fill"
        case .vanadium: return "v.circle.fill"
        case .manganese: return "m.circle.fill"
        case .plasma: return "bolt.fill"
        case .element: return "atom"
        case .isotope: return "circle.dotted"
        case .energy: return "bolt.circle.fill"
        case .radiation: return "waveform"
        case .heat: return "flame.fill"
        case .light: return "sun.max.fill"
        case .gravity: return "arrow.down.circle.fill"
        case .magnetic: return "magnet"
        case .solar: return "sun.max.circle.fill"
        }
    }
    
    private func getResourceColor(for type: ResourceType) -> Color {
        switch type {
        case .ironOre: return .gray
        case .silicon: return .purple
        case .water: return .blue
        case .oxygen: return .cyan
        case .carbon: return .black
        case .nitrogen: return .green
        case .phosphorus: return .orange
        case .sulfur: return .yellow
        case .calcium: return .white
        case .magnesium: return .pink
        case .helium3: return .blue
        case .titanium: return .gray
        case .aluminum: return .gray
        case .nickel: return .gray
        case .cobalt: return .blue
        case .chromium: return .gray
        case .vanadium: return .green
        case .manganese: return .purple
        case .plasma: return .red
        case .element: return .purple
        case .isotope: return .blue
        case .energy: return .yellow
        case .radiation: return .green
        case .heat: return .red
        case .light: return .yellow
        case .gravity: return .gray
        case .magnetic: return .blue
        case .solar: return .orange
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

// MARK: - Objectives View
struct ObjectivesView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Taps Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Taps")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(gameState.availableLocations, id: \.id) { location in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(location.name)
                                        .font(.headline)
                                    Text("\(location.system) • \(location.kind.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("\(gameState.locationTapCounts[location.id, default: 0])")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Coming Soon Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Coming Soon")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("More objectives and achievements will be added in future updates!")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Objectives")
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

