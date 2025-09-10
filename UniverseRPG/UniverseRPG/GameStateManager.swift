//
//  GameStateManager.swift
//  UniverseRPG
//
//  Created by Adam Epstein on 9/3/25.
//

import Foundation
import SwiftUI

// MARK: - Save Data Version
struct SaveDataVersion {
    static let current = "1.0.0"
}

// MARK: - Serializable Game State
struct SerializableGameState: Codable {
    let version: String
    let playerName: String
    let playerLevel: Int
    let playerXP: Int
    let currency: Int
    let currentLocationId: String
    let resources: [SerializableResource]
    let constructionBays: [SerializableConstructionBay]
    let ownedCards: [SerializableUserCard]
    let currentLocationTapCount: Int
    let locationTapCounts: [String: Int]
    let totalTapsCount: Int
    let totalXPGained: Int
    let locationIdleCollectionCounts: [String: Int]
    let totalIdleCollectionCount: Int
    let totalNuminsCollected: Int
    let totalConstructionsCompleted: Int
    let smallConstructionsCompleted: Int
    let mediumConstructionsCompleted: Int
    let largeConstructionsCompleted: Int
    let maxStorageCapacity: Int
    let currentPage: String
    let lastSaved: Date
    
    init(from gameState: GameState) {
        self.version = SaveDataVersion.current
        self.playerName = gameState.playerName
        self.playerLevel = gameState.playerLevel
        self.playerXP = gameState.playerXP
        self.currency = gameState.currency
        self.currentLocationId = gameState.currentLocation.id
        self.resources = gameState.resources.map { SerializableResource(from: $0) }
        self.constructionBays = gameState.constructionBays.map { SerializableConstructionBay(from: $0) }
        self.ownedCards = gameState.ownedCards.map { SerializableUserCard(from: $0) }
        self.currentLocationTapCount = gameState.currentLocationTapCount
        self.locationTapCounts = gameState.locationTapCounts
        self.totalTapsCount = gameState.totalTapsCount
        self.totalXPGained = gameState.totalXPGained
        self.locationIdleCollectionCounts = gameState.locationIdleCollectionCounts
        self.totalIdleCollectionCount = gameState.totalIdleCollectionCount
        self.totalNuminsCollected = gameState.totalNuminsCollected
        self.totalConstructionsCompleted = gameState.totalConstructionsCompleted
        self.smallConstructionsCompleted = gameState.smallConstructionsCompleted
        self.mediumConstructionsCompleted = gameState.mediumConstructionsCompleted
        self.largeConstructionsCompleted = gameState.largeConstructionsCompleted
        self.maxStorageCapacity = gameState.maxStorageCapacity
        self.currentPage = gameState.currentPage.rawValue
        self.lastSaved = Date()
    }
}

// MARK: - Serializable Data Models
struct SerializableResource: Codable {
    let type: String
    let amount: Double
    
    init(from resource: Resource) {
        self.type = resource.type.rawValue
        self.amount = resource.amount
    }
}

struct SerializableConstructionBay: Codable {
    let id: String
    let size: String
    let currentConstruction: SerializableConstruction?
    let isUnlocked: Bool
    
    init(from bay: ConstructionBay) {
        self.id = bay.id
        self.size = bay.size.rawValue
        self.currentConstruction = bay.currentConstruction.map { SerializableConstruction(from: $0) }
        self.isUnlocked = bay.isUnlocked
    }
}

struct SerializableConstruction: Codable {
    let id: String
    let recipeId: String
    let timeRemaining: Double
    let progress: Double
    
    init(from construction: Construction) {
        self.id = construction.id
        self.recipeId = construction.recipe.id
        self.timeRemaining = construction.timeRemaining
        self.progress = construction.progress
    }
}

struct SerializableUserCard: Codable {
    let id: String
    let cardId: String
    let copies: Int
    let tier: Int
    let slottedOn: [String]
    
    init(from card: UserCard) {
        self.id = card.id
        self.cardId = card.cardId
        self.copies = card.copies
        self.tier = card.tier
        self.slottedOn = card.slottedOn
    }
}

// MARK: - Game State Manager
class GameStateManager: ObservableObject {
    static let shared = GameStateManager()
    
    @Published var gameState: GameState
    @Published var isLoggedIn: Bool = false
    @Published var currentUsername: String = ""
    
    private let userDefaults = UserDefaults.standard
    private let saveDataKey = "UniverseRPG_SaveData"
    private let usernameKey = "UniverseRPG_Username"
    private let isLoggedInKey = "UniverseRPG_IsLoggedIn"
    
    private init() {
        // Initialize with default game state
        self.gameState = GameState()
        
        // Connect GameState to GameStateManager for auto-save
        self.gameState.gameStateManager = self
        
        // Clear all saved usernames and force login screen
        self.isLoggedIn = false
        self.currentUsername = ""
        
        // Clear all stored data
        userDefaults.removeObject(forKey: isLoggedInKey)
        userDefaults.removeObject(forKey: usernameKey)
        
        // Clear all user-specific data except test account
        let allKeys = userDefaults.dictionaryRepresentation().keys
        for key in allKeys {
            if key.contains("_password") {
                // Don't clear test account
                if key != "test_password" {
                    userDefaults.removeObject(forKey: key)
                }
            }
        }
        
        // Always ensure test account exists
        userDefaults.set("test", forKey: "test_password")
    }
    
    // MARK: - Authentication
    func login(username: String) {
        print("🔐 LOGIN - Starting login for user: \(username)")
        self.currentUsername = username
        self.isLoggedIn = true
        
        userDefaults.set(username, forKey: usernameKey)
        userDefaults.set(true, forKey: isLoggedInKey)
        
        // Load existing save data
        loadGameState()
        print("🔐 LOGIN - Login completed with currentPage: \(gameState.currentPage)")
    }
    
    func createUser(username: String, password: String) {
        print("🆕 CREATE USER - Starting account creation for: \(username)")
        // Create new user with fresh game state
        self.currentUsername = username
        self.isLoggedIn = true
        
        // Store user credentials
        userDefaults.set(username, forKey: usernameKey)
        userDefaults.set(password, forKey: "\(username)_password")
        userDefaults.set(true, forKey: isLoggedInKey)
        
        // Reset to fresh game state for new user
        resetGameStateToFresh()
        
        // Save the fresh state
        saveGameState()
        print("🆕 CREATE USER - Account creation completed with currentPage: \(gameState.currentPage)")
    }
    
    func logout() {
        // Save current state before logout
        saveGameState()
        
        self.isLoggedIn = false
        self.currentUsername = ""
        
        userDefaults.removeObject(forKey: usernameKey)
        userDefaults.set(false, forKey: isLoggedInKey)
        
        // Reset to default game state
        resetGameStateToFresh()
    }
    
    func validateCredentials(username: String, password: String) -> Bool {
        let storedPassword = userDefaults.string(forKey: "\(username)_password")
        return storedPassword == password
    }
    
    // MARK: - Dev Tools
    func getAllStoredUsers() -> [(username: String, password: String)] {
        var users: [(username: String, password: String)] = []
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        for key in allKeys {
            if key.contains("_password") {
                let username = String(key.dropLast("_password".count))
                if let password = userDefaults.string(forKey: key) {
                    users.append((username: username, password: password))
                }
            }
        }
        
        return users.sorted { $0.username < $1.username }
    }
    
    func clearAllData() {
        // Clear all stored data
        userDefaults.removeObject(forKey: isLoggedInKey)
        userDefaults.removeObject(forKey: usernameKey)
        userDefaults.removeObject(forKey: saveDataKey)
        
        // Clear all user-specific data
        let allKeys = userDefaults.dictionaryRepresentation().keys
        for key in allKeys {
            if key.contains("_password") || key.contains("UniverseRPG") {
                userDefaults.removeObject(forKey: key)
            }
        }
        
        // Reset state
        self.isLoggedIn = false
        self.currentUsername = ""
        resetGameStateToFresh()
    }
    
    private func resetGameStateToFresh() {
        // Instead of creating a new GameState, reset the existing one to fresh values
        let freshGameState = GameState()
        
        // Copy all properties from fresh state to existing state
        gameState.currentLocation = freshGameState.currentLocation
        gameState.resources = freshGameState.resources
        gameState.constructionBays = freshGameState.constructionBays
        gameState.availableLocations = freshGameState.availableLocations
        gameState.ownedCards = freshGameState.ownedCards
        gameState.currentPage = freshGameState.currentPage
        gameState.showingLocationList = freshGameState.showingLocationList
        
        // Reset all UI state
        gameState.showConstructionMenu = false
        gameState.showConstructionPage = false
        gameState.showLocations = false
        gameState.showResourcesPage = false
        gameState.showCards = false
        gameState.showLocationResources = false
        gameState.showObjectives = false
        gameState.showTapCounter = false
        gameState.showIdleCollectionDetails = false
        gameState.showTapDetails = false
        gameState.showConstructionDetails = false
        gameState.showCardsDetails = false
        gameState.showLocationSlots = false
        gameState.showResourcesSlots = false
        gameState.showShopSlots = false
        gameState.showCardsSlots = false
        
        // Reset player data
        gameState.playerName = "Commander"
        gameState.playerLevel = 0
        gameState.playerXP = 0
        gameState.currency = 0
        gameState.maxStorageCapacity = 1000
        
        // Reset statistics
        gameState.currentLocationTapCount = 0
        gameState.locationTapCounts = [:]
        gameState.totalTapsCount = 0
        gameState.totalXPGained = 0
        gameState.locationIdleCollectionCounts = [:]
        gameState.totalIdleCollectionCount = 0
        gameState.totalNuminsCollected = 0
        gameState.totalConstructionsCompleted = 0
        gameState.smallConstructionsCompleted = 0
        gameState.mediumConstructionsCompleted = 0
        gameState.largeConstructionsCompleted = 0
        
        // Reset feedback states
        gameState.lastCollectedResource = nil
        gameState.showCollectionFeedback = false
        gameState.lastIdleCollectedResource = nil
        gameState.showIdleCollectionFeedback = false
        gameState.lastNuminsAmount = 0
        gameState.showNuminsFeedback = false
        gameState.lastXPAmount = 0
        gameState.showXPFeedback = false
        
        // Reset sort options
        gameState.resourceSortOption = .alphabetical
        gameState.resourceSortAscending = true
        gameState.selectedResourceForDetail = nil
        gameState.selectedCardForDetail = nil
        
        // Ensure game state manager reference is maintained
        gameState.gameStateManager = self
        
        // Explicitly trigger UI updates
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        
        print("Game state reset to fresh values with currentPage = \(gameState.currentPage)")
    }
    
    // MARK: - Save/Load System
    func saveGameState() {
        guard isLoggedIn else { return }
        
        let saveData = SerializableGameState(from: gameState)
        
        do {
            let data = try JSONEncoder().encode(saveData)
            userDefaults.set(data, forKey: saveDataKey)
            print("Game state saved successfully")
        } catch {
            print("Failed to save game state: \(error)")
        }
    }
    
    func loadGameState() {
        guard isLoggedIn else { return }
        
        guard let data = userDefaults.data(forKey: saveDataKey) else {
            print("No save data found, starting fresh")
            // Reset existing game state to fresh state
            resetGameStateToFresh()
            return
        }
        
        do {
            let saveData = try JSONDecoder().decode(SerializableGameState.self, from: data)
            applySaveData(saveData)
            print("Game state loaded successfully")
        } catch {
            print("Failed to load game state: \(error)")
            // Reset existing game state to fresh state
            resetGameStateToFresh()
        }
    }
    
    private func applySaveData(_ saveData: SerializableGameState) {
        // Update player data
        gameState.playerName = saveData.playerName
        gameState.playerLevel = saveData.playerLevel
        gameState.playerXP = saveData.playerXP
        gameState.currency = saveData.currency
        gameState.maxStorageCapacity = saveData.maxStorageCapacity
        
        // Update current location
        if let location = gameState.availableLocations.first(where: { $0.id == saveData.currentLocationId }) {
            gameState.currentLocation = location
        }
        
        // Update resources
        gameState.resources = saveData.resources.compactMap { serializableResource in
            guard let resourceType = ResourceType(rawValue: serializableResource.type) else { return nil }
            return Resource(
                type: resourceType,
                amount: serializableResource.amount,
                icon: gameState.getResourceIcon(for: resourceType),
                color: gameState.getResourceColor(for: resourceType)
            )
        }
        
        // Update construction bays
        gameState.constructionBays = saveData.constructionBays.compactMap { serializableBay in
            guard let baySize = BaySize(rawValue: serializableBay.size) else { return nil }
            
            let currentConstruction: Construction? = {
                guard let serializableConstruction = serializableBay.currentConstruction else { return nil }
                guard let recipe = ConstructionRecipe.allRecipes.first(where: { $0.id == serializableConstruction.recipeId }) else { return nil }
                
                return Construction(
                    id: serializableConstruction.id,
                    recipe: recipe,
                    timeRemaining: serializableConstruction.timeRemaining,
                    progress: serializableConstruction.progress
                )
            }()
            
            return ConstructionBay(
                id: serializableBay.id,
                size: baySize,
                currentConstruction: currentConstruction,
                isUnlocked: serializableBay.isUnlocked
            )
        }
        
        // Update owned cards
        gameState.ownedCards = saveData.ownedCards.map { serializableCard in
            UserCard(
                id: serializableCard.id,
                cardId: serializableCard.cardId,
                copies: serializableCard.copies,
                tier: serializableCard.tier,
                slottedOn: serializableCard.slottedOn
            )
        }
        
        // Update statistics
        gameState.currentLocationTapCount = saveData.currentLocationTapCount
        gameState.locationTapCounts = saveData.locationTapCounts
        gameState.totalTapsCount = saveData.totalTapsCount
        gameState.totalXPGained = saveData.totalXPGained
        gameState.locationIdleCollectionCounts = saveData.locationIdleCollectionCounts
        gameState.totalIdleCollectionCount = saveData.totalIdleCollectionCount
        gameState.totalNuminsCollected = saveData.totalNuminsCollected
        gameState.totalConstructionsCompleted = saveData.totalConstructionsCompleted
        gameState.smallConstructionsCompleted = saveData.smallConstructionsCompleted
        gameState.mediumConstructionsCompleted = saveData.mediumConstructionsCompleted
        gameState.largeConstructionsCompleted = saveData.largeConstructionsCompleted
        
        // Update navigation
        if let page = AppPage(rawValue: saveData.currentPage) {
            // If the saved page is .location (which has no bottom nav button), 
            // set it to .starMap instead so the navigation works properly
            if page == .location {
                gameState.currentPage = .starMap
                gameState.showingLocationList = false
            } else {
                gameState.currentPage = page
            }
        }
        
        // Explicitly trigger UI updates after applying save data
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        
        print("Applied save data with currentPage = \(gameState.currentPage)")
    }
    
    // MARK: - Auto-save Triggers
    func triggerAutoSave() {
        saveGameState()
    }
    
    // MARK: - Export/Import
    func exportSaveData() -> Data? {
        guard isLoggedIn else { return nil }
        
        let saveData = SerializableGameState(from: gameState)
        return try? JSONEncoder().encode(saveData)
    }
    
    func importSaveData(_ data: Data) -> Bool {
        guard isLoggedIn else { return false }
        
        do {
            let saveData = try JSONDecoder().decode(SerializableGameState.self, from: data)
            applySaveData(saveData)
            saveGameState() // Save the imported data
            return true
        } catch {
            print("Failed to import save data: \(error)")
            return false
        }
    }
    
    // MARK: - Username Validation
    func validateUsername(_ username: String) -> (isValid: Bool, errorMessage: String?) {
        // Check length
        if username.count < 3 {
            return (false, "Username must be at least 3 characters long")
        }
        
        if username.count > 20 {
            return (false, "Username must be no more than 20 characters long")
        }
        
        // Check characters (alphanumeric and underscores only)
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        if username.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            return (false, "Username can only contain letters, numbers, and underscores")
        }
        
        // Check if username is already taken (for local storage)
        let existingUsernames = userDefaults.stringArray(forKey: "UniverseRPG_AllUsernames") ?? []
        if existingUsernames.contains(username) {
            return (false, "Username is already taken")
        }
        
        return (true, nil)
    }
    
    func registerUsername(_ username: String) {
        var existingUsernames = userDefaults.stringArray(forKey: "UniverseRPG_AllUsernames") ?? []
        if !existingUsernames.contains(username) {
            existingUsernames.append(username)
            userDefaults.set(existingUsernames, forKey: "UniverseRPG_AllUsernames")
        }
    }
}
