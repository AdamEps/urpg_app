import Foundation
import SwiftUI

// MARK: - Game State
class GameState: ObservableObject {
    @Published var currentLocation: Location
    @Published var resources: [Resource] = []
    @Published var activeConstructions: [Construction] = []
    @Published var availableLocations: [Location] = []
    @Published var showConstructionMenu = false
    @Published var showLocations = false
    @Published var showShop = false
    @Published var showCards = false
    
    private var gameTimer: Timer?
    
    init() {
        // Initialize with starting location
        self.currentLocation = Location(
            id: "earth",
            name: "Earth",
            description: "Your home planet",
            availableResources: ["Energy", "Metal", "Crystal"],
            unlockRequirements: []
        )
        
        // Initialize resources
        self.resources = [
            Resource(type: .energy, amount: 100, icon: "bolt.fill", color: .yellow),
            Resource(type: .metal, amount: 50, icon: "cube.fill", color: .gray),
            Resource(type: .crystal, amount: 25, icon: "diamond.fill", color: .purple),
            Resource(type: .fuel, amount: 10, icon: "fuelpump.fill", color: .orange)
        ]
        
        // Initialize available locations
        self.availableLocations = [
            currentLocation,
            Location(
                id: "moon",
                name: "Moon",
                description: "Earth's natural satellite",
                availableResources: ["Energy", "Metal", "Helium"],
                unlockRequirements: ["Energy: 200"]
            ),
            Location(
                id: "mars",
                name: "Mars",
                description: "The red planet",
                availableResources: ["Metal", "Crystal", "Water"],
                unlockRequirements: ["Energy: 500", "Fuel: 50"]
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
        // Update constructions
        for i in activeConstructions.indices {
            activeConstructions[i].timeRemaining -= 1.0
            
            // Update progress
            let totalDuration = activeConstructions[i].type.duration
            let elapsed = totalDuration - activeConstructions[i].timeRemaining
            activeConstructions[i].progress = min(elapsed / totalDuration, 1.0)
            
            if activeConstructions[i].timeRemaining <= 0 {
                // Construction completed
                completeConstruction(at: i)
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
        // Different resources have different idle collection rates
        switch type {
        case .energy:
            return 0.1
        case .metal:
            return 0.05
        case .crystal:
            return 0.02
        case .fuel:
            return 0.01
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
        // Tap rewards based on current location
        switch currentLocation.id {
        case "earth":
            return [.energy: 5, .metal: 2, .crystal: 1]
        case "moon":
            return [.energy: 8, .metal: 3, .crystal: 1]
        case "mars":
            return [.energy: 10, .metal: 5, .crystal: 3]
        default:
            return [.energy: 3, .metal: 1, .crystal: 0.5]
        }
    }
    
    func startConstruction(type: ConstructionType) {
        guard canAffordConstruction(type: type) else { return }
        
        // Deduct cost
        for i in resources.indices {
            if let cost = type.cost[resources[i].type] {
                resources[i].amount -= cost
            }
        }
        
        // Create construction
        let construction = Construction(
            id: UUID().uuidString,
            name: type.name,
            type: type,
            timeRemaining: type.duration,
            progress: 0.0
        )
        
        activeConstructions.append(construction)
    }
    
    func canAffordConstruction(type: ConstructionType) -> Bool {
        for resource in resources {
            if let cost = type.cost[resource.type] {
                if resource.amount < cost {
                    return false
                }
            }
        }
        return true
    }
    
    private func completeConstruction(at index: Int) {
        let construction = activeConstructions[index]
        
        // Give rewards based on construction type
        for i in resources.indices {
            if let reward = construction.type.reward[resources[i].type] {
                resources[i].amount += reward
            }
        }
        
        // Remove completed construction
        activeConstructions.remove(at: index)
        
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
    
    deinit {
        gameTimer?.invalidate()
    }
}

// MARK: - Data Models

struct Location: Identifiable {
    let id: String
    let name: String
    let description: String
    let availableResources: [String]
    let unlockRequirements: [String]
}

struct Resource {
    let type: ResourceType
    var amount: Double
    let icon: String
    let color: Color
}

enum ResourceType: String, CaseIterable {
    case energy = "Energy"
    case metal = "Metal"
    case crystal = "Crystal"
    case fuel = "Fuel"
}

struct Construction: Identifiable {
    let id: String
    let name: String
    let type: ConstructionType
    var timeRemaining: Double
    var progress: Double
}

enum ConstructionType: CaseIterable {
    case solarPanel
    case miningDrill
    case researchLab
    case fuelRefinery
    
    var name: String {
        switch self {
        case .solarPanel:
            return "Solar Panel"
        case .miningDrill:
            return "Mining Drill"
        case .researchLab:
            return "Research Lab"
        case .fuelRefinery:
            return "Fuel Refinery"
        }
    }
    
    var duration: Double {
        switch self {
        case .solarPanel:
            return 30.0
        case .miningDrill:
            return 60.0
        case .researchLab:
            return 120.0
        case .fuelRefinery:
            return 90.0
        }
    }
    
    var cost: [ResourceType: Double] {
        switch self {
        case .solarPanel:
            return [.energy: 50, .metal: 25]
        case .miningDrill:
            return [.energy: 100, .metal: 50, .crystal: 10]
        case .researchLab:
            return [.energy: 200, .metal: 100, .crystal: 25]
        case .fuelRefinery:
            return [.energy: 150, .metal: 75, .crystal: 15]
        }
    }
    
    var reward: [ResourceType: Double] {
        switch self {
        case .solarPanel:
            return [.energy: 100]
        case .miningDrill:
            return [.metal: 50, .crystal: 10]
        case .researchLab:
            return [.crystal: 25, .energy: 50]
        case .fuelRefinery:
            return [.fuel: 30, .energy: 25]
        }
    }
}
