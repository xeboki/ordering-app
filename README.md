<p align="center">
  <img src="assets/images/xe_logo.svg" alt="Xeboki" width="120" />
</p>

<h1 align="center">Xeboki Ordering App</h1>

<p align="center">
  White-label Flutter ordering app for <a href="https://xeboki.com/xe-pos">Xeboki POS</a> subscribers.<br/>
  Your branding. Your menu. Your customers. Powered by Xeboki.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter" />
  <img src="https://img.shields.io/badge/Dart-3.4+-0175C2?logo=dart" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey" />
  <img src="https://img.shields.io/badge/License-Xeboki%20Subscriber-6366F1" />
</p>

---

## What is this?

A fully-featured, white-label mobile ordering app that connects directly to your **Xeboki POS** store. Fork this repo, run the setup wizard, and publish it under your own brand name on the App Store and Google Play.

**What customers get:**
- Browse your live menu (products, categories, modifiers, meal deals)
- Pickup, delivery, dine-in, and takeaway ordering
- Real-time order tracking with live delivery map
- Stripe card payments, Apple Pay, Google Pay, cash, and gift cards
- Loyalty points — earn and redeem at checkout
- Discount / promo codes
- Order history and re-order
- Appointment booking (salons, gyms, service businesses)

**What you configure once, then manage remotely:**
- App name, logo, colours, and font — set in `brand.json` once; update anytime from the Manager dashboard without rebuilding
- Which order types and payment methods to offer
- Welcome screen headline, subtext, and call-to-action button text
- Announcement bar (text and colour)
- Menu layout (grid or list) and featured categories
- Tipping, guest checkout, allergen display, calorie display
- Social links (Instagram, Facebook, WhatsApp)

---

## Requirements

| | |
|---|---|
| **Xeboki POS subscription** | **Paid plan required.** Free plan accounts are blocked at app launch — both client-side and server-side. Get a plan at [xeboki.com/xe-pos](https://xeboki.com/xe-pos) |
| Flutter SDK | ≥ 3.22 — [install guide](https://docs.flutter.dev/get-started/install) |
| Python 3 | Used by the setup wizard |
| Xcode ≥ 15 | iOS builds only (macOS required) |
| Android Studio | Android builds |

---

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/xeboki/ordering-app.git
cd ordering-app

# 2. Run the interactive setup wizard
bash setup.sh
```

The wizard walks you through:
- Pasting your **API Key** from the Developer Portal
- App name, tagline, business type
- Brand colours and font family
- Currency, tax label, and store info
- Order types (pickup / delivery / dine-in)
- Payment methods (cash / card / gift cards)
- Optional features (loyalty, tipping, Stripe)

After setup:
```bash
# Run on a connected device
flutter run --dart-define-from-file=.dart_defines.json

# Build Android APK
bash scripts/build.sh android release

# Build iOS IPA (macOS + Xcode required)
bash scripts/build.sh ios
```

---

## Get Your API Key

1. Log in to **[account.xeboki.com](https://account.xeboki.com) → Developer → API Keys**
2. Create a key with `pos:read` + `pos:write` scopes
3. Copy your **API Key** (`xbk_live_...`)

> No Location ID is required. The app automatically discovers your ordering-enabled branches at runtime.

## Enable Ordering Per Branch

In the **Xeboki POS Manager**: go to **Locations → Edit branch → Online Ordering** and toggle it on for each branch that accepts online orders.

- **1 branch enabled** → app starts directly, no picker shown
- **2+ branches enabled** → customer sees a branch picker screen on first launch
- **0 branches enabled** → app shows a "not available" screen until you enable at least one

---

## Configuration

### Local branding — `assets/brand.json`

This file sets the baseline branding baked into the app at build time. You only need to edit it once during initial setup — all fields can be overridden remotely afterward without a redeploy (see [Remote Branding](#remote-branding--no-redeploy) below).

```json
{
  "app_name": "My Store",
  "tagline": "Fresh. Fast. Yours.",

  "colors": {
    "primary": "#1A1A2E",
    "secondary": "#E94560"
  },

  "features": {
    "stripe_payments": true,
    "loyalty": true,
    "tipping": false,
    "dark_mode": true,
    "allergens": false,
    "calories": false,
    "guest_checkout": true
  },

  "checkout": {
    "allowed_order_types": ["pickup", "delivery"],
    "payment_methods": ["cash", "card"],
    "tip_presets": [10, 15, 20],
    "min_order_value": 5.00
  },

  "menu": {
    "layout": "grid",
    "show_category_images": true,
    "featured_category_ids": []
  },

  "social": {
    "instagram": "",
    "facebook": "",
    "whatsapp": ""
  }
}
```

See [`assets/brand.example.json`](assets/brand.example.json) for every available field with documentation.

---

## Remote Branding — No Redeploy

After the initial build, all branding and configuration can be updated from the **Xeboki Manager dashboard** without rebuilding or resubmitting to the App Store.

**How it works:**

1. Open **Manager → Ordering App** in the Xeboki dashboard
2. Edit any field — app name, tagline, colours, welcome screen text, menu layout, announcement bar, tipping presets, social links, etc.
3. Click **Save** — changes are written to the Xeboki API instantly
4. The next time a customer opens your app, the updated config is fetched from `GET /v1/pos/ordering-app-config` and applied automatically

**What can be changed remotely without a rebuild:**

| Section | Fields |
|---------|--------|
| Branding | App display name, tagline, logo URL, splash background colour, primary colour, secondary colour, font family |
| Welcome Screen | Headline, subtext, CTA button text |
| Menu & Catalog | Menu layout (grid/list), show category images, featured category IDs |
| Promotions | Announcement bar text and colour |
| Checkout | Guest checkout toggle, require phone, tip enabled, tip presets, minimum order value |
| Social | Instagram, Facebook, WhatsApp links |
| Accessibility | Show allergens, show calories |

> Remote config is merged on top of `brand.json` at runtime. Fields not set in the dashboard fall back to `brand.json` values. **No App Store resubmission needed** for any of these changes.

### Remote config flow

```
Manager Dashboard → PUT /v1/pos/ordering-app-config
       ↓  (saves to Manager Firebase)
App launches → GET /v1/pos/store-config
       ↓  (returns ordering_app block alongside store config)
BrandConfig.applyStoreConfig() merges remote values on top of brand.json
       ↓
UI rebuilds with latest branding — zero redeploy
```

---

## Your Credentials File

After running `setup.sh`, a `.dart_defines.json` file is created at the project root. **This file is gitignored — never commit it.**

```json
{
  "XEBOKI_API_KEY": "xbk_live_...",
  "XEBOKI_ENV": "production"
}
```

Copy `.dart_defines.json.example` and fill it in manually if you prefer not to use the wizard.

---

## Building

```bash
# Android — release APK (sideload / direct download)
bash scripts/build.sh android release

# Android — AAB for Google Play
bash scripts/build.sh android aab

# iOS — release IPA
bash scripts/build.sh ios

# Web
bash scripts/build.sh web
```

For a **signed Android release**, create `android/key.properties` pointing to your keystore and update `android/app/build.gradle`. See the [Flutter Android signing guide](https://docs.flutter.dev/deployment/android).

Change your **App ID / Bundle ID** before publishing:
- Android: `android/app/build.gradle` → `applicationId`
- iOS: Xcode → Runner target → Bundle Identifier

---

## VS Code

Four run configurations are pre-configured in `.vscode/launch.json` — they automatically load credentials from `.dart_defines.json`.

| Configuration | Use |
|---|---|
| Xeboki Ordering (dev) | Daily development |
| Xeboki Ordering (profile) | Performance profiling |
| Xeboki Ordering (release) | Release mode on device |
| Xeboki Ordering (web) | Chrome / web build |

---

## Add Your Logo

Replace `assets/images/logo.png` with your own.

- **Recommended:** 400 × 140 px, PNG with transparent background
- For a square logo update `logo.width` and `logo.height` in `brand.json`
- The same image is used on the splash screen

---

## Stripe Payments

1. Set `features.stripe_payments: true` in `brand.json`
2. Add your Stripe publishable key to `checkout.stripe_publishable_key`
3. Optionally enable `features.apple_pay` and `features.google_pay`

> Your Stripe **secret key** stays server-side — never put it in `brand.json`.

---

## Firebase Auth (Optional)

By default the app uses REST-based customer authentication. To switch to Firebase Auth (email + password via your Pro Firebase project):

1. Enable Firebase on your subscription: **POS Dashboard → Settings → Firebase**
2. Set `features.firebase_auth: true` in `brand.json`
3. No `google-services.json` needed — the config is fetched at runtime

---

## Subscription Gate

Your API key and subscription are validated every time the app launches. The check is enforced both in the app and on the server — it cannot be bypassed through device-level manipulation or developer tools. Plan changes take effect immediately with no delay.

---

## Project Structure

```
ordering-app/
├── setup.sh                     ← Run this first
├── SETUP.md                     ← Full configuration reference
├── .dart_defines.json.example   ← Credentials template
├── scripts/build.sh             ← Build helper
├── .vscode/launch.json          ← VS Code run configs
│
├── assets/
│   ├── brand.json               ← Baseline branding (edit once; manage remotely after)
│   ├── brand.example.json       ← Documented reference for every field
│   └── images/logo.png          ← Replace with your logo
│
└── lib/
    ├── core/
    │   ├── config/
    │   │   ├── app_config.dart       ← Build-time constants (do not edit)
    │   │   └── brand_config.dart     ← Parses brand.json + merges remote ordering-app-config
    │   ├── services/                 ← Stripe, Firebase, FCM
    │   └── types.dart                ← SDK client, StoreConfig (with orderingApp block), models
    ├── features/                     ← Screens & widgets
    ├── providers/                    ← Riverpod state management
    └── router/                       ← Navigation (GoRouter)
```

---

## Full Documentation

See **[SETUP.md](SETUP.md)** for the complete reference — every `brand.json` field, Android/iOS signing, localization, troubleshooting, and more.

---

## Support

- **Subscription & billing:** [xeboki.com/xe-pos](https://xeboki.com/xe-pos)
- **Technical issues:** [Open an issue](https://github.com/xeboki/ordering-app/issues)
- **POS Manager:** [pos.xeboki.com](https://pos.xeboki.com)
- **Developer docs:** [docs.xeboki.com](https://docs.xeboki.com)
