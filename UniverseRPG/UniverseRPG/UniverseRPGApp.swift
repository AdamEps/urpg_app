//
//  UniverseRPGApp.swift
//  UniverseRPG
//
//  Created by Adam Epstein on 9/3/25.
//

import SwiftUI

@main
struct UniverseRPGApp: App {
    @StateObject private var gameState = GameState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameState)
                .preferredColorScheme(gameState.appColorScheme) // Override system color scheme
        }
    }
}
