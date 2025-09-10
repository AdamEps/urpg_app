//
//  APIServices.swift
//  UniverseRPG
//
//  Created by Adam Epstein on 9/3/25.
//

import Foundation

// MARK: - API Response Models
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: String?
    let timestamp: Date
}

struct UserProfile: Codable {
    let id: String
    let username: String
    let createdAt: Date
    let lastLoginAt: Date
    let level: Int
    let totalPlayTime: TimeInterval
}

struct GameProgress: Codable {
    let userId: String
    let saveData: SerializableGameState
    let lastUpdated: Date
    let version: String
}

// MARK: - API Service Protocols
protocol UserServiceProtocol {
    func createUser(username: String) async throws -> UserProfile
    func getUserProfile(userId: String) async throws -> UserProfile
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile
    func deleteUser(userId: String) async throws -> Bool
    func validateUsername(_ username: String) async throws -> Bool
}

protocol GameProgressServiceProtocol {
    func saveGameProgress(_ progress: GameProgress) async throws -> Bool
    func loadGameProgress(userId: String) async throws -> GameProgress?
    func deleteGameProgress(userId: String) async throws -> Bool
    func getGameProgressHistory(userId: String) async throws -> [GameProgress]
}

// MARK: - Local Mock Implementations
class LocalUserService: UserServiceProtocol {
    private let userDefaults = UserDefaults.standard
    private let usersKey = "UniverseRPG_LocalUsers"
    
    func createUser(username: String) async throws -> UserProfile {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let profile = UserProfile(
            id: UUID().uuidString,
            username: username,
            createdAt: Date(),
            lastLoginAt: Date(),
            level: 0,
            totalPlayTime: 0
        )
        
        // Store locally
        var users = getStoredUsers()
        users[profile.id] = profile
        storeUsers(users)
        
        return profile
    }
    
    func getUserProfile(userId: String) async throws -> UserProfile {
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        let users = getStoredUsers()
        guard let profile = users[userId] else {
            throw APIError.userNotFound
        }
        
        return profile
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
        
        var users = getStoredUsers()
        users[profile.id] = profile
        storeUsers(users)
        
        return profile
    }
    
    func deleteUser(userId: String) async throws -> Bool {
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
        
        var users = getStoredUsers()
        users.removeValue(forKey: userId)
        storeUsers(users)
        
        return true
    }
    
    func validateUsername(_ username: String) async throws -> Bool {
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        let users = getStoredUsers()
        return !users.values.contains { $0.username == username }
    }
    
    private func getStoredUsers() -> [String: UserProfile] {
        guard let data = userDefaults.data(forKey: usersKey) else { return [:] }
        return (try? JSONDecoder().decode([String: UserProfile].self, from: data)) ?? [:]
    }
    
    private func storeUsers(_ users: [String: UserProfile]) {
        if let data = try? JSONEncoder().encode(users) {
            userDefaults.set(data, forKey: usersKey)
        }
    }
}

class LocalGameProgressService: GameProgressServiceProtocol {
    private let userDefaults = UserDefaults.standard
    private let progressKey = "UniverseRPG_LocalProgress"
    
    func saveGameProgress(_ progress: GameProgress) async throws -> Bool {
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
        
        var allProgress = getStoredProgress()
        allProgress[progress.userId] = progress
        storeProgress(allProgress)
        
        return true
    }
    
    func loadGameProgress(userId: String) async throws -> GameProgress? {
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        let allProgress = getStoredProgress()
        return allProgress[userId]
    }
    
    func deleteGameProgress(userId: String) async throws -> Bool {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        var allProgress = getStoredProgress()
        allProgress.removeValue(forKey: userId)
        storeProgress(allProgress)
        
        return true
    }
    
    func getGameProgressHistory(userId: String) async throws -> [GameProgress] {
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
        
        // For now, just return the current progress as a single-item array
        let allProgress = getStoredProgress()
        if let progress = allProgress[userId] {
            return [progress]
        }
        return []
    }
    
    private func getStoredProgress() -> [String: GameProgress] {
        guard let data = userDefaults.data(forKey: progressKey) else { return [:] }
        return (try? JSONDecoder().decode([String: GameProgress].self, from: data)) ?? [:]
    }
    
    private func storeProgress(_ progress: [String: GameProgress]) {
        if let data = try? JSONEncoder().encode(progress) {
            userDefaults.set(data, forKey: progressKey)
        }
    }
}

// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case userNotFound
    case invalidUsername
    case networkError
    case serverError
    case invalidData
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .invalidUsername:
            return "Invalid username"
        case .networkError:
            return "Network connection error"
        case .serverError:
            return "Server error"
        case .invalidData:
            return "Invalid data received"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}

// MARK: - API Service Manager
class APIServiceManager: ObservableObject {
    static let shared = APIServiceManager()
    
    let userService: UserServiceProtocol
    let gameProgressService: GameProgressServiceProtocol
    
    @Published var isOnline: Bool = false
    @Published var lastSyncTime: Date?
    
    private init() {
        // For now, use local implementations
        // In the future, this will switch to cloud implementations
        self.userService = LocalUserService()
        self.gameProgressService = LocalGameProgressService()
        
        // Simulate online/offline detection
        checkNetworkStatus()
    }
    
    private func checkNetworkStatus() {
        // For now, always simulate offline (local-first)
        isOnline = false
        
        // In the future, this would check actual network connectivity
        // and switch between local and cloud services
    }
    
    func syncToCloud() async {
        guard isOnline else { return }
        
        // Future implementation will sync local data to cloud
        print("Syncing to cloud...")
        lastSyncTime = Date()
    }
    
    func syncFromCloud() async {
        guard isOnline else { return }
        
        // Future implementation will sync cloud data to local
        print("Syncing from cloud...")
        lastSyncTime = Date()
    }
}

