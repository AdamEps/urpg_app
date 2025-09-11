//
//  AccountDevToolView.swift
//  UniverseRPG
//
//  Created by Adam Epstein on 9/10/25.
//

import SwiftUI

struct AccountDevToolView: View {
    @ObservedObject var gameStateManager: GameStateManager
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var showingResetAlert = false
    @State private var accountToDelete: String?
    @State private var accountToReset: String?
    @State private var accounts: [GameStateManager.AccountInfo] = []
    @Environment(\.dismiss) private var dismiss
    
    // Callback to auto-fill login credentials
    var onDevLogin: ((String, String) -> Void)?
    
    var filteredAccounts: [GameStateManager.AccountInfo] {
        if searchText.isEmpty {
            return accounts
        } else {
            return gameStateManager.searchAccounts(query: searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search accounts...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Account list
                List {
                    ForEach(filteredAccounts, id: \.username) { account in
                        AccountRowView(
                            account: account,
                            onDelete: {
                                accountToDelete = account.username
                                showingDeleteAlert = true
                            },
                            onReset: {
                                print("🔄 RESET CALLED - Account: \(account.username)")
                                accountToReset = account.username
                                showingResetAlert = true
                            },
                            onDevLogin: {
                                print("🔧 DEV LOGIN CALLED - Account: \(account.username)")
                                // Get the password for this account
                                let userDefaults = UserDefaults.standard
                                if let password = userDefaults.string(forKey: "\(account.username)_password") {
                                    print("🔧 DEV LOGIN - Auto-filling credentials for: \(account.username)")
                                    // Call the callback to auto-fill the login form
                                    onDevLogin?(account.username, password)
                                    // Dismiss the dev tool
                                    dismiss()
                                } else {
                                    print("❌ DEV LOGIN - Could not find password for: \(account.username)")
                                }
                            }
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Account Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        refreshAccounts()
                    }
                }
            }
            .onAppear {
                refreshAccounts()
            }
            .alert("Delete Account", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    accountToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let username = accountToDelete {
                        deleteAccount(username)
                    }
                }
            } message: {
                if let username = accountToDelete {
                    Text("Are you sure you want to delete the account '\(username)'? This action cannot be undone.")
                }
            }
            .alert("Reset Account Data", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {
                    accountToReset = nil
                }
                Button("Reset", role: .destructive) {
                    if let username = accountToReset {
                        resetAccountData(username)
                    }
                }
            } message: {
                if let username = accountToReset {
                    Text("Are you sure you want to reset all game data for '\(username)'? This will clear all progress, resources, and achievements. This action cannot be undone.")
                }
            }
        }
    }
    
    private func refreshAccounts() {
        accounts = gameStateManager.getAllAccountInfo()
    }
    
    private func deleteAccount(_ username: String) {
        if gameStateManager.deleteAccount(username: username) {
            refreshAccounts()
        }
    }
    
    private func resetAccountData(_ username: String) {
        if gameStateManager.resetAccountData(username: username) {
            refreshAccounts()
        }
    }
}

struct AccountRowView: View {
    let account: GameStateManager.AccountInfo
    let onDelete: () -> Void
    let onReset: () -> Void
    let onDevLogin: () -> Void
    
    private var dataSizeFormatted: String {
        formatBytes(account.dataSize)
    }
    
    private var createdAtFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: account.createdAt)
    }
    
    private var lastLoginFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: account.lastLoginAt)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(account.username)
                            .font(.headline)
                            .foregroundColor(account.isActive ? .blue : .primary)
                        
                        if account.isActive {
                            Text("(Current)")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text("Password: \(account.password)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 8) {
                    // Dev Login button
                    Button(action: {
                        print("🔧 DEV LOGIN BUTTON TAPPED - Account: \(account.username)")
                        onDevLogin()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.caption)
                            Text("Login")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Reset Data button
                    Button(action: {
                        print("🔄 RESET BUTTON TAPPED - Account: \(account.username)")
                        onReset()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise.circle")
                                .font(.caption)
                            Text("Reset")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Delete button
                    Button(action: {
                        print("🗑️ DELETE BUTTON TAPPED - Account: \(account.username)")
                        onDelete()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(account.isActive)
                    .opacity(account.isActive ? 0.5 : 1.0)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Created: \(createdAtFormatted)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Last Login: \(lastLoginFormatted)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Data Size")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(dataSizeFormatted)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

#Preview {
    AccountDevToolView(gameStateManager: GameStateManager.shared, onDevLogin: { username, password in
        print("Preview: Dev login for \(username)")
    })
}
