# Security Setup Guide
## VibeNou Production-Grade Security Implementation

This guide walks you through setting up all security features for the VibeNou dating app.

---

## Step 1: Set Up GitHub Secrets (CRITICAL - Do this first!)

Your Firebase credentials are currently in a `.env` file which should NEVER be committed to git. We need to move them to GitHub Secrets.

### How to Add GitHub Secrets:

1. **Go to your GitHub repository**
2. **Click Settings** (repository settings, not your account)
3. **Click "Secrets and variables"** → **"Actions"** in the left sidebar
4. **Click "New repository secret"**
5. **Add each of these secrets** (copy from your `.env` file):

| Secret Name | Value (from your .env file) |
|-------------|----------------------------|
| `FIREBASE_API_KEY_ANDROID` | AIzaSyDXYedN9RWDBdnIQdA00EeDggAgfnonrAI |
| `FIREBASE_APP_ID_ANDROID` | 1:161222852953:android:59c904d713b999ba890c48 |
| `FIREBASE_API_KEY_IOS` | AIzaSyAyUfdAfuwF4UtfFCaHVuV9rcL4iL4zFDs |
| `FIREBASE_APP_ID_IOS` | 1:161222852953:ios:0b12d1ef1932b1f5890c48 |
| `FIREBASE_IOS_BUNDLE_ID` | com.vibenou.vibenou |
| `FIREBASE_API_KEY_WEB` | AIzaSyCm4M3jeSw4E54FGQoAaI6q5BvQtMf54ls |
| `FIREBASE_APP_ID_WEB` | 1:161222852953:web:d8c69996270b0a63890c48 |
| `FIREBASE_AUTH_DOMAIN` | vibenou-5d701.firebaseapp.com |
| `FIREBASE_MESSAGING_SENDER_ID` | 161222852953 |
| `FIREBASE_PROJECT_ID` | vibenou-5d701 |
| `FIREBASE_STORAGE_BUCKET` | vibenou-5d701.firebasestorage.app |
| `GOOGLE_SERVER_CLIENT_ID` | 161222852953-a340277ohdd5vddlvga4auhpk51ai7eg.apps.googleusercontent.com |

### Additional Secrets (if using Supabase):

If you're using Supabase, also add:
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Your Supabase anon/public key

---

## Step 2: Remove .env from Git History (CRITICAL)

Your `.env` file may have been committed to git in the past. We need to remove it from git history:

```bash
# WARNING: This rewrites git history. Coordinate with your team first!

# Remove .env from all commits
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env" \
  --prune-empty --tag-name-filter cat -- --all

# Force push to remote (BE CAREFUL!)
git push origin --force --all

# Clean up
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

**Alternative (if you have a small repo):** Start fresh by creating a new repository and copying only the code (not .git folder).

---

##Step 3: Verify GitHub Actions Workflow

The workflow file `.github/workflows/build_android.yml` has been created. It will:

1. Automatically create `.env` from GitHub Secrets at build time
2. Build your app with the secrets injected
3. Clean up the `.env` file after build
4. Never expose secrets in logs or artifacts

**Test it:**
1. Push your code to GitHub
2. Go to the "Actions" tab in your repository
3. You should see the workflow running
4. Verify it builds successfully

---

## Step 4: Local Development Setup

For local development, you still need a `.env` file:

```bash
# Copy the example
cp .env.example .env

# Edit .env and fill in your credentials
# (You already have this file, so you're good to go!)
```

---

## Step 5: Security Checklist

Before proceeding to implement other security features, verify:

- [ ] All secrets added to GitHub Secrets
- [ ] `.env` removed from git history
- [ ] GitHub Actions workflow runs successfully
- [ ] `.gitignore` includes `.env` (already done)
- [ ] `.env.example` has placeholder values only (no real credentials)
- [ ] Team members know to never commit `.env`

---

## Step 6: Next Security Features to Implement

After secrets are secured, we'll implement (in order):

1. **Persistent Rate Limiting** - Prevent DoS attacks
2. **Email Verification** - Prevent fake accounts
3. **Two-Factor Authentication** - Prevent account takeovers
4. **Audit Logging** - Track security events
5. **Error Telemetry** - Monitor crashes
6. **Account Lockout** - Prevent brute force
7. **CAPTCHA** - Prevent bot signups

---

## Important Notes

### DO:
✅ Keep your local `.env` file secure
✅ Use GitHub Secrets for CI/CD builds
✅ Rotate credentials if they're ever exposed
✅ Review who has access to your GitHub repository
✅ Enable 2FA on your GitHub account

### DON'T:
❌ Commit `.env` to git
❌ Share `.env` via email, Slack, or messaging apps
❌ Screenshot your `.env` file
❌ Hard-code credentials in source files
❌ Use production credentials in development

---

## Troubleshooting

### GitHub Actions build fails with "Environment variables not set"
- Check that all secrets are added to GitHub Secrets
- Secret names must match exactly (case-sensitive)
- Re-run the workflow after adding secrets

### Local build fails with "Cannot load .env"
- Make sure `.env` file exists in the root directory
- Copy from `.env.example` if missing
- Check that all required variables are present

### Secrets exposed in git history
- Follow Step 2 to clean git history
- Consider rotating all Firebase credentials
- Review GitHub security alerts

---

## Support

If you encounter issues:
1. Check the error messages carefully
2. Verify all secrets are configured correctly
3. Ensure `.env` file exists for local development
4. Review GitHub Actions logs for build errors

---

**Ready to proceed?** Once you've completed Steps 1-5, we can continue with implementing the remaining security features!
