//
//  SimpleProfileView.swift
//  UniverseRPG
//
//  Created by Adam Epstein on 9/10/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var gameState: GameState
    let currentUsername: String
    let logoutAction: () -> Void
    @State private var showingLogoutAlert = false
    
    init(gameState: GameState, currentUsername: String, logoutAction: @escaping () -> Void) {
        self.gameState = gameState
        self.currentUsername = currentUsername
        self.logoutAction = logoutAction
        print("🔍 PROFILE VIEW - ProfileView created for user: \(currentUsername)")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.purple.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Profile Header
                        VStack(spacing: 15) {
                            // Avatar
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text(String(currentUsername.prefix(1)).uppercased())
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                            
                            Text(currentUsername)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Level \(gameState.playerLevel) Commander")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 20)
                        
                        // Game Statistics
                        VStack(spacing: 20) {
                            // XP and Currency
                            HStack(spacing: 30) {
                                StatCard(title: "XP", value: "\(gameState.playerXP)", color: .blue)
                                StatCard(title: "Currency", value: "\(gameState.currency)", color: .green)
                            }
                            
                            // Progress Stats
                            HStack(spacing: 30) {
                                StatCard(title: "Total Taps", value: "\(gameState.totalTapsCount)", color: .orange)
                                StatCard(title: "Constructions", value: "\(gameState.totalConstructionsCompleted)", color: .purple)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Action Buttons
                        VStack(spacing: 15) {
                            Button(action: {
                                showingLogoutAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.right.square")
                                    Text("Sign Out")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                logoutAction()
            }
        } message: {
            Text("Are you sure you want to sign out? Your progress will be saved locally.")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.7))
                .textCase(.uppercase)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}
