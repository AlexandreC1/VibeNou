# Fixing Firestore Permission Denied Error for Profile Views

## The Problem

You're seeing this error:
```
Error [cloud_firestore/permission-denied] The caller does not have permission to execute this specific operation
```

This happens because your app is trying to access a `profileViews` collection in Firestore, but the security rules don't allow it yet.

## Solution: Update Firestore Security Rules

### Step 1: Go to Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your VibeNou project
3. Click on **Firestore Database** in the left menu
4. Click on the **Rules** tab at the top

### Step 2: Add Security Rules for Profile Views

Replace your current rules with the following (or add the `profileViews` section to your existing rules):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users collection (existing rules)
    match /users/{userId} {
      // Allow read access to all authenticated users
      allow read: if request.auth != null;

      // Allow write access only to the user's own document
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Profile Views collection (NEW - add this)
    match /profileViews/{viewId} {
      // Allow authenticated users to read their own views (where they are the viewed user)
      allow read: if request.auth != null &&
                     resource.data.viewedUserId == request.auth.uid;

      // Allow authenticated users to create views (recording when they view someone)
      allow create: if request.auth != null &&
                       request.resource.data.viewerId == request.auth.uid;

      // Allow users to update their own view records (marking as read)
      allow update: if request.auth != null &&
                       resource.data.viewedUserId == request.auth.uid;

      // Allow users to delete old views if they own them
      allow delete: if request.auth != null &&
                       resource.data.viewedUserId == request.auth.uid;
    }

    // Chats collection (if you have it)
    match /chats/{chatId} {
      allow read, write: if request.auth != null;
    }

    // Messages collection (if you have it)
    match /chats/{chatId}/messages/{messageId} {
      allow read, write: if request.auth != null;
    }

    // Matches collection (if you have it)
    match /matches/{matchId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Step 3: Create Required Firestore Indexes

The profile views feature uses compound queries that require indexes. You have two options:

#### Option A: Let Firebase Create Indexes Automatically (Recommended)

1. Just use the app normally
2. When you try to view profile views, Firebase will show you an error with a link
3. Click the link in the error to automatically create the index
4. Wait a few minutes for the index to be built

#### Option B: Create Indexes Manually

Go to the **Indexes** tab in Firestore and create these composite indexes:

**Index 1: For checking recent views**
- Collection ID: `profileViews`
- Fields:
  - `viewerId` - Ascending
  - `viewedUserId` - Ascending
  - `viewedAt` - Descending
- Query scope: Collection

**Index 2: For getting all profile views**
- Collection ID: `profileViews`
- Fields:
  - `viewedUserId` - Ascending
  - `viewedAt` - Descending
- Query scope: Collection

**Index 3: For unread views count**
- Collection ID: `profileViews`
- Fields:
  - `viewedUserId` - Ascending
  - `isRead` - Ascending
- Query scope: Collection

### Step 4: Test the Fix

1. Save the security rules in Firebase Console
2. Restart your Flutter app (hot reload won't work for this)
3. Navigate to the Profile tab
4. The permission error should be gone!

## What the Profile Views Feature Does

- **Tracks who views profiles**: When someone looks at another user's profile, it records the view
- **Shows unread count**: Users can see how many new profile views they have
- **View history**: Users can see who viewed their profile and when
- **Privacy**: Users can only see who viewed THEIR profile, not others' profile views

## Troubleshooting

### Still seeing permission errors?

1. Make sure you saved the security rules in Firebase Console
2. Try signing out and signing back in to the app
3. Clear the app data and reinstall
4. Check the Firebase Console Firestore Rules tab to ensure the rules were saved correctly

### Index errors?

If you see "index required" errors, either:
1. Click the link in the error message to create the index automatically
2. Or manually create the indexes as described in Step 3

## Additional Security Considerations

The security rules above ensure:
- ✅ Users can only see who viewed THEIR profile (not others')
- ✅ Users can only create views where they are the viewer
- ✅ Users can't fake views from other people
- ✅ Users can only mark their own views as read
- ✅ All operations require authentication

This keeps your users' data safe and private!
