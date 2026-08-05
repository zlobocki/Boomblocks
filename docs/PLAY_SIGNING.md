# Google Play signing for Mine Puzzle

## What is Play App Signing?

Google Play keeps the **app signing key** (the key users’ phones trust) in Google’s
vault. You keep an **upload key** on your computer. You sign each release with
the upload key; Play re-signs with the app signing key before users download.

Benefits:

- If you lose the upload key, Google can register a new one
- You never ship the long-term app signing key yourself

## First upload (your situation — no existing keystore)

1. Create a **new upload keystore** (see below / generated for you).
2. In Play Console → your app → **Setup → App integrity → App signing**:
   choose **Google manage and protect your app signing key** (default for new apps).
3. Build a signed **AAB** (`flutter build appbundle --release`) with the upload keystore.
4. Upload that AAB as the first release. Play will generate/store the app signing key.

**Back up** `upload-keystore.p12` and the passwords in a password manager / offline USB.
Without them you cannot upload updates until you go through Play’s upload-key reset.

## Local files (gitignored)

| File | Purpose |
|------|---------|
| `android/app/upload-keystore.p12` | Upload keystore |
| `android/key.properties` | Passwords + alias for Gradle |

These must **not** be committed to GitHub.

## Build a Play upload (AAB)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## Package details

- Application id: `com.boomblocks.boomblocks`
- Display name: Mine Puzzle
- Developer: Zbigniew Łobocki
- Privacy policy URL (after GitHub Pages is on):  
  https://zlobocki.github.io/mine_puzzle/privacy.html
