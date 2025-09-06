import Foundation
import SwiftUI

// MARK: - Resource Sort Option
enum ResourceSortOption: String, CaseIterable {
    case alphabetical = "A-Z"
    case reverseAlphabetical = "Z-A"
    case quantityAscending = "Quantity ↑"
    case quantityDescending = "Quantity ↓"
    case rarity = "Rarity"
}

// MARK: - Game State
class GameState: ObservableObject {
    @Published var currentLocation: Location
    @Published var resources: [Resource] = []
    @Published var constructionBays: [ConstructionBay] = []
    @Published var availableLocations: [Location] = []
    @Published var showConstructionMenu = false
    @Published var showConstructionPage = false
    @Published var showLocations = false
    @Published var showResourcesPage = false
    @Published var showCards = false
    @Published var showLocationResources = false
    @Published var showObjectives = false
    @Published var showTapCounter = false
    @Published var showIdleCollectionDetails = false
    @Published var showTapDetails = false
    @Published var showConstructionDetails = false
    @Published var showCardsDetails = false
    @Published var resourceSortOption: ResourceSortOption = .alphabetical
    @Published var selectedResourceForDetail: ResourceType?
    
    // Player data
    @Published var playerName: String = "Commander"
    @Published var playerLevel: Int = 0
    @Published var playerXP: Int = 0
    @Published var currency: Int = 0
    
    // XP requirements for each level (Fibonacci sequence)
    private let xpRequirements: [Int] = [
        1000, 2000, 3000, 5000, 8000, 13000, 21000, 34000, 55000, 89000,
        144000, 233000, 377000, 610000, 987000, 1597000, 2584000, 4181000, 6765000, 10946000,
        17711000, 28657000, 46368000, 75025000, 121393000, 196418000, 317811000, 514229000, 832040000, 1346269000,
        2178309000, 3524578000, 5702887000, 9227465000, 14930352000, 24157817000, 39088169000, 63245986000, 102334155000, 165580141000
    ]
    
    // Tap tracking
    @Published var currentLocationTapCount: Int = 0
    @Published var locationTapCounts: [String: Int] = [:]
    @Published var totalTapsCount: Int = 0
    @Published var totalXPGained: Int = 0
    
    // Idle collection tracking
    @Published var locationIdleCollectionCounts: [String: Int] = [:]
    @Published var totalIdleCollectionCount: Int = 0
    @Published var totalNuminsCollected: Int = 0
    
    // Construction tracking
    @Published var totalConstructionsCompleted: Int = 0
    @Published var smallConstructionsCompleted: Int = 0
    @Published var mediumConstructionsCompleted: Int = 0
    @Published var largeConstructionsCompleted: Int = 0
    
    // Visual feedback
    @Published var lastCollectedResource: ResourceType?
    @Published var showCollectionFeedback: Bool = false
    @Published var lastIdleCollectedResource: ResourceType?
    @Published var showIdleCollectionFeedback: Bool = false
    @Published var lastNuminsAmount: Int = 0
    @Published var showNuminsFeedback: Bool = false
    @Published var lastXPAmount: Int = 0
    @Published var showXPFeedback: Bool = false
    
    // Cards system
    @Published var ownedCards: [UserCard] = []
    
    // Navigation state
    @Published var currentPage: AppPage = .location
    @Published var showingLocationList: Bool = false
    
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
            availableResources: ["Iron Ore", "Silicon", "Water", "Oxygen", "Graphite", "Nitrogen", "Phosphorus", "Sulfur", "Calcium", "Magnesium"],
            unlockRequirements: []
        )
        
        // Initialize resources as empty - resources will be added when first collected
        self.resources = []
        
        // Initialize cards - add the 4 example cards for testing
        self.ownedCards = [
            UserCard(id: UUID().uuidString, cardId: "astro-prospector", copies: 1, tier: 1),
            UserCard(id: UUID().uuidString, cardId: "deep-scan", copies: 3, tier: 1),
            UserCard(id: UUID().uuidString, cardId: "bay-optimizer", copies: 1, tier: 1),
            UserCard(id: UUID().uuidString, cardId: "bulk-storage", copies: 2, tier: 1),
            UserCard(id: UUID().uuidString, cardId: "learned-hands", copies: 1, tier: 1)
        ]
        
        // Initialize all 11 available locations from TDD
        self.availableLocations = [
            // Taragon Gamma System (5 locations)
            currentLocation, // Taragam-7
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
                id: "taragam-3",
                name: "TaraGam 3",
                description: "Ice planet with rings",
                system: "Taragon Gamma",
                kind: .planet,
                availableResources: ["Water", "Oxygen", "Nitrogen", "Carbon", "Hydrogen", "Methane", "Ammonia", "Ice", "Crystals", "Minerals"],
                unlockRequirements: ["Water: 150", "Oxygen: 100"]
            ),
            Location(
                id: "abandoned-star-ship",
                name: "Abandoned Star Ship",
                description: "Derelict vessel floating in space",
                system: "Taragon Gamma",
                kind: .ship,
                availableResources: ["Scrap Metal", "Electronics", "Fuel Cells", "Data Cores", "Circuits", "Alloys", "Components", "Tech Parts", "Batteries", "Wiring"],
                unlockRequirements: ["Silicon: 200", "Titanium: 75"]
            ),
            Location(
                id: "taragon-gamma",
                name: "Taragon Gamma",
                description: "Class 3 star, main sequence, yellow",
                system: "Taragon Gamma",
                kind: .star,
                availableResources: ["Plasma", "Element", "Isotope", "Energy", "Radiation", "Heat", "Light", "Gravity", "Magnetic", "Solar"],
                unlockRequirements: ["Silicon: 300", "Helium-3: 100"]
            ),
            
            // Taragon Beta System (3 locations)
            Location(
                id: "ernests-homestead",
                name: "Ernest's Homestead",
                description: "Remote moon settlement",
                system: "Taragon Beta",
                kind: .moon,
                availableResources: ["Food", "Textiles", "Tools", "Medicine", "Seeds", "Livestock", "Grain", "Vegetables", "Herbs", "Supplies"],
                unlockRequirements: ["Iron Ore: 500", "Water: 300"]
            ),
            Location(
                id: "koraxon",
                name: "Koraxon",
                description: "Brown dwarf - supermassive planet",
                system: "Taragon Beta",
                kind: .dwarf,
                availableResources: ["Heavy Elements", "Dense Matter", "Compressed Gas", "Exotic Matter", "Gravitons", "Dark Energy", "Neutronium", "Quark Matter", "Strange Matter", "Antimatter"],
                unlockRequirements: ["Titanium: 200", "Energy: 150"]
            ),
            Location(
                id: "taragon-beta",
                name: "Taragon Beta",
                description: "Class 5 star, main sequence, deep red",
                system: "Taragon Beta",
                kind: .star,
                availableResources: ["Red Plasma", "Infrared Energy", "Stellar Wind", "Magnetic Fields", "Cosmic Rays", "Photons", "Particles", "Solar Flares", "Corona", "Chromosphere"],
                unlockRequirements: ["Plasma: 100", "Energy: 200"]
            ),
            
            // Violis Constellation (3 locations)
            Location(
                id: "violis-alpha",
                name: "Violis Alpha",
                description: "Dwarf star - class 2",
                system: "Violis",
                kind: .dwarf,
                availableResources: ["Stellar Dust", "Cosmic Debris", "Micro Particles", "Space Gas", "Ion Streams", "Electron Flow", "Proton Beams", "Neutron Flux", "Gamma Rays", "X-Rays"],
                unlockRequirements: ["Heavy Elements: 50", "Plasma: 150"]
            ),
            Location(
                id: "violis-outpost",
                name: "Violis Outpost",
                description: "Remote research station",
                system: "Violis",
                kind: .anomaly,
                availableResources: ["Research Data", "Lab Equipment", "Samples", "Experiments", "Prototypes", "Blueprints", "Formulas", "Algorithms", "Code", "Documentation"],
                unlockRequirements: ["Data Cores: 25", "Electronics: 100"]
            ),
            Location(
                id: "rogue-wanderer",
                name: "Rogue Wanderer",
                description: "Nomadic planet without a star",
                system: "Violis",
                kind: .rogue,
                availableResources: ["Frozen Gases", "Ice Crystals", "Preserved Matter", "Ancient Artifacts", "Relics", "Fossils", "Minerals", "Rare Elements", "Crystalline Structures", "Geological Samples"],
                unlockRequirements: ["Exotic Matter: 30", "Research Data: 50"]
            )
        ]
        
        // Initialize construction bays (start with 4 Small bays)
        self.constructionBays = [
            ConstructionBay(
                id: "small-bay-1",
                size: .small,
                currentConstruction: nil,
                isUnlocked: true
            ),
            ConstructionBay(
                id: "small-bay-2",
                size: .small,
                currentConstruction: nil,
                isUnlocked: false
            ),
            ConstructionBay(
                id: "small-bay-3",
                size: .small,
                currentConstruction: nil,
                isUnlocked: false
            ),
            ConstructionBay(
                id: "small-bay-4",
                size: .small,
                currentConstruction: nil,
                isUnlocked: false
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
                    // Construction completed - just mark as ready for collection
                    constructionBays[i].currentConstruction?.timeRemaining = 0
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
        totalIdleCollectionCount += 1
        
        // 2% chance for XP from idle collection
        if Double.random(in: 0...100) <= 2.0 {
            addXP(1)
        }
        
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
        totalTapsCount += 1
        
        // 10% chance for Numins bonus
        if Double.random(in: 0...100) <= 10.0 {
            let numinsAmount = Double.random(in: 1...100)
            
            // Add Numins to resources
            if let existingIndex = resources.firstIndex(where: { $0.type == .numins }) {
                resources[existingIndex].amount += numinsAmount
            } else {
                let newNumins = Resource(
                    type: .numins,
                    amount: numinsAmount,
                    icon: getResourceIcon(for: .numins),
                    color: getResourceColor(for: .numins)
                )
                resources.append(newNumins)
            }
            
            // Update currency display and tracking
            currency += Int(numinsAmount)
            totalNuminsCollected += Int(numinsAmount)
            
            // Show Numins feedback
            lastNuminsAmount = Int(numinsAmount)
            showNuminsFeedback = true
            
            // Hide Numins feedback after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.showNuminsFeedback = false
            }
            
            print("Bonus! Collected \(Int(numinsAmount)) Numins!")
        }
        
        // 1% chance for XP from tapping
        if Double.random(in: 0...100) <= 1.0 {
            addXP(1)
        }
        
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
        
        // Deduct resource cost
        for i in resources.indices {
            if let cost = recipe.cost[resources[i].type] {
                resources[i].amount -= cost
            }
        }
        
        // Deduct currency cost
        currency -= recipe.currencyCost
        
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
        // Check resource costs
        for resource in resources {
            if let cost = recipe.cost[resource.type] {
                if resource.amount < cost {
                    return false
                }
            }
        }
        
        // Check currency cost
        if currency < recipe.currencyCost {
            return false
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
        
        // Track construction statistics
        totalConstructionsCompleted += 1
        switch construction.recipe.requiredBaySize {
        case .small:
            smallConstructionsCompleted += 1
        case .medium:
            mediumConstructionsCompleted += 1
        case .large:
            largeConstructionsCompleted += 1
        }
        
        // Clear the bay
        constructionBays[index].currentConstruction = nil
        
        // Check for location unlocks
        checkLocationUnlocks()
    }
    
    func checkLocationUnlocks() {
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
        // Taragon Gamma System
        case "taragam-7":
            let resources: [ResourceType] = [.ironOre, .silicon, .water, .oxygen, .graphite, .nitrogen, .phosphorus, .sulfur, .calcium, .magnesium]
            return Array(zip(resources, percentages))
        case "elcinto":
            let resources: [ResourceType] = [.ironOre, .silicon, .helium3, .titanium, .aluminum, .nickel, .cobalt, .chromium, .vanadium, .manganese]
            return Array(zip(resources, percentages))
        case "taragam-3":
            let resources: [ResourceType] = [.water, .oxygen, .nitrogen, .graphite, .hydrogen, .methane, .ammonia, .ice, .crystals, .minerals]
            return Array(zip(resources, percentages))
        case "abandoned-star-ship":
            let resources: [ResourceType] = [.scrapMetal, .electronics, .fuelCells, .dataCores, .circuits, .alloys, .components, .techParts, .batteries, .wiring]
            return Array(zip(resources, percentages))
        case "taragon-gamma":
            let resources: [ResourceType] = [.plasma, .element, .isotope, .energy, .radiation, .heat, .light, .gravity, .magnetic, .solar]
            return Array(zip(resources, percentages))
            
        // Taragon Beta System
        case "ernests-homestead":
            let resources: [ResourceType] = [.food, .textiles, .tools, .medicine, .seeds, .livestock, .grain, .vegetables, .herbs, .supplies]
            return Array(zip(resources, percentages))
        case "koraxon":
            let resources: [ResourceType] = [.heavyElements, .denseMatter, .compressedGas, .exoticMatter, .gravitons, .darkEnergy, .neutronium, .quarkMatter, .strangeMatter, .antimatter]
            return Array(zip(resources, percentages))
        case "taragon-beta":
            let resources: [ResourceType] = [.redPlasma, .infraredEnergy, .stellarWind, .magneticFields, .cosmicRays, .photons, .particles, .solarFlares, .corona, .chromosphere]
            return Array(zip(resources, percentages))
            
        // Violis Constellation
        case "violis-alpha":
            let resources: [ResourceType] = [.stellarDust, .cosmicDebris, .microParticles, .spaceGas, .ionStreams, .electronFlow, .protonBeams, .neutronFlux, .gammaRays, .xRays]
            return Array(zip(resources, percentages))
        case "violis-outpost":
            let resources: [ResourceType] = [.researchData, .labEquipment, .samples, .experiments, .prototypes, .blueprints, .formulas, .algorithms, .code, .documentation]
            return Array(zip(resources, percentages))
        case "rogue-wanderer":
            let resources: [ResourceType] = [.frozenGases, .iceCrystals, .preservedMatter, .ancientArtifacts, .relics, .fossils, .minerals, .rareElements, .crystallineStructures, .geologicalSamples]
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
    
    // MARK: - XP Management
    
    func addXP(_ amount: Int) {
        playerXP += amount
        totalXPGained += amount
        
        // Check for level ups
        while canLevelUp() {
            levelUp()
        }
        
        // Show XP feedback
        lastXPAmount = amount
        showXPFeedback = true
        
        // Hide XP feedback after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showXPFeedback = false
        }
        
        print("Gained \(amount) XP! Total XP: \(playerXP), Level: \(playerLevel)")
    }
    
    private func canLevelUp() -> Bool {
        guard playerLevel < xpRequirements.count else { return false }
        return playerXP >= getXPRequiredForNextLevel()
    }
    
    private func levelUp() {
        guard canLevelUp() else { return }
        
        let xpRequired = getXPRequiredForNextLevel()
        playerXP -= xpRequired
        playerLevel += 1
        
        print("LEVEL UP! Now level \(playerLevel)")
        // TODO: Add level up rewards and effects
    }
    
    func getXPRequiredForNextLevel() -> Int {
        guard playerLevel < xpRequirements.count else { return Int.max }
        return xpRequirements[playerLevel]
    }
    
    func getXPProgressPercentage() -> Double {
        let required = getXPRequiredForNextLevel()
        guard required != Int.max else { return 1.0 }
        return min(Double(playerXP) / Double(required), 1.0)
    }
    
    // MARK: - Resource Detail Methods
    func getResourceLore(for resourceType: ResourceType) -> String {
        switch resourceType {
        case .ironOre:
            return "The backbone of civilization! This metallic ore has been forged into tools, weapons, and starships for millennia. Essential for any serious construction project."
        case .silicon:
            return "The digital heart of technology. Pure silicon crystals are the foundation of all advanced computing systems and energy storage devices."
        case .water:
            return "Life's most precious resource. In the vast emptiness of space, water becomes more valuable than gold. Essential for survival and advanced chemical processes."
        case .oxygen:
            return "The breath of life itself. Without oxygen, even the hardiest explorers would perish. Critical for life support systems and combustion processes."
        case .graphite:
            return "The crystalline form of carbon! This versatile material conducts electricity and is essential for advanced construction and energy systems."
        case .nitrogen:
            return "The silent supporter of life. While oxygen gets all the glory, nitrogen makes up most of our atmosphere and is crucial for plant growth."
        case .phosphorus:
            return "The spark of life! This element is essential for DNA, RNA, and energy storage in living cells. Without it, life as we know it would be impossible."
        case .sulfur:
            return "The stinky but essential element. Despite its distinctive odor, sulfur is crucial for many biological processes and industrial applications."
        case .calcium:
            return "The strength of bones and shells. This mineral builds the structural framework of many life forms and is essential for healthy development."
        case .magnesium:
            return "The green machine! This element is at the heart of chlorophyll, making photosynthesis possible and keeping plants alive."
        case .helium3:
            return "The fuel of the future! This rare isotope could power fusion reactors and enable interstellar travel. Highly sought after by advanced civilizations."
        case .titanium:
            return "The aerospace champion! Lightweight yet incredibly strong, titanium is the material of choice for high-performance aircraft and spacecraft."
        case .aluminum:
            return "The everyday miracle metal. Lightweight, corrosion-resistant, and abundant - aluminum revolutionized transportation and packaging."
        case .nickel:
            return "The magnetic marvel! This metal's magnetic properties make it essential for motors, generators, and advanced electronic devices."
        case .cobalt:
            return "The blue beauty! This rare metal gives glass its beautiful blue color and is essential for high-performance batteries and superalloys."
        case .chromium:
            return "The stainless steel superstar! This metal makes steel rust-resistant and gives it that beautiful shiny finish we all love."
        case .vanadium:
            return "The spring steel secret! This metal makes steel incredibly strong and flexible, perfect for springs and high-stress applications."
        case .manganese:
            return "The steel strengthener! This metal makes steel harder and more durable, essential for construction and manufacturing."
        case .plasma:
            return "The fourth state of matter! This superheated gas conducts electricity and could be the key to unlimited clean energy."
        case .element:
            return "The fundamental building block! This represents the pure essence of matter itself, the foundation upon which all chemistry is built."
        case .isotope:
            return "The atomic variant! These are atoms with the same element but different numbers of neutrons, each with unique properties and uses."
        case .energy:
            return "The power that drives everything! Pure energy in its most concentrated form, ready to be harnessed for any purpose."
        case .radiation:
            return "The invisible force! This energy can be dangerous but also incredibly useful for power generation and medical applications."
        case .heat:
            return "The warmth of the universe! Thermal energy that can be converted into mechanical work or used for industrial processes."
        case .light:
            return "The illumination of knowledge! Photons carrying information and energy across the vast distances of space."
        case .gravity:
            return "The invisible hand that shapes the cosmos! This fundamental force holds planets in orbit and shapes the structure of the universe."
        case .magnetic:
            return "The invisible field! Magnetic forces guide compasses, power motors, and protect planets from harmful solar radiation."
        case .solar:
            return "The power of the stars! Energy harvested directly from stellar fusion, clean and abundant throughout the galaxy."
        case .numins:
            return "The currency of the cosmos! These mysterious particles are the universal medium of exchange, accepted by traders across the galaxy."
        case .steelPylons:
            return "Essential construction components! These sturdy steel pylons form the backbone of any serious building project, providing structural support and stability for advanced constructions."
        default:
            return "A mysterious resource with unknown properties. Further study may reveal its true potential and value."
        }
    }
    
    func getResourceCollectionLocations(for resourceType: ResourceType) -> [String] {
        // This would ideally be data-driven, but for now we'll use some examples
        switch resourceType {
        case .ironOre:
            return ["Taragam-7", "Abandoned Star Ship", "Koraxon"]
        case .silicon:
            return ["Taragam-7", "Violis Outpost"]
        case .water:
            return ["Taragam-7", "Rogue Wanderer"]
        case .oxygen:
            return ["Taragam-7", "Taragon Beta"]
        case .numins:
            return ["All Locations (Rare Drop)"]
        default:
            return ["Various Locations"]
        }
    }
    
    // MARK: - Currency Formatting
    
    func getFormattedCurrency() -> String {
        return formatLargeNumber(currency)
    }
    
    func getFormattedNumins() -> String {
        return formatLargeNumber(totalNuminsCollected)
    }
    
    private func formatLargeNumber(_ number: Int) -> String {
        let absNumber = abs(number)
        
        // Up to 5 digits (99,999) - show full number
        if absNumber < 100000 {
            return "\(number)"
        }
        // Thousands (K)
        else if absNumber < 1000000 {
            let thousands = Double(number) / 1000.0
            if thousands >= 100 {
                return "\(Int(thousands.rounded(.up)))K"
            } else {
                return String(format: "%.1fK", thousands)
            }
        }
        // Millions (M)
        else if absNumber < 1000000000 {
            let millions = Double(number) / 1000000.0
            return String(format: "%.2fM", millions)
        }
        // Billions (B)
        else if absNumber < 1000000000000 {
            let billions = Double(number) / 1000000000.0
            return String(format: "%.2fB", billions)
        }
        // Trillions (T)
        else {
            let trillions = Double(number) / 1000000000000.0
            return String(format: "%.2fT", trillions)
        }
    }
    
    // MARK: - Helper Functions
    
    func getResourceIcon(for type: ResourceType) -> String {
        switch type {
        case .ironOre: return "cube.fill"
        case .silicon: return "diamond.fill"
        case .water: return "drop.fill"
        case .oxygen: return "wind"
        case .graphite: return "diamond.fill"
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
        
        // Constructable items
        case .steelPylons: return "building.2"
        }
    }
    
    func getResourceColor(for type: ResourceType) -> Color {
        switch type {
        case .ironOre: return .gray
        case .silicon: return .purple
        case .water: return .blue
        case .oxygen: return .cyan
        case .graphite: return .gray
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
        
        // Constructable items
        case .steelPylons: return .orange
        }
    }
    
    // MARK: - Card System Functions
    
    func getAllCardDefinitions() -> [CardDef] {
        return [
            // Explorer Class
            CardDef(
                id: "astro-prospector",
                name: "Astro Prospector",
                cardClass: .explorer,
                effectKey: "tapYieldMultiplier",
                tiers: [
                    CardTier(copies: 2, value: 0.02),   // +2%
                    CardTier(copies: 5, value: 0.04),   // +4%
                    CardTier(copies: 10, value: 0.07),  // +7%
                    CardTier(copies: 25, value: 0.11),  // +11%
                    CardTier(copies: 100, value: 0.16)  // +16%
                ],
                description: "Increases tap yield when slotted on Resources/Map screens"
            ),
            CardDef(
                id: "deep-scan",
                name: "Deep Scan",
                cardClass: .explorer,
                effectKey: "idleRareBias",
                tiers: [
                    CardTier(copies: 2, value: 0.03),   // +3%
                    CardTier(copies: 5, value: 0.06),   // +6%
                    CardTier(copies: 10, value: 0.10),  // +10%
                    CardTier(copies: 25, value: 0.15),  // +15%
                    CardTier(copies: 100, value: 0.22)  // +22%
                ],
                description: "Bias lower-probability slots upward for idle collection"
            ),
            
            // Constructor Class
            CardDef(
                id: "bay-optimizer",
                name: "Bay Optimizer",
                cardClass: .constructor,
                effectKey: "buildTimeMultiplier",
                tiers: [
                    CardTier(copies: 2, value: -0.02),  // -2%
                    CardTier(copies: 5, value: -0.04),  // -4%
                    CardTier(copies: 10, value: -0.07), // -7%
                    CardTier(copies: 25, value: -0.11), // -11%
                    CardTier(copies: 100, value: -0.16) // -16%
                ],
                description: "Faster builds on Construction screen"
            ),
            
            // Collector Class
            CardDef(
                id: "bulk-storage",
                name: "Bulk Storage",
                cardClass: .collector,
                effectKey: "storageCapBonus",
                tiers: [
                    CardTier(copies: 2, value: 100),    // +100
                    CardTier(copies: 5, value: 250),    // +250
                    CardTier(copies: 10, value: 500),   // +500
                    CardTier(copies: 25, value: 900),   // +900
                    CardTier(copies: 100, value: 1500)  // +1500
                ],
                description: "Increases per-resource storage caps"
            ),
            
            // Progression Class
            CardDef(
                id: "learned-hands",
                name: "Learned Hands",
                cardClass: .progression,
                effectKey: "xpGainMultiplier",
                tiers: [
                    CardTier(copies: 2, value: 0.02),   // +2%
                    CardTier(copies: 5, value: 0.04),   // +4%
                    CardTier(copies: 10, value: 0.06),  // +6%
                    CardTier(copies: 25, value: 0.09),  // +9%
                    CardTier(copies: 100, value: 0.13)  // +13%
                ],
                description: "Global XP boost when slotted on any screen"
            )
        ]
    }
    
    func getCardsForClass(_ cardClass: CardClass) -> [CardDef] {
        return getAllCardDefinitions().filter { $0.cardClass == cardClass }
    }
    
    func getUserCard(for cardId: String) -> UserCard? {
        return ownedCards.first { $0.cardId == cardId }
    }
    
    func addCard(_ cardId: String, copies: Int = 1) {
        if let existingIndex = ownedCards.firstIndex(where: { $0.cardId == cardId }) {
            ownedCards[existingIndex].copies += copies
            // Auto-upgrade if we have enough copies for next tier
            checkAndUpgradeCard(at: existingIndex)
        } else {
            let newCard = UserCard(
                id: UUID().uuidString,
                cardId: cardId,
                copies: copies,
                tier: 1
            )
            ownedCards.append(newCard)
        }
    }
    
    private func checkAndUpgradeCard(at index: Int) {
        let userCard = ownedCards[index]
        guard let cardDef = getAllCardDefinitions().first(where: { $0.id == userCard.cardId }) else { return }
        
        // Check if we can upgrade to next tier
        if userCard.tier < 5 {
            let nextTier = userCard.tier
            let requiredCopies = cardDef.tiers[nextTier].copies
            
            if userCard.copies >= requiredCopies {
                ownedCards[index].copies -= requiredCopies
                ownedCards[index].tier += 1
                print("Card \(cardDef.name) upgraded to tier \(ownedCards[index].tier)!")
            }
        }
    }
    
    // MARK: - Card Statistics Functions
    
    func getTotalCardsCollected() -> Int {
        return ownedCards.reduce(0) { $0 + $1.copies }
    }
    
    func getCardsCollectedForClass(_ cardClass: CardClass) -> Int {
        return ownedCards
            .filter { userCard in
                getAllCardDefinitions().first { $0.id == userCard.cardId }?.cardClass == cardClass
            }
            .reduce(0) { $0 + $1.copies }
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

// MARK: - App Navigation

enum AppPage: String, CaseIterable {
    case location = "Location"
    case construction = "Construction"
    case starMap = "Star Map"
    case resources = "Resources"
    case cards = "Cards"
    case shop = "Shop"
}

// MARK: - Card System

enum CardClass: String, CaseIterable {
    case explorer = "Explorer"
    case constructor = "Constructor"
    case collector = "Collector"
    case progression = "Progression"
}

struct CardDef: Identifiable {
    let id: String
    let name: String
    let cardClass: CardClass
    let effectKey: String
    let tiers: [CardTier]
    let description: String
}

struct CardTier {
    let copies: Int
    let value: Double
}

struct UserCard: Identifiable {
    let id: String
    let cardId: String
    var copies: Int
    var tier: Int // 1-5
    var slottedOn: [String] = [] // Screen IDs where this card is slotted
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
    case graphite = "Graphite"
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
    case numins = "Numins"
    
    // TaraGam 3 resources
    case hydrogen = "Hydrogen"
    case methane = "Methane"
    case ammonia = "Ammonia"
    case ice = "Ice"
    case crystals = "Crystals"
    case minerals = "Minerals"
    
    // Abandoned Star Ship resources
    case scrapMetal = "Scrap Metal"
    case electronics = "Electronics"
    case fuelCells = "Fuel Cells"
    case dataCores = "Data Cores"
    case circuits = "Circuits"
    case alloys = "Alloys"
    case components = "Components"
    case techParts = "Tech Parts"
    case batteries = "Batteries"
    case wiring = "Wiring"
    
    // Ernest's Homestead resources
    case food = "Food"
    case textiles = "Textiles"
    case tools = "Tools"
    case medicine = "Medicine"
    case seeds = "Seeds"
    case livestock = "Livestock"
    case grain = "Grain"
    case vegetables = "Vegetables"
    case herbs = "Herbs"
    case supplies = "Supplies"
    
    // Koraxon resources
    case heavyElements = "Heavy Elements"
    case denseMatter = "Dense Matter"
    case compressedGas = "Compressed Gas"
    case exoticMatter = "Exotic Matter"
    case gravitons = "Gravitons"
    case darkEnergy = "Dark Energy"
    case neutronium = "Neutronium"
    case quarkMatter = "Quark Matter"
    case strangeMatter = "Strange Matter"
    case antimatter = "Antimatter"
    
    // Taragon Beta resources
    case redPlasma = "Red Plasma"
    case infraredEnergy = "Infrared Energy"
    case stellarWind = "Stellar Wind"
    case magneticFields = "Magnetic Fields"
    case cosmicRays = "Cosmic Rays"
    case photons = "Photons"
    case particles = "Particles"
    case solarFlares = "Solar Flares"
    case corona = "Corona"
    case chromosphere = "Chromosphere"
    
    // Violis Alpha resources
    case stellarDust = "Stellar Dust"
    case cosmicDebris = "Cosmic Debris"
    case microParticles = "Micro Particles"
    case spaceGas = "Space Gas"
    case ionStreams = "Ion Streams"
    case electronFlow = "Electron Flow"
    case protonBeams = "Proton Beams"
    case neutronFlux = "Neutron Flux"
    case gammaRays = "Gamma Rays"
    case xRays = "X-Rays"
    
    // Violis Outpost resources
    case researchData = "Research Data"
    case labEquipment = "Lab Equipment"
    case samples = "Samples"
    case experiments = "Experiments"
    case prototypes = "Prototypes"
    case blueprints = "Blueprints"
    case formulas = "Formulas"
    case algorithms = "Algorithms"
    case code = "Code"
    case documentation = "Documentation"
    
    // Rogue Wanderer resources
    case frozenGases = "Frozen Gases"
    case iceCrystals = "Ice Crystals"
    case preservedMatter = "Preserved Matter"
    case ancientArtifacts = "Ancient Artifacts"
    case relics = "Relics"
    case fossils = "Fossils"
    case rareElements = "Rare Elements"
    case crystallineStructures = "Crystalline Structures"
    case geologicalSamples = "Geological Samples"
    
    // Constructable items
    case steelPylons = "Steel Pylons"
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
    let currencyCost: Int
    let reward: [ResourceType: Double]
    let requiredBaySize: BaySize
    let xpReward: Int
}

// Sample recipes for MVP
extension ConstructionRecipe {
    static let steelPylons = ConstructionRecipe(
        id: "steel-pylons",
        name: "Steel Pylons",
        description: "Essential for building almost anything!",
        duration: 30.0,
        cost: [.ironOre: 50, .graphite: 1],
        currencyCost: 25,
        reward: [.steelPylons: 1], // Give 1 Steel Pylons when complete
        requiredBaySize: .small,
        xpReward: 2
    )
    
    static let allRecipes: [ConstructionRecipe] = [
        .steelPylons
    ]
}
