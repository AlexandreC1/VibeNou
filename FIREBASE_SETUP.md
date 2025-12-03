# Firebase Backend Setup Guide for VibeNou

This guide will walk you through setting up Firebase (the backend) for your VibeNou app step by step.

## 📋 Prerequisites

- Google account (Gmail)
- Internet connection
- The VibeNou project code on your computer

---

## Step 1: Create Firebase Project

### 1.1 Go to Firebase Console
1. Open your browser and go to: **https://console.firebase.google.com/**
2. Sign in with your Google account
3. Click **"Add project"** (or **"Create a project"**)

### 1.2 Configure Project
1. **Project name**: Enter `VibeNou`
2. Click **"Continue"**
3. **Google Analytics**:
   - Toggle OFF (optional, not needed for now)
   - Or leave ON and select your Analytics account
4. Click **"Create project"**
5. Wait for project creation (takes ~30 seconds)
6. Click **"Continue"** when ready

✅ **Checkpoint**: You should now see your Firebase project dashboard

---

## Step 2: Add Android App to Firebase

### 2.1 Register App
1. On the Firebase dashboard, click the **Android icon** (🤖)
2. Fill in the form:
   - **Android package name**: `com.vibenou.vibenou`
   - **App nickname** (optional): `VibeNou Android`
   - **Debug signing certificate SHA-1** (optional): Leave blank for now
3. Click **"Register app"**

### 2.2 Download Config File
1. Click **"Download google-services.json"**
2. Save this file to your computer

### 2.3 Place Config File
1. Open your VibeNou project folder: `C:\Users\charl\VibeNou\`
2. Navigate to: `android\app\`
3. Copy `google-services.json` into this folder
4. Final path should be: `C:\Users\charl\VibeNou\android\app\google-services.json`

### 2.4 Skip Remaining Steps
1. Click **"Next"** (we already have the code configured)
2. Click **"Next"** again
3. Click **"Continue to console"**

✅ **Checkpoint**: `google-services.json` file should be in `android/app/` folder

---

## Step 3: Add iOS App (OPTIONAL - Skip if only testing on Android)

### 3.1 Register iOS App
1. On Firebase dashboard, click **"Add app"**
2. Click the **iOS icon** (🍎)
3. Fill in the form:
   - **iOS bundle ID**: `com.vibenou.vibenou`
   - **App nickname**: `VibeNou iOS`
   - **App Store ID**: Leave blank
4. Click **"Register app"**

### 3.2 Download Config File
1. Click **"Download GoogleService-Info.plist"**
2. Save this file to your computer

### 3.3 Place Config File
1. Navigate to: `C:\Users\charl\VibeNou\ios\Runner\`
2. Copy `GoogleService-Info.plist` into this folder

### 3.4 Skip Steps and Continue
1. Click **"Next"** (skip remaining steps)
2. Click **"Continue to console"**

✅ **Checkpoint**: `GoogleService-Info.plist` in `ios/Runner/` folder (if doing iOS)

---

## Step 4: Enable Authentication

### 4.1 Go to Authentication
1. In Firebase Console left sidebar, click **"Build"** → **"Authentication"**
2. Click **"Get started"**

### 4.2 Enable Email/Password
1. Click the **"Sign-in method"** tab
2. Find **"Email/Password"** in the list
3. Click on it
4. Toggle **"Enable"** to ON
5. Click **"Save"**

✅ **Checkpoint**: Email/Password should show "Enabled" status

---

## Step 5: Create Firestore Database

### 5.1 Go to Firestore
1. In left sidebar, click **"Build"** → **"Firestore Database"**
2. Click **"Create database"**

### 5.2 Choose Mode
1. Select **"Start in production mode"**
2. Click **"Next"**

### 5.3 Choose Location
1. Select a location close to your users:
   - **For Haiti/Caribbean**: Choose `us-east1` (South Carolina)
   - **For North America**: Choose `us-central1` (Iowa)
   - **For Europe**: Choose `europe-west1` (Belgium)
2. Click **"Enable"**
3. Wait for database creation (~1 minute)

✅ **Checkpoint**: You should see an empty Firestore database

---

## Step 6: Configure Firestore Security Rules

### 6.1 Go to Rules Tab
1. In Firestore Database, click the **"Rules"** tab
2. You'll see the default rules

### 6.2 Replace Rules
1. **Delete all existing text**
2. **Copy and paste** this complete ruleset:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper function to check if user is authenticated
    function isSignedIn() {
      return request.auth != null;
    }

    // Helper function to check if user owns the document
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    // Users collection
    match /users/{userId} {
      // Anyone authenticated can read any user profile
      allow read: if isSignedIn();

      // Users can only write their own profile
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);
    }

    // Chat rooms
    match /chatRooms/{chatRoomId} {
      // Can read if you're a participant
      allow read: if isSignedIn() &&
        request.auth.uid in resource.data.participants;

      // Can create if you're one of the participants
      allow create: if isSignedIn() &&
        request.auth.uid in request.resource.data.participants;

      // Can update if you're a participant
      allow update: if isSignedIn() &&
        request.auth.uid in resource.data.participants;

      // Chat messages subcollection
      match /messages/{messageId} {
        allow read: if isSignedIn();
        allow create: if isSignedIn();
      }
    }

    // Reports collection
    match /reports/{reportId} {
      // Users can create reports
      allow create: if isSignedIn() &&
        request.auth.uid == request.resource.data.reporterId;

      // Users can read reports they created or that are about them
      allow read: if isSignedIn() &&
        (request.auth.uid == resource.data.reporterId ||
         request.auth.uid == resource.data.reportedUserId);
    }

    // Profile Views collection
    match /profileViews/{viewId} {
      // Users can read views where they are the viewer or viewed user
      allow read: if isSignedIn() &&
        (request.auth.uid == resource.data.viewerId ||
         request.auth.uid == resource.data.viewedUserId);

      // Users can create views for themselves
      allow create: if isSignedIn() &&
        request.auth.uid == request.resource.data.viewerId;

      // Users can update their own received views (mark as read)
      allow update: if isSignedIn() &&
        request.auth.uid == resource.data.viewedUserId;
    }
  }
}
```

### 6.3 Publish Rules
1. Click **"Publish"** button
2. Wait for confirmation message

✅ **Checkpoint**: Rules should show "Last updated: just now"

---

## Step 7: Create Firestore Indexes (For Better Performance)

### 7.1 Go to Indexes Tab
1. In Firestore Database, click the **"Indexes"** tab
2. Click **"Add Index"** (if available) or wait for automatic index creation

### 7.2 Create Composite Indexes
You'll create these indexes when the app requests them, but here are the ones you'll need:

**Index 1: Chat Rooms**
- Collection: `chatRooms`
- Fields:
  - `participants` (Array)
  - `lastMessageTime` (Descending)

**Index 2: Profile Views**
- Collection: `profileViews`
- Fields:
  - `viewedUserId` (Ascending)
  - `viewedAt` (Descending)

**Index 3: Profile Views (Unread)**
- Collection: `profileViews`
- Fields:
  - `viewedUserId` (Ascending)
  - `isRead` (Ascending)

**Note**: Firebase will prompt you to create these indexes when the app tries to use them. Just click the link in the error message.

✅ **Checkpoint**: Indexes tab is ready for future indexes

---

## Step 8: Enable Storage (Optional - For Future Features)

If you want to support profile pictures later:

1. In left sidebar, click **"Build"** → **"Storage"**
2. Click **"Get started"**
3. Use default security rules (we'll update later)
4. Choose same location as Firestore
5. Click **"Done"**

---

## Step 9: Get Your Firebase Configuration

### 9.1 Go to Project Settings
1. Click the **⚙️ gear icon** next to "Project Overview"
2. Click **"Project settings"**

### 9.2 Find Your Configuration
1. Scroll down to **"Your apps"**
2. You should see your Android app (and iOS if you added it)
3. Look for these values - you'll need them:

**For Android (google-services.json):**
```json
{
  "project_info": {
    "project_id": "YOUR_PROJECT_ID",
    "project_number": "YOUR_PROJECT_NUMBER"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "YOUR_APP_ID",
        "android_client_info": {
          "package_name": "com.vibenou.vibenou"
        }
      }
    }
  ]
}
```

Write down or screenshot:
- ✅ **Project ID**: (e.g., `vibenou-12345`)
- ✅ **App ID**: (e.g., `1:123456789:android:abc123...`)

---

## Step 10: Verify Your Setup

### 10.1 Check All Files
Verify these files exist in your project:

**Android:**
- ✅ `C:\Users\charl\VibeNou\android\app\google-services.json`

**iOS (if applicable):**
- ✅ `C:\Users\charl\VibeNou\ios\Runner\GoogleService-Info.plist`

### 10.2 Check Firebase Console
In Firebase Console, verify:
- ✅ Authentication is enabled (Email/Password)
- ✅ Firestore Database is created
- ✅ Security rules are published
- ✅ Your app is registered (Android and/or iOS)

---

## Step 11: Update App Code

Now we need to enable Firebase in the app code.

### 11.1 Update main.dart
I'll help you update this file in the next step.

### 11.2 Update firebase_options.dart
I'll help you configure this with your actual Firebase settings.

---

## 🎉 Firebase Setup Complete!

You've successfully:
- ✅ Created a Firebase project
- ✅ Registered your app (Android/iOS)
- ✅ Downloaded configuration files
- ✅ Enabled Authentication
- ✅ Created Firestore Database
- ✅ Configured Security Rules

---

## 🚨 Common Issues & Solutions

### Issue 1: Can't find google-services.json
**Solution**: Go to Firebase Console → Project Settings → Your apps → Click "google-services.json" button to re-download

### Issue 2: Location already set error
**Solution**: Once set, Firestore location cannot be changed. Create a new Firebase project if needed.

### Issue 3: Permission denied in Firestore
**Solution**: Check that security rules were published correctly

### Issue 4: Authentication not working
**Solution**: Verify Email/Password is enabled in Authentication → Sign-in method

---

## 📝 What's Next?

Now that Firebase is set up, we need to:
1. ✅ Update the app code to connect to Firebase
2. ✅ Test the connection
3. ✅ Create your first test account

I'll help you with these steps next! Let me know when you've completed the Firebase setup above.

---

## 💡 Pro Tips

- **Free Tier Limits**:
  - Firestore: 50K reads/day, 20K writes/day
  - Authentication: Unlimited
  - Storage: 5GB free

- **Monitoring**: Check the "Usage" tab in Firebase Console to monitor your limits

- **Backups**: Firebase doesn't auto-backup on free tier. Export data manually if needed.

- **Testing**: Use Firebase Emulator for local testing (advanced)

---

## 📞 Need Help?

If you get stuck:
1. Check the error message carefully
2. Look at Firebase Console → Authentication/Firestore for issues
3. Check the Firebase status page: https://status.firebase.google.com/
4. Ask me for help with the specific error message

---

**Ready to proceed?** Complete steps 1-10 above, then let me know and I'll help you update the app code! 🚀
