# Security Features Deployment Guide
## VibeNou Production-Grade Security

**Version:** 1.0
**Date:** December 24, 2024
**Status:** Ready for Deployment

---

## 🚨 Prerequisites

Before deploying, you must:

1. **Authenticate with Firebase:**
   ```bash
   cd C:\Users\charl\vibenou
   firebase login
   firebase use your-project-id
   ```

2. **Verify dependencies installed:**
   ```bash
   # Flutter dependencies
   flutter pub get

   # Cloud Functions dependencies
   cd functions
   npm install
   cd ..
   ```

3. **Configure environment variables** (see `.env.example`)

---

## 📦 Quick Deployment

### Option 1: Deploy Everything (Recommended)

```bash
# From project root
cd C:\Users\charl\vibenou

# Deploy all Firebase services at once
firebase deploy

# This deploys:
# ✅ Firestore security rules
# ✅ Cloud Functions (all 9 functions)
# ✅ Firestore indexes (if any)
```

### Option 2: Deploy Individually

```bash
# Deploy Firestore rules first (CRITICAL for security)
firebase deploy --only firestore:rules

# Deploy Cloud Functions
firebase deploy --only functions

# Deploy specific function (for faster deployment)
firebase deploy --only functions:sendPushNotification
```

---

## 🔐 Step-by-Step Deployment

### Step 1: Deploy Firestore Security Rules

**What this does:**
- Protects rate limits collection
- Protects audit logs
- Protects account lockout data
- Requires email verification for sensitive operations

```bash
firebase deploy --only firestore:rules
```

**Expected output:**
```
✔  Deploy complete!
Firestore Rules updated
```

**Verify:** Go to Firebase Console → Firestore Database → Rules

### Step 2: Deploy Cloud Functions

**Functions being deployed:**

1. `sendPushNotification` - FCM push notifications
2. `cleanupProcessedNotifications` - Cleanup old notifications
3. `checkRateLimit` - Client-side rate limit checking
4. `getRateLimitStatus` - Get user's rate limit status
5. `cleanupRateLimits` - Cleanup expired rate limits
6. `auditUserProfileChanges` - Auto-log profile changes
7. `auditReportSubmission` - Auto-log reports
8. `cleanupAuditLogs` - Cleanup old audit logs
9. `verifyRecaptcha` - CAPTCHA verification

```bash
firebase deploy --only functions
```

**This may take 5-10 minutes.** Expected output:
```
✔  functions[sendPushNotification]: Successful create operation
✔  functions[cleanupProcessedNotifications]: Successful create operation
✔  functions[checkRateLimit]: Successful create operation
... (6 more)
✔  Deploy complete!
```

**Verify:** Go to Firebase Console → Functions → Check all 9 functions are "Active"

### Step 3: Configure Firebase Services

#### A. Enable Firebase App Check

1. Go to Firebase Console → App Check
2. Click "Get Started"
3. Register your Android app:
   - Provider: **Play Integrity** (production) or **Debug** (development)
4. Register your iOS app:
   - Provider: **App Attest** (iOS 14+) or **DeviceCheck**

#### B. Enable Crashlytics

1. Go to Firebase Console → Crashlytics
2. Click "Enable Crashlytics"
3. No additional configuration needed (already integrated in app)

#### C. Add Debug Tokens (Development Only)

For local testing:
```bash
# Generate debug token
flutterfire configure --debug
```

Copy the token and add it to:
1. Firebase Console → App Check → Manage debug tokens
2. Your `.env` file: `APP_CHECK_DEBUG_TOKEN=...`

### Step 4: Run Beta User Migration (One-Time)

**IMPORTANT:** Run this BEFORE enforcing email verification!

This marks all existing users as email-verified (grandfather clause):

```dart
// In your app or Firebase Console
await grandfatherBetaUsers();

// This sets emailVerified: true for all users created before Dec 24, 2024
```

Or use Firebase Console:
1. Go to Firestore Database
2. Run query:
   ```
   users
   WHERE createdAt < December 24, 2024
   ```
3. Batch update all results: `emailVerified: true`

### Step 5: Update App Configuration for Production

Before building the app, make these changes:

#### Change 1: Enable Production CAPTCHA Providers

In `lib/services/captcha_service.dart`, update:

```dart
// FROM (debug):
await _appCheck.activate(
  androidProvider: AndroidProvider.debug,
  appleProvider: AppleProvider.debug,
);

// TO (production):
await _appCheck.activate(
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.appAttest,
);
```

Or simply call:
```dart
await CaptchaService.configureForProduction();
```

#### Change 2: Verify All Kill Switches are ON

Check these files have `ENABLED = true`:
- ✅ `lib/services/captcha_service.dart` → `static const bool ENABLED = true;`
- ✅ `lib/services/account_lockout_service.dart` → `static const bool ENABLED = true;`

### Step 6: Build & Deploy App

```bash
# Android (Debug for testing)
flutter build apk --debug

# Android (Production)
flutter build appbundle --release

# iOS (Production - requires macOS)
flutter build ipa --release
```

**Output:**
- Android: `build/app/outputs/bundle/release/app-release.aab`
- iOS: `build/ios/ipa/vibenou.ipa`

### Step 7: Deploy to App Stores

#### Google Play Store:
1. Go to [Google Play Console](https://play.google.com/console)
2. Upload `app-release.aab`
3. Add release notes (see template below)
4. Submit for review

**Release Notes Template:**
```
🔒 Major Security & Privacy Update

New Features:
• Two-Factor Authentication (2FA) - Protect your account
• Email verification - Prevent fake accounts
• Advanced bot protection
• Comprehensive security logging

Improvements:
• Enhanced account security against brute force attacks
• Better error reporting for faster bug fixes
• Improved app stability
• Rate limiting to prevent spam

Your security and privacy are our top priority!
```

---

## ✅ Post-Deployment Verification

### 1. Check Cloud Functions

```bash
# View deployed functions
firebase functions:list

# Check recent logs
firebase functions:log --limit 50

# Test a function
firebase functions:shell
> checkRateLimit({userId: 'test', action: 'messages'})
```

### 2. Test Firestore Rules

In Firebase Console → Firestore → Rules Playground:

**Test 1:** User can read own profile
```
Operation: get
Path: /users/user123
Auth: user123
Expected: ✅ Allowed
```

**Test 2:** User CANNOT read others' audit logs
```
Operation: get
Path: /auditLogs/otherUser/events/event1
Auth: user123
Expected: ❌ Denied
```

**Test 3:** Unverified user CANNOT send message
```
Operation: create
Path: /chatRooms/room123/messages/msg1
Auth: user123 (emailVerified: false)
Expected: ❌ Denied
```

### 3. Test App Features

1. **Sign up new account**
   - ✅ Email verification sent
   - ✅ CAPTCHA/App Check verified

2. **Try to send message (unverified)**
   - ✅ Blocked with verification prompt

3. **Verify email**
   - ✅ Click link in email
   - ✅ Can now send messages

4. **Enable 2FA**
   - ✅ QR code displayed
   - ✅ Recovery codes shown
   - ✅ Login requires 6-digit code

5. **Test rate limiting**
   - ✅ Send 60 messages in 1 minute → succeeds
   - ✅ Send 61st message → blocked

6. **Test account lockout**
   - ✅ 5 wrong passwords → account locked
   - ✅ Wait 15 minutes → can login again

### 4. Monitor Dashboards

Check Firebase Console:

1. **Crashlytics** → Verify crashes being reported
2. **App Check** → Check valid request metrics
3. **Functions** → Monitor invocations and errors
4. **Firestore** → Review read/write operations
5. **Authentication** → Track new signups

---

## 🚨 Emergency Rollback

If critical issues occur, use these kill switches:

### Quick Disable (No Deployment Required)

#### Disable CAPTCHA:
```dart
// lib/services/captcha_service.dart
static const bool ENABLED = false;  // Changed from true
```

#### Disable Account Lockout:
```dart
// lib/services/account_lockout_service.dart
static const bool ENABLED = false;  // Changed from true
```

#### Disable Email Verification Enforcement:
```javascript
// firestore.rules - Update and redeploy
function requiresVerification() {
  return false;  // Changed from checking emailVerified
}
```

Then redeploy rules only:
```bash
firebase deploy --only firestore:rules
```

### Rollback Cloud Functions

```bash
# List function versions
firebase functions:list

# Rollback specific function
firebase functions:rollback functionName --version previousVersion

# Or redeploy previous version
git checkout HEAD~1
firebase deploy --only functions
```

---

## 📊 Monitoring Checklist

### Daily (First Week)

- [ ] Check Crashlytics dashboard for errors
- [ ] Monitor Cloud Functions invocation count
- [ ] Review account lockout rate (< 5% acceptable)
- [ ] Check email verification completion (> 80% target)
- [ ] Monitor App Check invalid requests

### Weekly

- [ ] Review audit logs for suspicious activity
- [ ] Check Firebase costs (target: < $25/month)
- [ ] Monitor 2FA adoption rate
- [ ] Review support tickets
- [ ] Check user feedback on app stores

### Alerts to Set Up

In Firebase Console, create alerts for:

1. **Crashlytics:** Crash rate > 1%
2. **Functions:** Error rate > 5%
3. **Billing:** Monthly costs > $50

---

## 🎯 Success Metrics

Track these metrics post-deployment:

| Metric | Target | How to Check |
|--------|--------|--------------|
| Crash Rate | < 1% | Crashlytics Dashboard |
| Login Success Rate | > 95% | Analytics / Firestore |
| Email Verification Completion | > 90% | Firestore query |
| Account Lockout Rate | < 5% | Firestore `accountLockouts` count |
| 2FA Adoption (30 days) | > 20% | Firestore query |
| App Check Invalid Requests | < 10% | App Check Dashboard |
| Cloud Functions Error Rate | < 5% | Functions Metrics |

---

## 🔧 Troubleshooting

### "Failed to authenticate" Error

```bash
firebase logout
firebase login
firebase use your-project-id
```

### Cloud Functions Deployment Fails

```bash
cd functions
npm install
npm audit fix
cd ..
firebase deploy --only functions --debug
```

### App Check "Token is null"

1. Verify app registered in Firebase Console → App Check
2. For development: Add debug token
3. For production: Ensure app distributed via Play Store/App Store

### High Cloud Functions Costs

1. Review invocation metrics in Firebase Console
2. Check for infinite loops or excessive retries
3. Optimize function memory settings
4. Implement caching where appropriate

---

## 📋 Deployment Checklist

Use this before going live:

**Pre-Deployment:**
- [ ] Firebase CLI authenticated
- [ ] All dependencies installed
- [ ] `.env` configured (not committed to git)
- [ ] Beta users migrated
- [ ] Production CAPTCHA providers configured
- [ ] All kill switches enabled

**Deployment:**
- [ ] Firestore rules deployed
- [ ] Cloud Functions deployed (all 9)
- [ ] Firebase App Check enabled
- [ ] Crashlytics enabled
- [ ] App built for production
- [ ] Deployed to app stores

**Post-Deployment:**
- [ ] Firestore rules verified in Rules Playground
- [ ] Cloud Functions tested and active
- [ ] End-to-end user flow tested
- [ ] Monitoring dashboards configured
- [ ] Alert thresholds set
- [ ] Rollback plan documented

---

## 📚 Additional Resources

- **Full Testing Plan:** See `TESTING_PLAN.md`
- **CAPTCHA Setup:** See `CAPTCHA_SETUP.md`
- **Firebase Console:** https://console.firebase.google.com
- **Firebase CLI Docs:** https://firebase.google.com/docs/cli

---

## ✨ What You've Deployed

### Security Features (8 Total)

1. ✅ **Secrets Management** - Environment variables protected
2. ✅ **Rate Limiting** - Firestore-based, persistent
3. ✅ **Email Verification** - Prevents fake accounts
4. ✅ **2FA** - TOTP-based, optional
5. ✅ **Audit Logging** - Comprehensive security tracking
6. ✅ **Crashlytics** - Error & crash monitoring
7. ✅ **Account Lockout** - Brute force protection
8. ✅ **CAPTCHA** - Bot prevention via App Check

### Cloud Functions (9 Total)

1. `sendPushNotification` - Push notifications
2. `cleanupProcessedNotifications` - Cleanup job
3. `checkRateLimit` - Rate limit verification
4. `getRateLimitStatus` - Rate limit status
5. `cleanupRateLimits` - Rate limit cleanup
6. `auditUserProfileChanges` - Profile change logging
7. `auditReportSubmission` - Report logging
8. `cleanupAuditLogs` - Audit log cleanup
9. `verifyRecaptcha` - reCAPTCHA verification

---

## 🎉 Congratulations!

Your VibeNou app now has production-grade security! 🔒

**Next steps:**
1. Monitor dashboards daily for first week
2. Collect user feedback
3. Adjust thresholds if needed
4. Plan next security enhancements

**Questions?** Refer to:
- `TESTING_PLAN.md` for comprehensive testing
- `CAPTCHA_SETUP.md` for CAPTCHA configuration
- Firebase documentation for service-specific help

---

**Document Version:** 1.0
**Last Updated:** December 24, 2024
**Status:** ✅ Ready for Production
