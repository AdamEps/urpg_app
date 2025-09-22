//
//  ContentView.swift
//  UniverseRPG
//
//  Created by Adam Epstein on 9/3/25.
//

import SwiftUI

// MARK: - Overlay Height Preferences (for non-pushing overlays)
private struct BottomNavHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct ExtendedNavHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct ContentView: View {
    @EnvironmentObject var gameState: GameState
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
    @Environment(\.colorScheme) private var colorScheme
    @State private var bottomNavHeight: CGFloat = 0
    @State private var extendedNavHeight: CGFloat = 0
    
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
                    case .blueprints:
                        BlueprintsView(gameState: gameState, initialBaySize: gameState.selectedBaySizeForBlueprints)
                            .onAppear {
                                print("🔍 BlueprintsView appeared with selectedBaySizeForBlueprints: \(gameState.selectedBaySizeForBlueprints)")
                            }
                    case .starMap:
                        if gameState.showingLocationList {
                            StarMapView(gameState: gameState)
                        } else {
                            // Show hierarchical star map when not showing location list
                            StarMapView(gameState: gameState)
                        }
                    case .resources:
                        ResourcesPageView(gameState: gameState)
                    case .cards:
                        CardsView(gameState: gameState)
                    case .shop:
                        ShopView(gameState: gameState)
                    case .statistics:
                        StatisticsAndObjectivesView(gameState: gameState)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(nil, value: gameState.currentPage)
                
                // Bottom navigation removed from layout; rendered as overlay below
            }
            
            // Render both bars as a bottom overlay so content doesn't move
            VStack(spacing: 0) {
                Spacer()
                if gameState.showExtendedNavigation {
                    ExtendedNavigationView(gameState: gameState)
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(key: ExtendedNavHeightPreferenceKey.self, value: proxy.size.height)
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                BottomNavigationView(gameState: gameState)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(key: BottomNavHeightPreferenceKey.self, value: proxy.size.height)
                        }
                    )
            }
            .animation(.easeInOut(duration: 0.3), value: gameState.showExtendedNavigation)
            .onPreferenceChange(BottomNavHeightPreferenceKey.self) { bottomNavHeight = $0 }
            .onPreferenceChange(ExtendedNavHeightPreferenceKey.self) { extendedNavHeight = $0 }

            // Enhancements overlay - restores original pop-up behavior above nav bars
            VStack(spacing: 0) {
                Spacer()
                Group {
                    if gameState.currentPage == .location, gameState.showLocationSlots {
                        LocationSlotsView(gameState: gameState)
                    } else if gameState.currentPage == .construction, gameState.showConstructionSlots {
                        ConstructionSlotsView(gameState: gameState)
                    } else if gameState.currentPage == .resources, gameState.showResourcesSlots {
                        ResourcesSlotsView(gameState: gameState)
                    } else if gameState.currentPage == .shop, gameState.showShopSlots {
                        ShopSlotsView(gameState: gameState)
                    } else if gameState.currentPage == .cards, gameState.showCardsSlots {
                        CardsSlotsView(gameState: gameState)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, bottomNavHeight + (gameState.showExtendedNavigation ? extendedNavHeight : 0) + 80)
            }
            .animation(.easeInOut(duration: 0.3), value: gameState.showLocationSlots)
            .animation(.easeInOut(duration: 0.3), value: gameState.showConstructionSlots)
            .animation(.easeInOut(duration: 0.3), value: gameState.showResourcesSlots)
            .animation(.easeInOut(duration: 0.3), value: gameState.showShopSlots)
            .animation(.easeInOut(duration: 0.3), value: gameState.showCardsSlots)
            .zIndex(20)
            
            // Resource pop out positioned above bottom navigation
            if gameState.showLocationResources && gameState.currentPage == .location {
                HStack(spacing: 0) {
                    Spacer()
                        .allowsHitTesting(false)
                    
                    // Toggle button - right edge glued to left edge of popout
                    Button(action: {
                        gameState.showLocationResources.toggle()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(.adaptivePrimaryText)
                            .padding(8)
                            .background(Color.adaptiveSemiTransparentBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.adaptiveBorder, lineWidth: 1)
                            )
                            .cornerRadius(6)
                    }
                    
                    // Resource box - compact window with proper boundaries
                    LocationResourceListView(gameState: gameState)
                }
                    .padding(.trailing, 0)
                    .padding(.bottom, 80 + (gameState.showExtendedNavigation ? extendedNavHeight : 0)) // Respect extended nav overlay
            } else if gameState.currentPage == .location {
                HStack {
                    Spacer()
                        .allowsHitTesting(false)
                    
                    // Toggle button on right side of screen when closed
                    Button(action: {
                        gameState.showLocationResources.toggle()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.adaptivePrimaryText)
                            .padding(8)
                            .background(Color.adaptiveSemiTransparentBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.adaptiveBorder, lineWidth: 1)
                            )
                            .cornerRadius(6)
                    }
                }
                .padding(.trailing, 0)
                .padding(.bottom, 80 + (gameState.showExtendedNavigation ? extendedNavHeight : 0)) // Respect extended nav overlay
            }
            
            // Tap counter pop out positioned below location name
            VStack {
                if gameState.showTapCounter && gameState.currentPage == .location {
                    HStack(alignment: .bottom, spacing: 0) {
                        Spacer()
                            .allowsHitTesting(false)
                        
                        // Toggle button on left side of tap counter box when open
                        Button(action: {
                            gameState.showTapCounter.toggle()
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .foregroundColor(.adaptivePrimaryText)
                                .padding(8)
                                .background(Color.adaptiveSemiTransparentBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.adaptiveBorder, lineWidth: 1)
                                )
                                .cornerRadius(6)
                        }
                        
                        // Tap counter box
                        TapCounterView(gameState: gameState)
                            .frame(width: UIScreen.main.bounds.width * 0.3)
                    }
                    .padding(.trailing, 0)
                    .padding(.top, 100) // Position directly below top bar + location name
                } else if gameState.currentPage == .location {
                    HStack {
                        Spacer()
                            .allowsHitTesting(false)
                        
                        // Toggle button on right side of screen when closed
                        Button(action: {
                            gameState.showTapCounter.toggle()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.adaptivePrimaryText)
                                .padding(8)
                                .background(Color.adaptiveSemiTransparentBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.adaptiveBorder, lineWidth: 1)
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
    @Environment(\.colorScheme) private var colorScheme
    
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
                            .foregroundColor(.adaptivePrimaryText)
                    }
                }
                .frame(width: 100, alignment: .leading) // Match right side width for perfect centering
                
                Spacer()
                
                // Center - Player Name (bigger font) - perfectly centered
                Text(gameState.playerName)
                    .font(.title3)
                    .foregroundColor(.adaptivePrimaryText)
                
                Spacer()
                
                // Right - Currency (moved up) - fixed width
                HStack(spacing: 4) {
                    Image(systemName: "star.circle")
                        .foregroundColor(.yellow)
                    Text(gameState.getFormattedCurrency())
                        .font(.headline)
                        .foregroundColor(.adaptivePrimaryText)
                }
                .frame(width: 100, alignment: .trailing) // Fixed width to prevent shifting
            }
            
            // Bottom row - Level, progress bar, and objectives (moved down)
            HStack(spacing: 8) {
                Spacer()
                
                Text("Level \(gameState.playerLevel)")
                    .font(.caption)
                    .foregroundColor(.adaptivePrimaryText)
                
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
                                    .foregroundColor(.adaptivePrimaryText)
                                
                                Text("\(gameState.playerXP) / \(gameState.getXPRequiredForNextLevel()) XP")
                                    .font(.caption2)
                                    .foregroundColor(.adaptiveSecondaryText)
                                
                                Text("\(Int(gameState.getXPProgressPercentage() * 100))% to next level")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                
                                // Tap to dismiss hint
                                Text("Tap to close")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            .padding(8)
                            .background(Color.adaptiveDarkBackground)
                            .cornerRadius(8)
                            .offset(y: -60)
                            .animation(.easeInOut(duration: 0.2), value: showXPInfo)
                        }
                    },
                    alignment: .top
                )
                
                Button(action: {
                    gameState.toggleStatisticsPage()
                }) {
                    Image(systemName: "target")
                        .foregroundColor(gameState.currentPage == .statistics ? .blue : .adaptivePrimaryText)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.adaptiveDarkBackground)
    }
}

// MARK: - Header View (for location info)
struct HeaderView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Text(gameState.currentLocation.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.adaptivePrimaryText)
            
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
        .background(Color.adaptiveBlueBackground)
        .cornerRadius(12)
    }
}

// MARK: - Location View
struct LocationView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Full screen background - keep black for space theme
            Color.black
            
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
                            .foregroundColor(.adaptivePrimaryText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.adaptiveRedBackground)
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    Text(gameState.currentLocation.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.adaptivePrimaryText)
                    Spacer()
                    
                    // Invisible spacer to balance the layout
                    Color.clear
                        .frame(width: 40, height: 20)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.adaptiveSemiTransparentBackground)
                
                
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
                            Text("+\(gameState.lastCollectedAmount)")
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
            VStack(spacing: 0) {
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
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Enhancement slots - shown conditionally with animation
                if gameState.showLocationSlots {
                    LocationSlotsView(gameState: gameState)
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
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            // Scrollable selection area (only shown when a slot is selected)
            if gameState.selectedSlotIndex != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if gameState.selectedSlotType == "Cards" {
                            ForEach(getAvailableCards(), id: \.id) { userCard in
                                CompactCardView(userCard: userCard, gameState: gameState, page: "Location")
                            }
                        } else {
                            // TODO: Add items when ready
                            Text("Items coming soon...")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    .padding(.leading, 2) // Add 2pts to the left
                    .padding(.vertical, 4) // Add 4pts above and below inside scroll area
                }
                .frame(height: 88) // Perfect height: cards (80) + padding (8) = 88
                
                // Segmented control for Cards/Items
                Picker("Type", selection: $gameState.selectedSlotType) {
                    Text("Cards").tag("Cards")
                        .foregroundColor(.white)
                    Text("Items").tag("Items")
                        .foregroundColor(.white)
                }
                .pickerStyle(SegmentedPickerStyle())
                .colorScheme(.dark) // Force dark mode for proper contrast on black background
            }
            
            // Slots
            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { index in
                    LocationSlotView(slotIndex: index, gameState: gameState)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private func getAvailableCards() -> [UserCard] {
        // Get all equipped cards for the location page
        let equippedCards = gameState.getEquippedCardsForPage("Location").compactMap { $0 }
        
        // Filter cards to show only explorer/progression class cards that are unlocked and not already equipped
        return gameState.ownedCards.filter { userCard in
            // Skip if already equipped
            if equippedCards.contains(userCard.cardId) {
                return false
            }
            
            // Get the card definition to check class
            if let cardDef = gameState.getAllCardDefinitions().first(where: { $0.id == userCard.cardId }) {
                return (cardDef.cardClass == .explorer || cardDef.cardClass == .progression)
            }
            return false
        }
    }
}

struct LocationSlotView: View {
    let slotIndex: Int
    @ObservedObject var gameState: GameState
    @State private var isPressed = false
    
    var equippedCardId: String? {
        gameState.getEquippedCard(slotIndex: slotIndex, page: "Location")
    }
    
    var body: some View {
        Button(action: {
            print("enhancementsLocationSlot\(slotIndex + 1) tapped!")
            
            if equippedCardId != nil {
                // If slot has a card, unequip it
                gameState.unequipCardFromSlot(slotIndex: slotIndex, page: "Location")
            } else {
                // If slot is empty, select it for equipping
                if gameState.selectedSlotIndex == slotIndex {
                    gameState.selectedSlotIndex = nil
                } else {
                    gameState.selectedSlotIndex = slotIndex
                    gameState.selectedSlotType = "Cards" // Default to Cards
                }
            }
        }) {
        VStack(spacing: 4) {
            // Slot container
            RoundedRectangle(cornerRadius: 8)
                    .stroke(isPressed ? Color.blue : Color.gray.opacity(0.5), lineWidth: 2)
                .frame(width: 60, height: 80)
                .overlay(
                    Group {
                        if let equippedCardId = equippedCardId {
                            // Show equipped card as mini card overlay
                            if let userCard = gameState.getUserCard(for: equippedCardId) {
                                SlottedCardView(userCard: userCard, gameState: gameState, slotIndex: slotIndex, page: "Location")
                            }
                        } else {
                            // Show empty slot
                            VStack {
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .foregroundColor(.gray.opacity(0.6))
                                
                                Text("Slot \(slotIndex + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                        }
                    }
                )
        }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}


// MARK: - Slotted Card View
struct SlottedCardView: View {
    let userCard: UserCard
    @ObservedObject var gameState: GameState
    let slotIndex: Int
    let page: String
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            print("Slotted card tapped: \(userCard.cardId)")
            // Unequip the card from the slot
            gameState.unequipCardFromSlot(slotIndex: slotIndex, page: page)
        }) {
            VStack(spacing: 0) {
                // Card container with colored border and black interior
                RoundedRectangle(cornerRadius: 6)
                    .stroke(getCardColor(), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black)
                    )
                    .frame(width: 60, height: 80)
                    .overlay(
                        VStack(spacing: 0) {
                            // Top black area for card name
                            VStack {
                                Text(getAbbreviatedName(getCardName()))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(height: 20)
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.3))
                            
                            // Middle colored area with symbol background and text overlay
                            ZStack {
                                // Card symbol as background
                                Image(systemName: getCardIcon())
                                    .font(.largeTitle)
                                    .foregroundColor(getCardColor().opacity(0.3))
                                
                                // Ability text overlaid on symbol
                                VStack(spacing: 1) {
                                    ForEach(getAbilityLines(), id: \.self) { line in
                                        Text(line)
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.adaptivePrimaryText)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.6)
                                            .shadow(color: .black, radius: 1)
                                    }
                                }
                            }
                            .frame(height: 40)
                            .frame(maxWidth: .infinity)
                            .background(getCardColor().opacity(0.8))
                            
                            // Bottom black area for level/quantity
                            VStack {
                                Text("Lvl.\(userCard.tier)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .frame(height: 20)
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.3))
                        }
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private func getCardName() -> String {
        if let cardDef = gameState.getAllCardDefinitions().first(where: { $0.id == userCard.cardId }) {
            return cardDef.name
        }
        return userCard.cardId
    }
    
    private func getAbbreviatedName(_ name: String) -> String {
        // Create proper initials from each word
        let words = name.components(separatedBy: " ")
        let initials = words.compactMap { $0.first }.map { String($0).uppercased() }
        return initials.joined()
    }
    
    private func getCardIcon() -> String {
        switch userCard.cardId {
        case "astro-prospector":
            return "🔭"
        case "deep-scan":
            return "waveform"
        default:
            return getCardClassIcon()
        }
    }
    
    private func getCardClassIcon() -> String {
        if let cardDef = gameState.getAllCardDefinitions().first(where: { $0.id == userCard.cardId }) {
            switch cardDef.cardClass {
            case .explorer: return "telescope"
            case .constructor: return "hammer"
            case .collector: return "shippingbox"
            case .progression: return "chart.line.uptrend.xyaxis"
            case .trader: return "dollarsign.circle"
            case .card: return "rectangle.stack"
            }
        }
        return "questionmark"
    }
    
    private func getCardColor() -> Color {
        if let cardDef = gameState.getAllCardDefinitions().first(where: { $0.id == userCard.cardId }) {
            switch cardDef.cardClass {
            case .explorer:
                return Color(red: 0.2, green: 0.4, blue: 0.9) // Matching blue
            case .progression:
                return Color(red: 0.6, green: 0.2, blue: 0.8) // Matching purple
            case .constructor:
                return .orange
            case .collector:
                return .green
            case .trader:
                return .yellow
            case .card:
                return .red
            }
        }
        return .gray
    }
    
    private func getAbilityLines() -> [String] {
        let cardName = getCardName()
        let ability = getCardAbility()
        let percentage = getCardPercentage()
        let percentageString = percentage > 0 ? "+\(Int(percentage * 100))%" : "\(Int(percentage * 100))%"
        
        // Format abilities as requested with each word on different line
        if cardName.contains("Astro Prospector") {
            return [percentageString, "Tap", "Yield"]
        } else if cardName.contains("Deep Scan") {
            return [percentageString, "Rare", "Items"]
        } else if cardName.contains("Mining Mastery") {
            return [percentageString, "XP", "Gain"]
        } else if ability.contains("yield") && ability.contains("tap") {
            return [percentageString, "Tap", "Yield"]
        } else if ability.contains("rare") && ability.contains("chance") {
            return [percentageString, "Rare", "Items"]
        } else if ability.contains("xp") {
            return [percentageString, "XP", "Gain"]
        } else if ability.contains("speed") {
            return [percentageString, "Action", "Speed"]
        } else if ability.contains("efficiency") {
            return [percentageString, "Better", "Efficiency"]
        } else if ability.contains("bonus") {
            return [percentageString, "Bonus", "Rewards"]
        } else {
            // Fallback to first few words
            let words = ability.components(separatedBy: " ")
            if words.count >= 3 {
                return [percentageString, words[0], words[1]]
            } else if words.count == 2 {
                return [percentageString, words[0], words[1]]
            } else {
                return [percentageString, words.first ?? "Ability", ""]
            }
        }
    }
    
    private func getCardAbility() -> String {
        if let cardDef = gameState.getAllCardDefinitions().first(where: { $0.id == userCard.cardId }) {
            // Use the card's general description since tiers don't have descriptions
            return cardDef.description
        }
        return "Unknown ability"
    }
    
    private func getCardPercentage() -> Double {
        if let cardDef = gameState.getAllCardDefinitions().first(where: { $0.id == userCard.cardId }) {
            let tierIndex = userCard.tier - 1
            if tierIndex >= 0 && tierIndex < cardDef.tiers.count {
                return cardDef.tiers[tierIndex].value
            }
        }
        return 0.0
    }
}

// MARK: - Compact Card View
struct CompactCardView: View {
    let userCard: UserCard
    @ObservedObject var gameState: GameState
    let page: String
    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
                Button(action: {
                    print("Selected card: \(userCard.cardId)")
                    // Equip the card to the selected slot
                    if let selectedSlotIndex = gameState.selectedSlotIndex {
                        gameState.equipCardToSlot(cardId: userCard.cardId, slotIndex: selectedSlotIndex, page: page)
                        // Clear the selection to close the popup
                        gameState.selectedSlotIndex = nil
                    }
                }) {
            VStack(spacing: 0) {
                // Card container with colored border and black interior
                RoundedRectangle(cornerRadius: 6)
                    .stroke(getCardColor(), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black)
                    )
                    .frame(width: 60, height: 80)
                    .overlay(
                        VStack(spacing: 0) {
                            // Top black area for card name
                            VStack {
                                Text(getAbbreviatedName(getCardName()))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.adaptivePrimaryText)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(height: 20)
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.3))
                            
                            // Colored interior area with symbol background and text overlay
                            ZStack {
                                // Card symbol as background
                                Image(systemName: getCardIcon())
                                    .font(.largeTitle)
                                    .foregroundColor(getCardColor().opacity(0.3))
                                
                                // Ability text overlaid on symbol
                                VStack(spacing: 1) {
                                    ForEach(getAbilityLines(), id: \.self) { line in
                                        Text(line)
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.adaptivePrimaryText)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.6)
                                            .shadow(color: .black, radius: 1)
                                    }
                                }
                            }
                            .frame(height: 40)
                            .frame(maxWidth: .infinity)
                            .background(getCardColor().opacity(0.8))
                            
                            // Bottom black area for level
                            VStack {
                                Text("Lvl.\(userCard.tier)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .frame(height: 20)
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.3))
                        }
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private func getCardName() -> String {
        if let cardDef = gameState.getAllCardDefinitions().first(where: { $0.id == userCard.cardId }) {
            return cardDef.name
        }
        return userCard.cardId
    }
    
    private func getCardAbility() -> String {
        if let cardDef = gameState.getAllCardDefinitions().first(where: { $0.id == userCard.cardId }) {
            // Use the card's general description since tiers don't have descriptions
            return cardDef.description
        }
        return "Unknown ability"
    }
    
    private func getCardColor() -> Color {
        if let cardDef = gameState.getAllCardDefinitions().first(where: { $0.id == userCard.cardId }) {
            // Use exact colors from card page
            switch cardDef.cardClass {
            case .explorer:
                return .blue
            case .progression:
                return .purple
            case .constructor:
                return .orange
            case .collector:
                return .green
            case .trader:
                return .yellow
            case .card:
                return .red
            }
        }
        return .gray
    }
    
    private func getCardIcon() -> String {
        switch userCard.cardId {
        case "astro-prospector":
            return "🔭"
        case "deep-scan":
            return "waveform"
        default:
            return getCardClassIcon()
        }
    }
    
    private func getCardClassIcon() -> String {
        if let cardDef = gameState.getAllCardDefinitions().first(where: { $0.id == userCard.cardId }) {
            switch cardDef.cardClass {
            case .explorer: return "telescope"
            case .constructor: return "hammer"
            case .collector: return "shippingbox"
            case .progression: return "chart.line.uptrend.xyaxis"
            case .trader: return "dollarsign.circle"
            case .card: return "rectangle.stack"
            }
        }
        return "questionmark"
    }
    
    private func getCardPercentage() -> Double {
        if let cardDef = gameState.getAllCardDefinitions().first(where: { $0.id == userCard.cardId }) {
            let tierIndex = userCard.tier - 1
            if tierIndex >= 0 && tierIndex < cardDef.tiers.count {
                return cardDef.tiers[tierIndex].value
            }
        }
        return 0.0
    }
    
    private func getAbbreviatedName(_ name: String) -> String {
        // Create proper initials from each word
        let words = name.components(separatedBy: " ")
        let initials = words.compactMap { $0.first }.map { String($0).uppercased() }
        return initials.joined()
    }
    
    private func getAbilityLines() -> [String] {
        let cardName = getCardName()
        let description = getCardAbility().lowercased()
        
        // Get the actual percentage value from the card data
        let percentage = getCardPercentage()
        let percentageString = "[+\(Int(percentage * 100))%]"
        
        // Format abilities as requested with each word on different line
        if cardName.contains("Astro Prospector") {
            return [percentageString, "Tap", "Yield"]
        } else if cardName.contains("Deep Scan") {
            return [percentageString, "Rare", "Items"]
        } else if cardName.contains("Mining Mastery") {
            return [percentageString, "XP", "Gain"]
        } else if description.contains("yield") && description.contains("tap") {
            return [percentageString, "Tap", "Yield"]
        } else if description.contains("rare") && description.contains("chance") {
            return [percentageString, "Rare", "Items"]
        } else if description.contains("xp") {
            return [percentageString, "XP", "Gain"]
        } else if description.contains("speed") {
            return [percentageString, "Action", "Speed"]
        } else if description.contains("efficiency") {
            return [percentageString, "Better", "Efficiency"]
        } else if description.contains("bonus") {
            return [percentageString, "Bonus", "Rewards"]
        } else {
            // Fallback to first few words
            let words = getCardAbility().components(separatedBy: " ")
            if words.count >= 3 {
                return [percentageString, words[0], words[1]]
            } else if words.count == 2 {
                return [percentageString, words[0], words[1]]
            } else {
                return [percentageString, words.first ?? "Ability", ""]
            }
        }
    }
    
    private func getAbbreviatedAbility(_ ability: String) -> String {
        // Simplify ability text for compact display
        let description = ability.lowercased()
        
        // Extract key information and make it more concise
        if description.contains("yield") && description.contains("tap") {
            return "More yield on tap"
        } else if description.contains("rare") && description.contains("chance") {
            return "Better rare drops"
        } else if description.contains("xp") {
            return "More XP gain"
        } else if description.contains("speed") {
            return "Faster actions"
        } else if description.contains("efficiency") {
            return "Better efficiency"
        } else if description.contains("bonus") {
            return "Bonus rewards"
        } else {
            // Fallback to first few words
            let words = ability.components(separatedBy: " ")
            if words.count > 3 {
                return words.prefix(3).joined(separator: " ")
            }
            return ability
        }
    }
}

// MARK: - Resources Slots View
struct ResourcesSlotsView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 8) {
            // Scrollable selection area (only shown when a slot is selected)
            if gameState.selectedSlotIndex != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if gameState.selectedSlotType == "Cards" {
                            ForEach(getAvailableCards(), id: \.id) { userCard in
                                CompactCardView(userCard: userCard, gameState: gameState, page: "Resources")
                            }
                        } else {
                            // TODO: Add items when ready
                            Text("Items coming soon...")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    .padding(.leading, 2) // Add 2pts to the left
                    .padding(.vertical, 4) // Add 4pts above and below inside scroll area
                }
                .frame(height: 88) // Perfect height: cards (80) + padding (8) = 88
                
                // Segmented control for Cards/Items
                Picker("Type", selection: $gameState.selectedSlotType) {
                    Text("Cards").tag("Cards")
                        .foregroundColor(.white)
                    Text("Items").tag("Items")
                        .foregroundColor(.white)
                }
                .pickerStyle(SegmentedPickerStyle())
                .colorScheme(.dark) // Force dark mode for proper contrast on black background
            }
            
            // Slots
            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { index in
                    ResourcesSlotView(slotIndex: index, gameState: gameState)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(12)
    }
    
    private func getAvailableCards() -> [UserCard] {
        // Get all equipped cards for the resources page
        let equippedCards = gameState.getEquippedCardsForPage("Resources").compactMap { $0 }
        
        // Filter cards to show only collector/progression class cards that are unlocked and not already equipped
        return gameState.ownedCards.filter { userCard in
            // Skip if already equipped
            if equippedCards.contains(userCard.cardId) {
                return false
            }
            
            // Get the card definition to check class
            if let cardDef = gameState.getAllCardDefinitions().first(where: { $0.id == userCard.cardId }) {
                return (cardDef.cardClass == .collector || cardDef.cardClass == .progression)
            }
            return false
        }
    }
}

struct ResourcesSlotView: View {
    let slotIndex: Int
    @ObservedObject var gameState: GameState
    @State private var isPressed = false
    
    var equippedCardId: String? {
        gameState.getEquippedCard(slotIndex: slotIndex, page: "Resources")
    }
    
    var body: some View {
        Button(action: {
            print("enhancementsResourcesSlot\(slotIndex + 1) tapped!")
            
            if equippedCardId != nil {
                // If slot has a card, unequip it
                gameState.unequipCardFromSlot(slotIndex: slotIndex, page: "Resources")
            } else {
                // If slot is empty, select it for equipping
                if gameState.selectedSlotIndex == slotIndex {
                    gameState.selectedSlotIndex = nil
                } else {
                    gameState.selectedSlotIndex = slotIndex
                    gameState.selectedSlotType = "Cards" // Default to Cards
                }
            }
        }) {
        VStack(spacing: 4) {
            // Slot container
            RoundedRectangle(cornerRadius: 8)
                    .stroke(isPressed ? Color.blue : Color.gray.opacity(0.5), lineWidth: 2)
                .frame(width: 60, height: 80)
                .overlay(
                    Group {
                        if let equippedCardId = equippedCardId {
                            // Show equipped card as mini card overlay
                            if let userCard = gameState.getUserCard(for: equippedCardId) {
                                SlottedCardView(userCard: userCard, gameState: gameState, slotIndex: slotIndex, page: "Resources")
                            }
                        } else {
                            // Show empty slot
                            VStack {
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .foregroundColor(.gray.opacity(0.6))
                                
                                Text("Slot \(slotIndex + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                        }
                    }
                )
        }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Shop Slots View
struct ShopSlotsView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 8) {
            // Scrollable selection area (only shown when a slot is selected)
            if gameState.selectedSlotIndex != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if gameState.selectedSlotType == "Cards" {
                            ForEach(getAvailableCards(), id: \.id) { userCard in
                                CompactCardView(userCard: userCard, gameState: gameState, page: "Shop")
                            }
                        } else {
                            // TODO: Add items when ready
                            Text("Items coming soon...")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    .padding(.leading, 2) // Add 2pts to the left
                    .padding(.vertical, 4) // Add 4pts above and below inside scroll area
                }
                .frame(height: 88) // Perfect height: cards (80) + padding (8) = 88
                
                // Segmented control for Cards/Items
                Picker("Type", selection: $gameState.selectedSlotType) {
                    Text("Cards").tag("Cards")
                        .foregroundColor(.white)
                    Text("Items").tag("Items")
                        .foregroundColor(.white)
                }
                .pickerStyle(SegmentedPickerStyle())
                .colorScheme(.dark) // Force dark mode for proper contrast on black background
            }
            
            // Slots
            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { index in
                    ShopSlotView(slotIndex: index, gameState: gameState)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(12)
    }
    
    private func getAvailableCards() -> [UserCard] {
        // Get all equipped cards for the shop page
        let equippedCards = gameState.getEquippedCardsForPage("Shop").compactMap { $0 }
        
        // Filter cards to show only trader/progression class cards that are unlocked and not already equipped
        return gameState.ownedCards.filter { userCard in
            // Skip if already equipped
            if equippedCards.contains(userCard.cardId) {
                return false
            }
            
            // Get the card definition to check class
            if let cardDef = gameState.getAllCardDefinitions().first(where: { $0.id == userCard.cardId }) {
                return (cardDef.cardClass == .trader || cardDef.cardClass == .progression)
            }
            return false
        }
    }
}

struct ShopSlotView: View {
    let slotIndex: Int
    @ObservedObject var gameState: GameState
    @State private var isPressed = false
    
    var equippedCardId: String? {
        gameState.getEquippedCard(slotIndex: slotIndex, page: "Shop")
    }
    
    var body: some View {
        Button(action: {
            print("enhancementsShopSlot\(slotIndex + 1) tapped!")
            
            if equippedCardId != nil {
                // If slot has a card, unequip it
                gameState.unequipCardFromSlot(slotIndex: slotIndex, page: "Shop")
            } else {
                // If slot is empty, select it for equipping
                if gameState.selectedSlotIndex == slotIndex {
                    gameState.selectedSlotIndex = nil
                } else {
                    gameState.selectedSlotIndex = slotIndex
                    gameState.selectedSlotType = "Cards" // Default to Cards
                }
            }
        }) {
        VStack(spacing: 4) {
            // Slot container
            RoundedRectangle(cornerRadius: 8)
                    .stroke(isPressed ? Color.blue : Color.gray.opacity(0.5), lineWidth: 2)
                .frame(width: 60, height: 80)
                .overlay(
                    Group {
                        if let equippedCardId = equippedCardId {
                            // Show equipped card as mini card overlay
                            if let userCard = gameState.getUserCard(for: equippedCardId) {
                                SlottedCardView(userCard: userCard, gameState: gameState, slotIndex: slotIndex, page: "Shop")
                            }
                        } else {
                            // Show empty slot
                            VStack {
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .foregroundColor(.gray.opacity(0.6))
                                
                                Text("Slot \(slotIndex + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                        }
                    }
                )
        }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Cards Slots View
struct CardsSlotsView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 8) {
            // Scrollable selection area (only shown when a slot is selected)
            if gameState.selectedSlotIndex != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if gameState.selectedSlotType == "Cards" {
                            ForEach(getAvailableCards(), id: \.id) { userCard in
                                CompactCardView(userCard: userCard, gameState: gameState, page: "Cards")
                            }
                        } else {
                            // TODO: Add items when ready
                            Text("Items coming soon...")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    .padding(.leading, 2) // Add 2pts to the left
                    .padding(.vertical, 4) // Add 4pts above and below inside scroll area
                }
                .frame(height: 88) // Perfect height: cards (80) + padding (8) = 88
                
                // Segmented control for Cards/Items
                Picker("Type", selection: $gameState.selectedSlotType) {
                    Text("Cards").tag("Cards")
                        .foregroundColor(.white)
                    Text("Items").tag("Items")
                        .foregroundColor(.white)
                }
                .pickerStyle(SegmentedPickerStyle())
                .colorScheme(.dark) // Force dark mode for proper contrast on black background
            }
            
            // Slots
            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { index in
                    CardsSlotView(slotIndex: index, gameState: gameState)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(12)
    }
    
    private func getAvailableCards() -> [UserCard] {
        // Get all equipped cards for the cards page
        let equippedCards = gameState.getEquippedCardsForPage("Cards").compactMap { $0 }
        
        // Filter cards to show only card/progression class cards that are unlocked and not already equipped
        return gameState.ownedCards.filter { userCard in
            // Skip if already equipped
            if equippedCards.contains(userCard.cardId) {
                return false
            }
            
            // Get the card definition to check class
            if let cardDef = gameState.getAllCardDefinitions().first(where: { $0.id == userCard.cardId }) {
                return (cardDef.cardClass == .card || cardDef.cardClass == .progression)
            }
            return false
        }
    }
}

struct CardsSlotView: View {
    let slotIndex: Int
    @ObservedObject var gameState: GameState
    @State private var isPressed = false
    
    var equippedCardId: String? {
        gameState.getEquippedCard(slotIndex: slotIndex, page: "Cards")
    }
    
    var body: some View {
        Button(action: {
            print("enhancementsCardsSlot\(slotIndex + 1) tapped!")
            
            if equippedCardId != nil {
                // If slot has a card, unequip it
                gameState.unequipCardFromSlot(slotIndex: slotIndex, page: "Cards")
            } else {
                // If slot is empty, select it for equipping
                if gameState.selectedSlotIndex == slotIndex {
                    gameState.selectedSlotIndex = nil
                } else {
                    gameState.selectedSlotIndex = slotIndex
                    gameState.selectedSlotType = "Cards" // Default to Cards
                }
            }
        }) {
        VStack(spacing: 4) {
            // Slot container
            RoundedRectangle(cornerRadius: 8)
                    .stroke(isPressed ? Color.blue : Color.gray.opacity(0.5), lineWidth: 2)
                .frame(width: 60, height: 80)
                .overlay(
                    Group {
                        if let equippedCardId = equippedCardId {
                            // Show equipped card as mini card overlay
                            if let userCard = gameState.getUserCard(for: equippedCardId) {
                                SlottedCardView(userCard: userCard, gameState: gameState, slotIndex: slotIndex, page: "Cards")
                            }
                        } else {
                            // Show empty slot
                            VStack {
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .foregroundColor(.gray.opacity(0.6))
                                
                                Text("Slot \(slotIndex + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                        }
                    }
                )
        }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Location Resource List View
struct LocationResourceListView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header row - main headers
            HStack(spacing: 4) {
                HStack {
                    Text("Resources").font(.caption).foregroundColor(.adaptivePrimaryText).lineLimit(1)
                    Spacer()
                }
                .frame(width: 80) // Reduced from 120 to 80 (subtract 40 pts)
                Text("Tap").font(.caption).foregroundColor(.adaptivePrimaryText).frame(width: 65, alignment: .center)
                Text("Idle").font(.caption).foregroundColor(.adaptivePrimaryText).frame(width: 65, alignment: .center)
            }
            
            // Rate information row
            HStack(spacing: 4) {
                Text("").frame(width: 80, alignment: .leading) // Empty space for alignment
                Text("").frame(width: 65, alignment: .center) // Empty space for alignment
                Text("(10%/sec)").font(.caption2).foregroundColor(.gray).frame(width: 65, alignment: .center)
            }
            .padding(.leading, 16) // Add 16pt left padding
            
            // Resource rows - with breathing room
            ForEach(gameState.getModifiedDropTable(), id: \.0) { resourceType, percentage in
                HStack(spacing: 4) {
                    Image(systemName: getResourceIcon(for: resourceType)).foregroundColor(getResourceColor(for: resourceType)).frame(width: 16).font(.caption)
                    Text(resourceType.rawValue).font(.caption2).foregroundColor(.adaptivePrimaryText).frame(width: 80, alignment: .leading)
                    Text("\(String(format: "%.2f", percentage))%").font(.caption2).foregroundColor(.adaptivePrimaryText).frame(width: 65, alignment: .center)
                    // Show actual idle drop table percentage instead of hardcoded 0.0%
                    let idleDropTable = gameState.getIdleDropTable()
                    let idlePercentage = idleDropTable.first(where: { $0.0 == resourceType })?.1 ?? 0.0
                    Text("\(String(format: "%.2f", idlePercentage))%").font(.caption2).foregroundColor(.adaptiveSecondaryText).frame(width: 65, alignment: .center)
                }
                .frame(height: 16) // Increased from 10 to 16 for better breathing room
                .padding(.horizontal, 16) // Add horizontal padding to match the header
            }
            
            // Blank line after resources
            Spacer().frame(height: 8)
            
            // Additional Chances Section - completely compact
            VStack(spacing: 0) {
                HStack {
                    Text("Additional Chances").font(.caption).foregroundColor(.yellow)
                    Spacer()
                }
                .frame(height: 12)
                
                // Blank line after Additional Chances header
                Spacer().frame(height: 8)
                
                // Numins chance - completely compact
                HStack(spacing: 4) {
                    Image(systemName: "star.circle").foregroundColor(.yellow).frame(width: 16).font(.caption)
                    Text("Numins").font(.caption2).foregroundColor(.adaptivePrimaryText).frame(width: 80, alignment: .leading)
                    let numinsRange = gameState.getCurrentTapNuminsRange()
                    let numinsChance = gameState.getCurrentTapNuminsChance()
                    let numinsChanceText = numinsChance < 1.0 ? String(format: "%.2f", numinsChance) : "\(Int(numinsChance))"
                    Text("\(numinsChanceText)% (\(numinsRange.min)-\(numinsRange.max))").font(.caption2).foregroundColor(.adaptivePrimaryText).frame(width: 65, alignment: .center)
                    let idleNuminsRange = gameState.getCurrentIdleNuminsRange()
                    let idleNuminsChance = gameState.getCurrentIdleNuminsChance()
                    let idleNuminsChanceText = idleNuminsChance < 1.0 ? String(format: "%.2f", idleNuminsChance) : "\(Int(idleNuminsChance))"
                    Text("\(idleNuminsChanceText)% (\(idleNuminsRange.min)-\(idleNuminsRange.max))").font(.caption2).foregroundColor(.adaptivePrimaryText).frame(width: 65, alignment: .center)
                }
                .frame(height: 16) // Increased from 10 to 16 for better breathing room
                
                // XP chance - with breathing room
                HStack(spacing: 4) {
                    Image(systemName: "star.circle.fill").foregroundColor(.blue).frame(width: 16).font(.caption)
                    Text("XP").font(.caption2).foregroundColor(.adaptivePrimaryText).frame(width: 80, alignment: .leading)
                    let xpChance = gameState.getCurrentTapXPChance()
                    let xpChanceText = xpChance < 1.0 ? String(format: "%.2f", xpChance) : "\(Int(xpChance))"
                    Text("\(xpChanceText)% (\(gameState.getCurrentTapXPAmount()))").font(.caption2).foregroundColor(.adaptivePrimaryText).frame(width: 65, alignment: .center)
                    Text("0.0%").font(.caption2).foregroundColor(.adaptiveSecondaryText).frame(width: 65, alignment: .center)
                }
                .frame(height: 16) // Increased from 10 to 16 for better breathing room
                
                // Cards chance (Tap only, only for Taragam-7)
                if gameState.currentLocation.id == "taragam-7" {
                    VStack(spacing: 0) {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.stack.fill")
                                .foregroundColor(.purple)
                                .frame(width: 16)
                                .font(.caption)
                            
                            Text("Cards")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .frame(width: 80, alignment: .leading)
                            
                            // Tap Cards
                            let cardChance = gameState.getCurrentTapCardChance()
                            let cardChanceText = cardChance < 1.0 ? String(format: "%.2f", cardChance) : "\(Int(cardChance))"
                            Text("\(cardChanceText)%")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(width: 65, alignment: .center)
                            
                            // Idle Cards (0%)
                            Text("0.0%")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                                .frame(width: 65, alignment: .center)
                        }
                        .frame(height: 16) // Increased height for better breathing room
                        
                        // Card abbreviations row
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.stack.fill")
                                .foregroundColor(.clear) // Invisible icon for alignment
                                .frame(width: 16)
                                .font(.caption)
                            
                            let cardAbbrevs = gameState.getLocationCardAbbreviations()
                            Text(cardAbbrevs.joined(separator: ", "))
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .frame(width: 80, alignment: .leading)
                            
                            // Empty spaces to maintain alignment
                            Text("")
                                .frame(width: 65, alignment: .center)
                            
                            Text("")
                                .frame(width: 65, alignment: .center)
                        }
                        .frame(height: 16) // Increased height for better breathing room
                    }
                }
            }
            
        }
        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 0))
        .padding(2)
        .frame(maxWidth: 240)
        .background(Color.adaptiveSolidBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.adaptiveBorder, lineWidth: 1)
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
        
        // Enhancement items
        case .excavator: return "hammer.fill"
        case .laserHarvester: return "laser.burst"
        case .virtualAlmanac: return "book.fill"
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
        
        // Enhancement items
        case .excavator: return .brown
        case .laserHarvester: return .red
        case .virtualAlmanac: return .purple
        }
    }
}

// MARK: - Tap Counter View
struct TapCounterView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 4) {
            Text("Tap Count:")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.adaptivePrimaryText)
            
            Text("\(gameState.currentLocationTapCount)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.adaptivePrimaryText)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(Color.adaptiveSolidBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.adaptiveBorder, lineWidth: 1)
        )
        .cornerRadius(6)
    }
}

// MARK: - Construction View
struct ConstructionView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Construction Bays")
                        .font(.headline)
                        .foregroundColor(.adaptivePrimaryText)
                    
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
                .padding(.bottom, 80) // Position well above navigation bar
            }
            
            // Enhancement slots overlay - positioned at bottom without affecting layout
            VStack(spacing: 0) {
                Spacer()
                
                // Enhancement button - always visible
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        gameState.showConstructionSlots.toggle()
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
                    .background(Color.adaptiveCardBackground)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Enhancement slots - shown conditionally with animation
                if gameState.showConstructionSlots {
                    ConstructionSlotsView(gameState: gameState)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        print("🔍 Small bay clicked - setting selectedBaySizeForBlueprints to .small")
                        gameState.selectedBaySizeForBlueprints = .small
                        gameState.currentPage = .blueprints
                        gameState.starMapViaTelescope = false
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

// MARK: - Construction Slots View
struct ConstructionSlotsView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 8) {
            // Scrollable selection area (only shown when a slot is selected)
            if gameState.selectedSlotIndex != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if gameState.selectedSlotType == "Cards" {
                            ForEach(getAvailableCards(), id: \.id) { userCard in
                                CompactCardView(userCard: userCard, gameState: gameState, page: "Construction")
                            }
                        } else {
                            // TODO: Add items when ready
                            Text("Items coming soon...")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    .padding(.leading, 2) // Add 2pts to the left
                    .padding(.vertical, 4) // Add 4pts above and below inside scroll area
                }
                .frame(height: 88) // Perfect height: cards (80) + padding (8) = 88
                
                // Segmented control for Cards/Items
                Picker("Type", selection: $gameState.selectedSlotType) {
                    Text("Cards").tag("Cards")
                        .foregroundColor(.white)
                    Text("Items").tag("Items")
                        .foregroundColor(.white)
                }
                .pickerStyle(SegmentedPickerStyle())
                .colorScheme(.dark) // Force dark mode for proper contrast on black background
            }
            
            // Slots
            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { index in
                    ConstructionSlotView(slotIndex: index, gameState: gameState)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(12)
    }
    
    private func getAvailableCards() -> [UserCard] {
        // Get all equipped cards for the construction page
        let equippedCards = gameState.getEquippedCardsForPage("Construction").compactMap { $0 }
        
        // Filter cards to show only constructor/progression class cards that are unlocked and not already equipped
        return gameState.ownedCards.filter { userCard in
            // Skip if already equipped
            if equippedCards.contains(userCard.cardId) {
                return false
            }
            
            // Get the card definition to check class
            if let cardDef = gameState.getAllCardDefinitions().first(where: { $0.id == userCard.cardId }) {
                return (cardDef.cardClass == .constructor || cardDef.cardClass == .progression)
            }
            return false
        }
    }
}

struct ConstructionSlotView: View {
    let slotIndex: Int
    @ObservedObject var gameState: GameState
    @State private var isPressed = false
    
    var equippedCardId: String? {
        gameState.getEquippedCard(slotIndex: slotIndex, page: "Construction")
    }
    
    var body: some View {
        Button(action: {
            print("enhancementsConstructionSlot\(slotIndex + 1) tapped!")
            
            if equippedCardId != nil {
                // If slot has a card, unequip it
                gameState.unequipCardFromSlot(slotIndex: slotIndex, page: "Construction")
            } else {
                // If slot is empty, select it for equipping
                if gameState.selectedSlotIndex == slotIndex {
                    gameState.selectedSlotIndex = nil
                } else {
                    gameState.selectedSlotIndex = slotIndex
                    gameState.selectedSlotType = "Cards" // Default to Cards
                }
            }
        }) {
        VStack(spacing: 4) {
            // Slot container
            RoundedRectangle(cornerRadius: 8)
                    .stroke(isPressed ? Color.blue : Color.gray.opacity(0.5), lineWidth: 2)
                .frame(width: 60, height: 80)
                .overlay(
                    Group {
                        if let equippedCardId = equippedCardId {
                            // Show equipped card as mini card overlay
                            if let userCard = gameState.getUserCard(for: equippedCardId) {
                                SlottedCardView(userCard: userCard, gameState: gameState, slotIndex: slotIndex, page: "Construction")
                            }
                        } else {
                            // Show empty slot
                            VStack {
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .foregroundColor(.gray.opacity(0.6))
                                
                                Text("Slot \(slotIndex + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                        }
                    }
                )
        }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
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

// MARK: - Glowing Zoom Out Icon
struct GlowingZoomOutIcon: View {
    @State private var glowOpacity: Double = 0.3

    var body: some View {
        ZStack {
            // Outer glow layer
            Image("ZoomOutMaps")
                .resizable()
                .frame(width: 28, height: 28)
                .foregroundColor(.yellow.opacity(glowOpacity))
                .scaleEffect(1.2)
                .blur(radius: 8)

            // Middle glow layer
            Image("ZoomOutMaps")
                .resizable()
                .frame(width: 28, height: 28)
                .foregroundColor(.yellow.opacity(glowOpacity * 1.5))
                .scaleEffect(1.1)
                .blur(radius: 4)

            // Core zoom out icon
            Image("ZoomOutMaps")
                .resizable()
                .frame(width: 28, height: 28)
                .foregroundColor(.yellow)
        }
        .onAppear {
            // Start oscillating animation
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowOpacity = 0.8
            }
        }
    }
}

// MARK: - Bottom Navigation
struct BottomNavigationView: View {
    @ObservedObject var gameState: GameState

    var body: some View {
        VStack(spacing: 0) {
            // Regular navigation
            HStack {
            Button(action: {
                gameState.currentPage = .shop
                gameState.starMapViaTelescope = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    gameState.showExtendedNavigation = false
                }
            }) {
                Image(systemName: "cart.fill")
                    .font(.title2)
                    .foregroundColor(gameState.currentPage == .shop ? .blue : .white)
            }

                Spacer()

            Button(action: {
                gameState.currentPage = .construction
                gameState.starMapViaTelescope = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    gameState.showExtendedNavigation = false
                }
            }) {
                Image(systemName: "hammer.fill")
                    .font(.title2)
                    .foregroundColor((gameState.currentPage == .construction || gameState.currentPage == .blueprints) ? .blue : .white)
            }

                Spacer()

                Button(action: {
                    // Toggle extended navigation instead of navigating
                    // Only show extended navigation on location, star map, or when already showing extended navigation
                    if gameState.currentPage == .location || gameState.currentPage == .starMap || gameState.showExtendedNavigation {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            gameState.showExtendedNavigation.toggle()
                        }
                    } else {
                        // On other pages (shop, construction, resources, cards), go to location view first
                        gameState.currentPage = .location
                        gameState.starMapViaTelescope = false
                    }
                }) {
                    // Dynamic icon based on current page, zoom level, and extended navigation state
                    if gameState.showExtendedNavigation {
                        // When extended navigation is shown, show the zoom out icon
                        Image("ZoomOutMaps")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .foregroundColor(.blue)
                    } else if gameState.currentPage == .starMap {
                        if case .constellation = gameState.starMapZoomLevel {
                            // At constellation level (Multi system view), show glowing or non-glowing zoom out icon
                            if gameState.showExtendedNavigation {
                                // When extended navigation is shown, show non-glowing zoom out icon
                                if let _ = UIImage(named: "ZoomOutMaps") {
                                    Image("ZoomOutMaps")
                                        .resizable()
                                        .frame(width: 28, height: 28)
                                        .foregroundColor(.blue)
                                } else {
                                    Text("🔭")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            } else {
                                // When extended navigation is closed, show glowing zoom out icon
                                GlowingZoomOutIcon()
                            }
                        } else {
                            // In solar system view, show glowing zoom out icon when extended nav is closed
                            if gameState.showExtendedNavigation {
                                // When extended navigation is shown, show non-glowing zoom out icon
                                if let _ = UIImage(named: "ZoomOutMaps") {
                                    Image("ZoomOutMaps")
                                        .resizable()
                                        .frame(width: 28, height: 28)
                                        .foregroundColor(.blue)
                                } else {
                                    Text("🔭")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            } else {
                                // When extended navigation is closed, show glowing zoom out icon
                                GlowingZoomOutIcon()
                            }
                        }
                    } else if gameState.currentPage == .location {
                        // From location view, show glowing zoom out icon
                        GlowingZoomOutIcon()
                    } else {
                        // From other pages, show LocationView icon (fallback to globe if image missing)
                        if let image = UIImage(named: "LocationView") {
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 28, height: 28)
                                .foregroundColor(.white)
                        } else if let _ = UIImage(named: "SaturnLocation") {
                            Image("SaturnLocation")
                                .resizable()
                                .frame(width: 28, height: 28)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "globe")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                }

                Spacer()

            Button(action: {
                gameState.currentPage = .resources
                gameState.starMapViaTelescope = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    gameState.showExtendedNavigation = false
                }
            }) {
                Image(systemName: "cube.box.fill")
                    .font(.title2)
                    .foregroundColor(gameState.currentPage == .resources ? .blue : .white)
            }

                Spacer()

            Button(action: {
                gameState.currentPage = .cards
                gameState.starMapViaTelescope = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    gameState.showExtendedNavigation = false
                }
            }) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.title2)
                    .foregroundColor(gameState.currentPage == .cards ? .blue : .white)
            }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
        }
    }
}

// MARK: - Extended Navigation View
struct ExtendedNavigationView: View {
    @ObservedObject var gameState: GameState

    var body: some View {
        HStack {
            // Location View button (leftmost)
            Button(action: {
                // Go to location view
                gameState.currentPage = .location
                gameState.starMapViaTelescope = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    gameState.showExtendedNavigation = false
                }
            }) {
                if let image = UIImage(named: "LocationView") {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(gameState.currentPage == .location ? .blue : .white)
                } else {
                    Text("🌍")
                        .font(.title3)
                        .foregroundColor(gameState.currentPage == .location ? .blue : .white)
                }
            }

            Spacer()

            // Star System View button
            Button(action: {
                // Go to star system view (zoom into current system)
                if let constellation = gameState.getCurrentConstellation() {
                    let currentSystem = constellation.starSystems.first { starSystem in
                        starSystem.locations.contains { $0.id == gameState.currentLocation.id }
                    }
                    if let system = currentSystem {
                        gameState.zoomIntoStarSystem(system)
                        gameState.currentPage = .starMap
                        gameState.starMapViaTelescope = false
                    }
                }
                withAnimation(.easeInOut(duration: 0.3)) {
                    gameState.showExtendedNavigation = false
                }
            }) {
                if let image = UIImage(named: "StarSystem") {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(gameState.currentPage == .starMap && {
    if case .constellation = gameState.starMapZoomLevel {
        true
    } else {
        false
    }
}() ? .blue : .white)
                } else {
                    Text("🌟")
                        .font(.title3)
                        .foregroundColor(gameState.currentPage == .starMap && {
    if case .constellation = gameState.starMapZoomLevel {
        true
    } else {
        false
    }
}() ? .blue : .white)
                }
            }

            Spacer()

            // Multi-System View button (rightmost)
            Button(action: {
                // Go to constellation view (zoom out to multi-system)
                gameState.zoomOutToConstellation()
                gameState.currentPage = .starMap
                gameState.starMapViaTelescope = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    gameState.showExtendedNavigation = false
                }
            }) {
                if let image = UIImage(named: "MultiSystems") {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(gameState.currentPage == .starMap && {
    if case .constellation = gameState.starMapZoomLevel {
        true
    } else {
        false
    }
}() ? .blue : .white)
                } else {
                    Text("🌌")
                        .font(.title3)
                        .foregroundColor(gameState.currentPage == .starMap && {
    if case .constellation = gameState.starMapZoomLevel {
        true
    } else {
        false
    }
}() ? .blue : .white)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.4))
        .transition(.move(edge: .bottom))
    }
}

// MARK: - Construction Page View
struct ConstructionPageView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Construction Bays Header
                HStack {
                    Text("Construction Bays")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.adaptivePrimaryText)
                    Spacer()
                    
                    // Dev Tool Button - fixed position
                    Button(action: {
                        gameState.showDevToolsDropdown.toggle()
                    }) {
                        Text("DEV")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.adaptivePrimaryText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.adaptiveRedBackground)
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
                                    .foregroundColor(.adaptivePrimaryText)
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
                                    .foregroundColor(.adaptivePrimaryText)
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
                                    .foregroundColor(.adaptivePrimaryText)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.8))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(12)
                        .background(Color.adaptiveDarkBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.adaptiveBorder, lineWidth: 1)
                        )
                        .frame(width: 200) // Fixed width instead of full screen
                        .padding(.trailing, 16)
                    }
                    .padding(.top, 40) // Position below the header, touching the dev button
                    
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
            
            // Enhancement slots overlay - positioned at bottom without affecting layout
            VStack(spacing: 0) {
                Spacer()
                
                // Enhancement button - always visible
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        gameState.showConstructionSlots.toggle()
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
                    .background(Color.adaptiveCardBackground)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Enhancement slots - shown conditionally with animation
                if gameState.showConstructionSlots {
                    ConstructionSlotsView(gameState: gameState)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
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
                    gameState.currentPage = .blueprints
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
            
            // Award XP with multiplier
            let xpMultiplier = gameState.getXPGainMultiplier(for: "Construction")
            let xpAmount = Int(Double(construction.blueprint.xpReward) * xpMultiplier)
            gameState.addXP(xpAmount)
            
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
                    gameState.selectedBaySizeForBlueprints = .medium
                    gameState.currentPage = .blueprints
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
            
            // Award XP with multiplier
            let xpMultiplier = gameState.getXPGainMultiplier(for: "Construction")
            let xpAmount = Int(Double(construction.blueprint.xpReward) * xpMultiplier)
            gameState.addXP(xpAmount)
            
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
                    gameState.selectedBaySizeForBlueprints = .large
                    gameState.currentPage = .blueprints
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
            
            // Award XP with multiplier
            let xpMultiplier = gameState.getXPGainMultiplier(for: "Construction")
            let xpAmount = Int(Double(construction.blueprint.xpReward) * xpMultiplier)
            gameState.addXP(xpAmount)
            
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
            VStack(spacing: 0) {
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
                    .background(Color.adaptiveCardBackground)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Enhancement slots - shown conditionally with animation
                if gameState.showResourcesSlots {
                    ResourcesSlotsView(gameState: gameState)
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
        
        // Enhancement items
        case .excavator: return "hammer.fill"
        case .laserHarvester: return "laser.burst"
        case .virtualAlmanac: return "book.fill"
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
        
        // Enhancement items
        case .excavator: return .brown
        case .laserHarvester: return .red
        case .virtualAlmanac: return .purple
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
        case .excavator, .laserHarvester, .virtualAlmanac:
            return "Enhancement"
        case .copper, .gold, .lithium:
            return "Metals"
        }
    }
}

// MARK: - Card Detail View
struct CardDetailView: View {
    let cardId: String
    @ObservedObject var gameState: GameState
    @Environment(\.colorScheme) private var colorScheme

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
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.adaptivePrimaryText)
                    
                    Text("Card details and interactions will be available in a future update.")
                        .font(.callout)
                        .foregroundColor(.adaptiveSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding(40)
        }
        .frame(height: 200)
        .padding(.vertical, 8)
        .transition(.move(edge: .bottom))
    }
}

// MARK: - Star Map Visual Components

struct CelestialBodySymbol: View {
    let location: Location
    let isSelected: Bool
    let onTap: () -> Void
    let gameState: GameState?
    
    init(location: Location, isSelected: Bool, onTap: @escaping () -> Void, gameState: GameState? = nil) {
        self.location = location
        self.isSelected = isSelected
        self.onTap = onTap
        self.gameState = gameState
    }
    
    var body: some View {
        let isUnlocked = gameState?.isLocationUnlocked(location) ?? true
        
        Button(action: onTap) {
            ZStack {
                // Background circle for better visibility
                Circle()
                    .fill(isSelected ? Color.blue.opacity(0.3) : Color.clear)
                    .frame(width: 60, height: 60)
                
                // Special planet views for specific locations
                if location.name == "Taragam-7" {
                    Taragam7PlanetView(isSelected: isSelected, isUnlocked: isUnlocked)
                } else if location.name == "Elcinto" {
                    ElcintoMoonView(isSelected: isSelected, isUnlocked: isUnlocked)
                } else if location.name == "Taragam-3" {
                    Taragam3PlanetView(isSelected: isSelected, isUnlocked: isUnlocked)
                } else {
                    // Celestial body symbol for other locations
                    Image(systemName: symbolForLocation(location))
                        .font(.title2)
                        .foregroundColor(isUnlocked ? colorForLocation(location) : .gray)
                        .scaleEffect(isSelected ? 1.2 : 1.0)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isUnlocked ? 1.0 : 0.5)
    }
    
    private func symbolForLocation(_ location: Location) -> String {
        switch location.kind {
        case .planet: return "circle.fill"
        case .moon: return "moon.fill"
        case .star: return "sun.max.fill"
        case .ship: return "diamond.fill"
        case .anomaly: return "exclamationmark.triangle.fill"
        case .dwarf: return "circle.dotted"
        case .rogue: return "questionmark.circle.fill"
        }
    }
    
    private func colorForLocation(_ location: Location) -> Color {
        switch location.kind {
        case .planet: return .blue
        case .moon: return .gray
        case .star: return .yellow
        case .ship: return .green
        case .anomaly: return .purple
        case .dwarf: return .white
        case .rogue: return .red
        }
    }
}

struct Taragam7PlanetView: View {
    let isSelected: Bool
    let isUnlocked: Bool
    
    init(isSelected: Bool, isUnlocked: Bool = true) {
        self.isSelected = isSelected
        self.isUnlocked = isUnlocked
    }
    
    var body: some View {
        // Main planet body with blue/green gradient
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: isUnlocked ? [
                        Color.blue.opacity(0.9),
                        Color.cyan.opacity(0.7),
                        Color.green.opacity(0.6)
                    ] : [
                        Color.gray.opacity(0.9),
                        Color.gray.opacity(0.7),
                        Color.gray.opacity(0.6)
                    ]),
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 20
                )
            )
            .frame(width: 24, height: 24)
            .scaleEffect(isSelected ? 1.2 : 1.0)
    }
}

struct ElcintoMoonView: View {
    let isSelected: Bool
    let isUnlocked: Bool
    
    init(isSelected: Bool, isUnlocked: Bool = true) {
        self.isSelected = isSelected
        self.isUnlocked = isUnlocked
    }
    
    var body: some View {
        // Main moon body with yellow/brown gradient
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: isUnlocked ? [
                        Color.yellow.opacity(0.9),
                        Color.orange.opacity(0.7),
                        Color.brown.opacity(0.6)
                    ] : [
                        Color.gray.opacity(0.9),
                        Color.gray.opacity(0.7),
                        Color.gray.opacity(0.6)
                    ]),
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 12
                )
            )
            .frame(width: 18, height: 18) // Smaller than planet
            .scaleEffect(isSelected ? 1.2 : 1.0)
    }
}

struct Taragam3PlanetView: View {
    let isSelected: Bool
    let isUnlocked: Bool
    
    init(isSelected: Bool, isUnlocked: Bool = true) {
        self.isSelected = isSelected
        self.isUnlocked = isUnlocked
    }
    
    var body: some View {
        ZStack {
            // Planetary ring
            Circle()
                .stroke(isUnlocked ? Color.white.opacity(0.6) : Color.gray.opacity(0.6), lineWidth: 2)
                .frame(width: 32, height: 32)
                .scaleEffect(isSelected ? 1.2 : 1.0)
            
            // Main planet body with blue/white gradient
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: isUnlocked ? [
                            Color.blue.opacity(0.9),
                            Color.cyan.opacity(0.8),
                            Color.white.opacity(0.7)
                        ] : [
                            Color.gray.opacity(0.9),
                            Color.gray.opacity(0.8),
                            Color.gray.opacity(0.7)
                        ]),
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 20
                    )
                )
                .frame(width: 24, height: 24)
                .scaleEffect(isSelected ? 1.2 : 1.0)
        }
    }
}

struct CustomStarView: View {
    let starType: StarType
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // Outer glow effect
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            starType.color.opacity(0.4),
                            starType.color.opacity(0.1),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .scaleEffect(isSelected ? 1.3 : 1.0)
            
            // Main star body with gradient
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.9),
                            starType.color.opacity(0.8),
                            starType.color.opacity(0.6)
                        ]),
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 30
                    )
                )
                .frame(width: 60, height: 60)
                .scaleEffect(isSelected ? 1.2 : 1.0)
        }
    }
}

struct OrbitalRing: View {
    let radius: Double
    let isActive: Bool
    
    var body: some View {
        Circle()
            .stroke(
                isActive ? Color.white.opacity(0.6) : Color.gray.opacity(0.3),
                lineWidth: isActive ? 2 : 1
            )
            .frame(width: radius * 2, height: radius * 2)
    }
}

struct EllipticalOrbitalRing: View {
    let radiusX: Double
    let radiusY: Double
    let isActive: Bool
    
    var body: some View {
        Ellipse()
            .stroke(
                isActive ? Color.white.opacity(0.6) : Color.gray.opacity(0.3),
                lineWidth: isActive ? 2 : 1
            )
            .frame(width: radiusX * 2, height: radiusY * 2)
    }
}

struct StarSymbol: View {
    let starType: StarType
    let isSelected: Bool
    
    var body: some View {
        CustomStarView(starType: starType, isSelected: isSelected)
    }
}

// MARK: - Solar System View
struct SolarSystemView: View {
    @ObservedObject var gameState: GameState
    let starSystem: StarSystem
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                // Center point for the star system
                let centerX = geometry.size.width / 2
                let centerY = geometry.size.height / 2
                
                // Additional orbital rings for visual enhancement (keeping just 2)
                // 1 ring between Taragam-7 (100) and star (0) - at 50
                OrbitalRing(radius: 50, isActive: false)
                    .position(x: centerX, y: centerY)
                
                // 1 ring between Taragam-7 (100) and Taragam-3 (220) - at 160
                EllipticalOrbitalRing(radiusX: 160, radiusY: 140, isActive: false)
                    .position(x: centerX, y: centerY)
                
                // Orbital rings for actual celestial bodies (exclude stars and moons)
                ForEach(Array(starSystem.locations.enumerated()), id: \.offset) { index, location in
                    if location.kind != .star && location.kind != .moon {
                        let radius = calculateOrbitalRadius(for: location, at: index)
                        OrbitalRing(
                            radius: radius,
                            isActive: location.id == gameState.currentLocation.id
                        )
                        .position(x: centerX, y: centerY)
                    }
                }
                
                // Central star (clickable)
                Button(action: {
                    // Find the star location in this system
                    if let starLocation = starSystem.locations.first(where: { $0.kind == .star }) {
                        // If clicking the same location that's already selected, close the popup
                        if gameState.selectedLocationForPopup?.id == starLocation.id && gameState.showStarMapSlots {
                            gameState.selectedLocationForPopup = nil
                            gameState.showStarMapSlots = false
                        } else {
                            // Otherwise, show the popup for this location
                            gameState.selectedLocationForPopup = starLocation
                            gameState.showStarMapSlots = true
                        }
                    }
                }) {
                    StarSymbol(
                        starType: starSystem.starType,
                        isSelected: false
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .position(x: centerX, y: centerY)
                
                // Celestial bodies in their orbital positions
                ForEach(Array(starSystem.locations.enumerated()), id: \.element.id) { index, location in
                    if location.kind != .star {
                        Group {
                            if location.kind == .moon {
                                // Special positioning for moon - close to Taragam-7
                                let taragam7Index = starSystem.locations.firstIndex { $0.name == "Taragam-7" } ?? 0
                                let taragam7Radius = calculateOrbitalRadius(for: starSystem.locations[taragam7Index], at: taragam7Index)
                                let taragam7Angle = calculateOrbitalAngle(for: taragam7Index, total: starSystem.locations.count)
                                let taragam7X = centerX + taragam7Radius * cos(taragam7Angle)
                                let taragam7Y = centerY + taragam7Radius * sin(taragam7Angle)
                                
                                // Position moon close to Taragam-7 with small offset
                                let moonOffset = 40.0
                                let moonAngle = taragam7Angle + 0.3 // Small angular offset
                                let x = taragam7X + moonOffset * cos(moonAngle)
                                let y = taragam7Y + moonOffset * sin(moonAngle)
                                
                                ZStack {
                                    // Small orbital ring around Taragam-7 for the moon
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        .frame(width: moonOffset * 2, height: moonOffset * 2)
                                        .position(x: taragam7X, y: taragam7Y)
                                    
                                    // Moon symbol
                                    CelestialBodySymbol(
                                        location: location,
                                        isSelected: location.id == gameState.currentLocation.id,
                                        onTap: {
                                            // If clicking the same location that's already selected, close the popup
                                            if gameState.selectedLocationForPopup?.id == location.id && gameState.showStarMapSlots {
                                                gameState.selectedLocationForPopup = nil
                                                gameState.showStarMapSlots = false
                                            } else {
                                                // Otherwise, show the popup for this location
                                                gameState.selectedLocationForPopup = location
                                                gameState.showStarMapSlots = true
                                            }
                                        },
                                        gameState: gameState
                                    )
                                    .position(x: x, y: y)
                                }
                            } else {
                                // Normal orbital positioning for planets, ships, etc.
                                let radius = calculateOrbitalRadius(for: location, at: index)
                                let angle = calculateOrbitalAngle(for: location, at: index, total: starSystem.locations.count)
                                let x = centerX + radius * cos(angle)
                                let y = centerY + radius * sin(angle)
                                
                                CelestialBodySymbol(
                                    location: location,
                                    isSelected: location.id == gameState.currentLocation.id,
                                    onTap: {
                                        // If clicking the same location that's already selected, close the popup
                                        if gameState.selectedLocationForPopup?.id == location.id && gameState.showStarMapSlots {
                                            gameState.selectedLocationForPopup = nil
                                            gameState.showStarMapSlots = false
                                        } else {
                                            // Otherwise, show the popup for this location
                                            gameState.selectedLocationForPopup = location
                                            gameState.showStarMapSlots = true
                                        }
                                    },
                                    gameState: gameState
                                )
                                .position(x: x, y: y)
                            }
                        }
                    }
                }
                
                
                // Dev tool button (top right)
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            gameState.showStarMapDevToolsDropdown.toggle()
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
                        .padding(.trailing)
                    }
                    Spacer()
                }
                .padding(.top)
            }
            
            // Enhancement slots overlay - positioned at bottom without affecting layout
            VStack {
                Spacer()
                
                // Enhancement slots - shown conditionally with animation
                if gameState.showStarMapSlots {
                    StarMapSlotsView(gameState: gameState)
                        .padding(.bottom, 10) // Position just above navigation bar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            // Dev tools dropdown overlay
            VStack {
                HStack {
                    Spacer()
                    if gameState.showStarMapDevToolsDropdown {
                        VStack(alignment: .leading, spacing: 8) {
                            // Location Unlock Toggle
                            HStack {
                                Text("Unlock All Locations")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { gameState.devToolUnlockAllLocations },
                                    set: { _ in gameState.toggleLocationUnlock() }
                                ))
                                .toggleStyle(SwitchToggleStyle(tint: .green))
                                .scaleEffect(0.8)
                            }
                        }
                        .padding(12)
                        .background(Color.black.opacity(0.9))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .frame(width: 200)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .padding(.top, 60) // Position below the dev button
                .padding(.trailing, 16)
                Spacer()
            }
        }
    }
    
    private func calculateOrbitalRadius(for location: Location, at index: Int) -> Double {
        // Base radius with some variation based on location type
        let baseRadius = 100.0
        let typeMultiplier: Double = {
            switch location.kind {
            case .moon: return 0.7
            case .planet: return 1.0
            case .ship: return 1.0  // Ships now use same multiplier as planets
            case .anomaly: return 1.6
            default: return 1.0
            }
        }()
        
        // Special positioning for Abandoned Starship - just outside Taragam-3
        if location.name == "Abandoned Starship" {
            return 100.0 + (2 * 60.0) + 30.0  // Taragam-3's radius + small offset
        }
        
        return baseRadius + (Double(index) * 60.0) * typeMultiplier
    }
    
    private func calculateOrbitalAngle(for index: Int, total: Int) -> Double {
        // Distribute locations evenly around the star
        return (Double(index) / Double(total)) * 2 * .pi
    }
    
    private func calculateOrbitalAngle(for location: Location, at index: Int, total: Int) -> Double {
        // Special positioning for Abandoned Starship - above the star
        if location.name == "Abandoned Starship" {
            return -Double.pi / 2  // 90 degrees above (top)
        }
        
        // Distribute other locations evenly around the star
        return (Double(index) / Double(total)) * 2 * .pi
    }
}

// MARK: - Constellation View
struct ConstellationView: View {
    @ObservedObject var gameState: GameState
    let constellation: Constellation
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                // Center point
                let centerX = geometry.size.width / 2
                let centerY = geometry.size.height / 2
                
                // Star systems
                ForEach(Array(constellation.starSystems.enumerated()), id: \.element.id) { index, starSystem in
                    let angle = calculateSystemAngle(for: index, total: constellation.starSystems.count)
                    let distance = 150.0 + (Double(index) * 50.0)
                    let x = centerX + distance * cos(angle)
                    let y = centerY + distance * sin(angle)
                    
                    Button(action: {
                        gameState.zoomIntoStarSystem(starSystem)
                    }) {
                        VStack(spacing: 4) {
                            // Use MiniStarSystemView for Taragon Gamma, StarSymbol for others
                            if starSystem.name == "Taragon Gamma" {
                                MiniStarSystemView(gameState: gameState, starSystem: starSystem)
                            } else {
                                StarSymbol(
                                    starType: starSystem.starType,
                                    isSelected: false
                                )
                            }
                            Text(starSystem.name)
                                .font(.caption)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .position(x: x, y: y)
                }
                
                // Dev tool button (top right)
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            gameState.showStarMapDevToolsDropdown.toggle()
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
                        .padding(.trailing)
                    }
                    Spacer()
                }
                .padding(.top)
            }
            
            // Enhancement slots overlay - positioned at bottom without affecting layout
            VStack {
                Spacer()
                
                // Enhancement slots - shown conditionally with animation
                if gameState.showStarMapSlots {
                    StarMapSlotsView(gameState: gameState)
                        .padding(.bottom, 10) // Position just above navigation bar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            // Dev tools dropdown overlay
            VStack {
                HStack {
                    Spacer()
                    if gameState.showStarMapDevToolsDropdown {
                        VStack(alignment: .leading, spacing: 8) {
                            // Location Unlock Toggle
                            HStack {
                                Text("Unlock All Locations")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { gameState.devToolUnlockAllLocations },
                                    set: { _ in gameState.toggleLocationUnlock() }
                                ))
                                .toggleStyle(SwitchToggleStyle(tint: .green))
                                .scaleEffect(0.8)
                            }
                        }
                        .padding(12)
                        .background(Color.black.opacity(0.9))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .frame(width: 200)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .padding(.top, 60) // Position below the dev button
                .padding(.trailing, 16)
                Spacer()
            }
        }
    }
    
    private func calculateSystemAngle(for index: Int, total: Int) -> Double {
        return (Double(index) / Double(total)) * 2 * .pi
    }
}

// MARK: - Placeholder Views
struct StarMapView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        Group {
            switch gameState.starMapZoomLevel {
            case .constellation:
                if let constellation = gameState.getCurrentConstellation() {
                    ConstellationView(gameState: gameState, constellation: constellation)
                } else {
                    // Fallback to old list view
                    oldStarMapView
                }
            case .solarSystem(let starSystem):
                SolarSystemView(gameState: gameState, starSystem: starSystem)
            }
        }
    }
    
    private var oldStarMapView: some View {
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
                        // If clicking the same location that's already selected, close the popup
                        if gameState.selectedLocationForPopup?.id == location.id && gameState.showStarMapSlots {
                            gameState.selectedLocationForPopup = nil
                            gameState.showStarMapSlots = false
                        } else {
                            // Otherwise, show the popup for this location
                            gameState.selectedLocationForPopup = location
                            gameState.showStarMapSlots = true
                        }
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
            
            // Enhancement slots overlay - positioned at bottom without affecting layout
            VStack {
                Spacer()
                
                // Enhancement button - always visible
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        gameState.showStarMapSlots.toggle()
                    }
                }) {
                    HStack {
                        Text("Location")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Enhancement slots - shown conditionally with animation
                if gameState.showStarMapSlots {
                    StarMapSlotsView(gameState: gameState)
                        .padding(.bottom, 10) // Position just above navigation bar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
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
                        .font(.largeTitle)
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
            VStack(spacing: 0) {
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
                    .background(Color.adaptiveCardBackground)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Enhancement slots - shown conditionally with animation
                if gameState.showShopSlots {
                    ShopSlotsView(gameState: gameState)
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
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Fixed Header with Dev Button - using template
                DevButtonHeaderView(
                    title: "Cards",
                    onButtonTap: {
                        gameState.showCardsDevToolsDropdown.toggle()
                    }
                )
                
                ScrollView {
                    VStack(spacing: 24) {
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
            }
            
                    VStack {
                        Spacer()
                    }
            
            // Enhancement slots overlay - positioned at bottom without affecting layout
            VStack(spacing: 0) {
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
                    .background(Color.adaptiveCardBackground)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Enhancement slots - shown conditionally with animation
                if gameState.showCardsSlots {
                    CardsSlotsView(gameState: gameState)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            // Dropdown Overlay - using template
            DevButtonWithDropdownView(
                isDropdownVisible: $gameState.showCardsDevToolsDropdown
            ) {
                VStack(spacing: 8) {
                    // +1 All Cards Button (top)
                    Button(action: {
                        gameState.addOneOfEachCard()
                        // Note: Removed line that closes dropdown to keep it open
                    }) {
                        Text("+1 All Cards")
                            .font(.caption)
                            .foregroundColor(.white)
                            .frame(width: 100)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Level Up Button
                    Button(action: {
                        gameState.levelUpAllCards()
                        // Note: Removed line that closes dropdown to keep it open
                    }) {
                        Text("Level Up")
                            .font(.caption)
                            .foregroundColor(.white)
                            .frame(width: 100)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.8))
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Level Down Button
                    Button(action: {
                        gameState.levelDownAllCards()
                        // Note: Removed line that closes dropdown to keep it open
                    }) {
                        Text("Level Down")
                            .font(.caption)
                            .foregroundColor(.white)
                            .frame(width: 100)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.8))
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Cards")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CardClassSection: View {
    let title: String
    let cardClass: CardClass
    @ObservedObject var gameState: GameState
    @Environment(\.colorScheme) private var colorScheme
    
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
                .foregroundColor(.adaptivePrimaryText)
            
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
                    // Toggle detail view - if same card is tapped again, close it
                    if gameState.selectedCardForDetail == cardDef.id {
                        gameState.selectedCardForDetail = nil
                    } else {
                        gameState.selectedCardForDetail = cardDef.id
                    }
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
                                .font(.largeTitle)
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
                                .font(.largeTitle)
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
            return "🔭"
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

// MARK: - Segmented Button View
struct SegmentedButtonView: View {
    let labels: [String]
    @Binding var selectedIndex: Int
    let onSelectionChanged: (Int) -> Void
    let isUnlocked: [Bool]
    
    init(
        labels: [String],
        selectedIndex: Binding<Int>,
        onSelectionChanged: @escaping (Int) -> Void,
        isUnlocked: [Bool]
    ) {
        self.labels = labels
        self._selectedIndex = selectedIndex
        self.onSelectionChanged = onSelectionChanged
        self.isUnlocked = isUnlocked
    }
    
    var body: some View {
        ZStack {
            // Background with border
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray, lineWidth: 1)
                )
            
            // Highlighted section background
            HStack(spacing: 0) {
                ForEach(0..<labels.count, id: \.self) { index in
                    if selectedIndex == index {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                            .frame(maxWidth: .infinity, maxHeight: 32)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(maxWidth: .infinity, maxHeight: 32)
                    }
                }
            }
            
            // Button text overlay
            HStack(spacing: 0) {
                ForEach(0..<labels.count, id: \.self) { index in
                    let isButtonUnlocked = index < isUnlocked.count ? isUnlocked[index] : true
                    
                    Button(action: {
                        if isButtonUnlocked {
                            selectedIndex = index
                            onSelectionChanged(index)
                        }
                    }) {
                        Text(labels[index])
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(
                                selectedIndex == index ? .black : 
                                (isButtonUnlocked ? .white : .gray)
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!isButtonUnlocked)
                }
            }
        }
        .frame(height: 32)
    }
}

// MARK: - Statistics and Objectives View (Main UI)
struct StatisticsAndObjectivesView: View {
    @ObservedObject var gameState: GameState
    @State private var selectedTabIndex = 1 // Default to Statistics (index 1)
    @State private var selectedObjectivesTabIndex = 0 // Default to Daily (index 0)
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // Segmented Button for Objectives/Statistics
                SegmentedButtonView(
                    labels: ["Objectives", "Statistics"],
                    selectedIndex: $selectedTabIndex,
                    onSelectionChanged: { index in
                        // Handle tab selection if needed
                    },
                    isUnlocked: [true, true]
                )
                
                // Show content based on selected tab
                if selectedTabIndex == 0 { // Objectives tab
                    // Second Segmented Button for Objectives subcategories
                    SegmentedButtonView(
                        labels: ["Daily", "Seasonal", "∞"],
                        selectedIndex: $selectedObjectivesTabIndex,
                        onSelectionChanged: { index in
                            // Handle objectives subcategory selection if needed
                        },
                        isUnlocked: [true, true, true]
                    )
                    
                    // Objectives content will go here
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Objectives Coming Soon")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                } else if selectedTabIndex == 1 { // Statistics tab
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
                } // End of Statistics tab content
                
                } // End of main VStack
                .padding()
            } // End of ScrollView
        } // End of body
    } // End of StatisticsAndObjectivesView struct

// MARK: - Objectives View (Popup - kept for reference)
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

// MARK: - Blueprints View
struct BlueprintsView: View {
    @ObservedObject var gameState: GameState
    let initialBaySize: BaySize
    @State private var selectedBaySize: BaySize
    @State private var expandedBlueprints: Set<String> = []
    @State private var showEnhancementAbilities = false
    @Environment(\.colorScheme) private var colorScheme
    
    init(gameState: GameState, initialBaySize: BaySize = .small) {
        self.gameState = gameState
        self.initialBaySize = initialBaySize
        self._selectedBaySize = State(initialValue: initialBaySize)
        print("🔍 BlueprintsView init - initialBaySize: \(initialBaySize)")
    }
    
    private var filteredBlueprints: [ConstructionBlueprint] {
        let filtered = ConstructionBlueprint.allBlueprints.filter { $0.requiredBaySize == selectedBaySize }
        print("🔍 Filtered blueprints for \(selectedBaySize): \(filtered.count) blueprints")
        return filtered
    }
    
    private func hasUnlockedBay(of size: BaySize) -> Bool {
        return gameState.constructionBays.contains { $0.size == size && $0.isUnlocked }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            let _ = print("🔍 BlueprintsView body - selectedBaySize: \(selectedBaySize), initialBaySize: \(initialBaySize)")
            // Header
            HStack {
                Text("Construction Blueprints")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.adaptivePrimaryText)
                
                Spacer()
                
                // Dev tool button for Enhancement Abilities
                Button(action: {
                    showEnhancementAbilities = true
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
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            // Bay Size Selector - Single Button with Three Sections
            ZStack {
                // Background with border
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                
                // Highlighted section background
                HStack(spacing: 0) {
                    ForEach(BaySize.allCases, id: \.self) { baySize in
                        if selectedBaySize == baySize {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white)
                                .frame(maxWidth: .infinity, maxHeight: 32)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(maxWidth: .infinity, maxHeight: 32)
                        }
                    }
                }
                
                // Button text overlay
                HStack(spacing: 0) {
                    ForEach(BaySize.allCases, id: \.self) { baySize in
                        let _ = print("🔍 BaySize.allCases order: \(BaySize.allCases.map { $0.rawValue })")
                        let isUnlocked = hasUnlockedBay(of: baySize)
                        Button(action: {
                            if isUnlocked {
                                print("🔍 Button clicked - changing selectedBaySize from \(selectedBaySize) to \(baySize)")
                                selectedBaySize = baySize
                            }
                        }) {
                            Text(baySize.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selectedBaySize == baySize ? .black : (isUnlocked ? .white : .gray))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(!isUnlocked)
                    }
                }
            }
            .frame(height: 32)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Blueprints List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredBlueprints, id: \.id) { blueprint in
                        BlueprintCardView(
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
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100) // Space for bottom nav
            }
        }
        .background(Color.black)
        .sheet(isPresented: $showEnhancementAbilities) {
            EnhancementAbilitiesView()
        }
    }
}

// MARK: - Blueprint Card View
struct BlueprintCardView: View {
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
        )
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
        default: return "cube.fill"
        }
    }
    
    private func getResourceColor(for type: ResourceType) -> Color {
        switch type {
        case .ironOre: return .gray
        case .silicon: return .blue
        case .water: return .blue
        case .oxygen: return .cyan
        case .graphite: return .gray
        case .nitrogen: return .purple
        case .phosphorus: return .orange
        case .sulfur: return .yellow
        case .calcium: return .white
        case .magnesium: return .green
        case .helium3: return .cyan
        case .titanium: return .gray
        case .aluminum: return .gray
        case .nickel: return .gray
        case .cobalt: return .blue
        case .chromium: return .gray
        case .vanadium: return .green
        case .manganese: return .purple
        case .plasma: return .purple
        case .element: return .yellow
        case .isotope: return .orange
        case .energy: return .yellow
        case .radiation: return .red
        case .heat: return .red
        case .light: return .yellow
        case .gravity: return .purple
        case .magnetic: return .blue
        case .solar: return .yellow
        case .numins: return .purple
        default: return .white
        }
    }
}

// MARK: - Star Map Slots View
struct StarMapSlotsView: View {
    @ObservedObject var gameState: GameState
    
    private func getLockedLocationName(_ location: Location) -> String {
        switch location.name {
        case "Elcinto":
            return "Unlisted Moon"
        case "Taragam-3":
            return "Unlisted Planet"
        case "Taragon Gamma":
            return "Unlisted Star"
        case "Abandoned Starship":
            return "Unidentifed Object"
        default:
            return "Undiscovered Location"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Location popup content
            if let selectedLocation = gameState.selectedLocationForPopup {
                let isUnlocked = gameState.isLocationUnlocked(selectedLocation)
                
                HStack {
                    // Left side - Location info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isUnlocked ? selectedLocation.name : getLockedLocationName(selectedLocation))
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text(isUnlocked ? "\(selectedLocation.system) • \(selectedLocation.kind.rawValue)" : "Details Unknown")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Right side - Button
                    Button(action: {
                        if isUnlocked {
                            gameState.changeLocation(to: selectedLocation)
                            gameState.currentPage = .location
                            gameState.showingLocationList = false
                        }
                        gameState.selectedLocationForPopup = nil
                        gameState.showStarMapSlots = false
                    }) {
                        Text(isUnlocked ? (selectedLocation.id == gameState.currentLocation.id ? "Return Here" : "Go") : "Unlock Conditions Not Met")
                            .font(isUnlocked ? .headline : .caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(isUnlocked ? Color.blue : Color.gray)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
    }
}

// MARK: - Mini Star System View
struct MiniStarSystemView: View {
    @ObservedObject var gameState: GameState
    let starSystem: StarSystem
    
    var body: some View {
        ZStack {
            // Mini orbital rings (scaled down)
            ForEach(Array(starSystem.locations.enumerated()), id: \.offset) { index, location in
                if location.kind != .star && location.kind != .moon {
                    let radius = calculateMiniOrbitalRadius(for: location, at: index) * 0.3 // Scale down
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                        .frame(width: radius * 2, height: radius * 2)
                }
            }
            
            // Central star (scaled down)
            StarSymbol(
                starType: starSystem.starType,
                isSelected: false
            )
            .scaleEffect(0.4) // Scale down the star
            
            // Celestial bodies in their orbital positions (scaled down)
            ForEach(Array(starSystem.locations.enumerated()), id: \.element.id) { index, location in
                if location.kind != .star {
                    Group {
                        if location.kind == .moon {
                            // Special positioning for moon - close to its parent planet
                            let parentIndex = starSystem.locations.firstIndex { $0.name == "Taragam-7" } ?? 0
                            let parentRadius = calculateMiniOrbitalRadius(for: starSystem.locations[parentIndex], at: parentIndex) * 0.3
                            let parentAngle = calculateMiniOrbitalAngle(for: parentIndex, total: starSystem.locations.count)
                            let parentX = parentRadius * cos(parentAngle)
                            let parentY = parentRadius * sin(parentAngle)
                            
                            // Position moon close to parent with small offset
                            let moonOffset = 8.0 // Scaled down offset
                            let moonAngle = parentAngle + 0.3
                            let x = parentX + moonOffset * cos(moonAngle)
                            let y = parentY + moonOffset * sin(moonAngle)
                            
                            CelestialBodySymbol(
                                location: location,
                                isSelected: false,
                                onTap: {},
                                gameState: gameState
                            )
                            .scaleEffect(0.3) // Scale down
                            .offset(x: x, y: y)
                        } else {
                            // Normal orbital positioning for planets, ships, etc.
                            let radius = calculateMiniOrbitalRadius(for: location, at: index) * 0.3
                            let angle = calculateMiniOrbitalAngle(for: index, total: starSystem.locations.count)
                            let x = radius * cos(angle)
                            let y = radius * sin(angle)
                            
                            CelestialBodySymbol(
                                location: location,
                                isSelected: false,
                                onTap: {},
                                gameState: gameState
                            )
                            .scaleEffect(0.3) // Scale down
                            .offset(x: x, y: y)
                        }
                    }
                }
            }
        }
        .frame(width: 60, height: 60) // Fixed size for mini view
    }
    
    private func calculateMiniOrbitalRadius(for location: Location, at index: Int) -> Double {
        // Base radius with some variation based on location type
        let baseRadius = 100.0
        let typeMultiplier: Double = {
            switch location.kind {
            case .moon: return 0.7
            case .planet: return 1.0
            case .ship: return 1.2
            case .star: return 0.0
            case .anomaly: return 1.1
            case .dwarf: return 0.8
            case .rogue: return 1.3
            }
        }()
        return baseRadius * typeMultiplier
    }
    
    private func calculateMiniOrbitalAngle(for index: Int, total: Int) -> Double {
        // Distribute locations evenly around the star
        return (Double(index) / Double(total)) * 2 * .pi
    }
}

struct StarMapSlotView: View {
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

// MARK: - Enhancement Abilities View

struct EnhancementAbilitiesView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let enhancementAbilities = [
        EnhancementAbility(
            id: "excavator",
            name: "Excavator",
            description: "Increases resource collection efficiency by 25% when slotted on any screen. Provides bonus XP gain from resource collection activities.",
            icon: "hammer.fill",
            color: .brown,
            discoveryCost: 500,
            effectType: "Resource Collection Boost",
            effectValue: "+25%"
        ),
        EnhancementAbility(
            id: "laser-harvester",
            name: "Laser Harvester",
            description: "Automatically harvests resources from the current location every 30 seconds. Provides passive resource generation without manual tapping.",
            icon: "laser.burst",
            color: .red,
            discoveryCost: 750,
            effectType: "Passive Harvesting",
            effectValue: "Every 30s"
        ),
        EnhancementAbility(
            id: "virtual-almanac",
            name: "Virtual Almanac",
            description: "Reveals detailed information about all locations and their resource drop rates. Provides strategic insights for optimal resource collection.",
            icon: "book.fill",
            color: .purple,
            discoveryCost: 1000,
            effectType: "Location Intelligence",
            effectValue: "Full Details"
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Enhancement Abilities")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // Abilities List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(enhancementAbilities, id: \.id) { ability in
                            EnhancementAbilityCard(ability: ability)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // Space for navigation
                }
            }
            .background(Color.black)
        }
    }
}

// MARK: - Enhancement Ability Model
struct EnhancementAbility: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: Color
    let discoveryCost: Int
    let effectType: String
    let effectValue: String
}

// MARK: - Enhancement Ability Card
struct EnhancementAbilityCard: View {
    let ability: EnhancementAbility
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: ability.icon)
                    .font(.title2)
                    .foregroundColor(ability.color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(ability.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(ability.effectType)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(ability.effectValue)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Discovery Cost: \(ability.discoveryCost)")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
            }
            
            // Description
            Text(ability.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(ability.color.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
    }
}

// MARK: - Dev Button with Dropdown View Template
struct DevButtonWithDropdownView<Content: View>: View {
    @Binding var isDropdownVisible: Bool
    let content: () -> Content
    let dropdownWidth: CGFloat
    
    init(
        isDropdownVisible: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content,
        dropdownWidth: CGFloat = 200
    ) {
        self._isDropdownVisible = isDropdownVisible
        self.content = content
        self.dropdownWidth = dropdownWidth
    }
    
    var body: some View {
        // Dropdown Overlay - positioned absolutely (full screen overlay)
        if isDropdownVisible {
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        content()
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.9))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .frame(minWidth: dropdownWidth, maxWidth: dropdownWidth, alignment: .trailing) // Fixed width with right alignment
                    .padding(.trailing, 16) // Add 16 points of right padding
                }
                .padding(.top, 40) // Position below the header, touching the dev button
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // No background - let scrolling pass through completely
            .zIndex(1000)
        }
    }
}

// MARK: - Dev Button Template (separate component for the button)
struct DevButtonView: View {
    let buttonText: String
    let buttonColor: Color
    let onButtonTap: () -> Void
    
    init(
        buttonText: String = "DEV",
        buttonColor: Color = Color.red.opacity(0.8),
        onButtonTap: @escaping () -> Void
    ) {
        self.buttonText = buttonText
        self.buttonColor = buttonColor
        self.onButtonTap = onButtonTap
    }
    
    var body: some View {
        Button(action: onButtonTap) {
            Text(buttonText)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(buttonColor)
                .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Dev Button Header Template (includes proper header structure)
struct DevButtonHeaderView: View {
    let title: String
    let buttonText: String
    let buttonColor: Color
    let onButtonTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        title: String,
        buttonText: String = "DEV",
        buttonColor: Color = Color.red.opacity(0.8),
        onButtonTap: @escaping () -> Void
    ) {
        self.title = title
        self.buttonText = buttonText
        self.buttonColor = buttonColor
        self.onButtonTap = onButtonTap
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.adaptivePrimaryText)
            Spacer()
            
            DevButtonView(
                buttonText: buttonText,
                buttonColor: buttonColor,
                onButtonTap: onButtonTap
            )
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }
}

#Preview {
    ContentView()
}

