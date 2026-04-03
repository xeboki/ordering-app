<p align="center">
  <img src="assets/images/logo.png" alt="Xeboki Ordering App" width="120" />
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
  <img src="https://img.shields.io/badge/License-Xeboki%20Subscriber-blue" />
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
- Appointments booking (salons, gyms, service businesses)

**What you configure:**
- Your logo, colours, and font — one JSON file
- Which order types and payment methods to offer
- Your currency, tax label, and store details
- Stripe keys if you accept card payments
- Feature toggles for loyalty, tipping, dark mode, and more

---

## Requirements

| | |
|---|---|
| **Xeboki POS subscription** | **Paid plan required.** Free plan accounts are blocked at app launch. Get a plan at [xeboki.com/xe-pos](https://xeboki.com/xe-pos) |
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
- Pasting your **API Key** and **Location ID** from the POS Dashboard
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

## Get Your Credentials

1. Log in to your **Xeboki POS Dashboard**
2. Go to **Settings → Ordering App**
3. Copy your **API Key** (`xbk_live_...`) and **Location ID**

> Your API key is tied to your subscription. Only paid accounts with Ordering App access can use the developer API.

---

## Configuration

All branding and feature settings live in **`assets/brand.json`** — one file, no code changes needed.

```json
{
  "app_name": "My Store",
  "tagline": "Fresh. Fast. Yours.",
  "business_type": "restaurant",

  "colors": {
    "primary": "#1A1A2E",
    "secondary": "#E94560"
  },

  "store": {
    "currency_symbol": "$",
    "currency_code": "USD"
  },

  "features": {
    "stripe_payments": true,
    "loyalty": true,
    "tipping": false
  },

  "checkout": {
    "allowed_order_types": ["pickup", "delivery"],
    "payment_methods": ["cash", "card"]
  }
}
```

See [`assets/brand.example.json`](assets/brand.example.json) for every available field with documentation.

### Business types

`auto` · `restaurant` · `bar` · `qsr` · `coffeeshop` · `bakery` · `cafe` · `fastfood` · `pizza` · `foodtruck` · `retail` · `salon` · `gym` · `service`

---

## Your Credentials File

After running `setup.sh`, a `.dart_defines.json` file is created at the project root. **This file is gitignored — never commit it.**

```json
{
  "XEBOKI_API_KEY": "xbk_live_...",
  "XEBOKI_LOCATION_ID": "your_location_id",
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

The app validates your API key on every launch via `GET /v1/pos/validate`. Accounts that fail validation see a clear error screen and cannot proceed:

| Status | Screen shown |
|---|---|
| Invalid API key | "Invalid API Key" — contact app owner |
| No active subscription | "No Active Subscription" — link to upgrade |
| Free plan | "Plan Upgrade Required" — link to upgrade |
| Feature not in plan | "Feature Not Included" — link to upgrade |
| Network error | "Connection Error" — retry button |

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
│   ├── brand.json               ← Your branding & features (edit this)
│   ├── brand.example.json       ← Documented reference for every field
│   └── images/logo.png          ← Replace with your logo
│
└── lib/
    ├── core/
    │   ├── config/
    │   │   ├── app_config.dart  ← Build-time constants (do not edit)
    │   │   └── brand_config.dart← Parses brand.json (do not edit)
    │   ├── services/            ← Stripe, Firebase, FCM
    │   └── types.dart           ← SDK client & all data models
    ├── features/                ← Screens & widgets
    ├── providers/               ← Riverpod state management
    └── router/                  ← Navigation (GoRouter)
```

---

## Full Documentation

See **[SETUP.md](SETUP.md)** for the complete reference — every `brand.json` field, Android/iOS signing, localization, troubleshooting, and more.

---

## Support

- **Subscription & billing:** [xeboki.com/xe-pos](https://xeboki.com/xe-pos)
- **Technical issues:** [Open an issue](https://github.com/xeboki/ordering-app/issues)
- **POS Dashboard:** [pos.xeboki.com](https://pos.xeboki.com)
