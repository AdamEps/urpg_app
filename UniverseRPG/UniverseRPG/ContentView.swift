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
                
                // Tap counter pop out positioned below location name
                VStack {
                    // Push down to position below location name header
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 150) // Height to clear top bar + location name + more space
                    
                    if gameState.showTapCounter {
                        HStack(alignment: .bottom, spacing: 0) {
                            Spacer()
                            
                            // Toggle button on left side of tap counter box when open
                            Button(action: {
                                gameState.showTapCounter.toggle()
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
                            
                            // Tap counter box
                            TapCounterView(gameState: gameState)
                                .frame(width: UIScreen.main.bounds.width * 0.3)
                        }
                        .padding(.trailing, 0)
                    } else {
                        HStack {
                            Spacer()
                            
                            // Toggle button on right side of screen when closed
                            Button(action: {
                                gameState.showTapCounter.toggle()
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
                    }
                    
                    Spacer()
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
        VStack(spacing: 4) {
            // Top row - Player name, gear, and currency
            HStack {
                // Left - Settings (moved up) - fixed width
                Button(action: {
                    // Settings action
                }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.white)
                }
                .frame(width: 100, alignment: .leading) // Match right side width for perfect centering
                
                Spacer()
                
                // Center - Player Name (bigger font) - perfectly centered
                Text(gameState.playerName)
                    .font(.title3)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Right - Currency (moved up) - fixed width
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(gameState.getFormattedCurrency())
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(width: 100, alignment: .trailing) // Fixed width to prevent shifting
            }
            
            // Bottom row - Level, progress bar, and objectives (moved down)
            HStack(spacing: 8) {
                Spacer()
                
                Text("Level \(gameState.playerLevel)")
                    .font(.caption)
                    .foregroundColor(.white)
                
                // Level progress bar
                ProgressView(value: gameState.getXPProgressPercentage())
                    .frame(width: 140, height: 12)
                    .tint(.green)
                
                Button(action: {
                    gameState.showObjectives.toggle()
                }) {
                    Image(systemName: "target")
                        .foregroundColor(.white)
                }
                
                Spacer()
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
            
            // Tap counter with reset button (conditionally shown)
            if gameState.showTapCounter {
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
            }
            
            // Toggle button for tap counter
            HStack {
                Spacer()
                Button(action: {
                    gameState.showTapCounter.toggle()
                }) {
                    Image(systemName: gameState.showTapCounter ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(4)
                }
                Spacer()
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
                Spacer()
                
                // Centered clickable location (positioned based on tap counter visibility)
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
                    
                    // Collection feedback (tap)
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
                    
                    // Idle collection feedback
                    if gameState.showIdleCollectionFeedback, let resource = gameState.lastIdleCollectedResource {
                        VStack {
                            Text("+1")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Text(resource.rawValue)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .multilineTextAlignment(.center)
                            
                            Text("(Idle)")
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                        .offset(y: -120)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: gameState.showIdleCollectionFeedback)
                    }
                    
                    // Numins collection feedback
                    if gameState.showNuminsFeedback {
                        VStack {
                            Text("+\(gameState.lastNuminsAmount)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                            
                            Text("Numins")
                                .font(.caption)
                                .foregroundColor(.yellow)
                                .multilineTextAlignment(.center)
                            
                            Text("(Bonus!)")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                                .fontWeight(.medium)
                        }
                        .padding(8)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(8)
                        .offset(y: -160)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: gameState.showNuminsFeedback)
                    }
                    
                    // XP collection feedback
                    if gameState.showXPFeedback {
                        VStack {
                            Text("+\(gameState.lastXPAmount)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            
                            Text("XP")
                                .font(.caption)
                                .foregroundColor(.purple)
                                .multilineTextAlignment(.center)
                            
                            Text("(Experience!)")
                                .font(.caption2)
                                .foregroundColor(.purple)
                                .fontWeight(.medium)
                        }
                        .padding(8)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(8)
                        .offset(y: -200)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: gameState.showXPFeedback)
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
        case .numins: return "star.fill"
        
        // TaraGam 3 resources
        case .hydrogen: return "h.circle.fill"
        case .methane: return "flame"
        case .ammonia: return "drop.triangle"
        case .ice: return "snowflake"
        case .crystals: return "diamond"
        case .minerals: return "cube"
        
        // Abandoned Star Ship resources
        case .scrapMetal: return "wrench.and.screwdriver"
        case .electronics: return "cpu"
        case .fuelCells: return "battery.100"
        case .dataCores: return "externaldrive"
        case .circuits: return "circle.grid.cross"
        case .alloys: return "rectangle.stack"
        case .components: return "gearshape.2"
        case .techParts: return "gear"
        case .batteries: return "battery.50"
        case .wiring: return "cable.connector"
        
        // Ernest's Homestead resources
        case .food: return "leaf"
        case .textiles: return "tshirt"
        case .tools: return "hammer"
        case .medicine: return "cross.case"
        case .seeds: return "seedling"
        case .livestock: return "pawprint"
        case .grain: return "leaf.circle"
        case .vegetables: return "carrot"
        case .herbs: return "leaf.arrow.circlepath"
        case .supplies: return "shippingbox"
        
        // Koraxon resources
        case .heavyElements: return "atom"
        case .denseMatter: return "circle.fill"
        case .compressedGas: return "cloud.fill"
        case .exoticMatter: return "sparkles"
        case .gravitons: return "arrow.down.circle"
        case .darkEnergy: return "moon.stars"
        case .neutronium: return "n.circle"
        case .quarkMatter: return "q.circle"
        case .strangeMatter: return "s.circle"
        case .antimatter: return "minus.circle"
        
        // Taragon Beta resources
        case .redPlasma: return "flame.circle"
        case .infraredEnergy: return "thermometer"
        case .stellarWind: return "wind"
        case .magneticFields: return "magnifyingglass"
        case .cosmicRays: return "rays"
        case .photons: return "lightbulb"
        case .particles: return "circle.dotted"
        case .solarFlares: return "sun.max"
        case .corona: return "sun.haze"
        case .chromosphere: return "circle.hexagongrid"
        
        // Violis Alpha resources
        case .stellarDust: return "sparkle"
        case .cosmicDebris: return "trash"
        case .microParticles: return "circle.grid.3x3"
        case .spaceGas: return "cloud"
        case .ionStreams: return "arrow.right"
        case .electronFlow: return "e.circle"
        case .protonBeams: return "p.circle"
        case .neutronFlux: return "n.circle.fill"
        case .gammaRays: return "g.circle"
        case .xRays: return "x.circle"
        
        // Violis Outpost resources
        case .researchData: return "doc.text"
        case .labEquipment: return "flask"
        case .samples: return "testtube.2"
        case .experiments: return "beaker"
        case .prototypes: return "cube.transparent"
        case .blueprints: return "doc.plaintext"
        case .formulas: return "function"
        case .algorithms: return "chevron.left.forwardslash.chevron.right"
        case .code: return "curlybraces"
        case .documentation: return "book"
        
        // Rogue Wanderer resources
        case .frozenGases: return "snowflake.circle"
        case .iceCrystals: return "diamond.fill"
        case .preservedMatter: return "cube.box"
        case .ancientArtifacts: return "crown"
        case .relics: return "building.columns"
        case .fossils: return "leaf.fill"
        case .rareElements: return "r.circle"
        case .crystallineStructures: return "diamond.circle"
        case .geologicalSamples: return "mountain.2"
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
        case .numins: return .yellow
        
        // TaraGam 3 resources
        case .hydrogen: return .cyan
        case .methane: return .orange
        case .ammonia: return .green
        case .ice: return .blue
        case .crystals: return .purple
        case .minerals: return .brown
        
        // Abandoned Star Ship resources
        case .scrapMetal: return .gray
        case .electronics: return .blue
        case .fuelCells: return .green
        case .dataCores: return .purple
        case .circuits: return .yellow
        case .alloys: return .gray
        case .components: return .orange
        case .techParts: return .blue
        case .batteries: return .green
        case .wiring: return .red
        
        // Ernest's Homestead resources
        case .food: return .green
        case .textiles: return .blue
        case .tools: return .gray
        case .medicine: return .red
        case .seeds: return .brown
        case .livestock: return .orange
        case .grain: return .yellow
        case .vegetables: return .green
        case .herbs: return .green
        case .supplies: return .brown
        
        // Koraxon resources
        case .heavyElements: return .purple
        case .denseMatter: return .black
        case .compressedGas: return .cyan
        case .exoticMatter: return .purple
        case .gravitons: return .blue
        case .darkEnergy: return .black
        case .neutronium: return .gray
        case .quarkMatter: return .red
        case .strangeMatter: return .purple
        case .antimatter: return .white
        
        // Taragon Beta resources
        case .redPlasma: return .red
        case .infraredEnergy: return .red
        case .stellarWind: return .cyan
        case .magneticFields: return .blue
        case .cosmicRays: return .purple
        case .photons: return .yellow
        case .particles: return .white
        case .solarFlares: return .orange
        case .corona: return .yellow
        case .chromosphere: return .orange
        
        // Violis Alpha resources
        case .stellarDust: return .gray
        case .cosmicDebris: return .brown
        case .microParticles: return .white
        case .spaceGas: return .cyan
        case .ionStreams: return .blue
        case .electronFlow: return .yellow
        case .protonBeams: return .red
        case .neutronFlux: return .gray
        case .gammaRays: return .green
        case .xRays: return .purple
        
        // Violis Outpost resources
        case .researchData: return .blue
        case .labEquipment: return .gray
        case .samples: return .green
        case .experiments: return .purple
        case .prototypes: return .cyan
        case .blueprints: return .blue
        case .formulas: return .orange
        case .algorithms: return .red
        case .code: return .green
        case .documentation: return .brown
        
        // Rogue Wanderer resources
        case .frozenGases: return .cyan
        case .iceCrystals: return .blue
        case .preservedMatter: return .gray
        case .ancientArtifacts: return .yellow
        case .relics: return .brown
        case .fossils: return .brown
        case .rareElements: return .purple
        case .crystallineStructures: return .purple
        case .geologicalSamples: return .brown
        }
    }
}

// MARK: - Tap Counter View
struct TapCounterView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        HStack(spacing: 4) {
            Text("Tap Count:")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text("\(gameState.currentLocationTapCount)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(Color.black)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray, lineWidth: 1)
        )
        .cornerRadius(6)
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
        case .numins: return "star.fill"
        
        // TaraGam 3 resources
        case .hydrogen: return "h.circle.fill"
        case .methane: return "flame"
        case .ammonia: return "drop.triangle"
        case .ice: return "snowflake"
        case .crystals: return "diamond"
        case .minerals: return "cube"
        
        // Abandoned Star Ship resources
        case .scrapMetal: return "wrench.and.screwdriver"
        case .electronics: return "cpu"
        case .fuelCells: return "battery.100"
        case .dataCores: return "externaldrive"
        case .circuits: return "circle.grid.cross"
        case .alloys: return "rectangle.stack"
        case .components: return "gearshape.2"
        case .techParts: return "gear"
        case .batteries: return "battery.50"
        case .wiring: return "cable.connector"
        
        // Ernest's Homestead resources
        case .food: return "leaf"
        case .textiles: return "tshirt"
        case .tools: return "hammer"
        case .medicine: return "cross.case"
        case .seeds: return "seedling"
        case .livestock: return "pawprint"
        case .grain: return "leaf.circle"
        case .vegetables: return "carrot"
        case .herbs: return "leaf.arrow.circlepath"
        case .supplies: return "shippingbox"
        
        // Koraxon resources
        case .heavyElements: return "atom"
        case .denseMatter: return "circle.fill"
        case .compressedGas: return "cloud.fill"
        case .exoticMatter: return "sparkles"
        case .gravitons: return "arrow.down.circle"
        case .darkEnergy: return "moon.stars"
        case .neutronium: return "n.circle"
        case .quarkMatter: return "q.circle"
        case .strangeMatter: return "s.circle"
        case .antimatter: return "minus.circle"
        
        // Taragon Beta resources
        case .redPlasma: return "flame.circle"
        case .infraredEnergy: return "thermometer"
        case .stellarWind: return "wind"
        case .magneticFields: return "magnifyingglass"
        case .cosmicRays: return "rays"
        case .photons: return "lightbulb"
        case .particles: return "circle.dotted"
        case .solarFlares: return "sun.max"
        case .corona: return "sun.haze"
        case .chromosphere: return "circle.hexagongrid"
        
        // Violis Alpha resources
        case .stellarDust: return "sparkle"
        case .cosmicDebris: return "trash"
        case .microParticles: return "circle.grid.3x3"
        case .spaceGas: return "cloud"
        case .ionStreams: return "arrow.right"
        case .electronFlow: return "e.circle"
        case .protonBeams: return "p.circle"
        case .neutronFlux: return "n.circle.fill"
        case .gammaRays: return "g.circle"
        case .xRays: return "x.circle"
        
        // Violis Outpost resources
        case .researchData: return "doc.text"
        case .labEquipment: return "flask"
        case .samples: return "testtube.2"
        case .experiments: return "beaker"
        case .prototypes: return "cube.transparent"
        case .blueprints: return "doc.plaintext"
        case .formulas: return "function"
        case .algorithms: return "chevron.left.forwardslash.chevron.right"
        case .code: return "curlybraces"
        case .documentation: return "book"
        
        // Rogue Wanderer resources
        case .frozenGases: return "snowflake.circle"
        case .iceCrystals: return "diamond.fill"
        case .preservedMatter: return "cube.box"
        case .ancientArtifacts: return "crown"
        case .relics: return "building.columns"
        case .fossils: return "leaf.fill"
        case .rareElements: return "r.circle"
        case .crystallineStructures: return "diamond.circle"
        case .geologicalSamples: return "mountain.2"
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
        case .numins: return .yellow
        
        // TaraGam 3 resources
        case .hydrogen: return .cyan
        case .methane: return .orange
        case .ammonia: return .green
        case .ice: return .blue
        case .crystals: return .purple
        case .minerals: return .brown
        
        // Abandoned Star Ship resources
        case .scrapMetal: return .gray
        case .electronics: return .blue
        case .fuelCells: return .green
        case .dataCores: return .purple
        case .circuits: return .yellow
        case .alloys: return .gray
        case .components: return .orange
        case .techParts: return .blue
        case .batteries: return .green
        case .wiring: return .red
        
        // Ernest's Homestead resources
        case .food: return .green
        case .textiles: return .blue
        case .tools: return .gray
        case .medicine: return .red
        case .seeds: return .brown
        case .livestock: return .orange
        case .grain: return .yellow
        case .vegetables: return .green
        case .herbs: return .green
        case .supplies: return .brown
        
        // Koraxon resources
        case .heavyElements: return .purple
        case .denseMatter: return .black
        case .compressedGas: return .cyan
        case .exoticMatter: return .purple
        case .gravitons: return .blue
        case .darkEnergy: return .black
        case .neutronium: return .gray
        case .quarkMatter: return .red
        case .strangeMatter: return .purple
        case .antimatter: return .white
        
        // Taragon Beta resources
        case .redPlasma: return .red
        case .infraredEnergy: return .red
        case .stellarWind: return .cyan
        case .magneticFields: return .blue
        case .cosmicRays: return .purple
        case .photons: return .yellow
        case .particles: return .white
        case .solarFlares: return .orange
        case .corona: return .yellow
        case .chromosphere: return .orange
        
        // Violis Alpha resources
        case .stellarDust: return .gray
        case .cosmicDebris: return .brown
        case .microParticles: return .white
        case .spaceGas: return .cyan
        case .ionStreams: return .blue
        case .electronFlow: return .yellow
        case .protonBeams: return .red
        case .neutronFlux: return .gray
        case .gammaRays: return .green
        case .xRays: return .purple
        
        // Violis Outpost resources
        case .researchData: return .blue
        case .labEquipment: return .gray
        case .samples: return .green
        case .experiments: return .purple
        case .prototypes: return .cyan
        case .blueprints: return .blue
        case .formulas: return .orange
        case .algorithms: return .red
        case .code: return .green
        case .documentation: return .brown
        
        // Rogue Wanderer resources
        case .frozenGases: return .cyan
        case .iceCrystals: return .blue
        case .preservedMatter: return .gray
        case .ancientArtifacts: return .yellow
        case .relics: return .brown
        case .fossils: return .brown
        case .rareElements: return .purple
        case .crystallineStructures: return .purple
        case .geologicalSamples: return .brown
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
            ScrollView {
                VStack(spacing: 24) {
                    // Explorer Class Section
                    CardClassSection(
                        title: "Explorer Class",
                        cardClass: .explorer,
                        gameState: gameState
                    )
                    
                    // Constructor Class Section
                    CardClassSection(
                        title: "Constructor Class",
                        cardClass: .constructor,
                        gameState: gameState
                    )
                    
                    // Collector Class Section
                    CardClassSection(
                        title: "Collector Class",
                        cardClass: .collector,
                        gameState: gameState
                    )
                    
                    // Progression Class Section
                    CardClassSection(
                        title: "Progression Class",
                        cardClass: .progression,
                        gameState: gameState
                    )
                }
                .padding()
            }
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

struct CardClassSection: View {
    let title: String
    let cardClass: CardClass
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(0..<8, id: \.self) { index in
                    CardSlotView(
                        cardClass: cardClass,
                        slotIndex: index,
                        gameState: gameState
                    )
                }
            }
        }
    }
}

struct CardSlotView: View {
    let cardClass: CardClass
    let slotIndex: Int
    @ObservedObject var gameState: GameState
    
    private var cardDef: CardDef? {
        let cardsForClass = gameState.getCardsForClass(cardClass)
        return slotIndex < cardsForClass.count ? cardsForClass[slotIndex] : nil
    }
    
    private var userCard: UserCard? {
        guard let cardDef = cardDef else { return nil }
        return gameState.getUserCard(for: cardDef.id)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            if let cardDef = cardDef, let userCard = userCard {
                // Owned card
                VStack(spacing: 2) {
                    // Card icon/art placeholder
                    RoundedRectangle(cornerRadius: 8)
                        .fill(cardClassColor.opacity(0.3))
                        .frame(height: 180)
                        .overlay(
                            VStack {
                                Image(systemName: cardClassIcon)
                                    .font(.title2)
                                    .foregroundColor(cardClassColor)
                                
                                Text("T\(userCard.tier)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(cardClassColor)
                            }
                        )
                    
                    // Card name
                    Text(cardDef.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    // Copies count
                    Text("\(userCard.copies) copies")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                // Empty slot
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(cardClassColor.opacity(0.3), lineWidth: 2)
                        .frame(height: 180)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(cardClassColor.opacity(0.5))
                        )
                    
                    Text("Empty Slot")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 220)
    }
    
    private var cardClassColor: Color {
        switch cardClass {
        case .explorer: return .blue
        case .constructor: return .orange
        case .collector: return .green
        case .progression: return .purple
        }
    }
    
    private var cardClassIcon: String {
        switch cardClass {
        case .explorer: return "telescope"
        case .constructor: return "hammer"
        case .collector: return "shippingbox"
        case .progression: return "chart.line.uptrend.xyaxis"
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
                    // Gameplay Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Gameplay")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Total Experience Gained Tracker
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Experience Gained")
                                    .font(.headline)
                                Text("All XP earned from gameplay")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(gameState.totalXPGained)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.purple)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                        
                        // Total Taps Tracker (collapsible)
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                gameState.showTapDetails.toggle()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Total Taps")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("All location taps combined")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(gameState.totalTapsCount)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                    
                                    Image(systemName: gameState.showTapDetails ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.blue)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Expanded details
                            if gameState.showTapDetails {
                                ForEach(gameState.availableLocations, id: \.id) { location in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(location.name)
                                                .font(.subheadline)
                                            Text("\(location.system) • \(location.kind.rawValue)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("\(gameState.locationTapCounts[location.id, default: 0])")
                                            .font(.callout)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 16)
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(6)
                                }
                            }
                        }
                    }
                    
                    // Resources Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Resources")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Idle Collection Tracker (collapsible)
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                gameState.showIdleCollectionDetails.toggle()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Idle Collection")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("Resources collected while away")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(gameState.totalIdleCollectionCount)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                    
                                    Image(systemName: gameState.showIdleCollectionDetails ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.blue)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Expanded details
                            if gameState.showIdleCollectionDetails {
                                ForEach(gameState.availableLocations, id: \.id) { location in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(location.name)
                                                .font(.subheadline)
                                            Text("\(location.system) • \(location.kind.rawValue)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("\(gameState.locationIdleCollectionCounts[location.id, default: 0])")
                                            .font(.callout)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 16)
                                    .background(Color.blue.opacity(0.05))
                                    .cornerRadius(6)
                                }
                            }
                        }
                        
                        // Numins Tracker
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Numins")
                                    .font(.headline)
                                Text("The currency of the cosmos!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(gameState.getFormattedNumins())
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.yellow)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
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
            .navigationTitle("Statistics and Objectives")
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

