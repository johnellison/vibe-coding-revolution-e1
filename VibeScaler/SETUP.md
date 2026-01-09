# VibeScaler Setup Guide

## Prerequisites

- Xcode 15+ (for macOS development)
- Node.js 18+ (for backend)
- Homebrew (for ffmpeg)
- Apple Developer Account ($99/year)
- Cloudflare Account (free tier works)
- Supabase Account (free tier works)
- Fal.ai Account (pay-as-you-go)

## 1. Local Development Setup

### Install Dependencies

```bash
# Install ffmpeg for local upscaling
brew install ffmpeg

# Install Wrangler for Cloudflare Workers
npm install -g wrangler
```

### Clone and Open Project

```bash
cd VibeScaler

# Open in Xcode
open VibeScaler.xcodeproj
```

## 2. Create Xcode Project

Since we've created all the Swift files, you need to create the Xcode project:

1. Open Xcode
2. File → New → Project
3. Select "App" under macOS
4. Configure:
   - Product Name: `VibeScaler`
   - Team: Your Apple Developer Team
   - Organization Identifier: `com.johnellison`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum Deployment: macOS 13.0
5. Save to the `VibeScaler/` folder
6. Add existing files:
   - Drag all `.swift` files from `VibeScaler/` into the project
   - Ensure "Copy items if needed" is unchecked
   - Add to target: VibeScaler

### Configure Signing & Capabilities

1. Select project in navigator
2. Select VibeScaler target
3. Signing & Capabilities tab
4. Add capabilities:
   - Sign in with Apple
   - In-App Purchase

## 3. Backend Setup

### Supabase

1. Create project at [supabase.com](https://supabase.com)
2. Go to SQL Editor
3. Run the schema from `Backend/supabase-schema.sql`
4. Copy your project URL and anon key from Settings → API

### Cloudflare Workers

```bash
cd Backend

# Install dependencies
npm install

# Login to Cloudflare
wrangler login

# Set secrets
wrangler secret put FAL_API_KEY
# Enter your fal.ai API key

wrangler secret put SUPABASE_URL
# Enter your Supabase project URL

wrangler secret put SUPABASE_ANON_KEY
# Enter your Supabase anon key

# Deploy
wrangler deploy
```

### Update App Configuration

After deploying, update `APIService.swift` with your Worker URL:

```swift
private let baseURL = "https://vibescaler-api.YOUR-SUBDOMAIN.workers.dev"
```

## 4. Fal.ai Setup

1. Create account at [fal.ai](https://fal.ai)
2. Go to Dashboard → API Keys
3. Create new key
4. Add credits to your account
5. Use the key in Cloudflare Worker secrets

## 5. App Store Connect Setup

### Create App ID

1. Go to [developer.apple.com](https://developer.apple.com)
2. Certificates, Identifiers & Profiles
3. Identifiers → + → App IDs
4. Configure:
   - Description: VibeScaler
   - Bundle ID: `com.johnellison.vibescaler`
   - Capabilities: Sign in with Apple ✓

### Configure In-App Purchases

1. App Store Connect → My Apps → VibeScaler
2. Features → In-App Purchases → +
3. Create products:

| Product ID | Type | Price |
|------------|------|-------|
| `com.johnellison.vibescaler.credits.10` | Consumable | $1.99 |
| `com.johnellison.vibescaler.credits.50` | Consumable | $7.99 |
| `com.johnellison.vibescaler.credits.100` | Consumable | $12.99 |
| `com.johnellison.vibescaler.video.2min` | Consumable | $5.99 |
| `com.johnellison.vibescaler.video.5min` | Consumable | $12.99 |
| `com.johnellison.vibescaler.video.15min` | Consumable | $34.99 |
| `com.johnellison.vibescaler.pro.monthly` | Auto-Renewable | $19.99/mo |

## 6. Testing

### Local Testing

```bash
# Run backend locally
cd Backend
npm run dev
```

### TestFlight

1. Archive in Xcode: Product → Archive
2. Distribute App → TestFlight
3. Upload and wait for processing
4. Add testers in App Store Connect

## 7. Launch Checklist

- [ ] All IAP products approved
- [ ] Privacy policy published
- [ ] Support URL active
- [ ] App screenshots ready (5-6)
- [ ] App icon (1024x1024)
- [ ] Keywords optimized
- [ ] App description written

## Environment Variables

### Backend (Cloudflare Workers)

| Variable | Description |
|----------|-------------|
| `FAL_API_KEY` | Fal.ai API key |
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anonymous key |
| `APPLE_TEAM_ID` | Apple Developer Team ID |

## Costs Estimate

| Service | Cost |
|---------|------|
| Apple Developer | $99/year |
| Cloudflare Workers | Free (100K req/day) |
| Supabase | Free (500MB, 50K users) |
| Fal.ai | ~$0.02-0.04/image upscale |
| Domain (optional) | ~$12/year |

**Total startup cost:** ~$100

## Troubleshooting

### FFmpeg not found

```bash
brew install ffmpeg
# Or download from ffmpeg.org
```

### Xcode signing issues

1. Ensure you're signed into Apple Developer account
2. Check team is selected
3. Try: Product → Clean Build Folder

### API errors

1. Check Cloudflare Worker logs: `wrangler tail`
2. Verify secrets are set correctly
3. Test endpoints with curl

---

Questions? File an issue or contact support.
