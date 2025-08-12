# Provider Migration Scripts

This directory contains scripts to migrate provider data from the `users` collection to a new `providers` collection in Firebase Firestore.

## Overview

The migration scripts will:
1. ✅ Create a new `providers` collection
2. 🔍 Find all documents in `users` where `role == 'provider'` or `isProvider == true`
3. 📋 Copy those documents to the `providers` collection (preserving document IDs)
4. 🗑️ Optionally delete provider documents from the `users` collection
5. 📊 Log detailed results and verification

## Available Scripts

### 1. Dart Script (Flutter)
**File:** `lib/scripts/migrate_providers.dart`

**Features:**
- Uses Flutter's Firebase SDK
- Comprehensive error handling
- Detailed logging and progress tracking
- Migration verification
- Configurable deletion option

**Usage:**
```bash
# Run from Flutter project root
flutter run lib/scripts/migrate_providers.dart

# Or compile and run
dart lib/scripts/migrate_providers.dart
```

### 2. Node.js Script (Firebase Functions)
**File:** `functions/src/migrate-providers.js`

**Features:**
- Uses Firebase Admin SDK
- Can be deployed as a Firebase Function
- Command-line execution support
- REST API endpoint
- Same comprehensive features as Dart version

**Usage:**
```bash
# Run directly with Node.js
cd functions
node src/migrate-providers.js

# Run with deletion option
node src/migrate-providers.js --delete-from-users

# Deploy as Firebase Function
firebase deploy --only functions:migrateProviders
```

## Provider Detection

The scripts automatically detect providers using these field checks (in order):
1. `role == 'provider'`
2. `isProvider == true`
3. `userType == 'provider'`

## Migration Process

### Step 1: Backup (Recommended)
Before running the migration, consider backing up your Firestore data:
```bash
# Export your Firestore data
firebase firestore:export ./backup
```

### Step 2: Test Migration
Run the migration without deleting from users first:
```bash
# Dart version (default: deleteFromUsers = false)
flutter run lib/scripts/migrate_providers.dart

# Node.js version
node functions/src/migrate-providers.js
```

### Step 3: Verify Results
The scripts will automatically verify the migration by:
- Counting providers in both collections
- Checking for any discrepancies
- Reporting success/failure rates

### Step 4: Clean Up (Optional)
If the migration was successful and you want to remove providers from the users collection:
```bash
# Modify the script to set deleteFromUsers = true
# Or use the Node.js version with flag
node functions/src/migrate-providers.js --delete-from-users
```

## Migration Metadata

Each migrated document will include these additional fields:
- `migratedAt`: Server timestamp of migration
- `migratedFrom`: Source collection ('users')
- `originalCollection`: Original collection name

## Error Handling

The scripts include comprehensive error handling:
- ✅ Individual document migration failures don't stop the process
- 📝 All errors are logged with details
- 🔄 Failed migrations are reported in the final summary
- 🛡️ Graceful handling of network issues and permissions

## Sample Output

```
🚀 Starting provider migration...
📊 Delete from users: No
---
📋 Found 150 total users
👥 Found 25 providers to migrate
🔄 Migrating: provider_001
  ✅ Migrated successfully
🔄 Migrating: provider_002
  ✅ Migrated successfully
...

==================================================
📊 MIGRATION RESULTS
==================================================
Total providers: 25
Successful: 25
Failed: 0
Success rate: 100.0%
==================================================

🔍 Verifying migration...
📊 Verification:
  Providers in users: 25
  Providers in providers: 25
  Expected total: 25
✅ Verification successful!

🎉 Migration completed!
```

## Firebase Function Usage

If deployed as a Firebase Function, you can call it via HTTP:

```bash
# POST request to trigger migration
curl -X POST https://your-project.cloudfunctions.net/migrateProviders \
  -H "Content-Type: application/json" \
  -d '{"deleteFromUsers": false}'
```

## Security Considerations

- 🔐 Ensure your Firebase security rules allow the migration
- 👤 The scripts require appropriate Firestore permissions
- 🛡️ Test in a development environment first
- 📋 Review the migration results before cleaning up

## Troubleshooting

### Common Issues:

1. **Permission Denied**
   - Check Firebase security rules
   - Ensure service account has proper permissions

2. **Network Timeouts**
   - The scripts handle individual timeouts gracefully
   - Check your internet connection

3. **No Providers Found**
   - Verify your provider detection logic matches your data
   - Check field names and values in your documents

4. **Partial Migration**
   - Review error logs for specific failures
   - Re-run the migration (it's idempotent)

### Getting Help:

- Check the error logs in the console output
- Verify your Firestore data structure
- Test with a small subset of data first

## Post-Migration Tasks

After successful migration:

1. **Update Your App Code**
   - Modify queries to use the new `providers` collection
   - Update any references to the old collection structure

2. **Update Security Rules**
   - Add appropriate rules for the new `providers` collection
   - Test access patterns

3. **Monitor Performance**
   - Verify queries are working correctly
   - Check for any performance impacts

4. **Clean Up (Optional)**
   - Remove provider documents from `users` collection
   - Update any remaining references

---

**⚠️ Important:** Always test the migration in a development environment before running it in production! 