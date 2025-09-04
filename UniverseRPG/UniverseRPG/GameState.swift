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
    @Published var showObjectives = false
    @Published var showTapCounter = true
    
    // Player data
    @Published var playerName: String = "Commander"
    @Published var playerLevel: Int = 1
    @Published var playerXP: Int = 0
    @Published var currency: Int = 1000
    
    // Tap tracking
    @Published var currentLocationTapCount: Int = 0
    @Published var locationTapCounts: [String: Int] = [:]
    
    // Idle collection tracking
    @Published var locationIdleCollectionCounts: [String: Int] = [:]
    
    // Visual feedback
    @Published var lastCollectedResource: ResourceType?
    @Published var showCollectionFeedback: Bool = false
    @Published var lastIdleCollectedResource: ResourceType?
    @Published var showIdleCollectionFeedback: Bool = false
    
    // Idle collection tracking
    private var idleCollectionTimer: Double = 0.0
    private let idleCollectionInterval: Double = 10.0 // 10 seconds
    
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
        
        // Initialize resources as empty - resources will be added when first collected
        self.resources = []
        
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
        
        // Idle resource collection - every 10 seconds
        idleCollectionTimer += 1.0
        if idleCollectionTimer >= idleCollectionInterval {
            idleCollectionTimer = 0.0
            performIdleCollection()
        }
    }
    
    private func performIdleCollection() {
        // Idle collection: collect one resource every 10 seconds based on current location's drop table
        let dropTable = getLocationDropTable()
        let selectedResource = selectResourceFromDropTable(dropTable)
        
        // Add 1 of the selected resource (same logic as tapLocation)
        if let existingIndex = resources.firstIndex(where: { $0.type == selectedResource }) {
            // Resource already exists, increment amount
            resources[existingIndex].amount += 1
            print("Idle collected 1 \(selectedResource.rawValue) - Total: \(resources[existingIndex].amount)")
        } else {
            // Resource doesn't exist, create new entry
            let newResource = Resource(
                type: selectedResource,
                amount: 1,
                icon: getResourceIcon(for: selectedResource),
                color: getResourceColor(for: selectedResource)
            )
            resources.append(newResource)
            print("Idle collected 1 \(selectedResource.rawValue) - First collection!")
        }
        
        // Update idle collection counters
        locationIdleCollectionCounts[currentLocation.id, default: 0] += 1
        
        // Show visual feedback for idle collection
        lastIdleCollectedResource = selectedResource
        showIdleCollectionFeedback = true
        
        // Hide feedback after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showIdleCollectionFeedback = false
        }
    }
    
    func tapLocation() {
        // Active tapping mechanic - gives immediate resources based on drop table percentages
        let dropTable = getLocationDropTable()
        let selectedResource = selectResourceFromDropTable(dropTable)
        
        // Add 1 of the selected resource
        if let existingIndex = resources.firstIndex(where: { $0.type == selectedResource }) {
            // Resource already exists, increment amount
            resources[existingIndex].amount += 1
            print("Collected 1 \(selectedResource.rawValue) - Total: \(resources[existingIndex].amount)")
        } else {
            // Resource doesn't exist, create new entry
            let newResource = Resource(
                type: selectedResource,
                amount: 1,
                icon: getResourceIcon(for: selectedResource),
                color: getResourceColor(for: selectedResource)
            )
            resources.append(newResource)
            print("Collected 1 \(selectedResource.rawValue) - First collection!")
        }
        
        // Update tap counters
        currentLocationTapCount += 1
        locationTapCounts[currentLocation.id, default: 0] += 1
        
        // Show visual feedback
        lastCollectedResource = selectedResource
        showCollectionFeedback = true
        
        // Hide feedback after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showCollectionFeedback = false
        }
        
        print("Tap #\(currentLocationTapCount) - Collected: \(selectedResource.rawValue)")
    }
    
    private func selectResourceFromDropTable(_ dropTable: [(ResourceType, Double)]) -> ResourceType {
        // Generate random number between 0 and 100
        let randomValue = Double.random(in: 0...100)
        
        // Find which resource this random value corresponds to
        var cumulativePercentage: Double = 0
        
        for (resourceType, percentage) in dropTable {
            cumulativePercentage += percentage
            if randomValue <= cumulativePercentage {
                return resourceType
            }
        }
        
        // Fallback to first resource if something goes wrong
        return dropTable.first?.0 ?? .ironOre
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
        
        // Update current location tap count
        currentLocationTapCount = locationTapCounts[location.id, default: 0]
    }
    
    func resetCurrentLocationTapCount() {
        currentLocationTapCount = 0
        locationTapCounts[currentLocation.id] = 0
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
    
    // MARK: - Testing Functions
    
    func testDropTableDistribution(taps: Int = 1000) -> [ResourceType: Int] {
        // Test function to verify drop table percentages work correctly
        var results: [ResourceType: Int] = [:]
        let dropTable = getLocationDropTable()
        
        // Initialize counters
        for (resourceType, _) in dropTable {
            results[resourceType] = 0
        }
        
        // Simulate taps
        for _ in 0..<taps {
            let selectedResource = selectResourceFromDropTable(dropTable)
            results[selectedResource, default: 0] += 1
        }
        
        return results
    }
    
    func printDropTableTestResults(taps: Int = 1000) {
        let results = testDropTableDistribution(taps: taps)
        let dropTable = getLocationDropTable()
        
        print("Drop Table Test Results (\(taps) taps):")
        print("Expected vs Actual percentages:")
        
        for (resourceType, expectedPercentage) in dropTable {
            let actualCount = results[resourceType] ?? 0
            let actualPercentage = Double(actualCount) / Double(taps) * 100.0
            print("\(resourceType.rawValue): Expected \(expectedPercentage)%, Actual \(String(format: "%.1f", actualPercentage))% (\(actualCount)/\(taps))")
        }
    }
    
    deinit {
        gameTimer?.invalidate()
    }
    
    // MARK: - Helper Functions
    
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
