# VibeScaler Development Tasks

## Phase 1: Foundation (Week 1-2)

### 1.1 Project Setup
- [ ] Create Xcode project (SwiftUI macOS, minimum macOS 13)
- [ ] Set up git repository
- [ ] Configure signing & capabilities
- [ ] Add bundle identifier: com.johnellison.vibescaler

### 1.2 Design System
- [ ] Define color palette (teal primary, warm backgrounds)
- [ ] Set up typography (system fonts)
- [ ] Create reusable components:
  - [ ] PrimaryButton
  - [ ] SecondaryButton
  - [ ] DropZone
  - [ ] CreditBadge
  - [ ] ProcessingCard

### 1.3 File Handling
- [ ] Implement drag-and-drop zone
- [ ] Support formats: JPEG, PNG, HEIC, WebP, TIFF
- [ ] File validation (size limits, format checks)
- [ ] Temp file management

---

## Phase 2: Local Processing (Week 3-4)

### 2.1 FFmpeg Integration
- [ ] Bundle ffmpeg binary or use Homebrew detection
- [ ] Implement upscale command wrapper
- [ ] Support scale factors: 2x, 4x
- [ ] Quality presets (fast, balanced, quality)

### 2.2 Processing Pipeline
- [ ] Background processing with Progress
- [ ] Cancel support
- [ ] Error handling
- [ ] Output file naming convention

### 2.3 UI for Local Mode
- [ ] Processing progress indicator
- [ ] Success/error states
- [ ] Output file reveal in Finder

---

## Phase 3: Backend & Auth (Week 5-6)

### 3.1 Backend Proxy (Cloudflare Workers)
- [ ] Set up Cloudflare Workers project
- [ ] Implement /api/upscale endpoint
- [ ] Add fal.ai API integration
- [ ] Rate limiting per user
- [ ] Error handling & logging

### 3.2 Database (Supabase)
- [ ] Create Supabase project
- [ ] User table (apple_id, email, created_at)
- [ ] Credits table (user_id, image_credits, video_seconds)
- [ ] Transactions table (user_id, type, amount, timestamp)

### 3.3 Apple Sign-In
- [ ] Configure App ID for Sign in with Apple
- [ ] Implement AuthenticationServices
- [ ] Token validation on backend
- [ ] Session management

---

## Phase 4: AI Upscaling (Week 7-8)

### 4.1 Fal.ai Integration
- [ ] Implement image upload to fal.ai
- [ ] Call clarity-upscaler model
- [ ] Handle async response
- [ ] Download result

### 4.2 Credit System
- [ ] Deduct credits before processing
- [ ] Refund on failure
- [ ] Show credit balance in UI
- [ ] Low credit warning

### 4.3 Before/After UI
- [ ] Split view comparison
- [ ] Interactive slider
- [ ] Zoom controls
- [ ] Export button

---

## Phase 5: Monetization (Week 9-10)

### 5.1 StoreKit 2 Integration
- [ ] Configure IAP in App Store Connect
- [ ] Product IDs:
  - [ ] vibescaler.credits.10
  - [ ] vibescaler.credits.50
  - [ ] vibescaler.credits.100
  - [ ] vibescaler.video.2min
  - [ ] vibescaler.video.5min
  - [ ] vibescaler.pro.monthly
- [ ] Purchase flow UI
- [ ] Receipt validation
- [ ] Restore purchases

### 5.2 Credit Packs UI
- [ ] Store view with pricing
- [ ] Purchase confirmation
- [ ] Success animation
- [ ] Credit balance update

---

## Phase 6: Polish (Week 11-12)

### 6.1 Processing History
- [ ] SQLite local database
- [ ] Thumbnail generation
- [ ] History sidebar
- [ ] Re-open processed files

### 6.2 Settings
- [ ] Default save location
- [ ] Default quality preset
- [ ] Auto-reveal in Finder toggle
- [ ] Clear history option

### 6.3 Error Handling
- [ ] Network error recovery
- [ ] Graceful degradation
- [ ] User-friendly error messages
- [ ] Crash reporting (optional)

---

## Phase 7: Beta & Launch (Week 13-16)

### 7.1 Beta Testing
- [ ] TestFlight setup
- [ ] Recruit 20-30 beta testers
- [ ] Feedback collection
- [ ] Bug fixes

### 7.2 App Store Prep
- [ ] App icon (1024x1024)
- [ ] Screenshots (5-6)
- [ ] App description
- [ ] Keywords
- [ ] Privacy policy URL
- [ ] Support URL

### 7.3 Launch
- [ ] Submit to App Store
- [ ] Product Hunt prep
- [ ] Launch day execution
- [ ] Post-launch monitoring

---

## API Endpoints (Backend)

```
POST /api/auth/apple
  Body: { identityToken }
  Returns: { sessionToken, user }

GET /api/user/credits
  Headers: Authorization: Bearer {sessionToken}
  Returns: { imageCredits, videoSeconds }

POST /api/upscale/image
  Headers: Authorization: Bearer {sessionToken}
  Body: { imageUrl, model, scale }
  Returns: { jobId, status }

GET /api/upscale/status/{jobId}
  Returns: { status, resultUrl?, error? }

POST /api/purchase/verify
  Body: { receiptData, productId }
  Returns: { success, creditsAdded }
```

---

## File Structure

```
VibeScaler/
├── VibeScaler.xcodeproj
├── VibeScaler/
│   ├── App/
│   │   ├── VibeScalerApp.swift
│   │   └── ContentView.swift
│   ├── Features/
│   │   ├── Upscale/
│   │   │   ├── UpscaleView.swift
│   │   │   ├── UpscaleViewModel.swift
│   │   │   └── DropZone.swift
│   │   ├── Compare/
│   │   │   ├── CompareView.swift
│   │   │   └── CompareSlider.swift
│   │   ├── History/
│   │   │   ├── HistoryView.swift
│   │   │   └── HistoryItem.swift
│   │   ├── Store/
│   │   │   ├── StoreView.swift
│   │   │   └── StoreManager.swift
│   │   └── Settings/
│   │       └── SettingsView.swift
│   ├── Services/
│   │   ├── APIService.swift
│   │   ├── AuthService.swift
│   │   ├── UpscaleService.swift
│   │   ├── LocalUpscaler.swift
│   │   └── CreditManager.swift
│   ├── Models/
│   │   ├── User.swift
│   │   ├── UpscaleJob.swift
│   │   └── HistoryEntry.swift
│   ├── Design/
│   │   ├── Colors.swift
│   │   ├── Typography.swift
│   │   └── Components/
│   └── Resources/
│       └── Assets.xcassets
└── Backend/
    ├── wrangler.toml
    └── src/
        └── index.ts
```
