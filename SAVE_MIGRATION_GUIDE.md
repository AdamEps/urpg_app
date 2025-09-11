# Save File Migration System

## Overview

The UniverseRPG save system is designed to ensure that player progress is never lost during app updates. This system provides automatic migration, backup creation, and fallback mechanisms to handle various scenarios.

## Key Features

### 1. **Version Management**
- Each save file includes a version number (currently "1.0.0")
- Version history is tracked to enable step-by-step migration
- Version comparison allows for safe upgrades and downgrades

### 2. **Automatic Migration**
- When loading a save file, the system automatically detects version mismatches
- Migrates data from older versions to the current version
- Preserves as much player data as possible during migration

### 3. **Backup System**
- Creates automatic backups before each save
- Keeps the 5 most recent backups per user
- Allows restoration if migration fails

### 4. **Legacy Format Support**
- Handles save files from before versioning was implemented
- Attempts to preserve data even from unknown formats
- Graceful fallback to fresh game state if migration fails

## How It Works

### Save Process
1. **Create Backup**: Before saving, create a backup of the current save data
2. **Encode Data**: Convert game state to JSON with current version
3. **Store Data**: Save to UserDefaults with version information
4. **Cleanup**: Remove old backups (keep only 5 most recent)

### Load Process
1. **Load Raw Data**: Retrieve save data from UserDefaults
2. **Migration Check**: Determine if migration is needed
3. **Apply Migration**: If needed, migrate through version steps
4. **Apply Data**: Load the (possibly migrated) data into game state
5. **Fallback**: If migration fails, start with fresh game state

### Migration Steps
1. **Version Detection**: Identify the save file version
2. **Path Calculation**: Determine migration path to current version
3. **Step-by-Step Migration**: Apply each migration step in order
4. **Validation**: Ensure migrated data is valid
5. **Backup on Success**: Create backup of successfully migrated data

## Adding New Versions

When you need to add a new version (e.g., "1.1.0"):

### 1. Update Version Constants
```swift
struct SaveDataVersion {
    static let current = "1.1.0"
    
    static let versions: [String] = [
        "1.0.0",  // Previous version
        "1.1.0"   // New version
    ]
}
```

### 2. Add Migration Logic
```swift
private func applyMigrationStep(from saveData: SerializableGameState, to targetVersion: String) throws -> SerializableGameState {
    switch targetVersion {
    case "1.0.0":
        return saveData
    case "1.1.0":
        // Add migration logic here
        var migratedData = saveData
        // Example: Add new field with default value
        // migratedData.newField = "default_value"
        return migratedData
    default:
        throw MigrationError.unknownVersion(targetVersion)
    }
}
```

### 3. Update SerializableGameState
If you add new fields to the save data structure:
```swift
struct SerializableGameState: Codable {
    // ... existing fields ...
    let newField: String  // New field
    
    init(from gameState: GameState) {
        // ... existing assignments ...
        self.newField = gameState.newField
    }
}
```

## Migration Scenarios

### Scenario 1: Same Version
- **Input**: Save file version matches current version
- **Action**: Load directly without migration
- **Result**: Fast loading, no data loss

### Scenario 2: Older Version
- **Input**: Save file version is older than current
- **Action**: Migrate through version steps
- **Result**: Data preserved and updated to current format

### Scenario 3: Newer Version
- **Input**: Save file version is newer than current
- **Action**: Reject with error message
- **Result**: User prompted to update app

### Scenario 4: Unknown Version
- **Input**: Save file version not recognized
- **Action**: Attempt legacy format migration
- **Result**: Partial data preservation or fresh start

### Scenario 5: Corrupted Data
- **Input**: Save file cannot be decoded
- **Action**: Try legacy migration, then fallback
- **Result**: Fresh game state with backup available

## Best Practices

### 1. **Always Add New Fields as Optional**
```swift
let newField: String?  // Optional for backward compatibility
```

### 2. **Provide Sensible Defaults**
```swift
self.newField = gameState.newField ?? "default_value"
```

### 3. **Test Migration Paths**
- Test migration from each previous version
- Test with corrupted data
- Test with missing fields

### 4. **Preserve User Progress**
- Never remove existing data unless absolutely necessary
- Convert old data to new format when possible
- Provide compensation for lost data

### 5. **Log Migration Events**
```swift
print("🔄 MIGRATING - From \(oldVersion) to \(newVersion)")
print("✅ MIGRATION SUCCESS - Data preserved")
print("❌ MIGRATION FAILED - \(error)")
```

## Error Handling

The system handles various error conditions:

- **Unsupported Version**: Clear error message, fallback to fresh state
- **Migration Failure**: Attempt legacy migration, then fallback
- **Data Corruption**: Use backup if available, otherwise fresh state
- **Missing Fields**: Use default values, preserve existing data

## Backup Management

- **Automatic Backups**: Created before each save operation
- **Backup Retention**: Keeps 5 most recent backups per user
- **Backup Cleanup**: Removes old backups automatically
- **Backup Restoration**: Available through migration manager

## Testing the System

### 1. **Version Migration Test**
```swift
// Create save with old version
let oldSaveData = createOldVersionSave()
// Load and verify migration
let result = migrationManager.migrateSaveData(oldSaveData)
```

### 2. **Corruption Test**
```swift
// Create corrupted data
let corruptedData = createCorruptedSave()
// Verify fallback behavior
let result = migrationManager.migrateSaveData(corruptedData)
```

### 3. **Legacy Format Test**
```swift
// Create legacy format save
let legacyData = createLegacySave()
// Verify legacy migration
let result = migrationManager.migrateSaveData(legacyData)
```

## Monitoring and Debugging

The system provides extensive logging:

- **Migration Events**: Track which migrations are applied
- **Data Preservation**: Log what data is preserved/lost
- **Error Details**: Detailed error messages for debugging
- **Performance**: Track migration time and data size

## Future Enhancements

Potential improvements to consider:

1. **Cloud Backup Integration**: Sync backups to cloud storage
2. **Migration Rollback**: Allow reverting failed migrations
3. **Data Validation**: More robust data integrity checks
4. **Compression**: Compress save data to reduce storage
5. **Encryption**: Encrypt sensitive save data

## Conclusion

This migration system ensures that your players' progress is protected during app updates. The system is designed to be robust, automatic, and transparent to the user. Regular testing and careful version management will ensure a smooth experience for your players.
