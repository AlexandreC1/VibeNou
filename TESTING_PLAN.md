# Comprehensive Testing Plan
## VibeNou Security Implementation

**Version:** 1.0
**Date:** December 24, 2024
**Status:** Ready for Testing

---

## Table of Contents

1. [Testing Overview](#testing-overview)
2. [Pre-Testing Checklist](#pre-testing-checklist)
3. [Functional Testing](#functional-testing)
4. [Security Testing](#security-testing)
5. [Performance Testing](#performance-testing)
6. [Backward Compatibility Testing](#backward-compatibility-testing)
7. [Integration Testing](#integration-testing)
8. [User Acceptance Testing](#user-acceptance-testing)
9. [Regression Testing](#regression-testing)
10. [Test Execution & Reporting](#test-execution--reporting)

---

## Testing Overview

### Scope

This testing plan covers all 8 security features implemented in the VibeNou production-grade security upgrade:

1. ✅ Secrets Management
2. ✅ Persistent Rate Limiting
3. ✅ Email Verification
4. ✅ Two-Factor Authentication (2FA)
5. ✅ Audit Logging
6. ✅ Error Telemetry (Crashlytics)
7. ✅ Account Lockout
8. ✅ CAPTCHA/Bot Prevention

### Testing Environment

- **Development:** Local emulators + Firebase Staging Project
- **Staging:** Dedicated Firebase project for pre-production testing
- **Production:** Live Firebase project (gradual rollout)

### Testing Tools

- **Manual Testing:** Physical devices (Android/iOS)
- **Automated Testing:** Flutter integration tests
- **Security Testing:** Manual penetration testing
- **Performance Testing:** Firebase Performance Monitoring
- **Error Tracking:** Firebase Crashlytics
- **Monitoring:** Firebase Console, Cloud Functions logs

---

## Pre-Testing Checklist

### ✅ Before Starting Tests

- [ ] All dependencies installed (`flutter pub get` completed)
- [ ] Cloud Functions dependencies installed (`npm install` in functions/)
- [ ] `.env` file configured with valid credentials
- [ ] Firebase project selected and authenticated
- [ ] Firestore emulator running (optional for local testing)
- [ ] Test user accounts created
- [ ] Beta user migration script executed (if testing with existing data)

### ✅ Code Quality Checks

```bash
# Run Flutter analyzer
flutter analyze

# Expected: 0 errors, warnings acceptable (97 info-level issues is OK)

# Run tests
flutter test

# Expected: All tests passing

# Check Cloud Functions syntax
cd functions
npm run lint
```

### ✅ Build Verification

```bash
# Android build
flutter build apk --debug

# iOS build (macOS only)
flutter build ios --debug
```

---

## Functional Testing

### 1. Secrets Management

**Test ID:** FUNC-001
**Feature:** Environment variable protection

#### Test Cases:

| Test Case | Steps | Expected Result | Status |
|-----------|-------|-----------------|--------|
| SEC-001.1 | Check `.gitignore` includes `.env` | `.env` is ignored | ⬜ |
| SEC-001.2 | Verify `.env.example` has all variables | All secrets have placeholders | ⬜ |
| SEC-001.3 | Build app without `.env` file | Build fails with clear error message | ⬜ |
| SEC-001.4 | Build app with `.env` file | Build succeeds | ⬜ |

---

### 2. Persistent Rate Limiting

**Test ID:** FUNC-002
**Feature:** Firestore-based rate limiting

#### Test Cases:

| Test Case | Steps | Expected Result | Status |
|-----------|-------|-----------------|--------|
| RATE-002.1 | Send 60 messages in 1 minute | 60th message succeeds | ⬜ |
| RATE-002.2 | Send 61st message within same minute | Request blocked with rate limit error | ⬜ |
| RATE-002.3 | Wait 1 minute, send another message | Message succeeds | ⬜ |
| RATE-002.4 | Update profile 10 times in 1 hour | 10th update succeeds | ⬜ |
| RATE-002.5 | Update profile 11th time in same hour | Request blocked | ⬜ |
| RATE-002.6 | Check Firestore `rateLimits` collection | Rate limit documents created | ⬜ |
| RATE-002.7 | Restart app/Cloud Function | Rate limits persist across restarts | ⬜ |
| RATE-002.8 | Call `cleanupExpiredRateLimits` function | Old rate limits deleted | ⬜ |

#### Performance Criteria:

- Rate limit check adds < 100ms latency
- No false positives (legitimate users blocked)

---

### 3. Email Verification

**Test ID:** FUNC-003
**Feature:** Email verification enforcement

#### Test Cases:

| Test Case | Steps | Expected Result | Status |
|-----------|-------|-----------------|--------|
| EMAIL-003.1 | Sign up new account | Verification email sent automatically | ⬜ |
| EMAIL-003.2 | Login with unverified email | Login succeeds but shows verification reminder | ⬜ |
| EMAIL-003.3 | Try to send message (unverified) | Action blocked with verification prompt | ⬜ |
| EMAIL-003.4 | Try to like profile (unverified) | Action blocked | ⬜ |
| EMAIL-003.5 | Click verification link in email | Email verified successfully | ⬜ |
| EMAIL-003.6 | Send message (verified) | Message sent successfully | ⬜ |
| EMAIL-003.7 | Check beta user (created before cutoff) | Automatically marked as verified | ⬜ |
| EMAIL-003.8 | Resend verification email | New email sent | ⬜ |

#### Migration Testing:

```dart
// Run migration script
await grandfatherBetaUsers();

// Verify all users created before Dec 24, 2024 have emailVerified: true
```

---

### 4. Two-Factor Authentication (2FA)

**Test ID:** FUNC-004
**Feature:** TOTP-based 2FA

#### Test Cases:

| Test Case | Steps | Expected Result | Status |
|-----------|-------|-----------------|--------|
| 2FA-004.1 | Navigate to settings → Enable 2FA | QR code displayed | ⬜ |
| 2FA-004.2 | Scan QR code with Google Authenticator | App shows 6-digit codes | ⬜ |
| 2FA-004.3 | Enter 6-digit code from authenticator | 2FA enabled successfully | ⬜ |
| 2FA-004.4 | View recovery codes | 10 recovery codes displayed | ⬜ |
| 2FA-004.5 | Logout and login with password only | Prompted for 6-digit code | ⬜ |
| 2FA-004.6 | Enter correct 6-digit code | Login succeeds | ⬜ |
| 2FA-004.7 | Enter incorrect 6-digit code | Login fails with error message | ⬜ |
| 2FA-004.8 | Use recovery code to login | Login succeeds, recovery code consumed | ⬜ |
| 2FA-004.9 | Try to use same recovery code again | Login fails | ⬜ |
| 2FA-004.10 | Disable 2FA in settings | 2FA disabled, normal login restored | ⬜ |

#### Security Testing:

- [ ] Secret key encrypted in Firestore
- [ ] Recovery codes hashed (not plaintext)
- [ ] Time-based codes expire after 30 seconds

---

### 5. Audit Logging

**Test ID:** FUNC-005
**Feature:** Security event tracking

#### Test Cases:

| Test Case | Steps | Expected Result | Status |
|-----------|-------|-----------------|--------|
| AUDIT-005.1 | Login successfully | Login event logged in `auditLogs/{userId}/events` | ⬜ |
| AUDIT-005.2 | Login with wrong password | Failed login logged with reason | ⬜ |
| AUDIT-005.3 | Change password | Password change logged (severity: warning) | ⬜ |
| AUDIT-005.4 | Change email | Email change logged (severity: critical) | ⬜ |
| AUDIT-005.5 | Enable 2FA | 2FA enabled logged | ⬜ |
| AUDIT-005.6 | Disable 2FA | 2FA disabled logged (severity: warning) | ⬜ |
| AUDIT-005.7 | Change profile photo | Photo change logged | ⬜ |
| AUDIT-005.8 | Block another user | Block event logged | ⬜ |
| AUDIT-005.9 | Report another user | Report logged (severity: warning) in global logs | ⬜ |
| AUDIT-005.10 | Exceed rate limit | Rate limit violation logged | ⬜ |
| AUDIT-005.11 | View audit logs in app | User can see their own audit history | ⬜ |
| AUDIT-005.12 | Try to view others' audit logs | Access denied by Firestore rules | ⬜ |

#### Cloud Function Auto-Logging:

```javascript
// Manually update user email in Firestore (simulate attack)
// Check that auditUserProfileChanges function automatically logs it

db.collection('users').doc(userId).update({
  email: 'attacker@evil.com'
});

// Expected: Event logged in globalAuditLogs with severity: 'critical'
```

#### Retention Testing:

```bash
# Run cleanup function
firebase functions:shell
> cleanupOldAuditLogs()

# Verify:
# - Info logs older than 90 days deleted
# - Warning/critical logs older than 1 year deleted
```

---

### 6. Error Telemetry (Crashlytics)

**Test ID:** FUNC-006
**Feature:** Crash and error reporting

#### Test Cases:

| Test Case | Steps | Expected Result | Status |
|-----------|-------|-----------------|--------|
| CRASH-006.1 | Trigger test crash in debug mode | Crash reported to Crashlytics | ⬜ |
| CRASH-006.2 | Check Firebase Console → Crashlytics | Crash visible in dashboard | ⬜ |
| CRASH-006.3 | Login as user | User ID set in crash context | ⬜ |
| CRASH-006.4 | Trigger non-fatal error | Error logged without crashing app | ⬜ |
| CRASH-006.5 | Check crash logs | User context visible (userId, email) | ⬜ |
| CRASH-006.6 | Trigger auth error | Categorized as "authentication" error | ⬜ |
| CRASH-006.7 | Trigger network error | Categorized as "network" error | ⬜ |
| CRASH-006.8 | Logout | User context cleared from Crashlytics | ⬜ |
| CRASH-006.9 | View stack trace in Crashlytics | Source files and line numbers visible | ⬜ |
| CRASH-006.10 | Check breadcrumb logs | Custom logs visible in crash report | ⬜ |

#### Privacy Verification:

- [ ] PII (message content, sensitive data) NOT in crash logs
- [ ] User IDs present, but emails only as custom keys
- [ ] Stack traces don't expose encryption keys

---

### 7. Account Lockout

**Test ID:** FUNC-007
**Feature:** Brute force protection

#### Test Cases:

| Test Case | Steps | Expected Result | Status |
|-----------|-------|-----------------|--------|
| LOCK-007.1 | Login with wrong password (1st time) | Login fails, 4 attempts remaining | ⬜ |
| LOCK-007.2 | Login with wrong password (2nd time) | Login fails, 3 attempts remaining | ⬜ |
| LOCK-007.3 | Login with wrong password (3rd time) | Login fails, 2 attempts remaining | ⬜ |
| LOCK-007.4 | Login with wrong password (4th time) | Login fails, 1 attempt remaining | ⬜ |
| LOCK-007.5 | Login with wrong password (5th time) | Account locked for 15 minutes | ⬜ |
| LOCK-007.6 | Try to login again immediately | "Account locked" dialog shown | ⬜ |
| LOCK-007.7 | Check Firestore `accountLockouts` | Lockout document created | ⬜ |
| LOCK-007.8 | Wait 15 minutes | Lockout expires | ⬜ |
| LOCK-007.9 | Login with correct password | Login succeeds, lockout reset | ⬜ |
| LOCK-007.10 | Check audit logs | Lockout event logged | ⬜ |

#### UI Testing:

- [ ] Warning message shows attempts remaining (when ≤ 2)
- [ ] Lockout dialog shows time remaining
- [ ] Helpful tips displayed (check Caps Lock, forgot password link)

---

### 8. CAPTCHA/Bot Prevention

**Test ID:** FUNC-008
**Feature:** Firebase App Check & reCAPTCHA

#### Test Cases:

| Test Case | Steps | Expected Result | Status |
|-----------|-------|-----------------|--------|
| BOT-008.1 | Sign up new account | App Check token obtained | ⬜ |
| BOT-008.2 | Check logs | "App Check initialized" message | ⬜ |
| BOT-008.3 | Call `CaptchaService.getToken()` | Valid token returned | ⬜ |
| BOT-008.4 | Sign up with valid App Check | Signup succeeds | ⬜ |
| BOT-008.5 | Check Firebase Console → App Check | Valid requests counted | ⬜ |
| BOT-008.6 | Send message | App Check verified | ⬜ |
| BOT-008.7 | Call verifyRecaptcha Cloud Function | Score returned (0.0-1.0) | ⬜ |
| BOT-008.8 | Simulate bot (no App Check token) | Request blocked (if enforcement enabled) | ⬜ |

#### Debug Token Testing:

```bash
# Add debug token to Firebase Console
# Verify app works in development without Play Integrity
```

---

## Security Testing

### Penetration Testing

#### SEC-001: Authentication Bypass Attempts

| Attack Vector | Test | Expected Defense | Status |
|---------------|------|------------------|--------|
| SQL Injection | Try SQL in login fields | Firebase Auth sanitizes input | ⬜ |
| Password Brute Force | 100 login attempts | Account locked after 5 attempts | ⬜ |
| Session Hijacking | Steal auth token | Token expires, requires re-auth | ⬜ |
| Credential Stuffing | Login with leaked passwords | Rate limiting + lockout prevents | ⬜ |

#### SEC-002: Data Access Attempts

| Attack Vector | Test | Expected Defense | Status |
|---------------|------|------------------|--------|
| Read other users' data | Query Firestore for other user docs | Firestore rules deny | ⬜ |
| Modify other users' data | Update another user's profile | Firestore rules deny | ⬜ |
| Access audit logs | Read `/auditLogs/{otherUserId}` | Firestore rules deny | ⬜ |
| Bypass email verification | Send message without verification | Firestore rules block | ⬜ |
| Manipulate rate limits | Delete own rate limit doc | Firestore rules deny write | ⬜ |

#### SEC-003: Bot Attacks

| Attack Vector | Test | Expected Defense | Status |
|---------------|------|------------------|--------|
| Automated signups | Script to create 100 accounts | App Check blocks unauthorized clients | ⬜ |
| Message spam | Send 1000 messages/minute | Rate limiting blocks after 60 | ⬜ |
| Profile scraping | Scrape all user profiles | Rate limiting prevents | ⬜ |

#### SEC-004: Secrets Exposure

| Check | Test | Expected Result | Status |
|-------|------|-----------------|--------|
| Git history | Search for `.env` in git history | Not found | ⬜ |
| Source code | Search for hardcoded secrets | None found | ⬜ |
| APK decompilation | Decompile Android APK | No secrets in compiled app | ⬜ |
| Network traffic | Intercept HTTPS requests | All traffic encrypted | ⬜ |

---

## Performance Testing

### PERF-001: Latency Benchmarks

| Operation | Without Security | With Security | Acceptable? | Status |
|-----------|------------------|---------------|-------------|--------|
| Login (no 2FA) | 1.5s | < 2s | ✅ Yes | ⬜ |
| Login (with 2FA) | N/A | < 5s | ✅ Yes | ⬜ |
| Send message | 0.8s | < 1s | ✅ Yes | ⬜ |
| Profile update | 1.0s | < 1.5s | ✅ Yes | ⬜ |
| Signup | 2.0s | < 3s | ✅ Yes | ⬜ |

### PERF-002: Cloud Functions Performance

```bash
# Check Cloud Function execution times in Firebase Console
# Expected:
# - sendPushNotification: < 500ms
# - checkRateLimit: < 100ms
# - auditUserProfileChanges: < 200ms
# - verifyRecaptcha: < 300ms
```

### PERF-003: Firestore Costs

```bash
# Monitor Firestore usage in Firebase Console
# Expected daily costs for 10K DAU:
# - Reads: ~500K/day
# - Writes: ~200K/day
# - Deletes: ~10K/day
# Total: ~$5-10/month
```

### PERF-004: App Startup Time

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Cold start | < 3s | TBD | ⬜ |
| Hot start | < 1s | TBD | ⬜ |
| Crashlytics init | < 500ms | TBD | ⬜ |
| App Check init | < 500ms | TBD | ⬜ |

---

## Backward Compatibility Testing

### COMPAT-001: Beta User Migration

| Test Case | Steps | Expected Result | Status |
|-----------|-------|-----------------|--------|
| Existing user login | Beta user logs in | Login succeeds without verification | ⬜ |
| Existing user profile | Check user doc in Firestore | `emailVerified: true` field present | ⬜ |
| New user signup | New user signs up | Requires email verification | ⬜ |
| Mixed database | Both old and new users coexist | All features work for both | ⬜ |

### COMPAT-002: Data Migration

```dart
// Test migration script
final beforeCount = await FirebaseFirestore.instance
  .collection('users')
  .where('createdAt', '<', Timestamp.fromDate(DateTime(2024, 12, 24)))
  .get()
  .then((s) => s.docs.length);

await grandfatherBetaUsers();

final afterCount = await FirebaseFirestore.instance
  .collection('users')
  .where('emailVerified', '==', true)
  .get()
  .then((s) => s.docs.length);

assert(afterCount >= beforeCount); // All beta users migrated
```

### COMPAT-003: Feature Flags

| Feature | Enabled | Can Disable? | Rollback Plan | Status |
|---------|---------|--------------|---------------|--------|
| Rate Limiting | ✅ | Yes (kill switch) | Set `ENABLED = false` | ⬜ |
| Email Verification | ✅ | Yes (rules) | Update Firestore rules | ⬜ |
| 2FA | ✅ | Always optional | N/A (user choice) | ⬜ |
| Audit Logging | ✅ | Yes (non-blocking) | Failures don't block ops | ⬜ |
| Crashlytics | ✅ | Yes (console) | Disable in Firebase Console | ⬜ |
| Account Lockout | ✅ | Yes (kill switch) | Set `ENABLED = false` | ⬜ |
| CAPTCHA | ✅ | Yes (kill switch) | Set `ENABLED = false` | ⬜ |

---

## Integration Testing

### INT-001: End-to-End User Flows

#### Flow 1: New User Signup → First Message

```
1. Open app
2. Tap "Sign Up"
3. Enter email, password, profile info
   → CAPTCHA verification runs
4. Submit signup
   → Email verification sent
5. Login with credentials
   → Account lockout tracking starts
6. See verification reminder banner
7. Click verification link in email
8. Return to app
9. Navigate to discover
10. Like a profile
    → Rate limiting tracks action
11. Match occurs
12. Send message
    → Rate limiting checks message quota
    → Audit log records message event
    → Crashlytics tracks any errors
13. Message delivered successfully
```

**Expected:** All security features work together seamlessly

#### Flow 2: Existing User with 2FA

```
1. Login with email/password
   → Lockout service checks attempts
2. Enter 6-digit 2FA code
   → TOTP verified
3. Login succeeds
   → Audit log records login
   → Crashlytics sets user context
4. Send 60 messages rapidly
   → Rate limiting allows all 60
5. Send 61st message
   → Rate limiting blocks
6. Wait 1 minute
7. Send message
   → Rate limiting allows again
```

**Expected:** 2FA + rate limiting + audit logging work together

---

## User Acceptance Testing

### UAT-001: Beta User Feedback

**Test Group:** 10 beta users
**Duration:** 3 days
**Focus Areas:**

- [ ] Can existing users still login without issues?
- [ ] Is 2FA setup process clear and easy?
- [ ] Are lockout messages helpful and not frustrating?
- [ ] Do users understand email verification requirement?
- [ ] Any performance degradation noticed?

### UAT-002: User Experience Metrics

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Login success rate | > 95% | TBD | ⬜ |
| 2FA adoption rate (after 1 week) | > 10% | TBD | ⬜ |
| False lockouts | < 1% | TBD | ⬜ |
| Email verification completion | > 90% | TBD | ⬜ |
| Support tickets (security-related) | < 5/week | TBD | ⬜ |

---

## Regression Testing

### REG-001: Existing Features Still Work

| Feature | Test | Status |
|---------|------|--------|
| Chat | Send/receive messages | ⬜ |
| Profile | Update profile info | ⬜ |
| Discovery | Browse profiles | ⬜ |
| Matching | Like/match with users | ⬜ |
| Notifications | Receive push notifications | ⬜ |
| Block/Report | Block and report users | ⬜ |
| Language | Switch languages (EN/FR/HT) | ⬜ |
| Dark Mode | Toggle dark/light theme | ⬜ |
| Success Stories | View and submit stories | ⬜ |
| Daily Rewards | Claim daily rewards | ⬜ |

### REG-002: No Breaking Changes

```bash
# Build previous version (without security features)
git checkout previous_commit
flutter build apk

# Install and test
adb install build/app/outputs/apk/debug/app-debug.apk

# Build current version (with security features)
git checkout main
flutter build apk

# Install as update (not fresh install)
adb install -r build/app/outputs/apk/debug/app-debug.apk

# Expected: App updates successfully, existing data preserved
```

---

## Test Execution & Reporting

### Test Environment Setup

```bash
# 1. Start Firebase emulators (optional for local testing)
firebase emulators:start

# 2. Run app in debug mode
flutter run

# 3. Monitor logs
flutter logs

# 4. Monitor Cloud Functions
firebase functions:log --follow
```

### Test Execution Workflow

1. **Preparation Phase** (Day 1)
   - [ ] Set up test environment
   - [ ] Create test user accounts
   - [ ] Deploy to staging Firebase project
   - [ ] Run automated tests

2. **Functional Testing** (Day 2-3)
   - [ ] Execute all functional test cases
   - [ ] Record results in test report
   - [ ] Log bugs in issue tracker

3. **Security Testing** (Day 4)
   - [ ] Penetration testing
   - [ ] Security audit
   - [ ] Firestore rules verification

4. **Performance Testing** (Day 5)
   - [ ] Baseline performance measurements
   - [ ] Load testing with Firebase Test Lab
   - [ ] Cost analysis

5. **User Acceptance Testing** (Day 6-8)
   - [ ] Deploy to beta users (10%)
   - [ ] Collect feedback
   - [ ] Monitor metrics

6. **Regression Testing** (Day 9)
   - [ ] Full regression suite
   - [ ] Verify no breaking changes

### Bug Severity Levels

| Severity | Description | Example | Action |
|----------|-------------|---------|--------|
| **Critical** | App crash, data loss, security breach | Firestore rules allow unauthorized access | Fix immediately |
| **High** | Major feature broken | 2FA setup fails | Fix before release |
| **Medium** | Minor feature issue | UI glitch in lockout dialog | Fix in next update |
| **Low** | Cosmetic issue | Typo in error message | Backlog |

### Test Report Template

```markdown
# Test Execution Report
**Date:** YYYY-MM-DD
**Tester:** [Name]
**Build:** [Version]

## Summary
- Total Test Cases: X
- Passed: Y
- Failed: Z
- Blocked: W
- Pass Rate: (Y/X * 100)%

## Failed Test Cases
| Test ID | Feature | Failure Reason | Severity | Assignee |
|---------|---------|----------------|----------|----------|
| SEC-002.3 | Firestore Rules | Can read other users' audit logs | Critical | Developer A |

## Performance Metrics
| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Login time | < 2s | 1.8s | ✅ Pass |

## Recommendations
1. Fix critical bugs before deployment
2. Monitor lockout false positive rate
3. Adjust rate limit thresholds based on usage

## Sign-off
- [ ] All critical bugs resolved
- [ ] All high priority bugs resolved or documented
- [ ] Performance meets targets
- [ ] Ready for production deployment
```

### Continuous Monitoring (Post-Deployment)

**Week 1 After Launch:**

Daily checks:
- [ ] Firebase Crashlytics dashboard
- [ ] App Check metrics (valid vs invalid requests)
- [ ] Audit logs for suspicious activity
- [ ] Cloud Functions error rate
- [ ] Support tickets count

**Metrics to Track:**

| Metric | Frequency | Alert Threshold |
|--------|-----------|-----------------|
| Crash rate | Daily | > 1% |
| Lockout rate | Daily | > 5% of users |
| Email verification completion | Weekly | < 80% |
| 2FA adoption | Weekly | Track trend |
| Rate limit violations | Daily | > 10% of requests |
| CAPTCHA false positives | Daily | > 1% |
| Cloud Functions errors | Hourly | > 5% error rate |

---

## Success Criteria

The implementation is considered successful if:

✅ **Functionality**
- [ ] All 8 security features working as designed
- [ ] No critical or high severity bugs
- [ ] All existing features still functional

✅ **Security**
- [ ] Zero unauthorized data access
- [ ] No secrets exposed
- [ ] All penetration tests passed

✅ **Performance**
- [ ] Login time < 2s (without 2FA)
- [ ] App startup time < 3s
- [ ] No noticeable performance degradation

✅ **User Experience**
- [ ] Login success rate > 95%
- [ ] False lockout rate < 1%
- [ ] Email verification completion > 90%
- [ ] Support tickets < 5/week

✅ **Cost**
- [ ] Monthly Firebase costs < $25 for 10K DAU
- [ ] No unexpected cost spikes

✅ **Monitoring**
- [ ] Crashlytics capturing all errors
- [ ] Audit logs recording all security events
- [ ] App Check blocking bot requests

---

## Rollback Plan

If critical issues arise:

### Immediate Actions (< 1 hour)

1. **Disable problematic feature via kill switch:**
   ```dart
   // In respective service file
   static const bool ENABLED = false;
   ```

2. **Redeploy with fix or rollback**
   ```bash
   git revert <commit-hash>
   flutter build apk --release
   firebase deploy --only functions
   ```

### Communication

- [ ] Notify beta users of issue
- [ ] Post status update
- [ ] Document root cause

---

## Appendix

### A. Test User Accounts

| Email | Password | 2FA | Purpose |
|-------|----------|-----|---------|
| test1@vibenou.com | Test123! | No | Basic flow testing |
| test2@vibenou.com | Test123! | Yes | 2FA testing |
| beta@vibenou.com | Test123! | No | Beta user migration |
| admin@vibenou.com | Test123! | Yes | Admin testing |

### B. Test Data

- **Messages:** 100+ test messages
- **Profiles:** 50 test user profiles
- **Matches:** 20 test matches
- **Reports:** 5 test reports

### C. Automated Test Scripts

```dart
// Example: Rate limiting test
test('Rate limiting blocks excessive requests', () async {
  final service = ChatService();

  // Send 60 messages (should succeed)
  for (int i = 0; i < 60; i++) {
    await service.sendMessage('Test message $i');
  }

  // 61st message should fail
  expect(
    () => service.sendMessage('Test message 61'),
    throwsA(isA<RateLimitException>()),
  );
});
```

### D. Useful Commands

```bash
# View Firestore data
firebase firestore:get users/userId

# View Cloud Function logs
firebase functions:log --only sendPushNotification

# Check Firestore rules
firebase deploy --only firestore:rules --dry-run

# Monitor real-time logs
firebase functions:log --follow

# Check app build
flutter doctor -v

# Run specific test
flutter test test/services/auth_service_test.dart
```

---

## Contact & Support

**Questions during testing?**
- Technical issues: Check Firebase Console logs
- Test plan clarification: Refer to implementation plan
- Bug reporting: Create GitHub issue with template

---

**Document Version:** 1.0
**Last Updated:** December 24, 2024
**Next Review:** After beta testing completion
