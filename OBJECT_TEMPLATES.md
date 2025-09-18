# UniverseRPG - Object Templates

This document contains reusable UI components and templates for the UniverseRPG game. Each component is categorized by type and includes a description, visual representation, and code template.

## Table of Contents

- [Buttons](#buttons)
  - [SegmentedButtonView](#segmentedbuttonview)
  - [DevButtonWithDropdownView](#devbuttonwithdropdownview)
- [Menus](#menus)
- [Pop-out Windows](#pop-out-windows)
- [Cards](#cards)
- [Lists](#lists)
- [Input Fields](#input-fields)
- [Progress Indicators](#progress-indicators)

---

## Buttons

### SegmentedButtonView
**Type:** Button  
**Description:** A segmented control-style button with multiple sections that looks like a single button but functions as multiple clickable areas. Perfect for filtering, selection, or mode switching. You can specify any number of buttons with any labels you want - the component adapts automatically.

**Visual Representation:**
```
┌─────────────────────────────────────┐
│  [Button1] [Button2] [Button3]      │
│  ^^^^^^^^^                          │
│  Selected (white background)        │
└─────────────────────────────────────┘
```

**Variables:**

**Required Variables:**
- `labels: [String]` - Array of button text labels
- `selectedIndex: Binding<Int>` - Currently selected button index
- `onSelectionChanged: (Int) -> Void` - Callback when selection changes
- `isUnlocked: [Bool]` - Array indicating which buttons are enabled

**Fixed Styling (matches in-game implementation):**
**Note:** This template uses negative padding (-32pt) to compensate for ScrollView layout context. When used in a ScrollView (like Cards page), the dropdown needs to be positioned relative to the screen edge rather than the parent container edge.
- Height: 32 points
- Corner radius: 6
- Border color: Color.gray
- Selected background: Color.white
- Selected text color: .black
- Unlocked text color: .white
- Locked text color: .gray
- Font: .caption
- Font weight: .medium
- Width: Constrained by horizontal padding (16 points on each side)

**Code Template:**
```swift
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
        .padding(.horizontal, 16)
    }
}
```

**Usage Examples:**

**Example 1: Bay Size Selection**
```swift
SegmentedButtonView(
    labels: ["Small", "Medium", "Large"],
    selectedIndex: $selectedBaySizeIndex,
    onSelectionChanged: { index in
        selectedBaySize = BaySize.allCases[index]
    },
    isUnlocked: [true, true, false] // Large locked
)
```

**Example 2: Resource Type Filter**
```swift
SegmentedButtonView(
    labels: ["All", "Mining", "Research", "Construction"],
    selectedIndex: $selectedResourceTypeIndex,
    onSelectionChanged: { index in
        // Handle resource type selection
    },
    isUnlocked: [true, true, true, true] // All unlocked
)
```

**Example 3: Difficulty Level Selector**
```swift
SegmentedButtonView(
    labels: ["Easy", "Normal", "Hard", "Expert"],
    selectedIndex: $selectedDifficultyIndex,
    onSelectionChanged: { index in
        // Handle difficulty selection
    },
    isUnlocked: [true, true, false, false] // Only Easy and Normal unlocked
)
```

**Example 4: Variable Button Count**
```swift
// 2 buttons - each takes 50% of total width
SegmentedButtonView(
    labels: ["Yes", "No"],
    selectedIndex: $yesNoIndex,
    onSelectionChanged: { index in
        // Handle yes/no selection
    },
    isUnlocked: [true, true]
)

// 5 buttons - each takes 20% of total width
SegmentedButtonView(
    labels: ["A", "B", "C", "D", "E"],
    selectedIndex: $optionIndex,
    onSelectionChanged: { index in
        // Handle option selection
    },
    isUnlocked: [true, true, true, false, false]
)
```

**Key Features:**
- **Flexible Labels**: Use any number of buttons with any text labels
- **Consistent Total Width**: The segmented button maintains the same total width regardless of button count - each button gets an equal share
- **Width Constraint**: Fixed width constraint with 16-point horizontal padding (matches in-game implementation)
- **Lock/Unlock Support**: Individual buttons can be disabled
- **Consistent Styling**: Matches in-game UI exactly (32pt height, 6pt corner radius, gray border, white selected background)
- **Binding Support**: Works with `@State` and `@Binding`
- **Callback Support**: `onSelectionChanged` for additional logic

**Common Use Cases:**
- Bay size selection (Small/Medium/Large)
- Resource type filtering (All/Mining/Research)
- Difficulty level selection (Easy/Normal/Hard)
- Planet type filtering (All/Terrestrial/Gas Giant)
- Mode switching (View/Edit/Delete)
- Category filtering (All/Active/Completed)
- Any multi-option selection interface

### DevButtonWithDropdownView
**Type:** Dropdown Overlay  
**Description:** A dropdown window overlay that appears when triggered by a dev button. Perfect for developer tools, debug options, or admin controls. The dropdown content area is empty and customizable for different implementations. This component only handles the dropdown overlay - the button should be implemented using `DevButtonHeaderView` for proper header positioning.

**Visual Representation:**
```
┌─────────────────────────────────────┐
│  Page Title                    [DEV] │
│  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    │
│                                      │
│  ┌─────────────────────────────┐    │
│  │  [Dropdown Content Area]    │    │
│  │  (Empty - customizable)     │    │
│  │                             │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

**Variables:**

**Required Variables:**
- `isDropdownVisible: Binding<Bool>` - Controls dropdown visibility
- `content: () -> Content` - Custom content for the dropdown (using @ViewBuilder for flexibility)

**Optional Variables:**
- `dropdownWidth: CGFloat` - Width of the dropdown window (default: 200)

**Fixed Styling (matches in-game implementation):**
**Note:** This template uses negative padding (-32pt) to compensate for ScrollView layout context. When used in a ScrollView (like Cards page), the dropdown needs to be positioned relative to the screen edge rather than the parent container edge.
- Dropdown background: Color.black.opacity(0.9)
- Dropdown corner radius: 8
- Dropdown border: Color.gray, 1pt width
- Dropdown padding: 12
- Dropdown z-index: 1000
- Dropdown positioning: Top-right aligned, below header, right-justified to screen edge (compensates for ScrollView context)
- Scrollability: Page remains scrollable while dropdown is open (allows scrolling through content)
- Full screen overlay with tap-outside-to-close
- Page remains scrollable while dropdown is open

**Code Template:**
```swift
// MARK: - Dev Button with Dropdown View (Dropdown Overlay Only)
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
            .background(
                // Invisible background to catch taps outside the dropdown
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Close dropdown when tapping outside
                        isDropdownVisible = false
                    }
            )
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
                .foregroundColor(.white)
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
```

**Usage Examples:**

**Example 1: Basic Dev Tools (Construction Bays style)**
```swift
// In your page view:
ZStack {
    // Your main content here
    VStack(spacing: 0) {
        // Header with dev button - using template
        DevButtonHeaderView(
            title: "Construction Bays",
            onButtonTap: {
                gameState.showDevToolsDropdown.toggle()
            }
        )
        
        // Rest of your content...
        VStack(spacing: 24) {
            // Your page content here
        }
        .padding()
    }
    
    // Dropdown Overlay
    DevButtonWithDropdownView(
        isDropdownVisible: $gameState.showDevToolsDropdown
    ) {
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
}
```

**Example 2: Debug Tools (Cards page style)**
```swift
// In your page view:
ZStack {
    // Your main content here
    VStack(spacing: 0) {
        // Header with dev button - using template
        DevButtonHeaderView(
            title: "Cards",
            buttonText: "DEBUG",
            buttonColor: Color.blue.opacity(0.8),
            onButtonTap: {
                gameState.showCardsDevToolsDropdown.toggle()
            }
        )
        
        // Rest of your content...
        VStack(spacing: 24) {
            // Your page content here
        }
        .padding()
    }
    
    // Dropdown Overlay
    DevButtonWithDropdownView(
        isDropdownVisible: $gameState.showCardsDevToolsDropdown,
        dropdownWidth: 180
    ) {
        // Add Card Button
        Button(action: {
            gameState.addRandomCard()
            gameState.showCardsDevToolsDropdown = false
        }) {
            Text("Add Random Card")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.8))
                .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
        
        // Clear All Cards Button
        Button(action: {
            gameState.clearAllCards()
            gameState.showCardsDevToolsDropdown = false
        }) {
            Text("Clear All Cards")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.8))
                .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

**Example 3: Admin Panel (Star Map style)**
```swift
// In your page view:
ZStack {
    // Your main content here
    VStack(spacing: 0) {
        // Header with dev button - using template
        DevButtonHeaderView(
            title: "Star Map",
            buttonText: "ADMIN",
            buttonColor: Color.purple.opacity(0.8),
            onButtonTap: {
                print("Admin panel opened")
                gameState.showStarMapDevToolsDropdown.toggle()
            }
        )
        
        // Rest of your content...
        VStack(spacing: 24) {
            // Your page content here
        }
        .padding()
    }
    
    // Dropdown Overlay
    DevButtonWithDropdownView(
        isDropdownVisible: $gameState.showStarMapDevToolsDropdown,
        dropdownWidth: 220
    ) {
        // Unlock All Planets
        Button(action: {
            gameState.unlockAllPlanets()
            gameState.showStarMapDevToolsDropdown = false
        }) {
            Text("Unlock All Planets")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.cyan.opacity(0.8))
                .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
        
        // Reset Progress
        Button(action: {
            gameState.resetAllProgress()
            gameState.showStarMapDevToolsDropdown = false
        }) {
            Text("Reset All Progress")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.8))
                .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

**Key Features:**
- **Three Components**: `DevButtonHeaderView` (header + button), `DevButtonView` (button only), `DevButtonWithDropdownView` (dropdown overlay)
- **Proper Header Positioning**: Button positioned correctly in header on right side
- **Correct Dropdown Alignment**: Dropdown right-justified to screen edge (16pt from right edge)
- **Full Screen Overlay**: Dropdown covers entire screen with proper z-index management
- **Flexible Content**: Use @ViewBuilder for completely customizable dropdown content
- **Consistent Positioning**: Always appears in top-right corner, below header, aligned with button
- **Outside Tap to Close**: Tapping outside the dropdown closes it automatically
- **Customizable Button**: Change text, color, and add custom tap actions
- **Responsive Width**: Configurable dropdown width for different content needs
- **Matches Construction Bays**: Follows exact same pattern as Construction Bays page

**Implementation Pattern:**
1. Wrap your page content in a `ZStack`
2. Use `DevButtonHeaderView` for the header with title and dev button
3. Add `DevButtonWithDropdownView` as a separate overlay in the ZStack
4. Both components share the same `@Binding<Bool>` for dropdown visibility
5. Use `VStack(spacing: 0)` for proper header/content separation

**Common Use Cases:**
- Developer tools and debug options
- Admin panels and configuration
- Quick action menus
- Settings toggles and controls
- Testing and development utilities
- Power user features

---

## Menus

*Menu components will be added here as they are created*

---

## Pop-out Windows

*Pop-out window components will be added here as they are created*

---

## Cards

*Card components will be added here as they are created*

---

## Lists

*List components will be added here as they are created*

---

## Input Fields

*Input field components will be added here as they are created*

---

## Progress Indicators

*Progress indicator components will be added here as they are created*

---

## Usage Guidelines

### Naming Convention
- Use descriptive names that indicate the component's purpose
- End with "View" for SwiftUI components
- Use PascalCase for struct names

### Styling Consistency
- Use consistent color schemes across components
- Maintain consistent spacing and padding
- Use the same corner radius values throughout the app

### Accessibility
- Ensure all interactive elements are accessible
- Use appropriate font sizes and contrast ratios
- Provide clear visual feedback for user interactions

### Documentation
- Each component should include usage examples
- Document all customizable parameters
- Include common use cases for each component

---

## Contributing

When adding new components to this document:

1. **Categorize properly** - Place components in the appropriate section
2. **Include visual representation** - Use ASCII art or descriptions
3. **Provide complete code** - Include all necessary code for the component
4. **Add usage examples** - Show how to implement the component
5. **Document parameters** - List all customizable properties
6. **Update table of contents** - Keep the TOC current

---

*Last Updated: [Current Date]*
*Version: 1.0*
