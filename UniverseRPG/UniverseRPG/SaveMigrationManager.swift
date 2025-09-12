//
//  SaveMigrationManager.swift
//  UniverseRPG
//
//  Created by Adam Epstein on 9/11/25.
//

import Foundation

// MARK: - Migration Result
enum MigrationResult {
    case success(SerializableGameState)
    case failure(String)
    case noMigrationNeeded
}

// MARK: - Save Migration Manager
class SaveMigrationManager {
    static let shared = SaveMigrationManager()
    
    private init() {}
    
    // MARK: - Main Migration Function
    func migrateSaveData(_ data: Data) -> MigrationResult {
        do {
            // First, try to decode as the current version
            let currentSaveData = try JSONDecoder().decode(SerializableGameState.self, from: data)
            
            // Check if migration is needed
            if currentSaveData.version == SaveDataVersion.current {
                return .noMigrationNeeded
            }
            
            // Check if the version is supported
            guard SaveDataVersion.isVersionSupported(currentSaveData.version) else {
                return .failure("Unsupported save version: \(currentSaveData.version)")
            }
            
            // Perform migration
            return try performMigration(from: currentSaveData)
            
        } catch {
            // If decoding fails, try to migrate from older versions
            return tryMigrateFromLegacyFormat(data)
        }
    }
    
    // MARK: - Migration Logic
    private func performMigration(from saveData: SerializableGameState) throws -> MigrationResult {
        let currentVersion = saveData.version
        let targetVersion = SaveDataVersion.current
        
        // If already at current version, no migration needed
        if currentVersion == targetVersion {
            return .noMigrationNeeded
        }
        
        // Get migration path
        guard let migrationPath = SaveDataVersion.getMigrationPath(from: currentVersion, to: targetVersion) else {
            return .failure("No migration path from \(currentVersion) to \(targetVersion)")
        }
        
        var migratedData = saveData
        
        // Apply each migration step
        for version in migrationPath {
            migratedData = try applyMigrationStep(from: migratedData, to: version)
        }
        
        return .success(migratedData)
    }
    
    // MARK: - Individual Migration Steps
    private func applyMigrationStep(from saveData: SerializableGameState, to targetVersion: String) throws -> SerializableGameState {
        switch targetVersion {
        case "1.0.0":
            // This is the current version, no migration needed
            return saveData
        default:
            throw MigrationError.unknownVersion(targetVersion)
        }
    }
    
    // MARK: - Legacy Format Migration
    private func tryMigrateFromLegacyFormat(_ data: Data) -> MigrationResult {
        // Try to detect and migrate from various legacy formats
        // This is where you'd handle saves from before versioning was implemented
        
        // For now, we'll try to decode as a basic format and create a new save
        do {
            // Try to decode as a simple dictionary first
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return try migrateFromLegacyDictionary(json)
            }
        } catch {
            // If that fails, try other legacy formats
        }
        
        return .failure("Unable to migrate from legacy format")
    }
    
    private func migrateFromLegacyDictionary(_ json: [String: Any]) throws -> MigrationResult {
        // Create a new save data with default values and try to preserve what we can
        var migratedData = SerializableGameState(
            version: SaveDataVersion.current,
            playerName: json["playerName"] as? String ?? "Commander",
            playerLevel: json["playerLevel"] as? Int ?? 0,
            playerXP: json["playerXP"] as? Int ?? 0,
            currency: json["currency"] as? Int ?? 0,
            currentLocationId: json["currentLocationId"] as? String ?? "taragam-7",
            resources: [],
            constructionBays: [],
            ownedCards: [],
            currentLocationTapCount: json["currentLocationTapCount"] as? Int ?? 0,
            locationTapCounts: json["locationTapCounts"] as? [String: Int] ?? [:],
            totalTapsCount: json["totalTapsCount"] as? Int ?? 0,
            totalXPGained: json["totalXPGained"] as? Int ?? 0,
            locationIdleCollectionCounts: json["locationIdleCollectionCounts"] as? [String: Int] ?? [:],
            totalIdleCollectionCount: json["totalIdleCollectionCount"] as? Int ?? 0,
            totalNuminsCollected: json["totalNuminsCollected"] as? Int ?? 0,
            totalConstructionsCompleted: json["totalConstructionsCompleted"] as? Int ?? 0,
            smallConstructionsCompleted: json["smallConstructionsCompleted"] as? Int ?? 0,
            mediumConstructionsCompleted: json["mediumConstructionsCompleted"] as? Int ?? 0,
            largeConstructionsCompleted: json["largeConstructionsCompleted"] as? Int ?? 0,
            maxStorageCapacity: json["maxStorageCapacity"] as? Int ?? 1000,
            currentPage: json["currentPage"] as? String ?? "starMap",
            lastSaved: Date()
        )
        
        // Try to migrate resources if they exist
        if let resourcesData = json["resources"] as? [[String: Any]] {
            migratedData.resources = migrateResources(from: resourcesData)
        }
        
        // Try to migrate construction bays if they exist
        if let baysData = json["constructionBays"] as? [[String: Any]] {
            migratedData.constructionBays = migrateConstructionBays(from: baysData)
        }
        
        // Try to migrate cards if they exist
        if let cardsData = json["ownedCards"] as? [[String: Any]] {
            migratedData.ownedCards = migrateCards(from: cardsData)
        }
        
        return .success(migratedData)
    }
    
    // MARK: - Resource Migration
    private func migrateResources(from data: [[String: Any]]) -> [SerializableResource] {
        return data.compactMap { resourceDict in
            guard let type = resourceDict["type"] as? String,
                  let amount = resourceDict["amount"] as? Double else {
                return nil
            }
            return SerializableResource(type: type, amount: amount)
        }
    }
    
    // MARK: - Construction Bay Migration
    private func migrateConstructionBays(from data: [[String: Any]]) -> [SerializableConstructionBay] {
        return data.compactMap { bayDict in
            guard let id = bayDict["id"] as? String,
                  let size = bayDict["size"] as? String,
                  let isUnlocked = bayDict["isUnlocked"] as? Bool else {
                return nil
            }
            
            let currentConstruction: SerializableConstruction? = {
                guard let constructionDict = bayDict["currentConstruction"] as? [String: Any],
                      let constructionId = constructionDict["id"] as? String,
                      let blueprintId = constructionDict["recipeId"] as? String,
                      let timeRemaining = constructionDict["timeRemaining"] as? Double,
                      let progress = constructionDict["progress"] as? Double else {
                    return nil
                }
                return SerializableConstruction(
                    id: constructionId,
                    blueprintId: blueprintId,
                    timeRemaining: timeRemaining,
                    progress: progress
                )
            }()
            
            return SerializableConstructionBay(
                id: id,
                size: size,
                currentConstruction: currentConstruction,
                isUnlocked: isUnlocked
            )
        }
    }
    
    // MARK: - Card Migration
    private func migrateCards(from data: [[String: Any]]) -> [SerializableUserCard] {
        return data.compactMap { cardDict in
            guard let id = cardDict["id"] as? String,
                  let cardId = cardDict["cardId"] as? String,
                  let copies = cardDict["copies"] as? Int,
                  let tier = cardDict["tier"] as? Int else {
                return nil
            }
            
            let slottedOn = cardDict["slottedOn"] as? [String] ?? []
            
            return SerializableUserCard(
                id: id,
                cardId: cardId,
                copies: copies,
                tier: tier,
                slottedOn: slottedOn
            )
        }
    }
}

// MARK: - Migration Errors
enum MigrationError: Error, LocalizedError {
    case unknownVersion(String)
    case invalidData
    case migrationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .unknownVersion(let version):
            return "Unknown save version: \(version)"
        case .invalidData:
            return "Invalid save data format"
        case .migrationFailed(let reason):
            return "Migration failed: \(reason)"
        }
    }
}

// MARK: - Save Data Backup
extension SaveMigrationManager {
    func createBackup(of data: Data, for username: String) -> String? {
        let backupKey = "UniverseRPG_Backup_\(username)_\(Date().timeIntervalSince1970)"
        UserDefaults.standard.set(data, forKey: backupKey)
        return backupKey
    }
    
    func restoreBackup(_ backupKey: String) -> Data? {
        return UserDefaults.standard.data(forKey: backupKey)
    }
    
    func cleanupOldBackups(for username: String, keepCount: Int = 5) {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let backupKeys = allKeys.filter { $0.hasPrefix("UniverseRPG_Backup_\(username)_") }
            .sorted { $0 > $1 } // Sort by timestamp (newest first)
        
        // Keep only the most recent backups
        let keysToRemove = Array(backupKeys.dropFirst(keepCount))
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
