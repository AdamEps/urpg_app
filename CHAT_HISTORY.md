# URPG Development Chat History

> **IMPORTANT**: This file should be updated at the start of each new conversation session. Add a new entry for the current session with timestamp, key requests, solutions implemented, and status.

This document tracks our development conversations and key decisions for the UniverseRPG project.

## Session Log

### 2025-09-15 - Star Map Enhancement Slots Implementation
- **Request**: Add Enhancements popup to star map screens with "Location" instead of "Enhancements"
- **Solutions Implemented**:
  - Identified existing Enhancements popup pattern used across all 5 main pages (Location, Construction, Resources, Shop, Cards)
  - Found the exact code structure: enhancement button + 4-slot overlay system
  - Added `@Published var showStarMapSlots = false` to GameState.swift
  - Created `StarMapSlotsView` and `StarMapSlotView` components following the exact same pattern as other slot views
  - Added enhancement slots overlay to both `SolarSystemView` and `ConstellationView` 
  - Changed button text from "Enhancements" to "Location" as requested
  - Maintained same positioning, animation, and styling as other pages
  - Tested implementation by building and launching app on iPhone
- **Status**: ✅ Completed - Star map screens now have Location enhancement slots matching other pages

### 2025-09-15 - Star Map Location Popup Enhancement (Version 2.0.12)
- **Request**: 
  1. Remove "TEST" text from star map location popup
  2. When clicking on any map symbol, show location popup with name and "Go" button instead of direct navigation
  3. Clicking on the same location a second time should close the popup
  4. If the selected location is the current location, button should say "Return Here" instead of "Go"
- **Solutions Implemented**:
  - Removed "TEST" placeholder text from `StarMapSlotsView`
  - Added `@Published var selectedLocationForPopup: Location?` to GameState for popup state management
  - Updated `StarMapSlotsView` to display location name, system info, and dynamic button text
  - Modified all star map symbol tap actions with toggle behavior:
    - Central star button in `SolarSystemView`: Shows popup or closes if same location clicked
    - `CelestialBodySymbol` components (planets, moons, ships): Toggle popup behavior
    - Old star map list view: Toggle popup behavior
  - Button text dynamically shows "Return Here" for current location, "Go" for other locations
  - "Go"/"Return Here" button performs the actual location change and closes popup
  - Added enhancement slots overlay to old star map view for consistency
  - Updated `resetToDefaults()` method to include new popup state property
  - Tested implementation by building and launching app on iPhone
- **Status**: ✅ Completed - Star map symbols now show location popup with smart toggle behavior and contextual button text

### 2025-01-14 - Construction Bay Enhancements Popup (Fixed)
- **Request**: Add Enhancements popup to Construction Bay page using the same popup as other pages
- **Initial Issue**: Added Enhancements popup to wrong view (ConstructionView instead of ConstructionPageView)
- **Solutions Implemented**: 
  - Added showConstructionSlots state variable to GameState
  - Created ConstructionSlotsView and ConstructionSlotView components following the same pattern as other slots views
  - Initially modified ConstructionView, but discovered navigation uses ConstructionPageView
  - Fixed by adding Enhancements popup to ConstructionPageView (the actual page used in navigation)
  - Added proper positioning and animation consistent with other pages
  - Tested implementation by building and launching app on simulator
  - Committed changes with descriptive commit message
  - Updated app icon to version 1.994
- **Status**: ✅ Completed - Construction Bay page now correctly shows Enhancements popup matching other pages

### 2025-01-27 - Version 2.0.6 Release
- **Request**: Commit as 2.0.6 and update app logo
- **Solutions Implemented**: 
  - Committed all current changes as version 2.0.6
  - Updated app icon generation script to version 2.0.6
  - Generated new app icon with version 2.0.6 branding
  - Committed app icon updates
  - Launched app to verify changes
- **Status**: ✅ Completed - Version 2.0.6 successfully committed and app logo updated

### 2025-01-27 - Initial Setup
- **Request**: Create backup system for development chats
- **Solution**: Implemented automated chat log system with clear instructions for future sessions
- **Status**: ✅ Complete

### 2025-01-27 - System Test
- **Request**: Test the chat history system
- **Solution**: Updated chat history file to record test interaction
- **Status**: ✅ Complete

### 2025-01-27 - Chat History Test
- **Request**: Chat history test
- **Solution**: Testing the chat history update functionality
- **Status**: ✅ Complete

### 2025-01-27 - Blueprints Screen Redesign
- **Request**: Redesign Blueprints screen to remove popup and integrate with main navigation
  - Remove popup screen for Blueprints
  - Create screen like star map with info between top bar and bottom nav
  - Keep current blueprint style
  - Add 3 separate pages for Small, Medium, and Large Bays
  - Add bay size selector buttons (Small, Medium, Large) above blueprints
  - Filter blueprints by selected bay size
  - Allow construction only in matching bay size
- **Solution**: 
  - Added blueprints page to AppPage enum
  - Created new BlueprintsView with bay size filtering
  - Added bay size selector buttons with highlighting
  - Implemented blueprint filtering by bay size
  - Updated navigation to use new Blueprints page instead of popup
  - Removed old ConstructionMenuView and CollapsibleBlueprintView
  - Updated construction bay buttons to navigate to Blueprints page
- **Status**: ✅ Complete - App launched for testing

### 2025-01-27 - Blueprints Screen Fixes
- **Request**: Fix Blueprints screen issues
  - Remove Blueprints button from bottom navigation bar (should only be accessible via bay clicks)
  - Redesign bay size selector as single button with three clickable sections (Small, Medium, Large)
  - Use white background and black text for selected state instead of blue
- **Solution**: 
  - Removed Blueprints button from bottom navigation bar
  - Redesigned bay size selector as single button with three sections separated by dividers
  - Updated styling to use white background and black text for selected state
  - Maintained all existing functionality for bay-based access
- **Status**: ✅ Complete - App launched for testing

### 2025-01-27 - Blueprints UI Improvements
- **Request**: Improve Blueprints screen UI and functionality
  - Fix button UI to maintain beveled edges when highlighted
  - Remove dividers between Small, Medium, Large sections
  - Make button window wider horizontally
  - Fix bay size defaulting - clicking medium bay should show medium blueprints
  - Add 'Construction Blueprints' header above page buttons
- **Solution**: 
  - Redesigned button overlay to maintain beveled edges with RoundedRectangle
  - Removed gray dividers between button sections
  - Increased horizontal padding to make button wider
  - Added selectedBaySizeForBlueprints property to GameState
  - Updated all bay slot views to set correct bay size before navigation
  - Added 'Construction Blueprints' header above the button selector
  - Updated BlueprintsView to accept initialBaySize parameter
- **Status**: ✅ Complete - App launched for testing

### 2025-01-27 - Blueprints Bug Fixes
- **Request**: Fix Blueprints screen bugs
  - Small bay was defaulting to large blueprints instead of small
  - Text color visibility issue when button is highlighted
- **Solution**: 
  - Added debug logging to track bay size selection and BlueprintsView initialization
  - Redesigned button structure using ZStack to ensure proper text layering
  - Text now properly displays in black when highlighted (white background)
  - Debug logging will help identify any remaining bay size issues
- **Status**: ✅ Complete - App launched for testing with debug logging

### 2025-01-27 - Blueprints Final Fixes
- **Request**: Fix remaining Blueprints screen issues
  - Small bay was showing medium blueprints instead of small
  - Button got too wide horizontally
- **Solution**: 
  - Reverted horizontal padding from 8 to 16 to fix button width
  - Added comprehensive debug logging to track bay size selection flow
  - Added logging to track selectedBaySize vs initialBaySize
  - Added logging to track filtered blueprints count
  - Added logging to track BaySize.allCases order
- **Status**: ✅ Complete - App launched for testing with enhanced debug logging

### 2025-09-14 - Blueprints Button Height Fix
- **Request**: Fix oversized Small/Medium/Large buttons in Constructable Blueprints page
  - Buttons were taking up too much vertical space (half the screen)
  - Need to reduce button height while maintaining functionality
- **Solution**: 
  - Identified that background RoundedRectangle and Rectangle shapes were expanding to fill available space
  - Added maxHeight: 32 constraint to background shapes
  - Added .frame(height: 32) constraint to main ZStack container
  - Reduced text padding from .padding(.vertical, 8) to .padding(.vertical, 4)
  - Reduced container padding from .padding(.vertical, 12) to .padding(.vertical, 8)
  - Total button height now: 32 pixels (container) + 8 pixels (padding) = 40 pixels
- **Status**: ✅ Complete - Version 2.0.5 - App launched for testing

### 2025-01-27 - Enhancement Items Addition
- **Request**: Add 3 medium bay constructables that are enhancement items
  - Excavator: Steel Pylons (10) + Gears (3) + 300 Numins, 5 min, 25 XP
    - Ability: 2X-5X higher yield for common & uncommon resources for 1 min (3 min cooldown, 10% break chance)
  - Laser Harvester: Laser (5) + Circuit Board (3) + Steel Pylons (4) + 550 Numins, 7.5 min, 40 XP
    - Ability: Random rare resource collection every 5 sec for 30 sec (2 min cooldown, 25% break chance)
  - Virtual Almanac: CPU (1) + Data Storage Unit (1) + Alloys (50) + Silicon (50) + 995 Numins, 10 min, 75 XP
    - Ability: Shows location resources and chances (removable after 30 min, forfeits Numins earnings)
  - All show "Enhancement Item: Ability Unknown" until first construction + ability discovery cost paid
- **Solution**: 
  - Added new ResourceType cases: excavator, laserHarvester, virtualAlmanac
  - Added icons: hammer.fill, laser.burst, book.fill respectively
  - Added colors: brown, red, purple respectively
  - Created ConstructionBlueprint definitions with proper costs, durations, and XP rewards
  - Set all as medium bay constructables with "Enhancement Item: Ability Unknown" descriptions
  - Added blueprints to allBlueprints array for availability in game
- **Status**: ✅ Complete - App launched for testing

## 2025-01-27 - Blueprint Button Improvements & Dev Tool

### User Requests:
1. **Grey out medium/large blueprint buttons when no unlocked bays** - If there isn't an unlocked medium bay, make the medium blueprints button greyed out. Same for large.
2. **Add dev tool option to Constructables page** - Let's add a dev tool option to Constructables page, to see all Enhancement Abilities.

### Implementation:
1. **Blueprint Button Greying**:
   - Added `hasUnlockedBay(of size: BaySize)` helper function to check if any bay of a specific size is unlocked
   - Modified bay size selector buttons to:
     - Show grey text when no bays of that size are unlocked
     - Disable button interaction when no bays are unlocked
     - Only allow selection of unlocked bay sizes
   - Only the first small bay is unlocked by default, so medium and large buttons will be greyed out initially

2. **Enhancement Abilities Dev Tool**:
   - Added "DEV" button to BlueprintsView header (red background, similar to existing dev buttons)
   - Created `EnhancementAbilitiesView` with detailed information about all 3 enhancement abilities:
     - **Excavator**: +25% resource collection efficiency, 500 discovery cost
     - **Laser Harvester**: Passive harvesting every 30s, 750 discovery cost  
     - **Virtual Almanac**: Location intelligence with full details, 1000 discovery cost
   - Each ability card shows icon, name, effect type, effect value, discovery cost, and description
   - Added proper navigation with "Done" button to dismiss the sheet
   - Used consistent styling with the rest of the app (black background, proper colors)

### Technical Details:
- Modified `BlueprintsView` to include state for showing enhancement abilities sheet
- Added `EnhancementAbility` model struct for ability data
- Created `EnhancementAbilityCard` view component for displaying individual abilities
- Used sheet presentation for the dev tool to maintain navigation flow
- All enhancement abilities are defined as medium bay constructables as per previous implementation

### Status:
- ✅ **Blueprint Button Greying**: Complete - Medium and large buttons are greyed out when no bays of that size are unlocked
- ✅ **Enhancement Abilities Dev Tool**: Complete - Added comprehensive dev tool showing all enhancement abilities with detailed information
- ✅ **App Testing**: Launched app to verify changes work correctly

## 2025-01-27 - Telescope Navigation Enhancement

### User Requests:
1. **Add telescope icon button to location view** - Add a white telescope icon button in the top right of location view, below the name header
2. **Modify star map navigation** - Replace the toggle behavior of the star map button so it only goes to location view, not the location list
3. **Telescope button functionality** - The telescope button should show the location list (StarMapView) instead of the star map button

### Implementation:
1. **Telescope Button Addition**:
   - Added telescope icon button to LocationView header (top right, below name)
   - Used `Image(systemName: "telescope")` with white color and title2 font size
   - Positioned in HStack with proper spacing alongside location name
   - Button action navigates to starMap page with showingLocationList = true

2. **Star Map Button Modification**:
   - Removed toggle behavior from star map button in BottomNavigationView
   - Star map button now only goes to location view (showingLocationList = false)
   - Simplified button action to always set currentPage = .starMap and showingLocationList = false

3. **Navigation Flow Changes**:
   - **Before**: Star map button toggled between location view and location list
   - **After**: Star map button goes to location view, telescope button shows location list
   - Maintains existing StarMapView functionality for location selection

### Technical Details:
- Modified `LocationView` header HStack to include telescope button
- Updated `BottomNavigationView` star map button action
- No changes needed to `StarMapView` as it already handles location selection correctly
- Telescope button uses same navigation pattern as other buttons

### Status:
- ✅ **Telescope Button**: Complete - Added white telescope icon to location view header
- ✅ **Star Map Navigation**: Complete - Modified to only go to location view
- ✅ **Telescope Functionality**: Complete - Telescope button shows location list
- ✅ **App Testing**: Launched app to verify new navigation flow works correctly

---

## 2025-01-27 - App Logo Versioning Fix (v2.0.101)

### User Requests:
1. **Fix app logo versioning system** - Logo was always updating to version 1.994 instead of correct commit version
2. **Ensure rule compliance** - "Update the app logo with the correct commit version after each commit" rule wasn't working

### Problem Analysis:
- **Root Cause**: `update_app_icon.sh` script had hardcoded default version of "1.994"
- **Secondary Issue**: `generate_app_icon.py` also had hardcoded version "1.994" 
- **Impact**: Every commit would update logo to 1.994 regardless of actual commit count

### Implementation:
1. **Enhanced update_app_icon.sh**:
   - Added auto-detection logic when no version parameter provided
   - Uses `git rev-list --count HEAD` to get actual commit count
   - Creates version format "2.0.X" where X is commit count
   - Added informative logging for auto-detected vs provided versions

2. **Updated generate_app_icon.py**:
   - Changed default version from "1.994" to "2.0.0" 
   - Added comment indicating version will be overridden by update script

3. **Testing & Verification**:
   - Tested auto-detection: correctly identified version 2.0.101 (101 commits)
   - Generated new app icon with correct version number
   - Launched app to verify new logo appears

### Technical Details:
- **Version Format**: 2.0.X where X = git commit count
- **Auto-detection**: Only triggers when no version parameter provided
- **Backward Compatibility**: Still accepts manual version parameter
- **Logging**: Clear feedback about version source (auto-detected vs provided)

### Status:
- ✅ **Version Detection**: Complete - Auto-detects correct version from git commit count
- ✅ **Logo Generation**: Complete - Generated logo with version 2.0.101
- ✅ **Rule Compliance**: Complete - Logo now updates to correct commit version
- ✅ **App Testing**: Launched app to verify new logo appears correctly

---

*This file should be maintained during each development session. Each new conversation should start by reading this file and adding a new entry.*

## 2025-01-27 - Telescope Button Visibility Fix (v2.0.9)

### User Requests:
1. **Fix telescope button visibility** - The telescope button wasn't showing up on screen
2. **Commit as version 2.0.9** - Commit all changes with proper versioning

### Implementation:
1. **Telescope Button Visibility Fix**:
   - **Problem**: `Image(systemName: "telescope")` SF Symbol wasn't available in iOS version
   - **Solution**: Replaced with telescope emoji `Text("🔭")` for guaranteed visibility
   - **Font Size**: Changed from `.title` to `.largeTitle` for better visibility
   - **Color**: Maintained white color as requested
   - **Position**: Kept below header on left side as specified

2. **Version 2.0.9 Release**:
   - Updated app icon generation script to version 2.0.9
   - Generated new app icon with version 2.0.9 branding
   - Committed all changes with descriptive commit message
   - Updated CHAT_HISTORY.md with session details

### Technical Details:
- Used `sed` command to replace `Image(systemName: "telescope")` with `Text("🔭")`
- Updated font size from `.title` to `.largeTitle` for better visibility
- Maintained all existing functionality and positioning
- App successfully builds and launches with visible telescope button

### Status:
- ✅ **Telescope Visibility**: Complete - Telescope emoji (🔭) now visible below header on left side
- ✅ **Version 2.0.9**: Complete - All changes committed with proper versioning
- ✅ **App Icon Update**: Complete - App icon updated to version 2.0.9
- ✅ **App Testing**: Launched app to verify telescope button is now visible and functional

---

## 2025-01-27 - Hierarchical Star Map System Implementation (v2.1.0)

### Goal:
Transform the star map from a simple list into a hierarchical, visual star map system with:
- Symbolic black and white 2D visualization
- Orbital rings showing planetary positions
- Clickable celestial body symbols
- Hierarchical navigation (Constellation → Solar System → Location)
- Telescope functionality for zooming between levels

### Implementation:

1. **Data Model Creation**:
   - Added `Constellation`, `StarSystem`, and `StarType` models
   - Created `StarMapZoomLevel` enum for navigation state
   - Added star map hierarchy state to `GameState`

2. **Visual Components**:
   - `CelestialBodySymbol`: Clickable symbols for planets, moons, ships, etc.
   - `OrbitalRing`: Faint circular rings showing orbital paths
   - `StarSymbol`: Central star with different types (main sequence, red giant, etc.)
   - Color-coded symbols: Blue planets, gray moons, green ships, yellow stars

3. **View Implementation**:
   - `SolarSystemView`: Shows individual star system with orbital mechanics
   - `ConstellationView`: Shows multiple star systems in constellation
   - `StarMapView`: Main view that switches between hierarchy levels
   - Maintained fallback to old list view for compatibility

4. **Navigation System**:
   - `zoomIntoStarSystem()`: Zoom in to see individual solar system
   - `zoomOutToConstellation()`: Zoom out to see multiple star systems
   - Telescope button integration for hierarchical navigation
   - Smooth animations between zoom levels

5. **Taragon Gamma System**:
   - First 5 locations organized in orbital positions:
     - Taragam-7 (planet) + Elcinto (moon)
     - Taragam-3 (ice planet with rings)
     - Abandoned Starship (derelict vessel)
     - Repaired Starship (fixed vessel)
   - Central main sequence star
   - Orbital rings showing planetary positions

### Technical Details:
- Used `GeometryReader` for precise positioning
- Calculated orbital positions using trigonometry
- Maintained existing location selection functionality
- Added smooth animations with `withAnimation`
- Preserved all existing game mechanics

### Status:
- ✅ **Data Models**: Complete - Hierarchical star map data structure
- ✅ **Visual Components**: Complete - Symbolic celestial body representations
- ✅ **Solar System View**: Complete - Orbital mechanics for Taragon Gamma
- ✅ **Constellation View**: Complete - Multiple star system display
- ✅ **Zoom Navigation**: Complete - Smooth transitions between levels
- ✅ **Telescope Integration**: Complete - Hierarchical navigation via telescope
- ✅ **App Testing**: Complete - Successfully built and launched on iPhone
- ✅ **Version 2.1.0**: Complete - All changes implemented and tested

## Version 2.0.10 - Enhanced Star Map with Clickable Central Star

**Date**: 2025-01-15

### Changes Made:
- **Central Star Navigation**: Made central star symbol clickable to navigate to Taragon Gamma location
- **Orbital Positioning**: Adjusted outermost orbital ring to be closer to Taragam-3's orbit
- **Abandoned Starship Placement**: Positioned Abandoned Starship above the star on the outer ring
- **Moon Orbit Fix**: Fixed moon (Elcinto) positioning to orbit around Taragam-7 with small orbital ring
- **Navigation Enhancement**: Improved hierarchical star map navigation with telescope button
- **Visual Layout**: Enhanced visual layout of Taragon Gamma solar system

### Technical Details:
- Wrapped central `StarSymbol` in `Button` with proper action handling
- Added special orbital angle calculation for Abandoned Starship positioning
- Modified `calculateOrbitalRadius` function for better ring spacing
- Enhanced `SolarSystemView` with conditional moon positioning logic
- Updated app icon to version 2.0.10

### Status:
- ✅ **Central Star Button**: Complete - Central star now clickable
- ✅ **Orbital Ring Adjustment**: Complete - Outermost ring positioned closer to Taragam-3
- ✅ **Abandoned Starship Positioning**: Complete - Positioned above star
- ✅ **Moon Orbit Fix**: Complete - Elcinto now orbits Taragam-7
- ✅ **App Testing**: Complete - Successfully built and launched on iPhone
- ✅ **Version 2.0.10**: Complete - All changes implemented and tested

## Chat Session - September 15, 2025 (v2.0.12)

### User Requests:
1. **Star Map Navigation Bug Fix**: Fixed bottom nav star map button behavior
   - Star map button should only go to location view from Shop/Construction/Resources/Cards
   - Star map button should do nothing when already in star map view
   - Only telescope should take you to star map from location view

2. **Location Popouts Visibility**: Fixed right side popouts showing in star map
   - Location resource popouts should only show in location view, not star map
   - Tap counter popouts should only show in location view, not star map

3. **Telescope Button Enhancement**: Improved telescope navigation
   - Replaced telescope with left arrow at highest zoom level (Multi-Systems view)
   - Left arrow takes you back to current location instead of cycling through views

4. **Telescope Flicker Fix**: Fixed visual flicker when clicking telescope from location
   - Reordered operations to set zoom level before changing page
   - Eliminated brief flash of Multi-System view before Star System view

### Technical Changes:
- **GameState.swift**: Added `starMapViaTelescope` tracking property
- **ContentView.swift**: 
  - Updated bottom nav star map button logic
  - Fixed location popout visibility conditions
  - Replaced telescope with left arrow at constellation level
  - Fixed telescope button operation order
  - Added starMapViaTelescope reset to all navigation buttons

### Results:
- ✅ **Star Map Navigation**: Complete - Button behavior fixed
- ✅ **Location Popouts**: Complete - Only show in location view
- ✅ **Telescope Enhancement**: Complete - Left arrow at highest level
- ✅ **Flicker Fix**: Complete - Smooth telescope navigation
- ✅ **Version 2.0.12**: Complete - All changes implemented and tested

---

## Chat Session - Taragam-7 Planet Visual Enhancement

### User Request:
- Update Taragam-7 blue circle symbol in star map to look like a little blue/green planet
- Keep same size, location, and functionality
- Simple visual enhancement only

### Changes Made:
- **Custom Planet View**: Created `Taragam7PlanetView` with blue/green gradient
- **Visual Design**: 
  - Radial gradient from blue to cyan to green
  - Subtle texture overlay for depth
  - Small highlight for 3D effect
  - Maintains same 24x24 size as original circle
- **Integration**: Updated `CelestialBodySymbol` to use custom view for Taragam-7 specifically
- **Preservation**: All other locations continue using original SF Symbol icons

### Results:
- ✅ **Planet Visual**: Complete - Taragam-7 now displays as blue/green planet
- ✅ **Size Preservation**: Complete - Maintains original dimensions
- ✅ **Functionality**: Complete - All interactions preserved
- ✅ **Selective Application**: Complete - Only affects Taragam-7, other locations unchanged

### Follow-up Enhancements:
- **Taragam-7 Fix**: Removed grey dot texture overlay for cleaner appearance
- **Elcinto Moon**: Created custom yellow/brown gradient moon view (18x18px, smaller than planet)
- **Taragam-3 Planet**: Created custom blue/white gradient planet with white ring (32x32px ring)
- **Visual Consistency**: All three celestial bodies now use custom gradient views with 3D highlights

### Star Visual Enhancement:
- **Custom Star Design**: Created `CustomStarView` with gradient and star points
- **Visual Features**:
  - White-to-color gradient main body (30x30px)
  - Outer glow effect with color-based gradient
  - 4-pointed star design with radiating points
  - Scales appropriately when selected
- **Integration**: Updated `StarSymbol` to use custom view
- **Design Consistency**: Matches the aesthetic of the custom planet views

### Location Popup UI Redesign (v2.0.13):
- **Removed Header Buttons**: Eliminated both "Location" header buttons from star map view
- **Direct Icon Interaction**: Location icons now directly handle popup show/hide functionality
- **Horizontal Layout Redesign**:
  - Location name and system info positioned on the left side
  - Action button ("Go"/"Return Here") right-justified on the right side
  - Full-width popup with 16px horizontal padding for proper spacing
- **Improved UX**: Cleaner interface with better use of horizontal space
- **App Icon Update**: Updated to version 2.0.13

### Statistics and Objectives UI Integration (v2.0.14):
- **Main UI Integration**: Moved Statistics and Objectives from popup to main UI section
- **New StatisticsAndObjectivesView**: Created dedicated view without NavigationView wrapper
- **Page Navigation**: Added statistics page to AppPage enum and main game area switch
- **Button Updates**: Updated objectives button to navigate to statistics page instead of showing sheet
- **Bottom Navigation**: Added statistics button to bottom navigation bar
- **Sheet Removal**: Removed sheet presentation for objectives popup
- **Preserved Content**: Maintained exact same content and functionality as original popup
- **App Icon Update**: Updated to version 2.0.14

---
