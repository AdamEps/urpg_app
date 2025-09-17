import Foundation
import SwiftUI

// MARK: - Resource Sort Option
enum ResourceSortOption: String, CaseIterable {
    case alphabetical = "Alphabetical"
    case quantity = "Quantity"
    case rarity = "Rarity"
    
    var displayName: String {
        switch self {
        case .alphabetical:
            return "Alphabetical"
        case .quantity:
            return "Quantity"
        case .rarity:
            return "Rarity"
        }
    }
}

// MARK: - Resource Rarity
enum ResourceRarity: String, CaseIterable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .common: return "circle.fill"
        case .uncommon: return "diamond.fill"
        case .rare: return "star.fill"
        }
    }
}

// MARK: - Star Map Hierarchy Models
struct Constellation: Identifiable {
    let id: String
    let name: String
    let starSystems: [StarSystem]
}

struct StarSystem: Identifiable {
    let id: String
    let name: String
    let starType: StarType
    let locations: [Location]
    let orbitalRadius: Double // For visual positioning
}

enum StarType: String, CaseIterable {
    case mainSequence = "Main Sequence"
    case redGiant = "Red Giant"
    case whiteDwarf = "White Dwarf"
    case neutron = "Neutron Star"
    case blackHole = "Black Hole"
    
    var symbol: String {
        switch self {
        case .mainSequence: return "sun.max.fill"
        case .redGiant: return "sun.max"
        case .whiteDwarf: return "circle.fill"
        case .neutron: return "circle.dotted"
        case .blackHole: return "circle.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .mainSequence: return .yellow
        case .redGiant: return .red
        case .whiteDwarf: return .white
        case .neutron: return .blue
        case .blackHole: return .black
        }
    }
}

// MARK: - Star Map View State
enum StarMapZoomLevel {
    case constellation
    case solarSystem(StarSystem)
}

// MARK: - Game State
class GameState: ObservableObject {
    @Published var currentLocation: Location
    @Published var resources: [Resource] = []
    @Published var constructionBays: [ConstructionBay] = []
    @Published var availableLocations: [Location] = []
    @Published var showConstructionPage = false
    @Published var showConstructionMenu = false
    @Published var showLocations = false
    @Published var selectedBaySizeForBlueprints: BaySize = .small
    @Published var showResourcesPage = false
    @Published var showCards = false
    @Published var showLocationResources = false
    @Published var showObjectives = false
    @Published var showTapCounter = false
    @Published var showIdleCollectionDetails = false
    @Published var showTapDetails = false
    @Published var showConstructionDetails = false
    @Published var showCardsDetails = false
    @Published var showLocationSlots = false
    @Published var showResourcesSlots = false
    @Published var showShopSlots = false
    @Published var showCardsSlots = false
    @Published var showConstructionSlots = false
    @Published var showStarMapSlots = false
    
    // Enhancement slot selection state
    @Published var selectedSlotIndex: Int? = nil
    @Published var selectedSlotType: String = "Cards" // "Cards" or "Items"
    
    // Equipped cards state - each page has 4 slots, each slot can hold a card ID
    @Published var equippedLocationCards: [String?] = [nil, nil, nil, nil] // 4 slots for location page
    @Published var equippedShopCards: [String?] = [nil, nil, nil, nil] // 4 slots for shop page
    @Published var equippedCardsCards: [String?] = [nil, nil, nil, nil] // 4 slots for cards page
    @Published var equippedResourcesCards: [String?] = [nil, nil, nil, nil] // 4 slots for resources page
    @Published var equippedConstructionCards: [String?] = [nil, nil, nil, nil] // 4 slots for construction page
    @Published var selectedLocationForPopup: Location?
    @Published var resourceSortOption: ResourceSortOption = .alphabetical
    @Published var resourceSortAscending: Bool = true
    @Published var selectedResourceForDetail: ResourceType?
    @Published var selectedCardForDetail: String?
    @Published var maxStorageCapacity: Int = 1000
    
    // MARK: - Reset functionality
    func resetToDefaults() {
        let fresh = GameState()
        self.playerName = fresh.playerName
        self.playerLevel = fresh.playerLevel
        self.playerXP = fresh.playerXP
        self.currency = fresh.currency
        self.currentLocation = fresh.currentLocation
        self.resources = fresh.resources
        self.constructionBays = fresh.constructionBays
        self.availableLocations = fresh.availableLocations
        self.ownedCards = fresh.ownedCards
        self.currentPage = fresh.currentPage
        self.previousPage = fresh.previousPage
        self.showingLocationList = fresh.showingLocationList
        self.starMapViaTelescope = fresh.starMapViaTelescope
        self.currentLocationTapCount = fresh.currentLocationTapCount
        self.locationTapCounts = fresh.locationTapCounts
        self.totalTapsCount = fresh.totalTapsCount
        self.totalXPGained = fresh.totalXPGained
        self.locationIdleCollectionCounts = fresh.locationIdleCollectionCounts
        self.totalIdleCollectionCount = fresh.totalIdleCollectionCount
        self.totalNuminsCollected = fresh.totalNuminsCollected
        self.totalConstructionsCompleted = fresh.totalConstructionsCompleted
        self.smallConstructionsCompleted = fresh.smallConstructionsCompleted
        self.mediumConstructionsCompleted = fresh.mediumConstructionsCompleted
        self.largeConstructionsCompleted = fresh.largeConstructionsCompleted
        self.maxStorageCapacity = fresh.maxStorageCapacity
        self.showLocationResources = fresh.showLocationResources
        self.selectedLocationForPopup = fresh.selectedLocationForPopup
        print("🔄 Game state reset to defaults")
    }
    
    // Reference to GameStateManager for auto-save (deprecated)
    weak var gameStateManager: GameStateManager?
    
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
    @Published var lastCollectedAmount: Int = 1
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
    @Published var previousPage: AppPage = .location
    @Published var showingLocationList: Bool = false
    @Published var starMapViaTelescope: Bool = false
    
    // Star Map hierarchy state
    @Published var starMapZoomLevel: StarMapZoomLevel = .constellation
    @Published var constellations: [Constellation] = []
    @Published var currentStarSystem: StarSystem?
    
    // Idle collection tracking - now uses dynamic chance-based system
    
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
        
        // Initialize cards - start with no cards
        self.ownedCards = []
        
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
                name: "Taragam-3",
                description: "Ice planet with rings",
                system: "Taragon Gamma",
                kind: .planet,
                availableResources: ["Water", "Oxygen", "Nitrogen", "Carbon", "Hydrogen", "Methane", "Ammonia", "Ice", "Crystals", "Minerals"],
                unlockRequirements: ["Water: 150", "Oxygen: 100"]
            ),
            Location(
                id: "abandoned-star-ship",
                name: "Abandoned Starship",
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
        
        // Initialize star map hierarchy after locations are populated
        self.constellations = initializeStarMapHierarchy()
        
        // Initialize construction bays (start with 4 Small bays, 2 Medium bays, 1 Large bay)
        self.constructionBays = [
            // Small bays
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
            ),
            // Medium bays
            ConstructionBay(
                id: "medium-bay-1",
                size: .medium,
                currentConstruction: nil,
                isUnlocked: false
            ),
            ConstructionBay(
                id: "medium-bay-2",
                size: .medium,
                currentConstruction: nil,
                isUnlocked: false
            ),
            ConstructionBay(
                id: "medium-bay-3",
                size: .medium,
                currentConstruction: nil,
                isUnlocked: false
            ),
            // Large bays
            ConstructionBay(
                id: "large-bay-1",
                size: .large,
                currentConstruction: nil,
                isUnlocked: false
            ),
            ConstructionBay(
                id: "large-bay-2",
                size: .large,
                currentConstruction: nil,
                isUnlocked: false
            )
        ]
    }
    
    func startGame() {
        // Only start the timer if it's not already running
        guard gameTimer == nil else { return }
        
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
                let totalDuration = construction.blueprint.duration
                let elapsed = totalDuration - construction.timeRemaining
                constructionBays[i].currentConstruction?.progress = min(elapsed / totalDuration, 1.0)
                
                if construction.timeRemaining <= 0 {
                    // Construction completed - just mark as ready for collection
                    constructionBays[i].currentConstruction?.timeRemaining = 0
                }
            }
        }
        
        // Idle resource collection - dynamic chance every second
        if Double.random(in: 0...100) <= getCurrentIdleResourceChance() {
            performIdleResourceCollection()
        }
        
        // Idle Numins collection - dynamic chance every second (independent of resources)
        if Double.random(in: 0...100) <= getCurrentIdleNuminsChance() {
            performIdleNuminsCollection()
        }
    }
    
    private func performIdleResourceCollection() {
        // Idle resource collection: 10% chance every second based on current location's drop table
        let dropTable = getIdleDropTable()
        let selectedResource = selectResourceFromDropTable(dropTable)
        
        // Get card multiplier for idle yield (NOT affected by tap yield cards)
        let idleMultiplier = getIdleYieldMultiplier()
        let resourceAmount = calculateResourceYield(baseAmount: 1, multiplier: idleMultiplier)
        
        // Check if we can add this resource (storage limit check)
        guard canAddResource(selectedResource, amount: resourceAmount) else {
            print("Storage full! Cannot idle collect \(resourceAmount) \(selectedResource.rawValue)")
            return
        }
        
        // Add resources based on card multiplier (same logic as tapLocation)
        if let existingIndex = resources.firstIndex(where: { $0.type == selectedResource }) {
            // Resource already exists, increment amount
            resources[existingIndex].amount += Double(resourceAmount)
            print("Idle collected \(resourceAmount) \(selectedResource.rawValue) (x\(String(format: "%.1f", idleMultiplier))) - Total: \(resources[existingIndex].amount)")
        } else {
            // Resource doesn't exist, create new entry
            let newResource = Resource(
                type: selectedResource,
                amount: Double(resourceAmount),
                icon: getResourceIcon(for: selectedResource),
                color: getResourceColor(for: selectedResource)
            )
            resources.append(newResource)
            print("Idle collected \(resourceAmount) \(selectedResource.rawValue) (x\(String(format: "%.1f", idleMultiplier))) - First collection!")
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
    
    private func performIdleNuminsCollection() {
        // Idle Numins collection: dynamic chance every second with dynamic range
        let numinsRange = getCurrentIdleNuminsRange()
        let numinsAmount = Double.random(in: Double(numinsRange.min)...Double(numinsRange.max))
        
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
        
        print("Idle collected \(Int(numinsAmount)) Numins!")
    }
    
    func tapLocation() {
        // Active tapping mechanic - gives immediate resources based on drop table percentages
        let dropTable = getModifiedDropTable()
        let selectedResource = selectResourceFromDropTable(dropTable)
        
        // Get card multiplier for tap yield
        let tapMultiplier = getTapYieldMultiplier()
        let resourceAmount = calculateResourceYield(baseAmount: 1, multiplier: tapMultiplier)
        
        // Check if we can add this resource (storage limit check)
        guard canAddResource(selectedResource, amount: resourceAmount) else {
            print("Storage full! Cannot collect \(resourceAmount) \(selectedResource.rawValue)")
            return
        }
        
        // Add resources based on card multiplier
        if let existingIndex = resources.firstIndex(where: { $0.type == selectedResource }) {
            // Resource already exists, increment amount
            resources[existingIndex].amount += Double(resourceAmount)
            print("Collected \(resourceAmount) \(selectedResource.rawValue) (x\(String(format: "%.1f", tapMultiplier))) - Total: \(resources[existingIndex].amount)")
        } else {
            // Resource doesn't exist, create new entry
            let newResource = Resource(
                type: selectedResource,
                amount: Double(resourceAmount),
                icon: getResourceIcon(for: selectedResource),
                color: getResourceColor(for: selectedResource)
            )
            resources.append(newResource)
            print("Collected \(resourceAmount) \(selectedResource.rawValue) (x\(String(format: "%.1f", tapMultiplier))) - First collection!")
        }
        
        // Update tap counters
        currentLocationTapCount += 1
        locationTapCounts[currentLocation.id, default: 0] += 1
        totalTapsCount += 1
        
        // Dynamic chance for Numins bonus
        if Double.random(in: 0...100) <= getCurrentTapNuminsChance() {
            let numinsRange = getCurrentTapNuminsRange()
            let numinsAmount = Double.random(in: Double(numinsRange.min)...Double(numinsRange.max))
            
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
        
        // Dynamic chance for XP from tapping (with XP multiplier)
        if Double.random(in: 0...100) <= getCurrentTapXPChance() {
            let xpMultiplier = getXPGainMultiplier()
            let xpAmount = Int(Double(getCurrentTapXPAmount()) * xpMultiplier)
            addXP(xpAmount)
        }
        
        // Dynamic chance for card collection (only in Taragam-7 for now)
        if currentLocation.id == "taragam-7" && Double.random(in: 0...100) <= getCurrentTapCardChance() {
            collectRandomCard()
        }
        
        // Show visual feedback
        lastCollectedResource = selectedResource
        lastCollectedAmount = resourceAmount
        showCollectionFeedback = true
        
        // Hide feedback after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showCollectionFeedback = false
        }
        
        // Trigger auto-save
        gameStateManager?.triggerAutoSave()
        
        print("Tap #\(currentLocationTapCount) - Collected: \(selectedResource.rawValue)")
    }
    
    private func collectRandomCard() {
        // Get available cards for current location
        let availableCards = getLocationAvailableCards()
        guard !availableCards.isEmpty else { return }
        
        // Select a random card from available cards
        let randomIndex = Int.random(in: 0..<availableCards.count)
        let selectedCardId = availableCards[randomIndex]
        
        // Add the card to owned cards (or upgrade if already owned)
        if let existingCardIndex = ownedCards.firstIndex(where: { $0.cardId == selectedCardId }) {
            // Upgrade existing card
            ownedCards[existingCardIndex].tier += 1
            print("Upgraded \(selectedCardId) to tier \(ownedCards[existingCardIndex].tier)")
        } else {
            // Add new card at tier 1
            let newCard = UserCard(
                id: UUID().uuidString,
                cardId: selectedCardId,
                copies: 1,
                tier: 1
            )
            ownedCards.append(newCard)
            print("Collected new card: \(selectedCardId)")
        }
    }
    
    private func getLocationAvailableCards() -> [String] {
        // Define which cards are available in each location
        switch currentLocation.id {
        case "taragam-7":
            return ["astro-prospector", "deep-scan", "materials-engineer", "storage-bay"]
        // Add more locations as cards are implemented
        default:
            return []
        }
    }
    
    // MARK: - Dynamic Chance Calculations
    
    func getCurrentTapNuminsChance() -> Double {
        // Base chance is 10%, can be modified by cards/constructed items
        let baseChance = 10.0
        
        // TODO: Apply card/constructed item modifications here
        // Example: if hasCard("lucky-numins") { baseChance += 5.0 }
        
        return baseChance
    }
    
    func getCurrentTapNuminsRange() -> (min: Int, max: Int) {
        // Base range is 1-100, can be modified by cards/constructed items
        let minAmount = 1
        let maxAmount = 100
        
        // TODO: Apply card/constructed item modifications here
        // Example: if hasCard("numins-boost") { maxAmount += 50 }
        
        return (min: minAmount, max: maxAmount)
    }
    
    func getCurrentTapXPChance() -> Double {
        // Base chance is 1%, can be modified by cards/constructed items
        let baseChance = 1.0
        
        // TODO: Apply card/constructed item modifications here
        
        return baseChance
    }
    
    func getCurrentTapXPAmount() -> Int {
        // Base amount is 1, can be modified by cards/constructed items
        let amount = 1
        
        // TODO: Apply card/constructed item modifications here
        
        return amount
    }
    
    func getCurrentTapCardChance() -> Double {
        // Base chance is 0.1%, can be modified by cards/constructed items
        let baseChance = 0.1
        
        // TODO: Apply card/constructed item modifications here
        
        return baseChance
    }
    
    func getCurrentIdleResourceChance() -> Double {
        // Base chance is 10%, can be modified by cards/constructed items
        let baseChance = 10.0
        
        // TODO: Apply card/constructed item modifications here
        
        return baseChance
    }
    
    func getCurrentIdleNuminsChance() -> Double {
        // Base chance is 10%, can be modified by cards/constructed items
        let baseChance = 10.0
        
        // TODO: Apply card/constructed item modifications here
        
        return baseChance
    }
    
    func getCurrentIdleNuminsRange() -> (min: Int, max: Int) {
        // Base range is 1-50, can be modified by cards/constructed items
        let minAmount = 1
        let maxAmount = 50
        
        // TODO: Apply card/constructed item modifications here
        
        return (min: minAmount, max: maxAmount)
    }
    
    func getLocationCardAbbreviations() -> [String] {
        // Return abbreviated names for cards available in current location
        let availableCards = getLocationAvailableCards()
        let abbreviations: [String: String] = [
            "astro-prospector": "AP",
            "deep-scan": "DS", 
            "materials-engineer": "ME",
            "storage-bay": "SB"
        ]
        
        return availableCards.compactMap { abbreviations[$0] }
    }
    
    func selectResourceFromDropTable(_ dropTable: [(ResourceType, Double)]) -> ResourceType {
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
    
    func startConstruction(blueprint: ConstructionBlueprint) {
        guard canAffordConstruction(blueprint: blueprint) else { return }
        
        // Find an empty bay of the right size
        guard let bayIndex = constructionBays.firstIndex(where: { 
            $0.currentConstruction == nil && 
            $0.isUnlocked && 
            $0.size == blueprint.requiredBaySize 
        }) else { return }
        
        // Deduct resource cost
        for i in resources.indices {
            if let cost = blueprint.cost[resources[i].type] {
                resources[i].amount -= cost
            }
        }
        
        // Deduct currency cost
        currency -= blueprint.currencyCost
        
        // Create construction
        let construction = Construction(
            id: UUID().uuidString,
            blueprint: blueprint,
            timeRemaining: blueprint.duration,
            progress: 0.0
        )
        
        constructionBays[bayIndex].currentConstruction = construction
        
        // Navigate to construction page to show the new construction
        currentPage = .construction
        
        // Trigger auto-save
        gameStateManager?.triggerAutoSave()
    }
    
    func toggleStatisticsPage() {
        if currentPage == .statistics {
            // If we're on statistics page, go back to previous page
            currentPage = previousPage
        } else {
            // If we're on any other page, remember current page and go to statistics
            previousPage = currentPage
            currentPage = .statistics
        }
    }
    
    func canAffordConstruction(blueprint: ConstructionBlueprint) -> Bool {
        // If dev tool is enabled, always allow construction
        if devToolBuildableWithoutIngredients {
            return true
        }
        
        // Check ALL required resource costs
        for (requiredResourceType, requiredAmount) in blueprint.cost {
            // Find the player's current amount of this resource
            let playerAmount = resources.first(where: { $0.type == requiredResourceType })?.amount ?? 0
            
            // Check if player has enough
            if playerAmount < requiredAmount {
                return false
            }
        }
        
        // Check currency cost
        if currency < blueprint.currencyCost {
            return false
        }
        
        return true
    }
    
    private func completeConstruction(at index: Int) {
        guard let construction = constructionBays[index].currentConstruction else { return }
        
        // Give rewards based on construction recipe
        for i in resources.indices {
            if let reward = construction.blueprint.reward[resources[i].type] {
                resources[i].amount += reward
            }
        }
        
        // Track construction statistics
        totalConstructionsCompleted += 1
        switch construction.blueprint.requiredBaySize {
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
        
        // Trigger auto-save
        gameStateManager?.triggerAutoSave()
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
            let resources: [ResourceType] = [.ironOre, .silicon, .water, .oxygen, .graphite, .nitrogen, .copper, .sulfur, .calcium, .gold]
            return Array(zip(resources, percentages))
        case "elcinto":
            let resources: [ResourceType] = [.ironOre, .silicon, .helium3, .titanium, .aluminum, .nickel, .cobalt, .rareElements, .vanadium, .manganese]
            return Array(zip(resources, percentages))
        case "taragam-3":
            let resources: [ResourceType] = [.water, .oxygen, .nitrogen, .graphite, .hydrogen, .methane, .ammonia, .lithium, .crystals, .minerals]
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
        case .gears:
            return "Precision mechanical components! These interlocking gears transfer power and motion in complex machinery, essential for any advanced mechanical system."
        case .laser:
            return "Cutting-edge precision technology! This focused light beam can cut through materials with incredible accuracy, perfect for harvesting and manufacturing applications."
        case .circuitBoard:
            return "The electronic foundation! This printed circuit board connects and controls electronic components, forming the nervous system of any advanced device."
        case .cpu:
            return "The computational brain! This central processing unit performs billions of calculations per second, making it the heart of any advanced computing system."
        case .dataStorageUnit:
            return "Massive data capacity! This high-density storage system can hold vast amounts of information, essential for complex data processing and analysis."
        case .sensorArray:
            return "Advanced detection system! This array of sensors can detect and analyze environmental conditions, electromagnetic fields, and other phenomena with incredible precision."
        case .lithiumIonBattery:
            return "High-energy power storage! This advanced battery technology provides long-lasting, reliable power for portable devices and emergency systems."
        
        // Additional resources
        case .copper:
            return "The conductor of progress! This versatile metal is essential for electrical systems, communication networks, and advanced technology. Its excellent conductivity makes it invaluable for any electronic device."
        case .gold:
            return "The precious standard! This rare and beautiful metal has been valued for millennia. Beyond its aesthetic appeal, gold's unique properties make it essential for advanced electronics and precision instruments."
        case .lithium:
            return "The power of the future! This lightweight metal is the key to high-energy batteries and advanced power systems. Essential for any portable technology or energy storage solution."
        default:
            return "A mysterious resource with unknown properties. Further study may reveal its true potential and value."
        }
    }
    
    func getResourceCollectionLocations(for resourceType: ResourceType) -> [String] {
        // This would ideally be data-driven, but for now we'll use some examples
        switch resourceType {
        case .ironOre:
            return ["Taragam-7", "Abandoned Starship", "Koraxon"]
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
        case .numins: return "star.circle"
        
        // Taragam-3 resources
        case .hydrogen: return "h.circle.fill"
        case .methane: return "flame"
        case .ammonia: return "drop.triangle"
        case .ice: return "snowflake"
        case .crystals: return "diamond"
        case .minerals: return "cube"
        
        // Abandoned Starship resources
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
        case .gears: return "gear"
        case .laser: return "laser.burst"
        case .circuitBoard: return "cpu"
        case .cpu: return "cpu"
        case .dataStorageUnit: return "externaldrive"
        case .sensorArray: return "sensor.tag.radiowaves.forward"
        case .lithiumIonBattery: return "battery.100"
        case .fusionReactor: return "atom"
        case .quantumComputer: return "cpu"
        case .spaceStationModule: return "building.2.fill"
        case .starshipHull: return "airplane"
        case .terraformingArray: return "globe"
        
        // Additional resources
        case .copper: return "circle.fill"
        case .gold: return "star.fill"
        case .lithium: return "battery.100"
        
        // Enhancement items
        case .excavator: return "hammer.fill"
        case .laserHarvester: return "laser.burst"
        case .virtualAlmanac: return "book.fill"
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
        
        // Taragam-3 resources
        case .hydrogen: return .cyan
        case .methane: return .orange
        case .ammonia: return .green
        case .ice: return .blue
        case .crystals: return .purple
        case .minerals: return .brown
        
        // Abandoned Starship resources
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
        case .gears: return .gray
        case .laser: return .red
        case .circuitBoard: return .green
        case .cpu: return .blue
        case .dataStorageUnit: return .purple
        case .sensorArray: return .cyan
        case .lithiumIonBattery: return .yellow
        case .fusionReactor: return .red
        case .quantumComputer: return .purple
        case .spaceStationModule: return .blue
        case .starshipHull: return .gray
        case .terraformingArray: return .green
        
        // Additional resources
        case .copper: return .orange
        case .gold: return .yellow
        case .lithium: return .gray
        
        // Enhancement items
        case .excavator: return .brown
        case .laserHarvester: return .red
        case .virtualAlmanac: return .purple
        }
    }
    
    // MARK: - Resource Rarity System
    
    func getResourceRarity(for resourceType: ResourceType) -> ResourceRarity {
        let dropTable = getModifiedDropTable()
        
        // Find the resource in the drop table
        guard dropTable.contains(where: { $0.0 == resourceType }) else {
            return .common // Default to common if not found
        }
        
        // Sort resources by percentage (highest first) to determine rarity
        let sortedResources = dropTable.sorted { $0.1 > $1.1 }
        
        // Find the position of this resource in the sorted list
        guard let position = sortedResources.firstIndex(where: { $0.0 == resourceType }) else {
            return .common
        }
        
        // Categorize based on position:
        // Top 4 (0-3) = Common
        // Next 3 (4-6) = Uncommon  
        // Last 3 (7-9) = Rare
        if position < 4 {
            return .common
        } else if position < 7 {
            return .uncommon
        } else {
            return .rare
        }
    }
    
    func getResourcesByRarity(_ rarity: ResourceRarity) -> [ResourceType] {
        let dropTable = getModifiedDropTable()
        let sortedResources = dropTable.sorted { $0.1 > $1.1 }
        
        switch rarity {
        case .common:
            return Array(sortedResources.prefix(4).map { $0.0 })
        case .uncommon:
            return Array(sortedResources.dropFirst(4).prefix(3).map { $0.0 })
        case .rare:
            return Array(sortedResources.dropFirst(7).map { $0.0 })
        }
    }
    
    // MARK: - Dev Tools
    @Published var showDevToolsDropdown = false
    @Published var devToolUnlockAllBays = false
    @Published var devToolBuildableWithoutIngredients = false
    @Published var devToolUnlockAllLocations = false
    @Published var showStarMapDevToolsDropdown = false
    @Published var showTelescopeLockedMessage = false
    
    func unlockAllConstructionBays() {
        for i in 0..<constructionBays.count {
            constructionBays[i].isUnlocked = true
        }
        print("🔧 DEV TOOL - All construction bays unlocked!")
    }
    
    func toggleBayUnlock() {
        devToolUnlockAllBays.toggle()
        print("🔧 DEV TOOL - Toggle called, new state: \(devToolUnlockAllBays)")
        
        // Ensure we have all 9 construction bays (4 small + 3 medium + 2 large)
        if constructionBays.count < 9 {
            print("🔧 DEV TOOL - Reinitializing construction bays (had \(constructionBays.count), need 9)")
            initializeAllConstructionBays()
        }
        
        print("🔧 DEV TOOL - Total construction bays: \(constructionBays.count)")
        
        // Create new array with updated bay states to trigger UI update
        var updatedBays: [ConstructionBay] = []
        for i in 0..<constructionBays.count {
            let oldState = constructionBays[i].isUnlocked
            let newUnlockedState: Bool
            if i == 0 {
                // First small bay is always unlocked
                newUnlockedState = true
            } else {
                // All other bays follow the dev tool toggle
                newUnlockedState = devToolUnlockAllBays
            }
            
            let updatedBay = ConstructionBay(
                id: constructionBays[i].id,
                size: constructionBays[i].size,
                currentConstruction: constructionBays[i].currentConstruction,
                isUnlocked: newUnlockedState
            )
            updatedBays.append(updatedBay)
            
            print("🔧 DEV TOOL - Bay \(i) (\(constructionBays[i].size.rawValue) - \(constructionBays[i].id)): \(oldState) -> \(newUnlockedState)")
        }
        
        // Replace the entire array to trigger UI update
        constructionBays = updatedBays
        
        print("🔧 DEV TOOL - All bays unlock toggled: \(devToolUnlockAllBays)")
        print("🔧 DEV TOOL - First small bay always unlocked, others: \(devToolUnlockAllBays ? "unlocked" : "locked")")
        print("🔧 DEV TOOL - Updated \(updatedBays.count) bays total")
    }
    
    private func initializeAllConstructionBays() {
        self.constructionBays = [
            // Small bays
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
            ),
            // Medium bays
            ConstructionBay(
                id: "medium-bay-1",
                size: .medium,
                currentConstruction: nil,
                isUnlocked: false
            ),
            ConstructionBay(
                id: "medium-bay-2",
                size: .medium,
                currentConstruction: nil,
                isUnlocked: false
            ),
            ConstructionBay(
                id: "medium-bay-3",
                size: .medium,
                currentConstruction: nil,
                isUnlocked: false
            ),
            // Large bays
            ConstructionBay(
                id: "large-bay-1",
                size: .large,
                currentConstruction: nil,
                isUnlocked: false
            ),
            ConstructionBay(
                id: "large-bay-2",
                size: .large,
                currentConstruction: nil,
                isUnlocked: false
            )
        ]
        print("🔧 DEV TOOL - Initialized all 9 construction bays")
    }
    
    func completeAllConstructions() {
        for i in 0..<constructionBays.count {
            if constructionBays[i].currentConstruction != nil {
                // Complete the construction by setting time remaining to 0
                constructionBays[i].currentConstruction?.timeRemaining = 0
                constructionBays[i].currentConstruction?.progress = 1.0
            }
        }
        print("🔧 DEV TOOL - All constructions completed instantly!")
    }
    
    // MARK: - Location Unlocking System
    
    func isLocationUnlocked(_ location: Location) -> Bool {
        // Taragam-7 is always unlocked (starter planet)
        if location.id == "taragam-7" {
            return true
        }
        
        // If dev tool is enabled, all locations are unlocked
        if devToolUnlockAllLocations {
            return true
        }
        
        // For now, all other locations are locked unless dev tool is enabled
        return false
    }
    
    func toggleLocationUnlock() {
        devToolUnlockAllLocations.toggle()
        print("🔧 DEV TOOL - Toggle location unlock called, new state: \(devToolUnlockAllLocations)")
    }
    
    func isTelescopeUnlocked() -> Bool {
        // Telescope is unlocked if all locations are unlocked OR if we're not in Taragon Gamma system
        return devToolUnlockAllLocations || currentLocation.system != "Taragon Gamma"
    }
    
    func displayTelescopeLockedMessage() {
        showTelescopeLockedMessage = true
        // Hide the message after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showTelescopeLockedMessage = false
        }
    }
    
    func getModifiedDropTable() -> [(ResourceType, Double)] {
        let baseDropTable = getLocationDropTable()
        
        // Check if Deep Scan card is slotted on the Location page
        let equippedLocationCards = getEquippedCardsForPage("Location").compactMap { $0 }
        
        // Find Deep Scan card among slotted cards
        guard let deepScanCardId = equippedLocationCards.first(where: { $0 == "deep-scan" }),
              let deepScanCard = getUserCard(for: deepScanCardId),
              let cardDef = getAllCardDefinitions().first(where: { $0.id == "deep-scan" }) else {
            return baseDropTable
        }
        
        let tierIndex = deepScanCard.tier - 1
        let rareBiasPerLevel = cardDef.tiers[tierIndex].value
        
        // Get the 3 rare resources (last 3 in the drop table)
        let rareResources = Array(baseDropTable.suffix(3).map { $0.0 })
        // Get the 4 common resources (first 4 in the drop table)
        let commonResources = Array(baseDropTable.prefix(4).map { $0.0 })
        
        // Calculate total rare bias (3 rare resources × bias per level)
        let totalRareBias = rareBiasPerLevel * 3.0
        
        // Redistribute probabilities
        var modifiedTable: [(ResourceType, Double)] = []
        
        for (resourceType, basePercentage) in baseDropTable {
            var newPercentage = basePercentage
            
            if rareResources.contains(resourceType) {
                // Add rare bias to rare resources
                newPercentage += rareBiasPerLevel
            } else if commonResources.contains(resourceType) {
                // Reduce common resources proportionally
                // Distribute the reduction across the 4 common resources
                let reductionPerCommon = totalRareBias / 4.0
                newPercentage = max(0, newPercentage - reductionPerCommon)
            }
            // Uncommon resources (middle 3) remain unchanged
            
            modifiedTable.append((resourceType, newPercentage))
        }
        
        return modifiedTable
    }
    
    func getIdleDropTable() -> [(ResourceType, Double)] {
        // Idle collection always uses base drop table (no card modifications)
        return getLocationDropTable()
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
                    CardTier(copies: 2, value: 0.25),   // +25%
                    CardTier(copies: 5, value: 0.50),   // +50%
                    CardTier(copies: 10, value: 0.75),  // +75%
                    CardTier(copies: 25, value: 1.00),  // +100%
                    CardTier(copies: 100, value: 1.50)  // +150%
                ],
                description: "Increases tap yield when slotted on Resources/Map screens"
            ),
            CardDef(
                id: "deep-scan",
                name: "Deep Scan",
                cardClass: .explorer,
                effectKey: "idleRareBias",
                tiers: [
                    CardTier(copies: 2, value: 0.01),   // +1% per level
                    CardTier(copies: 5, value: 0.02),   // +2% per level
                    CardTier(copies: 10, value: 0.03),  // +3% per level
                    CardTier(copies: 25, value: 0.04),  // +4% per level
                    CardTier(copies: 100, value: 0.05)  // +5% per level
                ],
                description: "Improves chances of getting the 3 'Rare' resources during idle collection"
            ),
            
            // Constructor Class
            CardDef(
                id: "materials-engineer",
                name: "Materials Engineer",
                cardClass: .constructor,
                effectKey: "buildTimeMultiplier",
                tiers: [
                    CardTier(copies: 2, value: -0.02),  // -2%
                    CardTier(copies: 5, value: -0.04),  // -4%
                    CardTier(copies: 10, value: -0.07), // -7%
                    CardTier(copies: 25, value: -0.11), // -11%
                    CardTier(copies: 100, value: -0.16) // -16%
                ],
                description: "Reduces construction time when slotted"
            ),
            
            // Collector Class
            CardDef(
                id: "storage-bay",
                name: "Storage Bay",
                cardClass: .collector,
                effectKey: "storageCapBonus",
                tiers: [
                    CardTier(copies: 2, value: 100),    // +100
                    CardTier(copies: 5, value: 250),    // +250
                    CardTier(copies: 10, value: 500),   // +500
                    CardTier(copies: 25, value: 1000),  // +1000
                    CardTier(copies: 100, value: 1500)  // +1500
                ],
                description: "Expands storage capacity for resources"
            ),
            
            // Progression Class
            CardDef(
                id: "midas-touch",
                name: "Midas' Touch",
                cardClass: .progression,
                effectKey: "xpGainMultiplier",
                tiers: [
                    CardTier(copies: 2, value: 0.50),   // +50%
                    CardTier(copies: 5, value: 0.75),   // +75%
                    CardTier(copies: 10, value: 1.00),  // +100%
                    CardTier(copies: 25, value: 1.50),  // +150%
                    CardTier(copies: 100, value: 2.00)  // +200%
                ],
                description: "Increases experience (XP) gain across all activities on chosen screen"
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
            let currentTierIndex = userCard.tier - 1  // Convert tier to 0-based index
            let requiredCopies = cardDef.tiers[currentTierIndex].copies
            
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
    
    func getTotalResourcesHeld() -> Int {
        return resources.filter { $0.type != .numins }.reduce(0) { $0 + Int($1.amount) }
    }
    
    func isStorageFull() -> Bool {
        return getTotalResourcesHeld() >= maxStorageCapacity
    }
    
    func canAddResource(_ resourceType: ResourceType, amount: Int = 1) -> Bool {
        // Currency (Numins) can always be added
        if resourceType == .numins {
            return true
        }
        // Check if adding this amount would exceed storage capacity
        return getTotalResourcesHeld() + amount <= maxStorageCapacity
    }
    
    func deleteResource(_ resourceType: ResourceType, amount: Int) {
        guard let index = resources.firstIndex(where: { $0.type == resourceType }) else { return }
        
        let currentAmount = Int(resources[index].amount)
        let newAmount = max(0, currentAmount - amount)
        
        if newAmount == 0 {
            // Remove the resource entirely if amount becomes 0
            resources.remove(at: index)
        } else {
            // Update the amount
            resources[index].amount = Double(newAmount)
        }
        
        print("Deleted \(amount) \(resourceType.rawValue). Remaining: \(newAmount)")
    }
    
    func getCardsCollectedForClass(_ cardClass: CardClass) -> Int {
        return ownedCards
            .filter { userCard in
                getAllCardDefinitions().first { $0.id == userCard.cardId }?.cardClass == cardClass
            }
            .reduce(0) { $0 + $1.copies }
    }
    
    // MARK: - Card Slotting Functions
    
    func equipCardToSlot(cardId: String, slotIndex: Int, page: String) {
        guard slotIndex >= 0 && slotIndex < 4 else { return }
        
        switch page {
        case "Location":
            equippedLocationCards[slotIndex] = cardId
        case "Shop":
            equippedShopCards[slotIndex] = cardId
        case "Cards":
            equippedCardsCards[slotIndex] = cardId
        case "Resources":
            equippedResourcesCards[slotIndex] = cardId
        case "Construction":
            equippedConstructionCards[slotIndex] = cardId
        default:
            break
        }
        
        print("Equipped card \(cardId) to \(page) slot \(slotIndex + 1)")
    }
    
    func unequipCardFromSlot(slotIndex: Int, page: String) {
        guard slotIndex >= 0 && slotIndex < 4 else { return }
        
        switch page {
        case "Location":
            equippedLocationCards[slotIndex] = nil
        case "Shop":
            equippedShopCards[slotIndex] = nil
        case "Cards":
            equippedCardsCards[slotIndex] = nil
        case "Resources":
            equippedResourcesCards[slotIndex] = nil
        case "Construction":
            equippedConstructionCards[slotIndex] = nil
        default:
            break
        }
        
        print("Unequipped card from \(page) slot \(slotIndex + 1)")
    }
    
    func getEquippedCard(slotIndex: Int, page: String) -> String? {
        guard slotIndex >= 0 && slotIndex < 4 else { return nil }
        
        switch page {
        case "Location":
            return equippedLocationCards[slotIndex]
        case "Shop":
            return equippedShopCards[slotIndex]
        case "Cards":
            return equippedCardsCards[slotIndex]
        case "Resources":
            return equippedResourcesCards[slotIndex]
        case "Construction":
            return equippedConstructionCards[slotIndex]
        default:
            return nil
        }
    }
    
    func getEquippedCardsForPage(_ page: String) -> [String?] {
        switch page {
        case "Location":
            return equippedLocationCards
        case "Shop":
            return equippedShopCards
        case "Cards":
            return equippedCardsCards
        case "Resources":
            return equippedResourcesCards
        case "Construction":
            return equippedConstructionCards
        default:
            return [nil, nil, nil, nil]
        }
    }
    
    // MARK: - Card Effect Functions
    
    func getCardEffectMultiplier(effectKey: String, page: String) -> Double {
        let equippedCards = getEquippedCardsForPage(page).compactMap { $0 }
        var totalMultiplier = 0.0
        
        for cardId in equippedCards {
            if let userCard = getUserCard(for: cardId),
               let cardDef = getAllCardDefinitions().first(where: { $0.id == cardId }),
               cardDef.effectKey == effectKey {
                
                // Get the effect value for the card's current tier
                let tierIndex = userCard.tier - 1 // Convert to 0-based index
                if tierIndex >= 0 && tierIndex < cardDef.tiers.count {
                    totalMultiplier += cardDef.tiers[tierIndex].value
                }
            }
        }
        
        return totalMultiplier
    }
    
    func getTapYieldMultiplier() -> Double {
        // Check all pages that affect tap yield
        let locationMultiplier = getCardEffectMultiplier(effectKey: "tapYieldMultiplier", page: "Location")
        let resourcesMultiplier = getCardEffectMultiplier(effectKey: "tapYieldMultiplier", page: "Resources")
        
        return 1.0 + locationMultiplier + resourcesMultiplier
    }
    
    func getIdleYieldMultiplier() -> Double {
        // Idle collection should NOT be affected by tap yield multipliers
        // Only return base multiplier (1.0) for idle collection
        return 1.0
    }
    
    func calculateResourceYield(baseAmount: Int, multiplier: Double) -> Int {
        // multiplier represents the total multiplier (e.g., 1.25 for 25% bonus, 2.0 for 100% bonus, 2.5 for 150% bonus)
        let bonusMultiplier = multiplier - 1.0 // Convert to bonus percentage (0.25, 1.0, 1.5)
        
        if bonusMultiplier <= 0 {
            return baseAmount
        }
        
        // Calculate guaranteed extra resources
        let guaranteedExtra = Int(bonusMultiplier)
        let fractionalPart = bonusMultiplier - Double(guaranteedExtra)
        
        // Calculate total guaranteed amount
        let totalAmount = baseAmount + guaranteedExtra
        
        // If there's a fractional part, there's a chance for one more resource
        if fractionalPart > 0 && Double.random(in: 0...1) < fractionalPart {
            return totalAmount + 1
        }
        
        return totalAmount
    }
    
    func getRareItemBias() -> Double {
        // Check all pages that affect rare item chances
        let locationMultiplier = getCardEffectMultiplier(effectKey: "idleRareBias", page: "Location")
        let resourcesMultiplier = getCardEffectMultiplier(effectKey: "idleRareBias", page: "Resources")
        
        return locationMultiplier + resourcesMultiplier
    }
    
    func getXPGainMultiplier() -> Double {
        // Check all pages for XP gain multipliers
        let locationMultiplier = getCardEffectMultiplier(effectKey: "xpGainMultiplier", page: "Location")
        let shopMultiplier = getCardEffectMultiplier(effectKey: "xpGainMultiplier", page: "Shop")
        let cardsMultiplier = getCardEffectMultiplier(effectKey: "xpGainMultiplier", page: "Cards")
        let resourcesMultiplier = getCardEffectMultiplier(effectKey: "xpGainMultiplier", page: "Resources")
        let constructionMultiplier = getCardEffectMultiplier(effectKey: "xpGainMultiplier", page: "Construction")
        
        return 1.0 + locationMultiplier + shopMultiplier + cardsMultiplier + resourcesMultiplier + constructionMultiplier
    }
    
    func getBuildTimeMultiplier() -> Double {
        // Check construction page for build time reduction
        let constructionMultiplier = getCardEffectMultiplier(effectKey: "buildTimeMultiplier", page: "Construction")
        
        return 1.0 + constructionMultiplier // This will be negative, so 1.0 + (-0.1) = 0.9 (10% faster)
    }
    
    func getStorageCapacityBonus() -> Int {
        // Check all pages for storage capacity bonuses
        let locationBonus = getCardEffectMultiplier(effectKey: "storageCapBonus", page: "Location")
        let shopBonus = getCardEffectMultiplier(effectKey: "storageCapBonus", page: "Shop")
        let cardsBonus = getCardEffectMultiplier(effectKey: "storageCapBonus", page: "Cards")
        let resourcesBonus = getCardEffectMultiplier(effectKey: "storageCapBonus", page: "Resources")
        let constructionBonus = getCardEffectMultiplier(effectKey: "storageCapBonus", page: "Construction")
        
        return Int(locationBonus + shopBonus + cardsBonus + resourcesBonus + constructionBonus)
    }
    
    // MARK: - Star Map Hierarchy Methods
    
    private func initializeStarMapHierarchy() -> [Constellation] {
        // Create Taragon Gamma system with the first 5 locations
        let taragonGammaLocations = availableLocations.filter { $0.system == "Taragon Gamma" }
        
        let taragonGammaSystem = StarSystem(
            id: "taragon-gamma",
            name: "Taragon Gamma",
            starType: .mainSequence,
            locations: taragonGammaLocations,
            orbitalRadius: 200.0
        )
        
        // Create other systems (for future expansion)
        let taragonBetaSystem = StarSystem(
            id: "taragon-beta",
            name: "Taragon Beta",
            starType: .redGiant,
            locations: availableLocations.filter { $0.system == "Taragon Beta" },
            orbitalRadius: 300.0
        )
        
        let violisSystem = StarSystem(
            id: "violis",
            name: "Violis",
            starType: .whiteDwarf,
            locations: availableLocations.filter { $0.system == "Violis" },
            orbitalRadius: 150.0
        )
        
        // Create constellation containing all systems
        let localConstellation = Constellation(
            id: "local-constellation",
            name: "Local Constellation",
            starSystems: [taragonGammaSystem, taragonBetaSystem, violisSystem]
        )
        
        return [localConstellation]
    }
    
    func zoomIntoStarSystem(_ starSystem: StarSystem) {
        withAnimation(.easeInOut(duration: 0.5)) {
            starMapZoomLevel = .solarSystem(starSystem)
            currentStarSystem = starSystem
        }
    }
    
    func zoomOutToConstellation() {
        withAnimation(.easeInOut(duration: 0.5)) {
            starMapZoomLevel = .constellation
            currentStarSystem = nil
        }
    }
    
    func getCurrentConstellation() -> Constellation? {
        return constellations.first
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
    case blueprints = "Blueprints"
    case starMap = "Star Map"
    case resources = "Resources"
    case cards = "Cards"
    case shop = "Shop"
    case statistics = "Statistics"
}

// MARK: - Card System

enum CardClass: String, CaseIterable {
    case explorer = "Explorer"
    case constructor = "Constructor"
    case collector = "Collector"
    case progression = "Progression"
    case trader = "Trader"
    case card = "Card"
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
    
    // Taragam-3 resources
    case hydrogen = "Hydrogen"
    case methane = "Methane"
    case ammonia = "Ammonia"
    case ice = "Ice"
    case crystals = "Crystals"
    case minerals = "Minerals"
    
    // Abandoned Starship resources
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
    case gears = "Gears"
    case laser = "Laser"
    case circuitBoard = "Circuit Board"
    case cpu = "CPU"
    case dataStorageUnit = "Data Storage Unit"
    case sensorArray = "Sensor Array"
    case lithiumIonBattery = "Lithium-Ion Battery"
    case fusionReactor = "Fusion Reactor"
    case quantumComputer = "Quantum Computer"
    case spaceStationModule = "Space Station Module"
    case starshipHull = "Starship Hull"
    case terraformingArray = "Terraforming Array"
    
    // Additional resources for new constructables
    case copper = "Copper"
    case gold = "Gold"
    case lithium = "Lithium"
    
    // Enhancement items
    case excavator = "Excavator"
    case laserHarvester = "Laser Harvester"
    case virtualAlmanac = "Virtual Almanac"
}

struct ConstructionBay: Identifiable {
    let id: String
    let size: BaySize
    var currentConstruction: Construction?
    var isUnlocked: Bool
}

enum BaySize: String, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
}

struct Construction: Identifiable {
    let id: String
    let blueprint: ConstructionBlueprint
    var timeRemaining: Double
    var progress: Double
}

struct ConstructionBlueprint: Identifiable {
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
extension ConstructionBlueprint {
    static let steelPylons = ConstructionBlueprint(
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
    
    // Small Bay Constructables
    static let gears = ConstructionBlueprint(
        id: "gears",
        name: "Gears",
        description: "Basic mechanical components for complex machinery.",
        duration: 35.0,
        cost: [.ironOre: 10, .titanium: 10, .nickel: 10],
        currencyCost: 30,
        reward: [.gears: 1],
        requiredBaySize: .small,
        xpReward: 3
    )
    
    static let laser = ConstructionBlueprint(
        id: "laser",
        name: "Laser",
        description: "Precision cutting and harvesting technology.",
        duration: 60.0,
        cost: [.silicon: 70, .helium3: 15, .crystals: 1],
        currencyCost: 50,
        reward: [.laser: 1],
        requiredBaySize: .small,
        xpReward: 5
    )
    
    static let circuitBoard = ConstructionBlueprint(
        id: "circuit-board",
        name: "Circuit Board",
        description: "The foundation of all electronic devices.",
        duration: 45.0,
        cost: [.graphite: 15, .copper: 5, .water: 1],
        currencyCost: 35,
        reward: [.circuitBoard: 1],
        requiredBaySize: .small,
        xpReward: 4
    )
    
    static let cpu = ConstructionBlueprint(
        id: "cpu",
        name: "CPU",
        description: "The brain of any advanced computing system.",
        duration: 120.0,
        cost: [.silicon: 60, .gold: 15, .rareElements: 15],
        currencyCost: 100,
        reward: [.cpu: 1],
        requiredBaySize: .small,
        xpReward: 7
    )
    
    static let dataStorageUnit = ConstructionBlueprint(
        id: "data-storage-unit",
        name: "Data Storage Unit",
        description: "High-capacity data storage for complex systems.",
        duration: 90.0,
        cost: [.circuitBoard: 1, .dataCores: 25, .electronics: 45],
        currencyCost: 75,
        reward: [.dataStorageUnit: 1],
        requiredBaySize: .small,
        xpReward: 7
    )
    
    static let sensorArray = ConstructionBlueprint(
        id: "sensor-array",
        name: "Sensor Array",
        description: "Advanced detection and monitoring system.",
        duration: 75.0,
        cost: [.silicon: 50, .laser: 3],
        currencyCost: 150,
        reward: [.sensorArray: 1],
        requiredBaySize: .small,
        xpReward: 6
    )
    
    static let lithiumIonBattery = ConstructionBlueprint(
        id: "lithium-ion-battery",
        name: "Lithium-Ion Battery",
        description: "High-energy power storage for portable devices.",
        duration: 20.0,
        cost: [.lithium: 10, .graphite: 10, .manganese: 3],
        currencyCost: 75,
        reward: [.lithiumIonBattery: 1],
        requiredBaySize: .small,
        xpReward: 9
    )
    
    // Medium Bay Constructables
    static let fusionReactor = ConstructionBlueprint(
        id: "fusion-reactor",
        name: "Fusion Reactor",
        description: "Advanced power generation system for large-scale operations.",
        duration: 180.0,
        cost: [.helium3: 100, .titanium: 50, .rareElements: 25],
        currencyCost: 500,
        reward: [.fusionReactor: 1],
        requiredBaySize: .medium,
        xpReward: 15
    )
    
    static let quantumComputer = ConstructionBlueprint(
        id: "quantum-computer",
        name: "Quantum Computer",
        description: "Revolutionary computing technology for complex calculations.",
        duration: 240.0,
        cost: [.cpu: 5, .dataStorageUnit: 3, .rareElements: 50],
        currencyCost: 750,
        reward: [.quantumComputer: 1],
        requiredBaySize: .medium,
        xpReward: 20
    )
    
    static let spaceStationModule = ConstructionBlueprint(
        id: "space-station-module",
        name: "Space Station Module",
        description: "Habitable module for long-term space operations.",
        duration: 300.0,
        cost: [.steelPylons: 20, .circuitBoard: 10, .titanium: 100],
        currencyCost: 1000,
        reward: [.spaceStationModule: 1],
        requiredBaySize: .medium,
        xpReward: 25
    )
    
    static let excavator = ConstructionBlueprint(
        id: "excavator",
        name: "Excavator",
        description: "Enhancement Item: Ability Unknown",
        duration: 300.0, // 5 minutes
        cost: [.steelPylons: 10, .gears: 3],
        currencyCost: 300,
        reward: [.excavator: 1],
        requiredBaySize: .medium,
        xpReward: 25
    )
    
    static let laserHarvester = ConstructionBlueprint(
        id: "laser-harvester",
        name: "Laser Harvester",
        description: "Enhancement Item: Ability Unknown",
        duration: 450.0, // 7.5 minutes
        cost: [.laser: 5, .circuitBoard: 3, .steelPylons: 4],
        currencyCost: 550,
        reward: [.laserHarvester: 1],
        requiredBaySize: .medium,
        xpReward: 40
    )
    
    static let virtualAlmanac = ConstructionBlueprint(
        id: "virtual-almanac",
        name: "Virtual Almanac",
        description: "Enhancement Item: Ability Unknown",
        duration: 600.0, // 10 minutes
        cost: [.cpu: 1, .dataStorageUnit: 1, .alloys: 50, .silicon: 50],
        currencyCost: 995,
        reward: [.virtualAlmanac: 1],
        requiredBaySize: .medium,
        xpReward: 75
    )
    
    // Large Bay Constructables
    static let starshipHull = ConstructionBlueprint(
        id: "starship-hull",
        name: "Starship Hull",
        description: "The main structure of an interstellar vessel.",
        duration: 600.0,
        cost: [.titanium: 200, .steelPylons: 50, .rareElements: 100],
        currencyCost: 2000,
        reward: [.starshipHull: 1],
        requiredBaySize: .large,
        xpReward: 50
    )
    
    static let terraformingArray = ConstructionBlueprint(
        id: "terraforming-array",
        name: "Terraforming Array",
        description: "Massive system for planetary environment modification.",
        duration: 900.0,
        cost: [.fusionReactor: 2, .quantumComputer: 1, .rareElements: 200],
        currencyCost: 5000,
        reward: [.terraformingArray: 1],
        requiredBaySize: .large,
        xpReward: 75
    )
    
    static let allBlueprints: [ConstructionBlueprint] = [
        .steelPylons,
        .circuitBoard,
        .gears,
        .cpu,
        .laser,
        .lithiumIonBattery,
        .sensorArray,
        .dataStorageUnit,
        .fusionReactor,
        .quantumComputer,
        .spaceStationModule,
        .excavator,
        .laserHarvester,
        .virtualAlmanac,
        .starshipHull,
        .terraformingArray
    ]
}
