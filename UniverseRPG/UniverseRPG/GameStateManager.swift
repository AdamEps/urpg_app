//
//  GameStateManager.swift
//  UniverseRPG
//
//  Created by Adam Epstein on 9/3/25.
//

import Foundation
import SwiftUI

// MARK: - Save Data Version (Updated)
struct SaveDataVersion {
    static let current = "1.0.0"
    
    // Version history for migration (in chronological order)
    static let versions: [String] = [
        "1.0.0"  // Initial version
    ]
    
    // Check if a version is supported
    static func isVersionSupported(_ version: String) -> Bool {
        return versions.contains(version)
    }
    
    // Get the migration path from one version to another
    static func getMigrationPath(from: String, to: String) -> [String]? {
        guard let fromIndex = versions.firstIndex(of: from),
              let toIndex = versions.firstIndex(of: to) else {
            return nil
        }
        
        if fromIndex >= toIndex {
            return nil // No migration needed or invalid path
        }
        
        return Array(versions[fromIndex + 1...toIndex])
    }
}

// MARK: - Serializable Game State
struct SerializableGameState: Codable {
    let version: String
    let playerName: String
    let playerLevel: Int
    let playerXP: Int
    let currency: Int
    let currentLocationId: String
    var resources: [SerializableResource]
    var constructionBays: [SerializableConstructionBay]
    var ownedCards: [SerializableUserCard]
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
    
    // Custom initializer for migration
    init(version: String, playerName: String, playerLevel: Int, playerXP: Int, currency: Int, currentLocationId: String, resources: [SerializableResource], constructionBays: [SerializableConstructionBay], ownedCards: [SerializableUserCard], currentLocationTapCount: Int, locationTapCounts: [String: Int], totalTapsCount: Int, totalXPGained: Int, locationIdleCollectionCounts: [String: Int], totalIdleCollectionCount: Int, totalNuminsCollected: Int, totalConstructionsCompleted: Int, smallConstructionsCompleted: Int, mediumConstructionsCompleted: Int, largeConstructionsCompleted: Int, maxStorageCapacity: Int, currentPage: String, lastSaved: Date) {
        self.version = version
        self.playerName = playerName
        self.playerLevel = playerLevel
        self.playerXP = playerXP
        self.currency = currency
        self.currentLocationId = currentLocationId
        self.resources = resources
        self.constructionBays = constructionBays
        self.ownedCards = ownedCards
        self.currentLocationTapCount = currentLocationTapCount
        self.locationTapCounts = locationTapCounts
        self.totalTapsCount = totalTapsCount
        self.totalXPGained = totalXPGained
        self.locationIdleCollectionCounts = locationIdleCollectionCounts
        self.totalIdleCollectionCount = totalIdleCollectionCount
        self.totalNuminsCollected = totalNuminsCollected
        self.totalConstructionsCompleted = totalConstructionsCompleted
        self.smallConstructionsCompleted = smallConstructionsCompleted
        self.mediumConstructionsCompleted = mediumConstructionsCompleted
        self.largeConstructionsCompleted = largeConstructionsCompleted
        self.maxStorageCapacity = maxStorageCapacity
        self.currentPage = currentPage
        self.lastSaved = lastSaved
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
    
    init(type: String, amount: Double) {
        self.type = type
        self.amount = amount
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
    
    init(id: String, size: String, currentConstruction: SerializableConstruction?, isUnlocked: Bool) {
        self.id = id
        self.size = size
        self.currentConstruction = currentConstruction
        self.isUnlocked = isUnlocked
    }
}

struct SerializableConstruction: Codable {
    let id: String
    let blueprintId: String
    let timeRemaining: Double
    let progress: Double
    
    init(from construction: Construction) {
        self.id = construction.id
        self.blueprintId = construction.blueprint.id
        self.timeRemaining = construction.timeRemaining
        self.progress = construction.progress
    }
    
    init(id: String, blueprintId: String, timeRemaining: Double, progress: Double) {
        self.id = id
        self.blueprintId = blueprintId
        self.timeRemaining = timeRemaining
        self.progress = progress
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
    
    init(id: String, cardId: String, copies: Int, tier: Int, slottedOn: [String]) {
        self.id = id
        self.cardId = cardId
        self.copies = copies
        self.tier = tier
        self.slottedOn = slottedOn
    }
}

// MARK: - Game State Manager
class GameStateManager: ObservableObject {
    static let shared = GameStateManager()
    
    @Published var gameState: GameState
    @Published var isLoggedIn: Bool = false
    @Published var currentUsername: String = ""
    
    private let userDefaults = UserDefaults.standard
    private let migrationManager = SaveMigrationManager.shared
    private var saveDataKey: String {
        return "UniverseRPG_SaveData_\(currentUsername)"
    }
    private let usernameKey = "UniverseRPG_Username"
    private let isLoggedInKey = "UniverseRPG_IsLoggedIn"
    
    private init() {
        print("🚀 GameStateManager INIT - Starting initialization...")
        
        // Initialize with default game state
        self.gameState = GameState()
        print("🚀 GameStateManager INIT - Created fresh GameState")
        
        // Connect GameState to GameStateManager for auto-save
        self.gameState.gameStateManager = self
        print("🚀 GameStateManager INIT - Connected GameState to GameStateManager")
        
        // Check for existing login state instead of forcing logout
        self.isLoggedIn = userDefaults.bool(forKey: isLoggedInKey)
        self.currentUsername = userDefaults.string(forKey: usernameKey) ?? ""
        print("🚀 GameStateManager INIT - Login state check: isLoggedIn=\(isLoggedIn), username='\(currentUsername)'")
        print("🚀 GameStateManager INIT - UserDefaults keys: isLoggedInKey='\(isLoggedInKey)', usernameKey='\(usernameKey)'")
        
        // Debug: Check what's actually in UserDefaults
        let allKeys = userDefaults.dictionaryRepresentation().keys.filter { $0.contains("UniverseRPG") }
        print("🚀 GameStateManager INIT - All UniverseRPG keys in UserDefaults: \(Array(allKeys))")
        for key in allKeys {
            if let value = userDefaults.object(forKey: key) {
                print("🚀 GameStateManager INIT - Key '\(key)': \(value)")
            }
        }
        
        // If we have a valid login state, restore the user session
        if isLoggedIn && !currentUsername.isEmpty {
            print("🔄 RESTORING SESSION - User: \(currentUsername)")
            // Add a small delay to ensure UserDefaults is fully loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("🔄 RESTORING SESSION - Loading game state for: \(self.currentUsername)")
                self.loadGameState()
                // Trigger UI update after loading
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
        } else {
            // Only clear if no valid session exists
            print("🚀 GameStateManager INIT - No valid session found, staying logged out")
            self.isLoggedIn = false
            self.currentUsername = ""
        }
        
        // Always ensure test account exists
        userDefaults.set("test", forKey: "test_password")
        print("🚀 GameStateManager INIT - Initialization complete. Final state: isLoggedIn=\(isLoggedIn), username='\(currentUsername)'")
    }
    
    // MARK: - Authentication
    func login(username: String) {
        print("🔐 LOGIN - Starting login for user: \(username)")
        print("🔐 LOGIN - Previous user was: '\(currentUsername)'")
        
        self.currentUsername = username
        self.isLoggedIn = true
        
        userDefaults.set(username, forKey: usernameKey)
        userDefaults.set(true, forKey: isLoggedInKey)
        
        // Update last login time
        userDefaults.set(Date(), forKey: "\(username)_last_login")
        
        // Load existing save data
        print("🔐 LOGIN - About to load game state for: \(username)")
        loadGameState()
        print("🔐 LOGIN - Login completed with currentPage: \(gameState.currentPage)")
        print("🔐 LOGIN - Resources count after load: \(gameState.resources.count)")
        print("🔐 LOGIN - Currency after load: \(gameState.currency)")
    }
    
    func createUser(username: String, password: String) {
        print("🆕 CREATE USER - Starting account creation for: \(username)")
        // Create new user with fresh game state
        self.currentUsername = username
        self.isLoggedIn = true
        
        let now = Date()
        
        // Store user credentials
        userDefaults.set(username, forKey: usernameKey)
        userDefaults.set(password, forKey: "\(username)_password")
        userDefaults.set(true, forKey: isLoggedInKey)
        
        // Store creation and last login times
        userDefaults.set(now, forKey: "\(username)_created_at")
        userDefaults.set(now, forKey: "\(username)_last_login")
        
        // Reset to fresh game state for new user
        resetGameStateToFresh()
        
        // Save the fresh state
        saveGameState()
        print("🆕 CREATE USER - Account creation completed with currentPage: \(gameState.currentPage)")
    }
    
    func logout() {
        // Save current state before logout
        saveGameState()
        print("💾 LOGOUT - Game state saved for user: \(currentUsername)")
        
        // Only update login state, don't clear data
        self.isLoggedIn = false
        self.currentUsername = ""
        
        userDefaults.set(false, forKey: isLoggedInKey)
        // Don't remove username key - keep it for potential future login
        
        // DON'T reset game state - data should persist!
        print("🔓 LOGOUT - User logged out, data preserved")
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
    
    // MARK: - Enhanced Account Management
    struct AccountInfo {
        let username: String
        let password: String
        let createdAt: Date
        let lastLoginAt: Date
        let dataSize: Int
        let isActive: Bool
    }
    
    func getAllAccountInfo() -> [AccountInfo] {
        var accounts: [AccountInfo] = []
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        for key in allKeys {
            if key.contains("_password") {
                let username = String(key.dropLast("_password".count))
                if let password = userDefaults.string(forKey: key) {
                    let createdAt = userDefaults.object(forKey: "\(username)_created_at") as? Date ?? Date.distantPast
                    let lastLoginAt = userDefaults.object(forKey: "\(username)_last_login") as? Date ?? Date.distantPast
                    let dataSize = getAccountDataSize(username: username)
                    let isActive = username == currentUsername
                    
                    accounts.append(AccountInfo(
                        username: username,
                        password: password,
                        createdAt: createdAt,
                        lastLoginAt: lastLoginAt,
                        dataSize: dataSize,
                        isActive: isActive
                    ))
                }
            }
        }
        
        return accounts.sorted { $0.username < $1.username }
    }
    
    private func getAccountDataSize(username: String) -> Int {
        let saveDataKey = "UniverseRPG_SaveData_\(username)"
        guard let data = userDefaults.data(forKey: saveDataKey) else { return 0 }
        return data.count
    }
    
    func searchAccounts(query: String) -> [AccountInfo] {
        let allAccounts = getAllAccountInfo()
        guard !query.isEmpty else { return allAccounts }
        
        return allAccounts.filter { account in
            account.username.localizedCaseInsensitiveContains(query)
        }
    }
    
    func deleteAccount(username: String) -> Bool {
        guard username != currentUsername else { return false } // Can't delete current account
        
        // Remove password
        userDefaults.removeObject(forKey: "\(username)_password")
        
        // Remove creation date
        userDefaults.removeObject(forKey: "\(username)_created_at")
        
        // Remove last login
        userDefaults.removeObject(forKey: "\(username)_last_login")
        
        // Remove save data
        let saveDataKey = "UniverseRPG_SaveData_\(username)"
        userDefaults.removeObject(forKey: saveDataKey)
        
        // Remove from username list
        var existingUsernames = userDefaults.stringArray(forKey: "UniverseRPG_AllUsernames") ?? []
        existingUsernames.removeAll { $0 == username }
        userDefaults.set(existingUsernames, forKey: "UniverseRPG_AllUsernames")
        
        return true
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
    
    // MARK: - Save/Load System with Migration
    func saveGameState() {
        guard isLoggedIn else { 
            print("❌ Save failed: Not logged in")
            return 
        }
        
        print("💾 SAVING GAME STATE - User: \(currentUsername)")
        print("💾 SAVING GAME STATE - Resources count: \(gameState.resources.count)")
        print("💾 SAVING GAME STATE - Currency: \(gameState.currency)")
        print("💾 SAVING GAME STATE - Player XP: \(gameState.playerXP)")
        print("💾 SAVING GAME STATE - Save key: \(saveDataKey)")
        
        let saveData = SerializableGameState(from: gameState)
        
        do {
            let data = try JSONEncoder().encode(saveData)
            
            // Create backup before saving
            if let backupKey = migrationManager.createBackup(of: data, for: currentUsername) {
                print("💾 BACKUP CREATED - Key: \(backupKey)")
            }
            
            userDefaults.set(data, forKey: saveDataKey)
            print("✅ Game state saved successfully for \(currentUsername) - Data size: \(data.count) bytes")
            
            // Clean up old backups
            migrationManager.cleanupOldBackups(for: currentUsername)
            
        } catch {
            print("❌ Failed to save game state: \(error)")
        }
    }
    
    func loadGameState() {
        guard isLoggedIn else { 
            print("❌ Load failed: Not logged in")
            return 
        }
        
        print("📂 LOADING GAME STATE - User: \(currentUsername)")
        print("📂 LOADING GAME STATE - Save key: \(saveDataKey)")
        print("📂 LOADING GAME STATE - Current resources before load: \(gameState.resources.count)")
        print("📂 LOADING GAME STATE - Current currency before load: \(gameState.currency)")
        
        guard let data = userDefaults.data(forKey: saveDataKey) else {
            print("📭 No save data found for \(currentUsername), starting fresh")
            // Reset existing game state to fresh state
            resetGameStateToFresh()
            print("📂 LOADING GAME STATE - After reset: resources=\(gameState.resources.count), currency=\(gameState.currency)")
            return
        }
        
        print("📂 LOADING GAME STATE - Found save data: \(data.count) bytes")
        
        // Try to migrate the save data
        let migrationResult = migrationManager.migrateSaveData(data)
        
        switch migrationResult {
        case .success(let migratedSaveData):
            print("✅ MIGRATION SUCCESS - Applied migration to save data")
            applySaveData(migratedSaveData)
            print("✅ Game state loaded successfully for \(currentUsername)")
            
        case .noMigrationNeeded:
            print("📂 NO MIGRATION NEEDED - Save data is current version")
            do {
                let saveData = try JSONDecoder().decode(SerializableGameState.self, from: data)
                applySaveData(saveData)
                print("✅ Game state loaded successfully for \(currentUsername)")
            } catch {
                print("❌ Failed to load game state: \(error)")
                resetGameStateToFresh()
            }
            
        case .failure(let errorMessage):
            print("❌ MIGRATION FAILED - \(errorMessage)")
            print("🔄 FALLBACK - Starting fresh game state")
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
            
            let currentConstruction: Construction?
            if let serializableConstruction = serializableBay.currentConstruction,
               let blueprint = ConstructionBlueprint.allBlueprints.first(where: { $0.id == serializableConstruction.blueprintId }) {
                currentConstruction = Construction(
                    id: serializableConstruction.id,
                    blueprint: blueprint,
                    timeRemaining: serializableConstruction.timeRemaining,
                    progress: serializableConstruction.progress
                )
            } else {
                currentConstruction = nil
            }
            
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
            // Allow .location page to be restored from save data
            gameState.currentPage = page
        }
        
        // Explicitly trigger UI updates after applying save data
        DispatchQueue.main.async {
            self.objectWillChange.send()
            self.gameState.objectWillChange.send()
        }
        
        print("Applied save data with currentPage = \(gameState.currentPage)")
        print("Applied save data - Resources count: \(gameState.resources.count)")
        print("Applied save data - Currency: \(gameState.currency)")
        print("Applied save data - Player Level: \(gameState.playerLevel)")
        print("Applied save data - Player XP: \(gameState.playerXP)")
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
        
        // Try to migrate the imported data
        let migrationResult = migrationManager.migrateSaveData(data)
        
        switch migrationResult {
        case .success(let migratedSaveData):
            applySaveData(migratedSaveData)
            saveGameState() // Save the imported data
            return true
            
        case .noMigrationNeeded:
            do {
                let saveData = try JSONDecoder().decode(SerializableGameState.self, from: data)
                applySaveData(saveData)
                saveGameState() // Save the imported data
                return true
            } catch {
                print("Failed to import save data: \(error)")
                return false
            }
            
        case .failure(let errorMessage):
            print("Failed to migrate imported save data: \(errorMessage)")
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
    
    // MARK: - Dev Tools
    func resetAccountData(username: String) -> Bool {
        print("🔄 RESET ACCOUNT DATA - Resetting data for user: \(username)")
        
        // Remove save data for this account
        let saveDataKey = "UniverseRPG_SaveData_\(username)"
        userDefaults.removeObject(forKey: saveDataKey)
        
        // If this is the current user, reset their game state
        if username == currentUsername && isLoggedIn {
            resetGameStateToFresh()
            saveGameState() // Save the fresh state
        }
        
        print("✅ RESET ACCOUNT DATA - Data reset for user: \(username)")
        return true
    }
    
    func devLogin(username: String) -> Bool {
        print("🔧 DEV LOGIN - Bypassing password for user: \(username)")
        print("🔧 DEV LOGIN - Current state before login: isLoggedIn=\(isLoggedIn), currentUsername='\(currentUsername)'")
        
        // Check if account exists
        guard userDefaults.string(forKey: "\(username)_password") != nil else {
            print("❌ DEV LOGIN - Account '\(username)' does not exist")
            return false
        }
        
        print("🔧 DEV LOGIN - Account exists, proceeding with login")
        
        // Update last login time
        userDefaults.set(Date(), forKey: "\(username)_last_login")
        
        // Login the user
        login(username: username)
        
        print("🔧 DEV LOGIN - After login call: isLoggedIn=\(isLoggedIn), currentUsername='\(currentUsername)'")
        print("✅ DEV LOGIN - Successfully logged in as: \(username)")
        return true
    }
}
