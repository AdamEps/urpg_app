import Foundation
import SwiftUI

// MARK: - Game State
class GameState: ObservableObject {
    @Published var currentLocation: Location
    @Published var resources: [Resource] = []
    @Published var constructionBays: [ConstructionBay] = []
    @Published var availableLocations: [Location] = []
    @Published var showConstructionMenu = false
    @Published var showConstructionPage = false
    @Published var showLocations = false
    @Published var showShop = false
    @Published var showResourcesPage = false
    @Published var showCards = false
    @Published var showLocationResources = false
    
    // Player data
    @Published var playerName: String = "Commander"
    @Published var playerLevel: Int = 1
    @Published var playerXP: Int = 0
    @Published var currency: Int = 1000
    
    private var gameTimer: Timer?
    
    init() {
        // Initialize with starting location (Taragon Gamma system)
        self.currentLocation = Location(
            id: "taragam-7",
            name: "Taragam-7",
            description: "Habitable planet in Taragon Gamma system",
            system: "Taragon Gamma",
            kind: .planet,
            availableResources: ["Iron Ore", "Silicon", "Water", "Oxygen", "Carbon", "Nitrogen", "Phosphorus", "Sulfur", "Calcium", "Magnesium"],
            unlockRequirements: []
        )
        
        // Initialize resources (items with drop tables)
        self.resources = [
            Resource(type: .ironOre, amount: 0, icon: "cube.fill", color: .gray),
            Resource(type: .silicon, amount: 0, icon: "diamond.fill", color: .purple),
            Resource(type: .water, amount: 0, icon: "drop.fill", color: .blue),
            Resource(type: .oxygen, amount: 0, icon: "wind", color: .cyan),
            Resource(type: .carbon, amount: 0, icon: "circle.fill", color: .black),
            Resource(type: .nitrogen, amount: 0, icon: "n.circle.fill", color: .green),
            Resource(type: .phosphorus, amount: 0, icon: "p.circle.fill", color: .orange),
            Resource(type: .sulfur, amount: 0, icon: "s.circle.fill", color: .yellow),
            Resource(type: .calcium, amount: 0, icon: "c.circle.fill", color: .white),
            Resource(type: .magnesium, amount: 0, icon: "m.circle.fill", color: .pink)
        ]
        
        // Initialize available locations (Taragon Gamma system)
        self.availableLocations = [
            currentLocation,
            Location(
                id: "elcinto",
                name: "Elcinto",
                description: "Moon of Taragam-7",
                system: "Taragon Gamma",
                kind: .moon,
                availableResources: ["Iron Ore", "Silicon", "Helium-3", "Titanium", "Aluminum", "Nickel", "Cobalt", "Chromium", "Vanadium", "Manganese"],
                unlockRequirements: ["Iron Ore: 100"]
            ),
            Location(
                id: "taragon-gamma",
                name: "Taragon Gamma",
                description: "Class 3 star, main sequence, yellow",
                system: "Taragon Gamma",
                kind: .star,
                availableResources: ["Plasma", "Element", "Isotope", "Energy", "Radiation", "Heat", "Light", "Gravity", "Magnetic", "Solar"],
                unlockRequirements: ["Silicon: 200", "Helium-3: 50"]
            )
        ]
        
        // Initialize construction bays (start with 1 Small bay)
        self.constructionBays = [
            ConstructionBay(
                id: "bay-1",
                size: .small,
                currentConstruction: nil,
                isUnlocked: true
            )
        ]
    }
    
    func startGame() {
        // Start the game timer for idle collection
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateGame()
        }
    }
    
    private func updateGame() {
        // Update construction bays
        for i in constructionBays.indices {
            if let construction = constructionBays[i].currentConstruction {
                constructionBays[i].currentConstruction?.timeRemaining -= 1.0
                
                // Update progress
                let totalDuration = construction.recipe.duration
                let elapsed = totalDuration - construction.timeRemaining
                constructionBays[i].currentConstruction?.progress = min(elapsed / totalDuration, 1.0)
                
                if construction.timeRemaining <= 0 {
                    // Construction completed
                    completeConstruction(at: i)
                }
            }
        }
        
        // Idle resource collection
        collectIdleResources()
    }
    
    private func collectIdleResources() {
        // Simple idle collection - add small amounts of resources over time
        for i in resources.indices {
            let resource = resources[i]
            let idleRate = getResourceIdleRate(for: resource.type)
            resources[i].amount += idleRate
        }
    }
    
    private func getResourceIdleRate(for type: ResourceType) -> Double {
        // Idle collection: 1 item per minute (1/60 per second) with drop table odds
        // For MVP, simplified to basic rates
        switch type {
        case .ironOre, .silicon, .water, .oxygen, .carbon:
            return 1.0/60.0 // 1 per minute
        case .nitrogen, .phosphorus, .sulfur, .calcium, .magnesium:
            return 0.5/60.0 // 0.5 per minute
        case .helium3, .titanium, .aluminum, .nickel, .cobalt:
            return 0.3/60.0 // 0.3 per minute
        case .chromium, .vanadium, .manganese:
            return 0.2/60.0 // 0.2 per minute
        case .plasma, .element, .isotope, .energy, .radiation:
            return 0.1/60.0 // 0.1 per minute
        case .heat, .light, .gravity, .magnetic, .solar:
            return 0.05/60.0 // 0.05 per minute
        }
    }
    
    func tapLocation() {
        // Active tapping mechanic - gives immediate resources
        let tapReward = getTapReward()
        
        for i in resources.indices {
            if let reward = tapReward[resources[i].type] {
                resources[i].amount += reward
            }
        }
        
        // Add some visual feedback here if needed
    }
    
    private func getTapReward() -> [ResourceType: Double] {
        // Tap rewards based on current location (1 item per tap with rarity bias)
        switch currentLocation.id {
        case "taragam-7":
            return [.ironOre: 1, .silicon: 1, .water: 1, .oxygen: 1, .carbon: 1]
        case "elcinto":
            return [.ironOre: 1, .silicon: 1, .helium3: 1, .titanium: 1, .aluminum: 1]
        case "taragon-gamma":
            return [.plasma: 1, .element: 1, .isotope: 1, .energy: 1, .radiation: 1]
        default:
            return [.ironOre: 1]
        }
    }
    
    func startConstruction(recipe: ConstructionRecipe) {
        guard canAffordConstruction(recipe: recipe) else { return }
        
        // Find an empty bay of the right size
        guard let bayIndex = constructionBays.firstIndex(where: { 
            $0.currentConstruction == nil && 
            $0.isUnlocked && 
            $0.size == recipe.requiredBaySize 
        }) else { return }
        
        // Deduct cost
        for i in resources.indices {
            if let cost = recipe.cost[resources[i].type] {
                resources[i].amount -= cost
            }
        }
        
        // Create construction
        let construction = Construction(
            id: UUID().uuidString,
            recipe: recipe,
            timeRemaining: recipe.duration,
            progress: 0.0
        )
        
        constructionBays[bayIndex].currentConstruction = construction
    }
    
    func canAffordConstruction(recipe: ConstructionRecipe) -> Bool {
        for resource in resources {
            if let cost = recipe.cost[resource.type] {
                if resource.amount < cost {
                    return false
                }
            }
        }
        return true
    }
    
    private func completeConstruction(at index: Int) {
        guard let construction = constructionBays[index].currentConstruction else { return }
        
        // Give rewards based on construction recipe
        for i in resources.indices {
            if let reward = construction.recipe.reward[resources[i].type] {
                resources[i].amount += reward
            }
        }
        
        // Clear the bay
        constructionBays[index].currentConstruction = nil
        
        // Check for location unlocks
        checkLocationUnlocks()
    }
    
    private func checkLocationUnlocks() {
        // Simple unlock logic - could be more complex
        for location in availableLocations {
            if !isLocationUnlocked(location) && canUnlockLocation(location) {
                // Location is now unlocked
                // In a real game, you'd update the UI to show this
            }
        }
    }
    
    private func isLocationUnlocked(_ location: Location) -> Bool {
        // For now, all locations are unlocked
        return true
    }
    
    private func canUnlockLocation(_ location: Location) -> Bool {
        // Check if player has enough resources to unlock location
        for requirement in location.unlockRequirements {
            // Parse requirement string like "Energy: 200"
            let components = requirement.components(separatedBy: ": ")
            if components.count == 2,
               let resourceType = ResourceType(rawValue: components[0]),
               let requiredAmount = Double(components[1]) {
                
                if let resource = resources.first(where: { $0.type == resourceType }) {
                    if resource.amount < requiredAmount {
                        return false
                    }
                }
            }
        }
        return true
    }
    
    func changeLocation(to location: Location) {
        currentLocation = location
    }
    
    func getLocationDropTable() -> [(ResourceType, Double)] {
        // Return drop table percentages for current location
        // Based on TDD: [30%, 20%, 15%, 10%, 8%, 6%, 5%, 3%, 2%, 1%]
        let percentages = [30.0, 20.0, 15.0, 10.0, 8.0, 6.0, 5.0, 3.0, 2.0, 1.0]
        
        switch currentLocation.id {
        case "taragam-7":
            let resources: [ResourceType] = [.ironOre, .silicon, .water, .oxygen, .carbon, .nitrogen, .phosphorus, .sulfur, .calcium, .magnesium]
            return Array(zip(resources, percentages))
        case "elcinto":
            let resources: [ResourceType] = [.ironOre, .silicon, .helium3, .titanium, .aluminum, .nickel, .cobalt, .chromium, .vanadium, .manganese]
            return Array(zip(resources, percentages))
        case "taragon-gamma":
            let resources: [ResourceType] = [.plasma, .element, .isotope, .energy, .radiation, .heat, .light, .gravity, .magnetic, .solar]
            return Array(zip(resources, percentages))
        default:
            return []
        }
    }
    
    deinit {
        gameTimer?.invalidate()
    }
}

// MARK: - Data Models

struct Location: Identifiable {
    let id: String
    let name: String
    let description: String
    let system: String
    let kind: LocationKind
    let availableResources: [String]
    let unlockRequirements: [String]
}

enum LocationKind: String, CaseIterable {
    case planet = "Planet"
    case moon = "Moon"
    case star = "Star"
    case anomaly = "Anomaly"
    case ship = "Ship"
    case dwarf = "Dwarf"
    case rogue = "Rogue"
}

struct Resource {
    let type: ResourceType
    var amount: Double
    let icon: String
    let color: Color
}

enum ResourceType: String, CaseIterable {
    case ironOre = "Iron Ore"
    case silicon = "Silicon"
    case water = "Water"
    case oxygen = "Oxygen"
    case carbon = "Carbon"
    case nitrogen = "Nitrogen"
    case phosphorus = "Phosphorus"
    case sulfur = "Sulfur"
    case calcium = "Calcium"
    case magnesium = "Magnesium"
    case helium3 = "Helium-3"
    case titanium = "Titanium"
    case aluminum = "Aluminum"
    case nickel = "Nickel"
    case cobalt = "Cobalt"
    case chromium = "Chromium"
    case vanadium = "Vanadium"
    case manganese = "Manganese"
    case plasma = "Plasma"
    case element = "Element"
    case isotope = "Isotope"
    case energy = "Energy"
    case radiation = "Radiation"
    case heat = "Heat"
    case light = "Light"
    case gravity = "Gravity"
    case magnetic = "Magnetic"
    case solar = "Solar"
}

struct ConstructionBay: Identifiable {
    let id: String
    let size: BaySize
    var currentConstruction: Construction?
    let isUnlocked: Bool
}

enum BaySize: String, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
}

struct Construction: Identifiable {
    let id: String
    let recipe: ConstructionRecipe
    var timeRemaining: Double
    var progress: Double
}

struct ConstructionRecipe: Identifiable {
    let id: String
    let name: String
    let description: String
    let duration: Double
    let cost: [ResourceType: Double]
    let reward: [ResourceType: Double]
    let requiredBaySize: BaySize
}

// Sample recipes for MVP
extension ConstructionRecipe {
    static let basicOreProcessor = ConstructionRecipe(
        id: "basic-ore-processor",
        name: "Basic Ore Processor",
        description: "Processes raw ore into refined materials",
        duration: 60.0,
        cost: [.ironOre: 10, .silicon: 5],
        reward: [.ironOre: 15, .silicon: 8],
        requiredBaySize: .small
    )
    
    static let waterExtractor = ConstructionRecipe(
        id: "water-extractor",
        name: "Water Extractor",
        description: "Extracts water from planetary sources",
        duration: 45.0,
        cost: [.ironOre: 8, .silicon: 3],
        reward: [.water: 20],
        requiredBaySize: .small
    )
    
    static let oxygenGenerator = ConstructionRecipe(
        id: "oxygen-generator",
        name: "Oxygen Generator",
        description: "Generates breathable oxygen",
        duration: 90.0,
        cost: [.water: 15, .silicon: 10, .ironOre: 5],
        reward: [.oxygen: 25],
        requiredBaySize: .medium
    )
    
    static let plasmaReactor = ConstructionRecipe(
        id: "plasma-reactor",
        name: "Plasma Reactor",
        description: "Advanced energy generation system",
        duration: 180.0,
        cost: [.silicon: 20, .ironOre: 15, .helium3: 5],
        reward: [.plasma: 30, .energy: 50],
        requiredBaySize: .large
    )
    
    static let allRecipes: [ConstructionRecipe] = [
        .basicOreProcessor,
        .waterExtractor,
        .oxygenGenerator,
        .plasmaReactor
    ]
}
