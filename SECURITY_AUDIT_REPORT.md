# Security Audit Report

## Scope
- Flutter client security-sensitive services
- Firestore and Storage security rules
- Cloud Functions CAPTCHA validation path

## Findings & Remediations

### 1) Broken access control in Storage rules (**Critical**)
**Issue:** `storage.rules` allowed any authenticated user to write to any path under `profile_pictures/**`, enabling overwrite or defacement of other users' profile photos.

**Fix implemented:**
- Removed broad `profile_pictures/**` write permission.
- Restricted writes to owner-bound filename patterns only.
- Added upload constraints for MIME type (`image/*`) and file size (< 5MB).

**Impact after fix:** Authenticated users can only upload their own images in expected paths and only valid image payloads.

---

### 2) Sensitive 2FA secrets stored in publicly readable user documents (**Critical**)
**Issue:** 2FA material (`twoFactorSecret`, `recoveryCodes`) was stored on `/users/{uid}`. Your rules allow authenticated users to read user docs for discovery, so this exposed sensitive security data.

**Fix implemented:**
- Moved sensitive 2FA fields to `/users/{uid}/private/security`.
- Added Firestore rule for `/users/{uid}/private/security` (owner-only read/write).
- Added rule guard to block sensitive fields on root user create/update.
- Added legacy compatibility reads from old location so existing users continue working while migrating.
- On enabling 2FA, legacy sensitive root fields are deleted.

**Impact after fix:** 2FA secrets are no longer exposed through profile reads.

---

### 3) CAPTCHA/App Check fail-open behavior (**High**)
**Issue:** CAPTCHA verification and App Check token checks defaulted to allowing access when verification failed (network error, null token, missing secret), weakening bot protection.

**Fix implemented:**
- Client now uses production App Check providers in release builds and debug providers only in non-release builds.
- Client-side verification now fails closed when token retrieval/verification fails.
- Cloud Function CAPTCHA verification now fails closed when secret is missing or network verification fails.

**Impact after fix:** Bot mitigation controls enforce failure by default when trust checks cannot be completed.

## Additional Recommendations (not yet changed)
1. Add Firestore Emulator security-rule tests for regression protection.
2. Add stricter field-level allowlists for mutable docs (e.g., `chatRooms`, `matches`) to prevent unauthorized metadata tampering.
3. Rotate any existing 2FA secrets generated before this remediation and force re-enrollment for highest assurance.
4. Consider encrypting 2FA secrets at rest in backend-managed infrastructure if threat model requires defense against privileged datastore access.
