# Firebase Configuration Template

Fill this out as you go through the Firebase setup. You'll need these values later.

## 🔑 Your Firebase Configuration

### From Firebase Console → Project Settings:

```
Project ID: ___________________________
(Example: vibenou-12345)

App ID (Android): ___________________________
(Example: 1:123456789:android:abc123...)

Project Number: ___________________________
(Example: 123456789)

Storage Bucket: ___________________________
(Example: vibenou-12345.appspot.com)

API Key: ___________________________
(Example: AIzaSy...)
```

---

## 📁 Files Checklist

Check off when completed:

**Android Setup:**
- [ ] `google-services.json` downloaded
- [ ] `google-services.json` placed in `android/app/` folder
- [ ] File path verified: `C:\Users\charl\VibeNou\android\app\google-services.json`

**iOS Setup (if applicable):**
- [ ] `GoogleService-Info.plist` downloaded
- [ ] `GoogleService-Info.plist` placed in `ios/Runner/` folder
- [ ] File path verified: `C:\Users\charl\VibeNou\ios\Runner\GoogleService-Info.plist`

---

## ✅ Services Enabled Checklist

**In Firebase Console, verify:**

- [ ] **Project Created**: Project name is "VibeNou"
- [ ] **Android App Registered**: Package name is `com.vibenou.vibenou`
- [ ] **iOS App Registered** (optional): Bundle ID is `com.vibenou.vibenou`

**Authentication:**
- [ ] Authentication → Get Started clicked
- [ ] Email/Password sign-in method **ENABLED**
- [ ] Status shows "Enabled" with green checkmark

**Firestore Database:**
- [ ] Database created
- [ ] Location selected: _________________ (note which region)
- [ ] Started in **Production mode**
- [ ] Security rules updated and published
- [ ] Rules tab shows "Last updated: just now"

**Storage (Optional):**
- [ ] Storage enabled
- [ ] Same location as Firestore

---

## 🎯 Quick Verification

Open Firebase Console and check these:

1. **Project Overview**:
   - Shows 1 Android app (and 1 iOS app if applicable)
   - No error messages

2. **Authentication** page:
   - Email/Password shows "Enabled"
   - Users tab exists (will be empty)

3. **Firestore Database** page:
   - Database exists
   - Data tab shows empty database
   - Rules tab shows updated rules

4. **Project Settings**:
   - Your apps section shows registered apps
   - Config files can be re-downloaded if needed

---

## 🚀 Ready for Next Step?

When ALL items above are checked:
- ✅ All checkboxes are marked
- ✅ Configuration values are filled in
- ✅ Files are in correct locations
- ✅ Services are enabled in Firebase Console

**Then you're ready to update the app code!**

Tell me "Firebase setup complete" and I'll help you update the code to connect to your Firebase backend.

---

## 📸 Screenshot Checklist

Take screenshots of these (for troubleshooting):

1. Firebase Console → Project Overview (showing your apps)
2. Authentication → Sign-in method (showing Email/Password enabled)
3. Firestore Database → Data tab (empty database)
4. Firestore Database → Rules tab (showing your rules)
5. Project Settings → Your apps section

Save these in case you need help troubleshooting!
