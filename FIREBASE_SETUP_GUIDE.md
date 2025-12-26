# Firebase Setup Guide - Fix Google Sign-In & Read Receipts

## Issue 1: Google Sign-In Failed ❌

**Root Cause:** SHA-1 fingerprint not configured in Firebase Console

### Solution (5 minutes):

#### Step 1: Add SHA-1 to Firebase Console

1. Open **https://console.firebase.google.com**
2. Click on **VibeNou** project
3. Click **⚙️ Settings** → **Project settings**
4. Scroll to **Your apps** section
5. Find **Android app**: `com.vibenou.vibenou`
6. Click **Add fingerprint**
7. Paste this SHA-1:
   ```
   42:41:71:D1:31:50:D0:4B:18:AC:12:F3:39:42:FD:33:31:B5:6B:91
   ```
8. Click **Save**

#### Step 2: Download Updated Configuration

9. Still in Firebase Console, click **Download google-services.json**
10. Replace the file at:
    ```
    C:\Users\charl\VibeNou\android\app\google-services.json
    ```

#### Step 3: Rebuild App

Already done! Run:
```bash
flutter run
```

#### Test Google Sign-In:
1. Open app
2. Tap "Continue with Google"
3. Select Google account
4. Should work now ✅

---

## Issue 2: Read Receipts Not Working ❌

**Root Cause:** Firestore rules block message updates

### Solution (2 minutes):

#### Deploy Firestore Rules via Console

1. Open **https://console.firebase.google.com**
2. Select **VibeNou** project
3. Click **Firestore Database** in left sidebar
4. Click **Rules** tab at top
5. **Delete all existing rules**
6. **Copy-paste** the entire content from:
   ```
   C:\Users\charl\VibeNou\firestore.rules
   ```
7. Click **Publish**

#### Verify Deployment:
- You should see: "Rules published successfully"
- Check the publish timestamp

#### Test Read Receipts:
1. Send a message to another user
2. When they open the message, the checkmark should change:
   - Before: ✓ (single gray checkmark)
   - After: ✓✓ (double pink checkmark)

---

## Quick Reference

### Your App Configuration

**Package Name:** `com.vibenou.vibenou`

**Debug SHA-1:**
```
42:41:71:D1:31:50:D0:4B:18:AC:12:F3:39:42:FD:33:31:B5:6B:91
```

**Firebase Project ID:** `vibenou-5d701`

**Google OAuth Client ID:** `161222852953-a340277ohdd5vddlvga4auhpk51ai7eg.apps.googleusercontent.com`

---

## Troubleshooting

### Google Sign-In still fails:
- Make sure you downloaded the NEW google-services.json
- Make sure you replaced the file in `android/app/`
- Run `flutter clean && flutter pub get` again
- Restart your IDE

### Read Receipts still not working:
- Check Firestore rules were published (check timestamp in Firebase Console)
- Check both users are authenticated
- Check message document has `isRead: false` field

### Need to generate Release SHA-1 (for production):
```bash
keytool -list -v -keystore C:\Users\charl\upload-keystore.jks -alias upload
```

---

## Production Checklist (Before Release)

- [ ] Add **Release SHA-1** to Firebase Console
- [ ] Download updated google-services.json for release
- [ ] Test Google Sign-In with release build
- [ ] Verify read receipts work in production
- [ ] Test on multiple devices

---

**Last Updated:** 2024-12-25
**Status:** Awaiting your Firebase Console updates
