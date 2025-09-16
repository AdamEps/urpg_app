# UniverseRPG - Object Templates

This document contains reusable UI components and templates for the UniverseRPG game. Each component is categorized by type and includes a description, visual representation, and code template.

## Table of Contents

- [Buttons](#buttons)
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
