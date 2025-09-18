//
//  AdaptiveColors.swift
//  UniverseRPG
//
//  Created by Adam Epstein on 9/3/25.
//

import SwiftUI

// MARK: - Adaptive Color System
// This system preserves the current dark mode appearance while adapting to light mode
// Now controlled by GameState.appColorScheme instead of system color scheme

extension Color {
    // MARK: - Primary Text Colors
    // Current: .white (dark mode optimized)
    // Light mode: Dark text for readability
    static var adaptivePrimaryText: Color {
        .white
    }
    
    // MARK: - Secondary Text Colors  
    // Current: .gray (dark mode optimized)
    // Light mode: Darker gray for readability
    static var adaptiveSecondaryText: Color {
        .gray
    }
    
    // MARK: - Background Colors
    // Current: Color.black.opacity(0.8) (dark mode optimized)
    // Light mode: White with appropriate opacity
    static var adaptiveDarkBackground: Color {
        Color.black.opacity(0.8)
    }
    
    // Current: Color.black.opacity(0.3) (dark mode optimized)
    // Light mode: Light gray with appropriate opacity
    static var adaptiveSemiTransparentBackground: Color {
        Color.black.opacity(0.3)
    }
    
    // Current: Color.black.opacity(0.85) (dark mode optimized)
    // Light mode: Light card background
    static var adaptiveCardBackground: Color {
        Color.black.opacity(0.85)
    }
    
    // Current: Color.black (dark mode optimized)
    // Light mode: White background
    static var adaptiveSolidBackground: Color {
        .black
    }
    
    // MARK: - Border Colors
    // Current: .gray (dark mode optimized)
    // Light mode: Dark borders for contrast
    static var adaptiveBorder: Color {
        .gray
    }
    
    // Current: Color.gray.opacity(0.5) (dark mode optimized)
    // Light mode: Darker gray with opacity
    static var adaptiveBorderLight: Color {
        Color.gray.opacity(0.5)
    }
    
    // MARK: - Accent Colors (preserve current colors)
    // These colors work well in both modes, so we keep them as-is
    static var adaptiveBlue: Color { .blue }
    static var adaptiveGreen: Color { .green }
    static var adaptiveYellow: Color { .yellow }
    static var adaptiveRed: Color { .red }
    
    // MARK: - Special Background Colors
    // Current: Color.blue.opacity(0.1) (dark mode optimized)
    // Light mode: Lighter blue
    static var adaptiveBlueBackground: Color {
        Color.blue.opacity(0.1)
    }
    
    // Current: Color.green.opacity(0.2) (dark mode optimized)
    // Light mode: Lighter green
    static var adaptiveGreenBackground: Color {
        Color.green.opacity(0.2)
    }
    
    // Current: Color.yellow.opacity(0.2) (dark mode optimized)
    // Light mode: Lighter yellow
    static var adaptiveYellowBackground: Color {
        Color.yellow.opacity(0.2)
    }
    
    // Current: Color.red.opacity(0.8) (dark mode optimized)
    // Light mode: Lighter red
    static var adaptiveRedBackground: Color {
        Color.red.opacity(0.8)
    }
}

// MARK: - Convenience View Modifiers
extension View {
    // Apply adaptive primary text color
    func adaptivePrimaryText() -> some View {
        self.foregroundColor(.adaptivePrimaryText)
    }
    
    // Apply adaptive secondary text color
    func adaptiveSecondaryText() -> some View {
        self.foregroundColor(.adaptiveSecondaryText)
    }
    
    // Apply adaptive dark background
    func adaptiveDarkBackground() -> some View {
        self.background(Color.adaptiveDarkBackground)
    }
    
    // Apply adaptive semi-transparent background
    func adaptiveSemiTransparentBackground() -> some View {
        self.background(Color.adaptiveSemiTransparentBackground)
    }
    
    // Apply adaptive card background
    func adaptiveCardBackground() -> some View {
        self.background(Color.adaptiveCardBackground)
    }
    
    // Apply adaptive solid background
    func adaptiveSolidBackground() -> some View {
        self.background(Color.adaptiveSolidBackground)
    }
}