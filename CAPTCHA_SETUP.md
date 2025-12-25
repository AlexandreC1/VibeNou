# CAPTCHA & Bot Prevention Setup Guide

This guide explains how to configure bot prevention for the VibeNou app using Firebase App Check and optionally Google reCAPTCHA v3.

## Table of Contents

1. [Firebase App Check Setup (Recommended for Mobile)](#firebase-app-check-setup)
2. [Google reCAPTCHA v3 Setup (Optional for Web)](#google-recaptcha-v3-setup)
3. [Testing in Development](#testing-in-development)
4. [Production Deployment](#production-deployment)
5. [Troubleshooting](#troubleshooting)

---

## Firebase App Check Setup

Firebase App Check protects your app by verifying that requests come from authentic app instances, not bots or unauthorized clients.

### 1. Enable Firebase App Check in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project (VibeNou)
3. Navigate to **App Check** in the left sidebar
4. Click **Get Started**

### 2. Register Your Apps

#### For Android:

1. Click on your Android app
2. Select **Play Integrity** as the provider
3. Click **Register**
4. App Check is now enabled for Android

**Note:** Play Integrity requires your app to be distributed through Google Play Store. For testing, use debug tokens (see below).

#### For iOS:

1. Click on your iOS app
2. Select **App Attest** as the provider (iOS 14+)
3. Click **Register**
4. For older iOS versions, use **DeviceCheck**

### 3. Generate Debug Tokens (Development Only)

For local development and testing:

```bash
# Install flutterfire CLI if not already installed
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# Generate debug token
flutterfire configure --debug
```

Copy the generated debug token and:

1. Add it to your `.env` file:
   ```
   APP_CHECK_DEBUG_TOKEN=your_debug_token_here
   ```

2. Add it to Firebase Console:
   - Go to App Check → Apps → Click your app
   - Click "Manage debug tokens"
   - Add the debug token
   - Click "Add"

### 4. Update Code for Production

In `lib/services/captcha_service.dart`, change from debug to production providers:

```dart
// Development (current):
await _appCheck.activate(
  androidProvider: AndroidProvider.debug,
  appleProvider: AppleProvider.debug,
);

// Production (update to this):
await _appCheck.activate(
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.appAttest,
);
```

Or call the helper method:
```dart
await CaptchaService.configureForProduction();
```

### 5. Enforce App Check on Backend

Update Firestore security rules to require App Check (optional, for extra security):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Require App Check for writes
    function isAppCheckVerified() {
      return request.auth.token.firebase.sign_in_provider == 'custom'
        || request.app == null
        || request.app.isVerified;
    }

    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && isAppCheckVerified();
    }
  }
}
```

---

## Google reCAPTCHA v3 Setup (Optional)

Use this for web applications or as an additional layer of protection.

### 1. Register Your Site

1. Go to [Google reCAPTCHA Admin Console](https://www.google.com/recaptcha/admin)
2. Click **Create** (+)
3. Fill in the form:
   - **Label:** VibeNou Production
   - **reCAPTCHA type:** reCAPTCHA v3
   - **Domains:**
     - `localhost` (for testing)
     - `vibenou.com` (your production domain)
     - `vibenou.web.app` (if using Firebase Hosting)
4. Accept terms and click **Submit**

### 2. Save Your Keys

You'll get two keys:

- **Site Key:** Used in client-side code (public)
- **Secret Key:** Used in server-side verification (private)

### 3. Add Keys to Environment Variables

#### Local Development (.env file):
```bash
RECAPTCHA_SITE_KEY=your_site_key_here
RECAPTCHA_SECRET_KEY=your_secret_key_here
```

#### Production (CI/CD Secrets):

Add as GitHub Secrets, GitLab CI Variables, or your CI/CD platform:
- `RECAPTCHA_SITE_KEY`
- `RECAPTCHA_SECRET_KEY`

### 4. Configure Cloud Functions

The secret key must be available to Cloud Functions:

```bash
# Set Firebase Functions config
firebase functions:config:set recaptcha.secret_key="YOUR_SECRET_KEY"

# Or use environment variables (recommended)
# Add to functions/.env file:
RECAPTCHA_SECRET_KEY=your_secret_key_here
```

### 5. Update Firebase Functions Environment

In Firebase Console:
1. Go to **Functions**
2. Click on a function
3. Click **Edit**
4. Add environment variable:
   - Name: `RECAPTCHA_SECRET_KEY`
   - Value: Your secret key

---

## Testing in Development

### 1. Test Firebase App Check

```dart
// In your app, call this to test
final token = await CaptchaService.getToken();
print('App Check Token: $token');

// Verify signup works
final isHuman = await CaptchaService.verifySignup();
print('Signup verified: $isHuman');
```

### 2. Test reCAPTCHA (if using)

```dart
// Generate a test token (you'll need to implement client-side reCAPTCHA)
final result = await CaptchaService.verifyRecaptcha('test_token');
print('reCAPTCHA result: ${result.score}');
```

### 3. Monitor in Firebase Console

1. Go to **App Check** in Firebase Console
2. View metrics:
   - Valid requests
   - Invalid requests
   - Errors

---

## Production Deployment

### Pre-Deployment Checklist

- [ ] Firebase App Check enabled in Firebase Console
- [ ] App registered with Play Integrity (Android) or App Attest (iOS)
- [ ] Production providers configured in code
- [ ] Debug tokens removed from code
- [ ] Environment variables set in CI/CD
- [ ] Cloud Functions have RECAPTCHA_SECRET_KEY (if using)
- [ ] Tested in staging environment

### Deployment Steps

1. **Update Code for Production:**

   ```dart
   // In lib/services/captcha_service.dart
   await CaptchaService.configureForProduction();
   ```

2. **Deploy Cloud Functions:**

   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```

3. **Build Production App:**

   ```bash
   # Android
   flutter build appbundle --release

   # iOS
   flutter build ipa --release
   ```

4. **Monitor After Deployment:**

   - Check Firebase App Check metrics
   - Monitor Cloud Functions logs
   - Watch for bot signup attempts in audit logs

---

## Configuration Summary

### Current Setup (Development)

| Feature | Status | Provider |
|---------|--------|----------|
| Firebase App Check | ✅ Enabled | Debug Provider |
| Android | ✅ Configured | AndroidProvider.debug |
| iOS | ✅ Configured | AppleProvider.debug |
| reCAPTCHA | ⚠️ Optional | Not required for mobile |
| Kill Switch | ✅ Available | `CaptchaService.ENABLED` |

### Production Setup (Required Changes)

| Feature | Action Required |
|---------|-----------------|
| Android Provider | Change to `AndroidProvider.playIntegrity` |
| iOS Provider | Change to `AppleProvider.appAttest` |
| Debug Tokens | Remove from code |
| reCAPTCHA Secret | Add to Cloud Functions environment |
| Firestore Rules | Optionally enforce App Check |

---

## Verification Thresholds

Different actions have different bot detection thresholds:

| Action | Threshold | Strictness |
|--------|-----------|------------|
| **Signup** | 0.7 | High (blocks most bots) |
| **Login** | 0.3 | Low (only obvious bots) |
| **Send Message** | 0.5 | Medium |
| **Other** | 0.5 | Medium |

Scores range from 0.0 (definitely bot) to 1.0 (definitely human).

---

## Troubleshooting

### Issue: "App Check token is null"

**Cause:** App Check not properly initialized or app not registered.

**Solution:**
1. Verify app is registered in Firebase Console → App Check
2. Check that `CaptchaService.initialize()` is called in `main.dart`
3. For testing, ensure debug token is added to Firebase Console

### Issue: "CAPTCHA verification failed"

**Cause:** Cloud Functions can't reach reCAPTCHA API or invalid secret key.

**Solution:**
1. Check Cloud Functions logs: `firebase functions:log`
2. Verify `RECAPTCHA_SECRET_KEY` is set correctly
3. Ensure Cloud Functions has internet access
4. Check axios is installed: `cd functions && npm install axios`

### Issue: "Play Integrity API error" (Android)

**Cause:** App not distributed through Google Play or integrity check failed.

**Solution:**
1. For testing: Use debug provider or debug tokens
2. For production: Ensure app is uploaded to Google Play (even as internal testing)
3. Wait 24-48 hours after first Play Store upload for API to activate

### Issue: Too many false positives (legitimate users blocked)

**Cause:** Threshold too strict.

**Solution:**
1. Lower the threshold in `functions/src/captcha.js`
2. For signups, reduce from 0.7 to 0.5
3. Monitor and adjust based on metrics

### Issue: Too many bots getting through

**Cause:** Threshold too lenient.

**Solution:**
1. Raise the threshold in `functions/src/captcha.js`
2. For signups, increase from 0.7 to 0.8 or 0.9
3. Enable App Check enforcement in Firestore rules

---

## Disabling CAPTCHA (Emergency Rollback)

If CAPTCHA causes issues in production:

### Quick Disable (No Deployment)

Set the kill switch to `false`:

```dart
// In lib/services/captcha_service.dart
static const bool ENABLED = false;
```

Or in Cloud Functions:
```javascript
// In functions/src/captcha.js
const ENABLED = false;
```

### Complete Removal

1. Comment out CAPTCHA verification in AuthService:
   ```dart
   // final isHuman = await CaptchaService.verifySignup();
   // if (!isHuman) { ... }
   ```

2. Redeploy app and functions

---

## Monitoring & Analytics

### Key Metrics to Track

1. **App Check Dashboard:**
   - Valid vs invalid requests
   - Error rate
   - Token refresh rate

2. **Audit Logs:**
   - Signup attempts blocked by CAPTCHA
   - Bot signup patterns

3. **Cloud Functions Logs:**
   - reCAPTCHA score distribution
   - Verification failures

### Logging

All CAPTCHA events are logged via `AppLogger`:

```dart
// Search logs for CAPTCHA events
grep "CAPTCHA" app_logs.txt
grep "App Check" app_logs.txt
grep "Bot detection" app_logs.txt
```

---

## Cost Considerations

### Firebase App Check

- **Free tier:** 1 million verifications/month
- **Paid tier:** $0.50 per 100K verifications after free tier

### Google reCAPTCHA v3

- **Free tier:** 1 million assessments/month
- **Paid tier:** $1 per 1,000 assessments after free tier

**Estimated cost for VibeNou (10K daily active users):**
- App Check: ~300K verifications/month = **FREE**
- reCAPTCHA: ~10K assessments/month = **FREE**

Total: **$0/month** within free tier

---

## Security Best Practices

1. ✅ **Never expose secret keys** in client code
2. ✅ **Use App Check for mobile apps** (not reCAPTCHA)
3. ✅ **Use reCAPTCHA v3** for web (invisible, no user friction)
4. ✅ **Monitor for false positives** and adjust thresholds
5. ✅ **Combine with rate limiting** for defense in depth
6. ✅ **Enable audit logging** for bot detection events
7. ✅ **Test in staging** before production deployment
8. ✅ **Have a rollback plan** (kill switch ready)

---

## Next Steps

1. [ ] Enable Firebase App Check in Firebase Console
2. [ ] Register Android and iOS apps
3. [ ] Generate and add debug tokens for testing
4. [ ] Test bot detection in development
5. [ ] Configure production providers before launch
6. [ ] Set up monitoring and alerts
7. [ ] Deploy to production with gradual rollout

For questions or issues, check Firebase documentation:
- [Firebase App Check Docs](https://firebase.google.com/docs/app-check)
- [reCAPTCHA v3 Docs](https://developers.google.com/recaptcha/docs/v3)
