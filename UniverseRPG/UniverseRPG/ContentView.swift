//
//  ContentView.swift
//  UniverseRPG
//
//  Created by Adam Epstein on 9/3/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()
    @StateObject private var gameStateManager = GameStateManager.shared
    @State private var showXPInfo = false
    @State private var showingProfile = false {
        didSet {
            print("🔍 PROFILE STATE - showingProfile set to: \(showingProfile)")
            // Add stack trace to see where this is being set from
            print("🔍 PROFILE STATE - Stack trace:")
            Thread.callStackSymbols.forEach { print("  \($0)") }
        }
    }
    
    @State private var isLoggedIn = false
    @State private var currentUsername = ""
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            if isLoggedIn {
                mainGameView
            } else {
                LoginView(isLoggedIn: $isLoggedIn, currentUsername: $currentUsername, gameState: gameState, gameStateManager: gameStateManager)
            }
        }
        .onAppear {
            print("📱 ContentView onAppear - App appeared!")
            checkLoginStatus()
            
            // Test save system on app appear
            if isLoggedIn {
                print("🧪 TESTING SAVE SYSTEM - Current user: \(currentUsername)")
                print("🧪 GameStateManager isLoggedIn: \(gameStateManager.isLoggedIn)")
                print("🧪 GameStateManager currentUsername: \(gameStateManager.currentUsername)")
                
                // Add a visual indicator that we restored a session
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Show an alert or visual indicator that session was restored
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            print("📱 Scene phase changed to: \(phase)")
            switch phase {
            case .background:
                if isLoggedIn {
                    print("📱 App backgrounded - saving game state")
                    gameStateManager.saveGameState()
                } else {
                    print("📱 App backgrounded - not logged in, skipping save")
                }
            case .inactive:
                if isLoggedIn {
                    print("📱 App inactive - saving game state")
                    gameStateManager.saveGameState()
                } else {
                    print("📱 App inactive - not logged in, skipping save")
                }
            case .active:
                print("📱 App active - current login state: \(isLoggedIn)")
                if isLoggedIn {
                    print("📱 App active - checking session")
                    // Ensure session is still valid when app becomes active
                    checkLoginStatus()
                } else {
                    print("📱 App active - not logged in, will check on next onAppear")
                }
            @unknown default:
                print("📱 Unknown scene phase: \(phase)")
                break
            }
        }
    }
    
    private func checkLoginStatus() {
        print("🔍 ContentView checkLoginStatus - Starting...")
        print("🔍 ContentView checkLoginStatus - GameStateManager state: isLoggedIn=\(gameStateManager.isLoggedIn), username='\(gameStateManager.currentUsername)'")
        print("🔍 ContentView checkLoginStatus - showingProfile before sync: \(showingProfile)")
        
        // GameStateManager now handles session restoration automatically
        // Just sync the ContentView state with GameStateManager
        DispatchQueue.main.async {
            self.isLoggedIn = self.gameStateManager.isLoggedIn
            self.currentUsername = self.gameStateManager.currentUsername
            
            print("🔍 ContentView checkLoginStatus - ContentView state after sync: isLoggedIn=\(self.isLoggedIn), username='\(self.currentUsername)'")
            print("🔍 ContentView checkLoginStatus - showingProfile after sync: \(self.showingProfile)")
            
            if self.isLoggedIn && !self.currentUsername.isEmpty {
                // Connect GameState to GameStateManager
                self.gameState.gameStateManager = self.gameStateManager
                self.gameStateManager.gameState = self.gameState
                
                // Reset profile view to false when logging in
                self.showingProfile = false
                
                self.setupAutoSave()
                print("🔄 ContentView - Session restored for user: \(self.currentUsername)")
                
                // Force a game state load to ensure data is current
                print("🔄 ContentView - Forcing game state reload...")
                self.gameStateManager.loadGameState()
            } else {
                print("🔍 ContentView checkLoginStatus - No valid session found")
            }
        }
    }
    
    private func setupAutoSave() {
        // Auto-save every 30 seconds while logged in
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            if isLoggedIn {
                print("⏰ Auto-save triggered")
                gameStateManager.saveGameState()
            }
        }
    }
    
    // Save/load functions now handled by GameStateManager
    
    func logout() {
        print("🔍 LOGOUT - showingProfile before logout: \(showingProfile)")
        
        // GameStateManager handles saving and logout state
        gameStateManager.logout()
        
        // Sync ContentView state with GameStateManager
        isLoggedIn = gameStateManager.isLoggedIn
        currentUsername = gameStateManager.currentUsername
        
        // Close the profile view when logout is finalized
        showingProfile = false
        
        print("🔍 LOGOUT - showingProfile after logout: \(showingProfile)")
        print("✅ Logged out successfully - data preserved")
    }
    
    private var mainGameView: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top Bar (always visible)
                TopBarView(gameState: gameState, gameStateManager: gameStateManager, showXPInfo: $showXPInfo, showingProfile: $showingProfile, logoutAction: logout)
                
                // Main game area - conditional based on current page
                Group {
                    switch gameState.currentPage {
                    case .location:
                        LocationView(gameState: gameState)
                    case .construction:
                        ConstructionPageView(gameState: gameState)
                    case .starMap:
                        if gameState.showingLocationList {
                            StarMapView(gameState: gameState)
                        } else {
                            LocationView(gameState: gameState)
                        }
                    case .resources:
                        ResourcesPageView(gameState: gameState)
                    case .cards:
                        CardsView(gameState: gameState)
                    case .shop:
                        ShopView(gameState: gameState)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(nil, value: gameState.currentPage)
                
                // Bottom navigation
                BottomNavigationView(gameState: gameState)
            }
            
            // Resource pop out positioned above bottom navigation
            VStack {
                Spacer()
                    .allowsHitTesting(false)
                
                if gameState.showLocationResources && (gameState.currentPage == .location || (gameState.currentPage == .starMap && !gameState.showingLocationList)) {
                    HStack(alignment: .bottom, spacing: 0) {
                        Spacer()
                            .allowsHitTesting(false)
                        
                        // Toggle button on left side of resource box when open
                        Button(action: {
                            gameState.showLocationResources.toggle()
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .cornerRadius(6)
                        }
                        
                        // Resource box
                        LocationResourceListView(gameState: gameState)
                            .frame(width: UIScreen.main.bounds.width * 0.5)
                    }
                    .padding(.trailing, 0)
                    .padding(.bottom, 80) // Position well above navigation bar
                } else if (gameState.currentPage == .location || (gameState.currentPage == .starMap && !gameState.showingLocationList)) {
                    HStack {
                        Spacer()
                            .allowsHitTesting(false)
                        
                        // Toggle button on right side of screen when closed
                        Button(action: {
                            gameState.showLocationResources.toggle()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .cornerRadius(6)
                        }
                    }
                    .padding(.trailing, 0)
                    .padding(.bottom, 80) // Position well above navigation bar
                }
            }
            
            // Tap counter pop out positioned below location name
            VStack {
                if gameState.showTapCounter && (gameState.currentPage == .location || (gameState.currentPage == .starMap && !gameState.showingLocationList)) {
                    HStack(alignment: .bottom, spacing: 0) {
                        Spacer()
                            .allowsHitTesting(false)
                        
                        // Toggle button on left side of tap counter box when open
                        Button(action: {
                            gameState.showTapCounter.toggle()
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .cornerRadius(6)
                        }
                        
                        // Tap counter box
                        TapCounterView(gameState: gameState)
                            .frame(width: UIScreen.main.bounds.width * 0.3)
                    }
                    .padding(.trailing, 0)
                    .padding(.top, 100) // Position directly below top bar + location name
                } else if (gameState.currentPage == .location || (gameState.currentPage == .starMap && !gameState.showingLocationList)) {
                    HStack {
                        Spacer()
                            .allowsHitTesting(false)
                        
                        // Toggle button on right side of screen when closed
                        Button(action: {
                            gameState.showTapCounter.toggle()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .cornerRadius(6)
                        }
                    }
                    .padding(.trailing, 0)
                    .padding(.top, 100) // Position directly below top bar + location name
                }
                
                Spacer()
            }
        }
        .onAppear {
            print("🔍 CONTENT VIEW - onAppear called, showingProfile: \(showingProfile)")
            print("🔍 CONTENT VIEW - isLoggedIn: \(isLoggedIn), currentUsername: '\(currentUsername)'")
            gameState.startGame()
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView(gameState: gameState, currentUsername: currentUsername, logoutAction: logout)
        }
        .onAppear {
            print("🔍 SHEET - Profile sheet onAppear called, showingProfile: \(showingProfile)")
        }
        .onChange(of: showingProfile) { _, newValue in
            print("🔍 PROFILE VIEW - showingProfile changed to: \(newValue)")
        }
    }
}

// MARK: - Top Bar View
struct TopBarView: View {
    @ObservedObject var gameState: GameState
    @ObservedObject var gameStateManager: GameStateManager
    @Binding var showXPInfo: Bool
    @Binding var showingProfile: Bool
    let logoutAction: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            // Top row - Player name, gear, and currency
            HStack {
                // Left - Settings and Test Save - fixed width
                HStack {
                    Button(action: {
                        print("🧪 MANUAL SAVE TEST - Triggering save...")
                        gameStateManager.saveGameState()
                        print("🧪 MANUAL SAVE TEST - Save completed")
                    }) {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        showingProfile = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 100, alignment: .leading) // Match right side width for perfect centering
                
                Spacer()
                
                // Center - Player Name (bigger font) - perfectly centered
                Text(gameState.playerName)
                    .font(.title3)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Right - Currency (moved up) - fixed width
                HStack(spacing: 4) {
                    Image(systemName: "star.circle")
                        .foregroundColor(.yellow)
                    Text(gameState.getFormattedCurrency())
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(width: 100, alignment: .trailing) // Fixed width to prevent shifting
            }
            
            // Bottom row - Level, progress bar, and objectives (moved down)
            HStack(spacing: 8) {
                Spacer()
                
                Text("Level \(gameState.playerLevel)")
                    .font(.caption)
                    .foregroundColor(.white)
                
                // Level progress bar with tap tooltip
                ZStack {
                    ProgressView(value: gameState.getXPProgressPercentage())
                        .frame(width: 140, height: 12)
                        .tint(.green)
                        .allowsHitTesting(false) // Disable hit testing on ProgressView
                    
                    // Tap area for gesture - made slightly larger for easier tapping
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 150, height: 20) // Slightly larger tap area
                        .contentShape(Rectangle()) // Ensure the entire area is tappable
                        .onTapGesture {
                            showXPInfo.toggle()
                        }
                }
                .overlay(
                    // Tap tooltip
                    Group {
                        if showXPInfo {
                            VStack(spacing: 4) {
                                Text("Level \(gameState.playerLevel)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("\(gameState.playerXP) / \(gameState.getXPRequiredForNextLevel()) XP")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                
                                Text("\(Int(gameState.getXPProgressPercentage() * 100))% to next level")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                
                                // Tap to dismiss hint
                                Text("Tap to close")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.9))
                            .cornerRadius(8)
                            .offset(y: -60)
                            .animation(.easeInOut(duration: 0.2), value: showXPInfo)
                        }
                    },
                    alignment: .top
                )
                
                Button(action: {
                    gameState.showObjectives.toggle()
                }) {
                    Image(systemName: "target")
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
}

// MARK: - Header View (for location info)
struct HeaderView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 8) {
            Text(gameState.currentLocation.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text("\(gameState.currentLocation.system) • \(gameState.currentLocation.kind.rawValue)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Tap counter with reset button (conditionally shown)
            if gameState.showTapCounter && (gameState.currentPage == .location || (gameState.currentPage == .starMap && !gameState.showingLocationList)) {
                HStack {
                    Text("Taps: \(gameState.currentLocationTapCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Reset") {
                        gameState.resetCurrentLocationTapCount()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            // Toggle button for tap counter (only on location page)
            if gameState.currentPage == .location || (gameState.currentPage == .starMap && !gameState.showingLocationList) {
                HStack {
                    Spacer()
                    Button(action: {
                        gameState.showTapCounter.toggle()
                    }) {
                        Image(systemName: gameState.showTapCounter ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(4)
                    }
                    Spacer()
                }
            }
            
            HStack {
                ForEach(gameState.resources.filter { $0.amount > 0 }.prefix(5), id: \.type) { resource in
                    ResourceBadge(resource: resource)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Location View
struct LocationView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        ZStack {
            // Full screen background
            Color.clear
            
            VStack {
                // Location name header
                HStack {
                    // Developer button
                    Button(action: {
                        addDeveloperResources()
                    }) {
                        Text("DEV")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    Text(gameState.currentLocation.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    
                    // Invisible spacer to balance the layout
                    Color.clear
                        .frame(width: 40, height: 20)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.3))
                
                Spacer()
                
                // Centered clickable location (positioned based on tap counter visibility)
                Spacer()
                    .frame(height: 10)
                ZStack {
                    if gameState.currentLocation.id == "elcinto" {
                        AlphaHitTestButton(imageName: "Elcinto", alphaThreshold: 0.1) {
                            gameState.tapLocation()
                        }
                        .frame(width: 240, height: 240) // 80% of 300x300
                    } else if gameState.currentLocation.id == "taragam-3" {
                        AlphaHitTestButton(imageName: "Taragam3", alphaThreshold: 0.1) {
                            gameState.tapLocation()
                        }
                        .frame(width: 390, height: 390) // 30% bigger than Taragam-7
                    } else if gameState.currentLocation.id == "abandoned-star-ship" {
                        AlphaHitTestButton(imageName: "AbandonedStarship", alphaThreshold: 0.1) {
                            gameState.tapLocation()
                        }
                        .frame(width: 273, height: 273) // 30% smaller than Taragam-3
                    } else if gameState.currentLocation.id == "taragon-gamma" {
                        AlphaHitTestButton(imageName: "TargonGamma", alphaThreshold: 0.1) {
                            gameState.tapLocation()
                        }
                        .frame(width: 360, height: 360) // Same as Taragam-7 to avoid layout issues
                    } else {
                        AlphaHitTestButton(imageName: "Taragam7", alphaThreshold: 0.1) {
                            gameState.tapLocation()
                        }
                        .frame(width: 360, height: 360) // 20% bigger than original 300
                    }
                    
                    // Collection feedback (tap)
                    if gameState.showCollectionFeedback, let resource = gameState.lastCollectedResource {
                        VStack {
                            Text("+1")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            
                            Text(resource.rawValue)
                                .font(.caption)
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                        }
                        .padding(8)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                        .offset(y: -80)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: gameState.showCollectionFeedback)
                        .allowsHitTesting(false)
                    }
                    
                    // Idle collection feedback
                    if gameState.showIdleCollectionFeedback, let resource = gameState.lastIdleCollectedResource {
                        VStack {
                            Text("+1")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Text(resource.rawValue)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .multilineTextAlignment(.center)
                            
                            Text("(Idle)")
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                        .offset(y: -120)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: gameState.showIdleCollectionFeedback)
                        .allowsHitTesting(false)
                    }
                    
                    // Numins collection feedback
                    if gameState.showNuminsFeedback {
                        VStack {
                            Text("+\(gameState.lastNuminsAmount)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                            
                            Text("Numins")
                                .font(.caption)
                                .foregroundColor(.yellow)
                                .multilineTextAlignment(.center)
                            
                            Text("(Bonus!)")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                                .fontWeight(.medium)
                        }
                        .padding(8)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(8)
                        .offset(y: -160)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: gameState.showNuminsFeedback)
                        .allowsHitTesting(false)
                    }
                    
                    // XP collection feedback
                    if gameState.showXPFeedback {
                        VStack {
                            Text("+\(gameState.lastXPAmount)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            
                            Text("XP")
                                .font(.caption)
                                .foregroundColor(.purple)
                                .multilineTextAlignment(.center)
                            
                            Text("(Experience!)")
                                .font(.caption2)
                                .foregroundColor(.purple)
                                .fontWeight(.medium)
                        }
                        .padding(8)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(8)
                        .offset(y: -200)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: gameState.showXPFeedback)
                        .allowsHitTesting(false)
                    }
                }
                
                Spacer()
            }
            
            // Enhancement slots overlay - positioned at bottom without affecting layout
            VStack {
                Spacer()
                
                // Enhancement button - always visible
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        gameState.showLocationSlots.toggle()
                    }
                }) {
                    HStack {
                        Text("Enhancements")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.black)
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Enhancement slots - shown conditionally with animation
                if gameState.showLocationSlots {
                    LocationSlotsView(gameState: gameState)
                        .padding(.bottom, 10) // Position just above navigation bar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func addDeveloperResources() {
        // Add 100 resources based on current location's drop table distribution
        let dropTable = gameState.getLocationDropTable()
        let totalToAdd = 100
        
        for _ in 0..<totalToAdd {
            let selectedResource = gameState.selectResourceFromDropTable(dropTable)
            
            if let existingIndex = gameState.resources.firstIndex(where: { $0.type == selectedResource }) {
                gameState.resources[existingIndex].amount += 1
            } else {
                let newResource = Resource(
                    type: selectedResource,
                    amount: 1,
                    icon: gameState.getResourceIcon(for: selectedResource),
                    color: gameState.getResourceColor(for: selectedResource)
                )
                gameState.resources.append(newResource)
            }
        }
        
        // Also add some Numins for construction testing
        gameState.currency += 1000
    }
}

// MARK: - Location Slots View
struct LocationSlotsView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { index in
                    LocationSlotView(slotIndex: index, gameState: gameState)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

struct LocationSlotView: View {
    let slotIndex: Int
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 4) {
            // Slot container
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                .frame(width: 60, height: 80)
                .overlay(
                    VStack {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(.gray.opacity(0.6))
                        
                        Text("Slot \(slotIndex + 1)")
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                )
        }
    }
}


// MARK: - Resources Slots View
struct ResourcesSlotsView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { index in
                    ResourcesSlotView(slotIndex: index, gameState: gameState)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

struct ResourcesSlotView: View {
    let slotIndex: Int
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 4) {
            // Slot container
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                .frame(width: 60, height: 80)
                .overlay(
                    VStack {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(.gray.opacity(0.6))
                        
                        Text("Slot \(slotIndex + 1)")
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                )
        }
    }
}

// MARK: - Shop Slots View
struct ShopSlotsView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { index in
                    ShopSlotView(slotIndex: index, gameState: gameState)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

struct ShopSlotView: View {
    let slotIndex: Int
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 4) {
            // Slot container
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                .frame(width: 60, height: 80)
                .overlay(
                    VStack {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(.gray.opacity(0.6))
                        
                        Text("Slot \(slotIndex + 1)")
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                )
        }
    }
}

// MARK: - Cards Slots View
struct CardsSlotsView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { index in
                    CardsSlotView(slotIndex: index, gameState: gameState)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

struct CardsSlotView: View {
    let slotIndex: Int
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 4) {
            // Slot container
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                .frame(width: 60, height: 80)
                .overlay(
                    VStack {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(.gray.opacity(0.6))
                        
                        Text("Slot \(slotIndex + 1)")
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                )
        }
    }
}

// MARK: - Location Resource List View
struct LocationResourceListView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Available Resources Section
            VStack(alignment: .leading, spacing: 2) {
                Text("Available Resources")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.bottom, 2)
                
                ForEach(gameState.getLocationDropTable(), id: \.0) { resourceType, percentage in
                    HStack(spacing: 2) {
                        // Resource icon
                        Image(systemName: getResourceIcon(for: resourceType))
                            .foregroundColor(getResourceColor(for: resourceType))
                            .frame(width: 16)
                            .font(.caption)
                        
                        // Resource name
                        Text(resourceType.rawValue)
                            .font(.caption2)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Percentage
                        Text("\(Int(percentage))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 1)
                }
            }
            
            // Additional Chances Section (Tap-based)
            VStack(alignment: .leading, spacing: 2) {
                Text("Additional Chances")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.yellow)
                    .padding(.top, 4)
                
                // Numins chance
                HStack(spacing: 2) {
                    Image(systemName: "star.circle")
                        .foregroundColor(.yellow)
                        .frame(width: 16)
                        .font(.caption)
                    
                    Text("Numins")
                        .font(.caption2)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    let numinsRange = gameState.getCurrentTapNuminsRange()
                    let numinsChance = gameState.getCurrentTapNuminsChance()
                    let numinsChanceText = numinsChance < 1.0 ? String(format: "%.1f", numinsChance) : "\(Int(numinsChance))"
                    Text("\(numinsChanceText)% (\(numinsRange.min)-\(numinsRange.max))")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.vertical, 1)
                
                // XP chance
                HStack(spacing: 2) {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 16)
                        .font(.caption)
                    
                    Text("XP")
                        .font(.caption2)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    let xpChance = gameState.getCurrentTapXPChance()
                    let xpChanceText = xpChance < 1.0 ? String(format: "%.1f", xpChance) : "\(Int(xpChance))"
                    Text("\(xpChanceText)% (\(gameState.getCurrentTapXPAmount()))")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.vertical, 1)
                
                // Cards chance (only for Taragam-7)
                if gameState.currentLocation.id == "taragam-7" {
                    HStack(spacing: 2) {
                        Image(systemName: "rectangle.stack.fill")
                            .foregroundColor(.purple)
                            .frame(width: 16)
                            .font(.caption)
                        
                        Text("Cards")
                            .font(.caption2)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        let cardAbbrevs = gameState.getLocationCardAbbreviations()
                        let cardChance = gameState.getCurrentTapCardChance()
                        let cardChanceText = cardChance < 1.0 ? String(format: "%.1f", cardChance) : "\(Int(cardChance))"
                        Text("\(cardChanceText)% (\(cardAbbrevs.joined(separator: ", ")))")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 1)
                }
            }
            
            // Idle Chances Section
            VStack(alignment: .leading, spacing: 2) {
                Text("Idle Chances")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .padding(.top, 4)
                
                // Idle resources chance
                HStack(spacing: 2) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.green)
                        .frame(width: 16)
                        .font(.caption)
                    
                    Text("Resources")
                        .font(.caption2)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    let idleResourceChance = gameState.getCurrentIdleResourceChance()
                    let idleResourceChanceText = idleResourceChance < 1.0 ? String(format: "%.1f", idleResourceChance) : "\(Int(idleResourceChance))"
                    Text("\(idleResourceChanceText)%/sec")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.vertical, 1)
                
                // Idle Numins chance
                HStack(spacing: 2) {
                    Image(systemName: "star.circle")
                        .foregroundColor(.yellow)
                        .frame(width: 16)
                        .font(.caption)
                    
                    Text("Numins")
                        .font(.caption2)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    let idleNuminsRange = gameState.getCurrentIdleNuminsRange()
                    let idleNuminsChance = gameState.getCurrentIdleNuminsChance()
                    let idleNuminsChanceText = idleNuminsChance < 1.0 ? String(format: "%.1f", idleNuminsChance) : "\(Int(idleNuminsChance))"
                    Text("\(idleNuminsChanceText)%/sec (\(idleNuminsRange.min)-\(idleNuminsRange.max))")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.vertical, 1)
            }
        }
        .padding(8)
        .background(Color.black)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray, lineWidth: 1)
        )
        .cornerRadius(6)
    }
    
    private func getResourceIcon(for type: ResourceType) -> String {
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
        case .energy: return "bolt.fill"
        case .radiation: return "waveform"
        case .heat: return "flame.fill"
        case .light: return "sun.max.fill"
        case .gravity: return "arrow.down.circle.fill"
        case .magnetic: return "magnet"
        case .solar: return "sun.max.fill"
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
        case .copper: return "circle.fill"
        case .gold: return "star.fill"
        case .lithium: return "battery.100"
        }
    }
    
    private func getResourceColor(for type: ResourceType) -> Color {
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
        case .element: return .blue
        case .isotope: return .green
        case .energy: return .yellow
        case .radiation: return .orange
        case .heat: return .red
        case .light: return .yellow
        case .gravity: return .purple
        case .magnetic: return .blue
        case .solar: return .yellow
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
        case .copper: return .orange
        case .gold: return .yellow
        case .lithium: return .gray
        }
    }
}

// MARK: - Tap Counter View
struct TapCounterView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        HStack(spacing: 4) {
            Text("Tap Count:")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text("\(gameState.currentLocationTapCount)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(Color.black)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray, lineWidth: 1)
        )
        .cornerRadius(6)
    }
}

// MARK: - Construction View
struct ConstructionView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Construction Bays")
                .font(.headline)
            
            if gameState.constructionBays.isEmpty {
                Text("No construction bays available")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(gameState.constructionBays) { bay in
                    ConstructionBayRow(bay: bay, gameState: gameState)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Construction Bay Row
struct ConstructionBayRow: View {
    let bay: ConstructionBay
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(bay.size.rawValue) Bay")
                    .fontWeight(.medium)
                
                Spacer()
                
                if bay.currentConstruction != nil {
                    Text("In Use")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Empty")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            if let construction = bay.currentConstruction {
                HStack {
                    VStack(alignment: .leading) {
                        Text(construction.blueprint.name)
                            .fontWeight(.medium)
                        Text("Time remaining: \(Int(construction.timeRemaining))s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    ProgressView(value: construction.progress)
                        .frame(width: 100)
                }
            } else {
                if bay.isUnlocked {
                    Button("+") {
                        gameState.showConstructionMenu = true
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.green)
                } else {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Locked")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Resources View
struct ResourcesView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resources")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(gameState.resources, id: \.type) { resource in
                    ResourceCard(resource: resource, gameState: gameState)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Resource Card
struct ResourceCard: View {
    let resource: Resource
    @ObservedObject var gameState: GameState
    
    var body: some View {
        ZStack {
            VStack(spacing: 4) {
                if resource.amount > 0 {
                    Image(systemName: resource.icon)
                        .font(.title2)
                        .foregroundColor(resource.color)
                
                    Text("\(Int(resource.amount))")
                        .font(.caption)
                        .foregroundColor(.white)
                } else {
                    // Empty slot - show nothing or a placeholder
                    Image(systemName: "square")
                        .font(.title2)
                        .foregroundColor(.clear)
                    
                    Text("")
                        .font(.caption)
                }
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .cornerRadius(8)
            
            // Rarity indicator overlay in top right corner
            if resource.amount > 0 {
                let rarity = gameState.getResourceRarity(for: resource.type)
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: rarity.icon)
                            .font(.caption2)
                            .foregroundColor(rarity.color)
                            .padding(.top, 4)
                            .padding(.trailing, 4)
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Resource Deletion Controls
struct ResourceDeletionControls: View {
    let resource: Resource
    @ObservedObject var gameState: GameState
    @State private var amountToDelete: Int = 1
    @State private var showDeleteConfirmation = false
    @State private var isHoldingMinus = false
    @State private var isHoldingPlus = false
    @State private var holdTimer: Timer?
    @State private var holdSpeed: Double = 0.5 // Start slow, will accelerate
    
    var body: some View {
        // Only show deletion controls if the resource is NOT Numins
        if resource.type != .numins {
            HStack(spacing: 8) {
                // Delete button (leftmost)
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.caption)
                        Text("Delete")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(6)
                }
                .disabled(amountToDelete <= 0 || amountToDelete > Int(resource.amount))
                
                Spacer()
                
                // Max button
                Button("Max") {
                    amountToDelete = Int(resource.amount)
                }
                .font(.caption2)
                .foregroundColor(.blue)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(4)
                
                // Plus button with hold functionality
                Button(action: {
                    if amountToDelete < Int(resource.amount) {
                        amountToDelete += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
                .disabled(amountToDelete >= Int(resource.amount))
                .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 50) {
                    // Long press started
                } onPressingChanged: { pressing in
                    if pressing && amountToDelete < Int(resource.amount) {
                        startHoldIncrement(isIncrement: true)
                    } else {
                        stopHoldIncrement()
                    }
                }
                
                // Amount display
                Text("\(amountToDelete)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(minWidth: 30)
                
                // Minus button with hold functionality
                Button(action: {
                    if amountToDelete > 1 {
                        amountToDelete -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                }
                .disabled(amountToDelete <= 1)
                .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 50) {
                    // Long press started
                } onPressingChanged: { pressing in
                    if pressing && amountToDelete > 1 {
                        startHoldIncrement(isIncrement: false)
                    } else {
                        stopHoldIncrement()
                    }
                }
                
                // Min button
                Button("Min") {
                    amountToDelete = 1
                }
                .font(.caption2)
                .foregroundColor(.blue)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(4)
            }
            .alert("Delete \(amountToDelete) \(amountToDelete == 1 ? "unit" : "units")?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    gameState.deleteResource(resource.type, amount: amountToDelete)
                    amountToDelete = 1 // Reset to 1 after deletion
                }
            }
        } else {
            // Return empty view for Numins
            EmptyView()
        }
    }
    
    private func startHoldIncrement(isIncrement: Bool) {
        holdSpeed = 0.5 // Start slow
        holdTimer = Timer.scheduledTimer(withTimeInterval: holdSpeed, repeats: true) { _ in
            if isIncrement {
                if amountToDelete < Int(resource.amount) {
                    amountToDelete += 1
                } else {
                    stopHoldIncrement()
                }
            } else {
                if amountToDelete > 1 {
                    amountToDelete -= 1
                } else {
                    stopHoldIncrement()
                }
            }
            
            // Accelerate the timer (decrease interval)
            holdSpeed = max(0.05, holdSpeed * 0.9) // Speed up, but don't go below 0.05 seconds
            holdTimer?.invalidate()
            startHoldIncrement(isIncrement: isIncrement)
        }
    }
    
    private func stopHoldIncrement() {
        holdTimer?.invalidate()
        holdTimer = nil
        holdSpeed = 0.5 // Reset speed for next hold
    }
}

// MARK: - Empty Resource Card (placeholder for future resources)
struct EmptyResourceCard: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "questionmark.square")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("???")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
        )
        .cornerRadius(8)
    }
}

// MARK: - Blank Resource Card (for uncollected resources)
struct BlankResourceCard: View {
    var body: some View {
        VStack(spacing: 4) {
            // Completely blank - no icon or text
            Spacer()
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
        )
        .cornerRadius(8)
    }
}

// MARK: - Resource Badge
struct ResourceBadge: View {
    let resource: Resource
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: resource.icon)
                .foregroundColor(resource.color)
            Text("\(resource.amount)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Bottom Navigation
struct BottomNavigationView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        HStack {
            Button(action: {
                gameState.currentPage = .shop
            }) {
                Image(systemName: "cart.fill")
                    .font(.title2)
                    .foregroundColor(gameState.currentPage == .shop ? .blue : .white)
            }
            
            Spacer()
            
            Button(action: {
                gameState.currentPage = .construction
            }) {
                Image(systemName: "hammer.fill")
                    .font(.title2)
                    .foregroundColor(gameState.currentPage == .construction ? .blue : .white)
            }
            
            Spacer()
            
            Button(action: {
                if gameState.currentPage == .starMap {
                    gameState.showingLocationList.toggle()
                } else {
                    gameState.currentPage = .starMap
                    gameState.showingLocationList = false
                }
            }) {
                Image(systemName: "globe")
                    .font(.title2)
                    .foregroundColor(gameState.currentPage == .starMap ? .blue : .white)
            }
            
            Spacer()
            
            Button(action: {
                gameState.currentPage = .resources
            }) {
                Image(systemName: "cube.box.fill")
                    .font(.title2)
                    .foregroundColor(gameState.currentPage == .resources ? .blue : .white)
            }
            
            Spacer()
            
            Button(action: {
                gameState.currentPage = .cards
            }) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.title2)
                    .foregroundColor(gameState.currentPage == .cards ? .blue : .white)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.3))
        .sheet(isPresented: $gameState.showObjectives) {
            ObjectivesView(gameState: gameState)
        }
        .sheet(isPresented: $gameState.showConstructionMenu) {
            ConstructionMenuView(gameState: gameState)
        }
    }
}

// MARK: - Construction Menu
struct ConstructionMenuView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @State private var expandedBlueprints: Set<String> = []
    
    var body: some View {
        NavigationView {
            List {
                ForEach(ConstructionBlueprint.allBlueprints, id: \.id) { blueprint in
                    CollapsibleBlueprintView(
                        blueprint: blueprint,
                        gameState: gameState,
                        isExpanded: expandedBlueprints.contains(blueprint.id),
                        onToggle: {
                            if expandedBlueprints.contains(blueprint.id) {
                                expandedBlueprints.remove(blueprint.id)
                            } else {
                                expandedBlueprints.insert(blueprint.id)
                            }
                        },
                        onStartConstruction: {
                            gameState.startConstruction(blueprint: blueprint)
                            dismiss()
                        }
                    )
                }
            }
            .navigationTitle("Construction Blueprints")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func hasEnoughResource(_ resourceType: ResourceType, _ requiredAmount: Double) -> Bool {
        if let resource = gameState.resources.first(where: { $0.type == resourceType }) {
            return resource.amount >= requiredAmount
        }
        return false
    }
    
    private func getPlayerResourceAmount(_ resourceType: ResourceType) -> Double {
        if let resource = gameState.resources.first(where: { $0.type == resourceType }) {
            return resource.amount
        }
        return 0
    }
}

// MARK: - Collapsible Blueprint View
struct CollapsibleBlueprintView: View {
    let blueprint: ConstructionBlueprint
    @ObservedObject var gameState: GameState
    let isExpanded: Bool
    let onToggle: () -> Void
    let onStartConstruction: () -> Void
    
    private var canAfford: Bool {
        gameState.canAffordConstruction(blueprint: blueprint)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with expand/collapse button
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(blueprint.name)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(blueprint.xpReward) XP")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                        }
                        
                        HStack {
                            Text(blueprint.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(blueprint.duration))s")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Status line when collapsed
                        if !isExpanded {
                            HStack {
                                Text(canAfford ? "Ready to Construct" : "Missing Requirements")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(canAfford ? .green : .red)
                                Spacer()
                            }
                        }
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    // Resource requirements with color coding
                    ForEach(Array(blueprint.cost.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { resourceType in
                        if let requiredAmount = blueprint.cost[resourceType] {
                            HStack {
                                Image(systemName: getResourceIcon(for: resourceType))
                                    .foregroundColor(getResourceColor(for: resourceType))
                                    .frame(width: 16)
                                Text(resourceType.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("(\(Int(getPlayerResourceAmount(resourceType)))/\(Int(requiredAmount)))")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(hasEnoughResource(resourceType, requiredAmount) ? .green : .red)
                            }
                        }
                    }
                    
                    // Currency requirement with color coding
                    HStack {
                        Image(systemName: "star.circle")
                            .foregroundColor(.yellow)
                            .frame(width: 16)
                        Text("Numins")
                            .font(.caption)
                            .foregroundColor(.white)
                        Spacer()
                        Text("(\(blueprint.currencyCost))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(gameState.currency >= blueprint.currencyCost ? .green : .red)
                    }
                    
                    // Start construction button
                    Button(action: onStartConstruction) {
                        HStack {
                            Spacer()
                            Text("Start Construction")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .background(canAfford ? Color.blue : Color.gray)
                        .cornerRadius(6)
                    }
                    .disabled(!canAfford)
                }
                .padding(.top, 4)
            }
        }
        .opacity(canAfford ? 1.0 : 0.5)
    }
    
    private func hasEnoughResource(_ resourceType: ResourceType, _ requiredAmount: Double) -> Bool {
        if let resource = gameState.resources.first(where: { $0.type == resourceType }) {
            return resource.amount >= requiredAmount
        }
        return false
    }
    
    private func getPlayerResourceAmount(_ resourceType: ResourceType) -> Double {
        if let resource = gameState.resources.first(where: { $0.type == resourceType }) {
            return resource.amount
        }
        return 0
    }
    
    private func getResourceIcon(for type: ResourceType) -> String {
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
        }
    }
    
    private func getResourceColor(for type: ResourceType) -> Color {
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
        }
    }
}

// MARK: - Construction Page View
struct ConstructionPageView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Construction Bays Header
                HStack {
                    Text("Construction Bays")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    
                    // Dev Tool Button - fixed position
                    Button(action: {
                        gameState.showDevToolsDropdown.toggle()
                    }) {
                        Text("DEV")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 20)
            
            // Content area with fixed height
            VStack(spacing: 24) {
                // Small Bays Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Small Bays")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    GeometryReader { geometry in
                        HStack(spacing: 12) {
                            ForEach(0..<4, id: \.self) { index in
                                SmallBaySlotView(slotIndex: index, gameState: gameState, availableWidth: geometry.size.width - 32)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 100)
                }
                
                // Medium Bays Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Medium Bays")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    GeometryReader { geometry in
                        HStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { index in
                                MediumBaySlotView(slotIndex: index, gameState: gameState, availableWidth: geometry.size.width - 32)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 120)
                }
                
                // Large Bays Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Large Bays")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    GeometryReader { geometry in
                        HStack(spacing: 12) {
                            ForEach(0..<2, id: \.self) { index in
                                LargeBaySlotView(slotIndex: index, gameState: gameState, availableWidth: geometry.size.width - 32)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 140)
                }
                
                Spacer()
            }
            }
            
            // Dropdown Overlay - positioned absolutely
            if gameState.showDevToolsDropdown {
                VStack {
                    HStack {
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // Bay Unlock Toggle
                            HStack {
                                Text("Unlock All Bays")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { gameState.devToolUnlockAllBays },
                                    set: { _ in gameState.toggleBayUnlock() }
                                ))
                                .toggleStyle(SwitchToggleStyle(tint: .green))
                                .scaleEffect(0.8)
                            }
                            
                            // Buildable Without Ingredients Toggle
                            HStack {
                                Text("Build Without Ingredients")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Spacer()
                                Toggle("", isOn: $gameState.devToolBuildableWithoutIngredients)
                                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                                    .scaleEffect(0.8)
                            }
                            
                            // Complete All Constructions Button
                            Button(action: {
                                gameState.completeAllConstructions()
                                gameState.showDevToolsDropdown = false
                            }) {
                                Text("Complete All Constructions")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.8))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(12)
                        .background(Color.black.opacity(0.9))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .frame(width: 200) // Fixed width instead of full screen
                        .padding(.trailing, 16)
                    }
                    .padding(.top, 60) // Position below the header
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    // Invisible background to catch taps outside the dropdown
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Close dropdown when tapping outside
                            gameState.showDevToolsDropdown = false
                        }
                )
                .zIndex(1000)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Bay Slot Views
struct SmallBaySlotView: View {
    let slotIndex: Int
    @ObservedObject var gameState: GameState
    let availableWidth: CGFloat
    @State private var isCollecting = false
    
    private var bay: ConstructionBay? {
        let bayId = "small-bay-\(slotIndex + 1)"
        return gameState.constructionBays.first { $0.id == bayId }
    }
    
    private var isUnderConstruction: Bool {
        bay?.currentConstruction != nil
    }
    
    private var isCompleted: Bool {
        guard let construction = bay?.currentConstruction else { return false }
        return construction.timeRemaining <= 0
    }
    
    var body: some View {
        Button(action: {
            if let bay = bay, bay.isUnlocked {
                if isCompleted {
                    // Collect completed item
                    collectCompletedItem()
                } else if !isUnderConstruction {
                    // Start construction
                    gameState.showConstructionMenu = true
                }
            }
        }) {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCompleted ? Color.yellow : Color.gray.opacity(0.5), lineWidth: 2)
                .frame(width: (availableWidth - 36) / 4, height: (availableWidth - 36) / 4)
                .background(isCompleted ? Color.yellow.opacity(0.2) : Color.clear)
                .overlay(
                    Group {
                        if isUnderConstruction {
                            VStack(spacing: 4) {
                                // Construction name
                                Text(bay?.currentConstruction?.blueprint.name ?? "")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                // Construction icon
                                Image(systemName: getResourceIcon(for: bay?.currentConstruction?.blueprint.reward.keys.first ?? .ironOre))
                                    .font(.caption)
                                    .foregroundColor(getResourceColor(for: bay?.currentConstruction?.blueprint.reward.keys.first ?? .ironOre))
                                
                                if isCompleted {
                                    // Complete text
                                    Text("Complete")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                } else {
                                    // Progress bar
                                    ProgressView(value: bay?.currentConstruction?.progress ?? 0)
                                        .frame(width: 40, height: 4)
                                        .tint(.blue)
                                    
                                    // Countdown timer
                                    Text("\(Int(bay?.currentConstruction?.timeRemaining ?? 0))s")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                            }
                        } else if let bay = bay, bay.isUnlocked {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.gray.opacity(0.6))
                        } else {
                            Image(systemName: "star.circle")
                                .font(.title2)
                                .foregroundColor(.yellow)
                        }
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(bay?.isUnlocked != true && !isCompleted)
        .scaleEffect(isCollecting ? 0.8 : 1.0)
        .opacity(isCollecting ? 0.5 : 1.0)
    }
    
    private func collectCompletedItem() {
        guard let bay = bay, let construction = bay.currentConstruction else { return }
        
        // Start collection animation
        withAnimation(.easeInOut(duration: 0.5)) {
            isCollecting = true
        }
        
        // Delay the actual collection to allow animation to play
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Add rewards to player resources
            for (resourceType, amount) in construction.blueprint.reward {
                if let existingIndex = gameState.resources.firstIndex(where: { $0.type == resourceType }) {
                    gameState.resources[existingIndex].amount += amount
                } else {
                    let newResource = Resource(
                        type: resourceType,
                        amount: amount,
                        icon: getResourceIcon(for: resourceType),
                        color: getResourceColor(for: resourceType)
                    )
                    gameState.resources.append(newResource)
                }
            }
            
            // Clear the construction
            if let bayIndex = gameState.constructionBays.firstIndex(where: { $0.id == bay.id }) {
                gameState.constructionBays[bayIndex].currentConstruction = nil
            }
            
            // Award XP
            gameState.addXP(construction.blueprint.xpReward)
            
            // Check for location unlocks
            gameState.checkLocationUnlocks()
            
            // Reset animation state
            isCollecting = false
        }
    }
    
    private func getResourceIcon(for type: ResourceType) -> String {
        switch type {
        case .ironOre: return "cube.fill"
        case .silicon: return "diamond.fill"
        case .water: return "drop.fill"
        case .oxygen: return "wind"
        case .graphite: return "diamond.fill"
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
        case .copper: return "circle.fill"
        case .gold: return "star.fill"
        case .lithium: return "battery.100"
        default: return "questionmark.circle"
        }
    }
    
    private func getResourceColor(for type: ResourceType) -> Color {
        switch type {
        case .ironOre: return .gray
        case .silicon: return .purple
        case .water: return .blue
        case .oxygen: return .cyan
        case .graphite: return .gray
        case .steelPylons: return .orange
        default: return .gray
        }
    }
}

struct MediumBaySlotView: View {
    let slotIndex: Int
    @ObservedObject var gameState: GameState
    let availableWidth: CGFloat
    @State private var isCollecting = false
    
    private var bay: ConstructionBay? {
        let bayId = "medium-bay-\(slotIndex + 1)"
        return gameState.constructionBays.first { $0.id == bayId }
    }
    
    private var isUnderConstruction: Bool {
        bay?.currentConstruction != nil
    }
    
    private var isCompleted: Bool {
        guard let construction = bay?.currentConstruction else { return false }
        return construction.timeRemaining <= 0
    }
    
    var body: some View {
        Button(action: {
            if let bay = bay, bay.isUnlocked {
                if isCompleted {
                    // Collect completed item
                    collectCompletedItem()
                } else if !isUnderConstruction {
                    // Start construction
                    gameState.showConstructionMenu = true
                }
            }
        }) {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCompleted ? Color.yellow : Color.gray.opacity(0.5), lineWidth: 2)
                .frame(width: (availableWidth - 24) / 3, height: (availableWidth - 24) / 3)
                .background(isCompleted ? Color.yellow.opacity(0.2) : Color.clear)
                .overlay(
                    Group {
                        if isUnderConstruction {
                            VStack(spacing: 4) {
                                // Construction name
                                Text(bay?.currentConstruction?.blueprint.name ?? "")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                // Construction icon
                                Image(systemName: getResourceIcon(for: bay?.currentConstruction?.blueprint.reward.keys.first ?? .ironOre))
                                    .font(.caption)
                                    .foregroundColor(getResourceColor(for: bay?.currentConstruction?.blueprint.reward.keys.first ?? .ironOre))
                                
                                if isCompleted {
                                    // Complete text
                                    Text("Complete")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                } else {
                                    // Progress bar
                                    ProgressView(value: bay?.currentConstruction?.progress ?? 0)
                                        .frame(width: 40, height: 4)
                                        .tint(.blue)
                                    
                                    // Countdown timer
                                    Text("\(Int(bay?.currentConstruction?.timeRemaining ?? 0))s")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                            }
                        } else if let bay = bay, bay.isUnlocked {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.gray.opacity(0.6))
                        } else {
                            Image(systemName: "star.circle")
                                .font(.title2)
                                .foregroundColor(.yellow)
                        }
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(bay?.isUnlocked != true && !isCompleted)
        .scaleEffect(isCollecting ? 0.8 : 1.0)
        .opacity(isCollecting ? 0.5 : 1.0)
    }
    
    private func collectCompletedItem() {
        guard let bay = bay, let construction = bay.currentConstruction else { return }
        
        // Start collection animation
        withAnimation(.easeInOut(duration: 0.5)) {
            isCollecting = true
        }
        
        // Delay the actual collection to allow animation to play
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Add rewards to player resources
            for (resourceType, amount) in construction.blueprint.reward {
                if let existingIndex = gameState.resources.firstIndex(where: { $0.type == resourceType }) {
                    gameState.resources[existingIndex].amount += amount
                } else {
                    let newResource = Resource(
                        type: resourceType,
                        amount: amount,
                        icon: getResourceIcon(for: resourceType),
                        color: getResourceColor(for: resourceType)
                    )
                    gameState.resources.append(newResource)
                }
            }
            
            // Clear the construction
            if let bayIndex = gameState.constructionBays.firstIndex(where: { $0.id == bay.id }) {
                gameState.constructionBays[bayIndex].currentConstruction = nil
            }
            
            // Award XP
            gameState.addXP(construction.blueprint.xpReward)
            
            // Check for location unlocks
            gameState.checkLocationUnlocks()
            
            // Reset animation state
            isCollecting = false
        }
    }
    
    private func getResourceIcon(for type: ResourceType) -> String {
        switch type {
        case .ironOre: return "cube.fill"
        case .silicon: return "diamond.fill"
        case .water: return "drop.fill"
        case .oxygen: return "wind"
        case .graphite: return "diamond.fill"
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
        case .copper: return "circle.fill"
        case .gold: return "star.fill"
        case .lithium: return "battery.100"
        default: return "questionmark.circle"
        }
    }
    
    private func getResourceColor(for type: ResourceType) -> Color {
        switch type {
        case .ironOre: return .gray
        case .silicon: return .purple
        case .water: return .blue
        case .oxygen: return .cyan
        case .graphite: return .gray
        case .steelPylons: return .orange
        default: return .gray
        }
    }
}

struct LargeBaySlotView: View {
    let slotIndex: Int
    @ObservedObject var gameState: GameState
    let availableWidth: CGFloat
    @State private var isCollecting = false
    
    private var bay: ConstructionBay? {
        let bayId = "large-bay-\(slotIndex + 1)"
        return gameState.constructionBays.first { $0.id == bayId }
    }
    
    private var isUnderConstruction: Bool {
        bay?.currentConstruction != nil
    }
    
    private var isCompleted: Bool {
        guard let construction = bay?.currentConstruction else { return false }
        return construction.timeRemaining <= 0
    }
    
    var body: some View {
        Button(action: {
            if let bay = bay, bay.isUnlocked {
                if isCompleted {
                    // Collect completed item
                    collectCompletedItem()
                } else if !isUnderConstruction {
                    // Start construction
                    gameState.showConstructionMenu = true
                }
            }
        }) {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCompleted ? Color.yellow : Color.gray.opacity(0.5), lineWidth: 2)
                .frame(width: (availableWidth - 12) / 2, height: (availableWidth - 12) / 2)
                .background(isCompleted ? Color.yellow.opacity(0.2) : Color.clear)
                .overlay(
                    Group {
                        if isUnderConstruction {
                            VStack(spacing: 4) {
                                // Construction name
                                Text(bay?.currentConstruction?.blueprint.name ?? "")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                // Construction icon
                                Image(systemName: getResourceIcon(for: bay?.currentConstruction?.blueprint.reward.keys.first ?? .ironOre))
                                    .font(.caption)
                                    .foregroundColor(getResourceColor(for: bay?.currentConstruction?.blueprint.reward.keys.first ?? .ironOre))
                                
                                if isCompleted {
                                    // Complete text
                                    Text("Complete")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                } else {
                                    // Progress bar
                                    ProgressView(value: bay?.currentConstruction?.progress ?? 0)
                                        .frame(width: 40, height: 4)
                                        .tint(.blue)
                                    
                                    // Countdown timer
                                    Text("\(Int(bay?.currentConstruction?.timeRemaining ?? 0))s")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                            }
                        } else if let bay = bay, bay.isUnlocked {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.gray.opacity(0.6))
                        } else {
                            Image(systemName: "star.circle")
                                .font(.title2)
                                .foregroundColor(.yellow)
                        }
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(bay?.isUnlocked != true && !isCompleted)
        .scaleEffect(isCollecting ? 0.8 : 1.0)
        .opacity(isCollecting ? 0.5 : 1.0)
    }
    
    private func collectCompletedItem() {
        guard let bay = bay, let construction = bay.currentConstruction else { return }
        
        // Start collection animation
        withAnimation(.easeInOut(duration: 0.5)) {
            isCollecting = true
        }
        
        // Delay the actual collection to allow animation to play
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Add rewards to player resources
            for (resourceType, amount) in construction.blueprint.reward {
                if let existingIndex = gameState.resources.firstIndex(where: { $0.type == resourceType }) {
                    gameState.resources[existingIndex].amount += amount
                } else {
                    let newResource = Resource(
                        type: resourceType,
                        amount: amount,
                        icon: getResourceIcon(for: resourceType),
                        color: getResourceColor(for: resourceType)
                    )
                    gameState.resources.append(newResource)
                }
            }
            
            // Clear the construction
            if let bayIndex = gameState.constructionBays.firstIndex(where: { $0.id == bay.id }) {
                gameState.constructionBays[bayIndex].currentConstruction = nil
            }
            
            // Award XP
            gameState.addXP(construction.blueprint.xpReward)
            
            // Check for location unlocks
            gameState.checkLocationUnlocks()
            
            // Reset animation state
            isCollecting = false
        }
    }
    
    private func getResourceIcon(for type: ResourceType) -> String {
        switch type {
        case .ironOre: return "cube.fill"
        case .silicon: return "diamond.fill"
        case .water: return "drop.fill"
        case .oxygen: return "wind"
        case .graphite: return "diamond.fill"
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
        case .copper: return "circle.fill"
        case .gold: return "star.fill"
        case .lithium: return "battery.100"
        default: return "questionmark.circle"
        }
    }
    
    private func getResourceColor(for type: ResourceType) -> Color {
        switch type {
        case .ironOre: return .gray
        case .silicon: return .purple
        case .water: return .blue
        case .oxygen: return .cyan
        case .graphite: return .gray
        case .steelPylons: return .orange
        default: return .gray
        }
    }
}

// MARK: - Resources Page View
struct ResourcesPageView: View {
    @ObservedObject var gameState: GameState
    
    // Helper function to check if a resource is in a specific row
    func isResourceInRow(_ resourceType: ResourceType, rowIndex: Int) -> Bool {
        let startIndex = rowIndex * 5
        let endIndex = min(startIndex + 5, sortedResources.count)
        return (startIndex..<endIndex).contains { sortedResources[$0].type == resourceType }
    }
    
    private var sortedResources: [Resource] {
        let ownedResources = gameState.resources.filter { $0.amount > 0 }
        
        // Separate Numins from other resources
        let numinsResource = ownedResources.first { $0.type == .numins }
        let otherResources = ownedResources.filter { $0.type != .numins }
        
        // Sort other resources based on selected option and direction
        let sortedOtherResources: [Resource]
        let isAscending = gameState.resourceSortAscending
        
        switch gameState.resourceSortOption {
        case .alphabetical:
            sortedOtherResources = otherResources.sorted { 
                isAscending ? $0.type.rawValue < $1.type.rawValue : $0.type.rawValue > $1.type.rawValue
            }
        case .quantity:
            sortedOtherResources = otherResources.sorted { 
                isAscending ? $0.amount < $1.amount : $0.amount > $1.amount
            }
        case .rarity:
            // Sort by rarity: Common -> Uncommon -> Rare, then alphabetically within each rarity
            sortedOtherResources = otherResources.sorted { resource1, resource2 in
                let rarity1 = gameState.getResourceRarity(for: resource1.type)
                let rarity2 = gameState.getResourceRarity(for: resource2.type)
                
                // Define rarity order: Common (0), Uncommon (1), Rare (2)
                let rarityOrder: [ResourceRarity: Int] = [.common: 0, .uncommon: 1, .rare: 2]
                let order1 = rarityOrder[rarity1] ?? 0
                let order2 = rarityOrder[rarity2] ?? 0
                
                if order1 != order2 {
                    return isAscending ? order1 < order2 : order1 > order2
                } else {
                    // Same rarity, sort alphabetically
                    return isAscending ? resource1.type.rawValue < resource2.type.rawValue : resource1.type.rawValue > resource2.type.rawValue
                }
            }
        }
        
        // Always put Numins first, then other sorted resources
        if let numins = numinsResource {
            return [numins] + sortedOtherResources
        } else {
            return sortedOtherResources
        }
    }
    
    var body: some View {
        ZStack {
            VStack {
                // Page header
                HStack {
                    Text("Resources")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(gameState.getTotalResourcesHeld()) / \(gameState.maxStorageCapacity)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Sorting dropdown
                HStack {
                    Text("Sort by:")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        // Toggle sort direction if same option, otherwise set new option
                        if gameState.resourceSortOption == .alphabetical {
                            gameState.resourceSortAscending.toggle()
                        } else {
                            gameState.resourceSortOption = .alphabetical
                            gameState.resourceSortAscending = true
                        }
                    }) {
                        HStack {
                            Text("Alphabetical")
                            Image(systemName: gameState.resourceSortOption == .alphabetical ? 
                                  (gameState.resourceSortAscending ? "arrow.up" : "arrow.down") : "arrow.up.down")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(gameState.resourceSortOption == .alphabetical ? .blue : .white)
                    
                    Button(action: {
                        if gameState.resourceSortOption == .quantity {
                            gameState.resourceSortAscending.toggle()
                        } else {
                            gameState.resourceSortOption = .quantity
                            gameState.resourceSortAscending = true
                        }
                    }) {
                        HStack {
                            Text("Quantity")
                            Image(systemName: gameState.resourceSortOption == .quantity ? 
                                  (gameState.resourceSortAscending ? "arrow.up" : "arrow.down") : "arrow.up.down")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(gameState.resourceSortOption == .quantity ? .blue : .white)
                    
                    Button(action: {
                        if gameState.resourceSortOption == .rarity {
                            gameState.resourceSortAscending.toggle()
                        } else {
                            gameState.resourceSortOption = .rarity
                            gameState.resourceSortAscending = true
                        }
                    }) {
                        HStack {
                            Text("Rarity")
                            Image(systemName: gameState.resourceSortOption == .rarity ? 
                                  (gameState.resourceSortAscending ? "arrow.up" : "arrow.down") : "arrow.up.down")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(gameState.resourceSortOption == .rarity ? .blue : .white)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.2))
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Create rows of 5 resources each
                        ForEach(0..<((sortedResources.count + 4) / 5), id: \.self) { rowIndex in
                            VStack(spacing: 0) {
                                // Show detail view above this row if any resource in this row is selected
                                if let selectedResource = gameState.selectedResourceForDetail,
                                   let resource = gameState.resources.first(where: { $0.type == selectedResource }),
                                   isResourceInRow(selectedResource, rowIndex: rowIndex) {
                                    ResourceDetailView(resource: resource, gameState: gameState)
                                        .padding(.bottom, 16)
                                }
                                
                                // Resource row
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                                    ForEach(0..<5, id: \.self) { colIndex in
                                        let resourceIndex = rowIndex * 5 + colIndex
                                        
                                        if resourceIndex < sortedResources.count {
                                            let resource = sortedResources[resourceIndex]
                                            Button(action: {
                                                // Toggle selection: if same resource is tapped, deselect it
                                                if gameState.selectedResourceForDetail == resource.type {
                                                    // Immediate dismissal without animation
                                                    gameState.selectedResourceForDetail = nil
                                                } else {
                                                    // Clear any existing selection first, then animate new selection
                                                    gameState.selectedResourceForDetail = nil
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                            gameState.selectedResourceForDetail = resource.type
                                                        }
                                                    }
                                                }
                                            }) {
                                                ResourceCard(resource: resource, gameState: gameState)
                                                    .scaleEffect(gameState.selectedResourceForDetail == resource.type ? 0.95 : 1.0)
                                                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: gameState.selectedResourceForDetail)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        } else {
                                            EmptyResourceCard()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 100) // Add space for slots
                }
            }
            
                    VStack {
                        Spacer()
                        
                    }
            
            // Enhancement slots overlay - positioned at bottom without affecting layout
            VStack {
                Spacer()
                
                // Enhancement button - always visible
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        gameState.showResourcesSlots.toggle()
                    }
                }) {
                    HStack {
                        Text("Enhancements")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.black)
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Enhancement slots - shown conditionally with animation
                if gameState.showResourcesSlots {
                    ResourcesSlotsView(gameState: gameState)
                        .padding(.bottom, 10) // Position just above navigation bar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func getResourceIcon(for type: ResourceType) -> String {
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
        case .copper: return "circle.fill"
        case .gold: return "star.fill"
        case .lithium: return "battery.100"
        }
    }
    
    private func getResourceColor(for type: ResourceType) -> Color {
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
        case .copper: return .orange
        case .gold: return .yellow
        case .lithium: return .gray
        }
    }
}

// MARK: - Resource Detail View
struct ResourceDetailView: View {
    let resource: Resource
    @ObservedObject var gameState: GameState

    var body: some View {
        ZStack {
            // Clean background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(resource.color.opacity(0.3), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 12) {
                // Top row - Icon and Name with Rarity symbol
                HStack(spacing: 12) {
                    // Icon and name side by side
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(resource.color.opacity(0.15))
                                .frame(width: 50, height: 50)

                            Image(systemName: resource.icon)
                                .font(.system(size: 24))
                                .foregroundColor(resource.color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(resource.type.rawValue)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text("\(Int(resource.amount)) units")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(resource.color)
                        }
                    }

                    Spacer()

                    // Rarity indicator in top right corner
                    let rarity = gameState.getResourceRarity(for: resource.type)
                    Image(systemName: rarity.icon)
                        .font(.title3)
                        .foregroundColor(rarity.color)
                        .padding(.top, 4)
                        .padding(.trailing, 4)
                }

                // Description - takes up remaining space
                Text(gameState.getResourceLore(for: resource.type))
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                // Collection locations at bottom
                if !gameState.getResourceCollectionLocations(for: resource.type).isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Found at:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.7))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(gameState.getResourceCollectionLocations(for: resource.type), id: \.self) { location in
                                    Text(location)
                                        .font(.caption)
                                        .foregroundColor(.blue.opacity(0.9))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }
                }
                
                // Resource deletion controls
                ResourceDeletionControls(resource: resource, gameState: gameState)
            }
            .padding(20)
        }
        .frame(height: 280)
        .padding(.vertical, 8)
        .transition(.move(edge: .bottom))
    }
    
    private func getResourceCategory(for resourceType: ResourceType) -> String {
        switch resourceType {
        case .ironOre, .titanium, .aluminum, .nickel, .cobalt, .chromium, .vanadium, .manganese:
            return "Metals"
        case .silicon, .graphite, .nitrogen, .phosphorus, .sulfur, .calcium, .magnesium, .helium3:
            return "Elements"
        case .water, .oxygen:
            return "Life Support"
        case .plasma, .element, .isotope, .energy, .radiation, .heat, .light, .gravity, .magnetic, .solar:
            return "Energy"
        case .numins:
            return "Currency"
        case .hydrogen, .methane, .ammonia, .ice, .crystals, .minerals:
            return "Planetary"
        case .scrapMetal, .electronics, .fuelCells, .dataCores, .circuits, .alloys, .components, .techParts, .batteries, .wiring:
            return "Technology"
        case .food, .textiles, .tools, .medicine, .seeds, .livestock, .grain, .vegetables, .herbs, .supplies:
            return "Organic"
        case .heavyElements, .denseMatter, .compressedGas, .exoticMatter, .gravitons, .darkEnergy, .neutronium, .quarkMatter, .strangeMatter, .antimatter:
            return "Exotic"
        case .redPlasma, .infraredEnergy, .stellarWind, .magneticFields, .cosmicRays, .photons, .particles, .solarFlares, .corona, .chromosphere:
            return "Stellar"
        case .stellarDust, .cosmicDebris, .microParticles, .spaceGas, .ionStreams, .electronFlow, .protonBeams, .neutronFlux, .gammaRays, .xRays:
            return "Cosmic"
        case .researchData, .labEquipment, .samples, .experiments, .prototypes, .blueprints, .formulas, .algorithms, .code, .documentation:
            return "Research"
        case .frozenGases, .iceCrystals, .preservedMatter, .ancientArtifacts, .relics, .fossils, .rareElements, .crystallineStructures, .geologicalSamples:
            return "Ancient"
        case .steelPylons, .gears, .laser, .circuitBoard, .cpu, .dataStorageUnit, .sensorArray, .lithiumIonBattery, .fusionReactor, .quantumComputer, .spaceStationModule, .starshipHull, .terraformingArray:
            return "Constructed"
        case .copper, .gold, .lithium:
            return "Metals"
        }
    }
}

// MARK: - Card Detail View
struct CardDetailView: View {
    let cardId: String
    @ObservedObject var gameState: GameState
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false

    var body: some View {
        ZStack {
            // Clean background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )

            VStack(alignment: .center, spacing: 20) {
                // Coming Soon text
                VStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Coming Soon")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Card details and interactions will be available in a future update.")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding(40)
        }
        .frame(height: 200)
        .padding(.vertical, 8)
        .offset(y: dragOffset.height)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    isDragging = true
                    dragOffset = gesture.translation
                }
                .onEnded { gesture in
                    isDragging = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if gesture.translation.height > 100 {
                            gameState.selectedCardForDetail = nil
                        }
                        dragOffset = .zero
                    }
                }
        )
        .transition(.move(edge: .bottom))
        .opacity(isDragging ? 0.8 : 1.0)
    }
}

// MARK: - Placeholder Views
struct StarMapView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack {
            // Page header
            HStack {
                Text("Star Map")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            List {
                ForEach(gameState.availableLocations, id: \.id) { location in
                    Button(action: {
                        gameState.changeLocation(to: location)
                        gameState.showingLocationList = false
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(location.name)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                Text("\(location.system) • \(location.kind.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if location.id == gameState.currentLocation.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

struct ShopView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Shop Coming Soon!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("The shop will be available in a future update!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .padding(.bottom, 100) // Add space for slots
            }
            
                    VStack {
                        Spacer()
                    }
            
            // Enhancement slots overlay - positioned at bottom without affecting layout
            VStack {
                Spacer()
                
                // Enhancement button - always visible
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        gameState.showShopSlots.toggle()
                    }
                }) {
                    HStack {
                        Text("Enhancements")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.black)
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Enhancement slots - shown conditionally with animation
                if gameState.showShopSlots {
                    ShopSlotsView(gameState: gameState)
                        .padding(.bottom, 10) // Position just above navigation bar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Shop")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CardsView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Dev Tool Section
                    HStack {
                        Spacer()
                        Button(action: {
                            addAllCards()
                        }) {
                            Text("DEV")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Explorer Class Section
                    CardClassSection(
                        title: "Explorer Class",
                        cardClass: .explorer,
                        gameState: gameState
                    )
                    
                    // Constructor Class Section
                    CardClassSection(
                        title: "Constructor Class",
                        cardClass: .constructor,
                        gameState: gameState
                    )
                    
                    // Collector Class Section
                    CardClassSection(
                        title: "Collector Class",
                        cardClass: .collector,
                        gameState: gameState
                    )
                    
                    // Progression Class Section
                    CardClassSection(
                        title: "Progression Class",
                        cardClass: .progression,
                        gameState: gameState
                    )
                    
                    // Trader Class Section
                    CardClassSection(
                        title: "Trader Class",
                        cardClass: .trader,
                        gameState: gameState
                    )
                    
                    // Card Class Section
                    CardClassSection(
                        title: "Card Class",
                        cardClass: .card,
                        gameState: gameState
                    )
                }
                .padding()
                .padding(.bottom, 100) // Add space for slots
            }
            
                    VStack {
                        Spacer()
                    }
            
            // Enhancement slots overlay - positioned at bottom without affecting layout
            VStack {
                Spacer()
                
                // Enhancement button - always visible
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        gameState.showCardsSlots.toggle()
                    }
                }) {
                    HStack {
                        Text("Enhancements")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.black)
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Enhancement slots - shown conditionally with animation
                if gameState.showCardsSlots {
                    CardsSlotsView(gameState: gameState)
                        .padding(.bottom, 10) // Position just above navigation bar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Cards")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func addAllCards() {
        let allCardIds = gameState.getAllCardDefinitions().map { $0.id }
        for cardId in allCardIds {
            gameState.addCard(cardId, copies: 1)
        }
    }
}

struct CardClassSection: View {
    let title: String
    let cardClass: CardClass
    @ObservedObject var gameState: GameState
    
    // Computed property to get cards for this class
    private var cardsForClass: [CardDef] {
        gameState.getCardsForClass(cardClass)
    }
    
    // Helper function to check if a card is in a specific row
    private func isCardInRow(_ cardId: String, rowIndex: Int) -> Bool {
        // Quick bounds check
        guard rowIndex >= 0 && rowIndex < 3 else { return false }
        
        let startIndex = rowIndex * 3
        let endIndex = min(startIndex + 3, cardsForClass.count)
        
        // Safety check to prevent out of bounds
        guard startIndex < cardsForClass.count else { return false }
        
        // Check each card in the row range
        for i in startIndex..<endIndex {
            if cardsForClass[i].id == cardId {
                return true
            }
        }
        return false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                // Create rows of 3 cards each
                ForEach(0..<3, id: \.self) { rowIndex in
                    VStack(spacing: 0) {
                        // Show detail view above this row if any card in this row is selected
                        if let selectedCardId = gameState.selectedCardForDetail,
                           isCardInRow(selectedCardId, rowIndex: rowIndex) {
                            CardDetailView(cardId: selectedCardId, gameState: gameState)
                                .padding(.bottom, 8)
                        }
                        
                        // Card row
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            ForEach(0..<3, id: \.self) { colIndex in
                                let cardIndex = rowIndex * 3 + colIndex
                                
                                if cardIndex < 8 {
                                    CardSlotView(
                                        cardClass: cardClass,
                                        slotIndex: cardIndex,
                                        gameState: gameState
                                    )
                                } else {
                                    // Empty slot for incomplete rows
                                    Color.clear
                                        .frame(height: 120)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct CardSlotView: View {
    let cardClass: CardClass
    let slotIndex: Int
    @ObservedObject var gameState: GameState
    
    private var cardDef: CardDef? {
        let cardsForClass = gameState.getCardsForClass(cardClass)
        return slotIndex < cardsForClass.count ? cardsForClass[slotIndex] : nil
    }
    
    private var userCard: UserCard? {
        guard let cardDef = cardDef else { return nil }
        return gameState.getUserCard(for: cardDef.id)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let cardDef = cardDef, let userCard = userCard {
                // Owned card
                Button(action: {
                    gameState.selectedCardForDetail = cardDef.id
                }) {
                    VStack(spacing: 0) {
                    // Card name at the top
                    Text(cardDef.name)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                        .lineLimit(1)
                    
                    // Card icon/art in top half
                    RoundedRectangle(cornerRadius: 8)
                        .fill(cardClassColor.opacity(0.3))
                        .frame(height: 80)
                        .overlay(
                            Image(systemName: getCardIcon(for: cardDef.id))
                                .font(.title)
                                .foregroundColor(cardClassColor)
                        )
                        .padding(.horizontal, 4)
                        .padding(.top, 2)
                    
                    // Ability text in bottom half
                    Text(getAbilityText(for: cardDef, userCard: userCard))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                        .frame(height: 40)
                    
                    // Bottom row: Level (left) and Quantity (right)
                    HStack {
                        // Level in bottom left
                        Text("Level \(userCard.tier)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(cardClassColor)
                        
                        Spacer()
                        
                        // Quantity in bottom right
                        Text("\(userCard.copies)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(cardClassColor.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(cardClassColor, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Empty slot
                VStack(spacing: 0) {
                    // Card name placeholder
                    Text("Empty Slot")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                    
                    // Card icon/art placeholder
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(cardClassColor.opacity(0.3), lineWidth: 2)
                        .frame(height: 80)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.title)
                                .foregroundColor(cardClassColor.opacity(0.5))
                        )
                        .padding(.horizontal, 4)
                        .padding(.top, 2)
                    
                    // Empty space for ability text
                    Spacer()
                        .frame(height: 40)
                        .padding(.top, 4)
                    
                    // Bottom row placeholder
                    HStack {
                        Text("")
                        Spacer()
                        Text("")
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(cardClassColor.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                        )
                )
            }
        }
        .frame(height: 160)
    }
    
    private func getCardIcon(for cardId: String) -> String {
        switch cardId {
        case "astro-prospector":
            return "telescope.fill"
        case "deep-scan":
            return "waveform"
        default:
            return cardClassIcon
        }
    }
    
    private func getAbilityText(for cardDef: CardDef, userCard: UserCard) -> String {
        let tierValue = cardDef.tiers[userCard.tier - 1].value
        let percentage = Int(abs(tierValue) * 100)
        
        switch cardDef.effectKey {
        case "tapYieldMultiplier":
            return "[+\(percentage)%] Tap Yield"
        case "idleRareBias":
            return "[+\(percentage)%] to rare items"
        case "buildTimeMultiplier":
            return "[\(percentage)%] faster construction time"
        case "storageCapBonus":
            return "[+\(Int(tierValue))] storage capacity"
        case "xpGainMultiplier":
            return "[+\(percentage)%] XP gain"
        default:
            return cardDef.description
        }
    }
    
    private var cardClassColor: Color {
        switch cardClass {
        case .explorer: return .blue
        case .constructor: return .orange
        case .collector: return .green
        case .progression: return .purple
        case .trader: return .yellow
        case .card: return .red
        }
    }
    
    private var cardClassIcon: String {
        switch cardClass {
        case .explorer: return "telescope"
        case .constructor: return "hammer"
        case .collector: return "shippingbox"
        case .progression: return "chart.line.uptrend.xyaxis"
        case .trader: return "dollarsign.circle"
        case .card: return "rectangle.stack"
        }
    }
}

// MARK: - Objectives View
struct ObjectivesView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Gameplay Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Gameplay")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Total Experience Gained Tracker
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Experience Gained")
                                    .font(.headline)
                                Text("All XP earned from gameplay")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(gameState.totalXPGained)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.purple)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                        
                        // Total Taps Tracker (collapsible)
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                gameState.showTapDetails.toggle()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Total Taps")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("All location taps combined")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(gameState.totalTapsCount)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                    
                                    Image(systemName: gameState.showTapDetails ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.blue)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Expanded details
                            if gameState.showTapDetails {
                                ForEach(gameState.availableLocations, id: \.id) { location in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(location.name)
                                                .font(.subheadline)
                                            Text("\(location.system) • \(location.kind.rawValue)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("\(gameState.locationTapCounts[location.id, default: 0])")
                                            .font(.callout)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 16)
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(6)
                                }
                            }
                        }
                    }
                    
                    // Resources Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Resources")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Idle Collection Tracker (collapsible)
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                gameState.showIdleCollectionDetails.toggle()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Idle Collection")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("Resources collected while away")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(gameState.totalIdleCollectionCount)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                    
                                    Image(systemName: gameState.showIdleCollectionDetails ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.blue)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Expanded details
                            if gameState.showIdleCollectionDetails {
                                ForEach(gameState.availableLocations, id: \.id) { location in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(location.name)
                                                .font(.subheadline)
                                            Text("\(location.system) • \(location.kind.rawValue)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("\(gameState.locationIdleCollectionCounts[location.id, default: 0])")
                                            .font(.callout)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 16)
                                    .background(Color.blue.opacity(0.05))
                                    .cornerRadius(6)
                                }
                            }
                        }
                        
                        // Numins Tracker
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Numins")
                                    .font(.headline)
                                Text("The currency of the cosmos!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(gameState.getFormattedNumins())
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.yellow)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Construction Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Construction")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Total Constructions Tracker (collapsible)
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                gameState.showConstructionDetails.toggle()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Total Constructions")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("All constructions completed")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(gameState.totalConstructionsCompleted)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                    
                                    Image(systemName: gameState.showConstructionDetails ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.orange)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Expanded details
                            if gameState.showConstructionDetails {
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Small Constructions")
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(gameState.smallConstructionsCompleted)")
                                            .font(.callout)
                                            .fontWeight(.medium)
                                            .foregroundColor(.orange)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 16)
                                    .background(Color.orange.opacity(0.05))
                                    .cornerRadius(6)
                                    
                                    HStack {
                                        Text("Medium Constructions")
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(gameState.mediumConstructionsCompleted)")
                                            .font(.callout)
                                            .fontWeight(.medium)
                                            .foregroundColor(.orange)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 16)
                                    .background(Color.orange.opacity(0.05))
                                    .cornerRadius(6)
                                    
                                    HStack {
                                        Text("Large Constructions")
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(gameState.largeConstructionsCompleted)")
                                            .font(.callout)
                                            .fontWeight(.medium)
                                            .foregroundColor(.orange)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 16)
                                    .background(Color.orange.opacity(0.05))
                                    .cornerRadius(6)
                                }
                            }
                        }
                    }
                    
                    // Cards Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cards")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Total Cards Tracker (collapsible)
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                gameState.showCardsDetails.toggle()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Total Cards Collected")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("All card copies collected")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(gameState.getTotalCardsCollected())")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.purple)
                                    
                                    Image(systemName: gameState.showCardsDetails ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.purple)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Expanded details
                            if gameState.showCardsDetails {
                                VStack(spacing: 8) {
                                    ForEach(CardClass.allCases, id: \.self) { cardClass in
                                        HStack {
                                            Text("\(cardClass.rawValue) Cards")
                                                .font(.subheadline)
                                            Spacer()
                                            Text("\(gameState.getCardsCollectedForClass(cardClass))")
                                                .font(.callout)
                                                .fontWeight(.medium)
                                                .foregroundColor(.purple)
                                        }
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 16)
                                        .background(Color.purple.opacity(0.05))
                                        .cornerRadius(6)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Coming Soon Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Coming Soon")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("More objectives and achievements will be added in future updates!")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Statistics and Objectives")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

