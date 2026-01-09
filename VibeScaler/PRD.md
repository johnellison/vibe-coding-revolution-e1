# VibeScaler: Product Requirements Document
## Corrected Economics Based on Real Fal.ai Usage

**Last Updated:** January 9, 2026
**Status:** Ready for Development
**Confidence Level:** High (based on production API data)

---

## EXECUTIVE SUMMARY

**Product:** VibeScaler — Mac App Store AI image & video upscaler
**Price:** $9.99 app purchase + credit system
**Target:** Creators, designers, photographers
**Timeline:** 4-5 months to launch
**Year 1 Profit:** $5K-$10K (conservative estimate)

---

## 1. REAL FAL.AI COSTS (FROM PRODUCTION USAGE)

### 1.1 Actual API Costs (January 2026)

| Service | Model | Cost | Notes |
|---------|-------|------|-------|
| **Image Upscale** | clarity-upscaler | $0.02-0.04/image | 2x scale per pass |
| **Image Upscale** | creative-upscaler | $0.04/image | AI enhancement |
| **Image Upscale** | real-esrgan | $0.01/image | Fast, basic |
| **Video Upscale** | bytedance-upscaler (4K) | $0.0288/second | = $1.73/minute |
| **Video Upscale** | bytedance-upscaler (1080p) | $0.015/second | = $0.90/minute |

### 1.2 Real-World Examples (From Today's Usage)

```
Image: 1200x700 → 4800x2800 (2 passes)
  Pass 1: $0.02
  Pass 2: $0.02
  Total cost: $0.04

Video: 8 seconds, 1080p → 4K
  Cost: 8 × $0.0288 = $0.23

Video: 5 minutes, 1080p → 4K
  Cost: 300 × $0.0288 = $8.64
```

---

## 2. CORRECTED PRICING MODEL

### 2.1 Credit System (Fair to Users)

```
$9.99 APP PURCHASE (one-time)
├─ Includes: 5 image credits + 30 video seconds
├─ Unlock: Pro UI, batch processing, all presets
└─ Access: Full video upscaling

CREDIT PACKS (with real volume discounts):
├─ 10 image credits     = $1.99  ($0.20 each)
├─ 50 image credits     = $7.99  ($0.16 each, 20% off)
├─ 100 image credits    = $12.99 ($0.13 each, 35% off)
│
├─ 5 min video credits  = $4.99  ($1.00/min, your cost $1.73)
├─ 15 min video credits = $11.99 ($0.80/min)
├─ 30 min video credits = $19.99 ($0.67/min)

MONTHLY PRO (Capped, not unlimited):
├─ $14.99/month
├─ Includes: 100 image credits + 10 min video
├─ Rollover: Unused credits roll over (max 200)
├─ Best for: Regular creators
└─ Your cost: ~$4 (images) + $17 (video) = $21 LOSS
   → Cap at 100 images + 10 min to stay profitable

REVISED MONTHLY PRO:
├─ $19.99/month
├─ Includes: 75 image credits + 5 min video
├─ Your cost: ~$3 + $8.65 = $11.65
├─ Your margin: $8.34 (42%)
└─ After App Store 30%: $5.84 profit
```

### 2.2 Unit Economics (Corrected)

```
IMAGE UPSCALE:
  Your cost (fal.ai):        $0.02-0.04
  You charge:                $0.16-0.20/credit
  Gross margin:              75-87%
  After App Store (30%):     45-57%

VIDEO UPSCALE (per minute):
  Your cost (fal.ai 4K):     $1.73
  You charge:                $0.67-1.00/min
  Gross margin:              NEGATIVE at low prices!

  CORRECTED VIDEO PRICING:
  You charge:                $2.50/min (covers cost + margin)
  Gross margin:              31%
  After App Store:           ~1% margin

  → Video is a loss leader or needs higher pricing
```

### 2.3 Video Pricing Reality Check

**The Problem:** Video upscaling is expensive.
- 5-minute video at 4K = $8.64 cost to you
- If you charge $4.99, you LOSE $3.65 per transaction

**Solutions:**
1. **Premium video pricing:** $3/minute (users pay $15 for 5-min video)
2. **1080p only in base tier:** 4K as premium add-on
3. **Local fallback:** Use ffmpeg for basic upscaling, fal.ai for "AI Enhanced" only
4. **Hybrid approach:** First pass local (free), AI enhancement pass (paid)

**Recommended:** Option 4 - Hybrid
```
Standard Upscale (Local ffmpeg): FREE with app purchase
AI Enhanced Upscale (Fal.ai):    Credits required
```

---

## 3. CORRECTED FINANCIAL PROJECTIONS

### 3.1 Conservative Year 1 Model

```
Downloads:                    2,000 (Product Hunt + organic)

Conversion to $9.99 app:      12% = 240 users (industry realistic)
  Revenue from app:           240 × $9.99 = $2,398
  After App Store (30%):      $1,678

Of 240 paying users:
  15% power users (36):       Heavy usage
    • Monthly Pro: $19.99/mo × 8 months avg = $5,757
    • After App Store: $4,030
    • Your fal.ai cost: 36 × 8 × $11.65 = $3,355
    • Net from power users: $675

  35% regular users (84):     Moderate usage
    • Credit purchases: avg $30/year = $2,520
    • After App Store: $1,764
    • Your fal.ai cost: ~$600
    • Net from regular: $1,164

  50% casual users (120):     Light usage
    • Use included credits only
    • Your fal.ai cost: 120 × $0.20 = $24
    • Net: -$24

YEAR 1 SUMMARY:
  App purchase revenue:       $1,678 (net)
  Power user subscriptions:   $675 (net)
  Regular user credits:       $1,164 (net)
  Casual user costs:          -$24
  Marketing/hosting:          -$500
  ────────────────────────────
  NET PROFIT:                 $2,993

REALISTIC RANGE: $2,000 - $5,000
```

### 3.2 Optimistic Year 1 Model (Strong Launch)

```
Downloads:                    5,000
Conversion:                   15% = 750 users
App revenue (net):            $5,243

Power (15%): 112 users × $19.99 × 8mo = $17,911 → net ~$2,100
Regular (35%): 262 users × $40/yr = $10,480 → net ~$3,600
Casual (50%): 376 users → cost ~$75

OPTIMISTIC NET PROFIT:        $10,000 - $12,000
```

---

## 4. REVISED PRICING TIERS

### 4.1 Final Pricing Structure

```
┌─────────────────────────────────────────────────────────┐
│  FREE TIER (No purchase required)                       │
├─────────────────────────────────────────────────────────┤
│  • 2 image upscales/month (watermarked)                │
│  • Standard quality only (no AI enhancement)            │
│  • No video support                                     │
│  • No batch processing                                  │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  PRO APP - $9.99 (one-time)                            │
├─────────────────────────────────────────────────────────┤
│  • Includes 5 AI image credits + 30 sec video          │
│  • Unlimited LOCAL upscaling (ffmpeg, no AI)           │
│  • All quality presets unlocked                        │
│  • Batch processing                                     │
│  • No watermarks                                        │
│  • Export all formats (JPEG/PNG/TIFF/HEIC)             │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  CREDIT PACKS (In-App Purchase)                        │
├─────────────────────────────────────────────────────────┤
│  IMAGES (AI Enhanced):                                 │
│  • 10 credits  = $1.99   ($0.20/image)                │
│  • 50 credits  = $7.99   ($0.16/image) ⭐ Popular     │
│  • 100 credits = $12.99  ($0.13/image)                │
│                                                         │
│  VIDEO (AI Enhanced 4K):                               │
│  • 2 minutes  = $5.99    ($3.00/min)                  │
│  • 5 minutes  = $12.99   ($2.60/min) ⭐ Popular       │
│  • 15 minutes = $34.99   ($2.33/min)                  │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  CREATOR PRO - $19.99/month                            │
├─────────────────────────────────────────────────────────┤
│  • 75 AI image credits/month                           │
│  • 5 minutes AI video/month                            │
│  • Unused credits roll over (max 150 images, 10 min)   │
│  • Priority processing queue                           │
│  • Early access to new features                        │
│  • Cancel anytime                                       │
└─────────────────────────────────────────────────────────┘
```

### 4.2 Margin Analysis

| Tier | User Pays | Your Cost | App Store Cut | Your Net | Margin |
|------|-----------|-----------|---------------|----------|--------|
| App Purchase | $9.99 | $0.10 | $3.00 | $6.89 | 69% |
| 10 Image Credits | $1.99 | $0.30 | $0.60 | $1.09 | 55% |
| 50 Image Credits | $7.99 | $1.50 | $2.40 | $4.09 | 51% |
| 5 Min Video | $12.99 | $8.65 | $3.90 | $0.44 | 3% |
| Monthly Pro | $19.99 | $11.65 | $6.00 | $2.34 | 12% |

**Key Insight:** Images are profitable, video barely breaks even. Lead with images, video is premium add-on.

---

## 5. TECHNICAL ARCHITECTURE

### 5.1 Hybrid Processing Model

```
┌──────────────────────────────────────────────────────────┐
│                    VibeScaler App                        │
└──────────────────────┬───────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        ↓                              ↓
┌───────────────────┐      ┌───────────────────────────────┐
│  LOCAL PROCESSING │      │  CLOUD PROCESSING (Fal.ai)    │
│  (Free with app)  │      │  (Credits required)           │
├───────────────────┤      ├───────────────────────────────┤
│ • ffmpeg upscale  │      │ • clarity-upscaler (images)   │
│ • Basic bicubic   │      │ • creative-upscaler (images)  │
│ • Lanczos resize  │      │ • bytedance-upscaler (video)  │
│ • Fast, instant   │      │ • High quality AI             │
│ • No API calls    │      │ • 3-30 sec processing         │
└───────────────────┘      └───────────────────────────────┘
```

### 5.2 API Security (Critical)

**Problem:** Can't embed fal.ai API key in distributed Mac app.

**Solution:** Proxy server

```
User App → Your Server (validates credits) → Fal.ai
                ↓
         Supabase/Firebase
         (user accounts, credit balance)
```

**Implementation:**
1. User authenticates with Apple Sign-In
2. App calls YOUR server with user token
3. Your server checks credit balance in database
4. If credits available: deduct credit, call fal.ai, return result
5. If no credits: return purchase prompt

**Tech Stack for Backend:**
- Cloudflare Workers (cheap, fast) OR
- Vercel Edge Functions OR
- Supabase Edge Functions

### 5.3 Privacy Considerations

```
PRIVACY POLICY MUST DISCLOSE:
• Images/videos are uploaded to fal.ai servers for processing
• Files are deleted after processing (verify with fal.ai)
• No images stored on your servers (pass-through only)
• Apple Sign-In for authentication (no passwords stored)
• Analytics: anonymous usage only (no PII)
```

---

## 6. DEVELOPMENT TIMELINE (Realistic)

### Month 1: Foundation
- Week 1-2: Project setup, SwiftUI scaffolding, design system
- Week 3-4: Local upscaling (ffmpeg integration), file handling

### Month 2: Core Features
- Week 1-2: Backend proxy server, user auth (Apple Sign-In)
- Week 3-4: Fal.ai integration, credit system

### Month 3: Polish & Video
- Week 1-2: Video processing pipeline, batch processing
- Week 3-4: Before/after UI, settings, error handling

### Month 4: Beta & Launch Prep
- Week 1-2: Beta testing (20-30 users), bug fixes
- Week 3-4: App Store assets, submission, marketing prep

### Month 5: Launch
- Week 1: App Store approval, soft launch
- Week 2: Product Hunt launch
- Week 3-4: Post-launch fixes, user feedback

---

## 7. MVP FEATURE SET

### 7.1 Must Have (Launch)
- [x] Drag-and-drop image upscaling
- [x] Local upscaling (free, ffmpeg)
- [x] AI upscaling (credits, fal.ai)
- [x] Before/after comparison slider
- [x] Quality presets (Standard, Enhanced, Maximum)
- [x] Apple Sign-In authentication
- [x] Credit purchase (StoreKit 2)
- [x] Processing history
- [x] Dark mode support

### 7.2 Should Have (V1.1)
- [ ] Video upscaling (4K)
- [ ] Batch processing queue
- [ ] Finder Quick Actions
- [ ] Export format options

### 7.3 Nice to Have (V1.2+)
- [ ] Subscription tier
- [ ] Selective upscaling (mask tool)
- [ ] Preset library
- [ ] Keyboard shortcuts

---

## 8. SUCCESS METRICS

### Launch (90 Days)
| Metric | Target | Stretch |
|--------|--------|---------|
| Downloads | 500 | 1,500 |
| Conversion | 10% | 15% |
| Rating | 4.3⭐ | 4.7⭐ |
| Revenue | $500 | $2,000 |

### Year 1
| Metric | Conservative | Optimistic |
|--------|--------------|------------|
| Downloads | 2,000 | 5,000 |
| Paying Users | 240 | 750 |
| Revenue | $5,000 | $15,000 |
| Profit | $2,000 | $10,000 |

---

## 9. RISKS & MITIGATIONS

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Fal.ai price increase | Medium | High | Build local fallback, multi-provider support |
| Low conversion | High | Medium | Strong free tier demo, fair pricing |
| App Store rejection | Low | High | Follow guidelines, no private APIs |
| Competition (Pixelmator) | Medium | Medium | Focus on simplicity, creator niche |
| Video costs unsustainable | High | High | Higher pricing OR local-only video |

---

## 10. GO DECISION

### Ship If:
- You accept $2-5K Year 1 profit (conservative)
- You can commit 4-5 months
- You want to learn indie Mac development
- You're OK with video being a premium/loss-leader feature

### Don't Ship If:
- You need $10K+ guaranteed
- You can't build/maintain a backend proxy
- You expect passive income (needs ongoing work)

---

**This PRD reflects real-world fal.ai costs from production usage.**
**Ship it.** 🚀
