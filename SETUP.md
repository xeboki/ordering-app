# Xeboki Ordering App — Setup Guide

White-label Flutter ordering app for Xeboki POS subscribers.  
Customers browse your menu, place pickup / delivery / dine-in orders, and track delivery — all under your own branding.

---

## Requirements

| Requirement | Details |
|---|---|
| **Xeboki POS subscription** | Paid plan with Ordering App access required. Free plan is blocked at app startup. |
| **Flutter SDK** | ≥ 3.22 (`flutter --version`) |
| **Python 3** | Used by the setup wizard and build scripts |
| **Dart SDK** | Bundled with Flutter |
| **For iOS builds** | macOS, Xcode ≥ 15, Apple Developer account |
| **For Android release** | Java / Android SDK (bundled with Android Studio) |

> **Subscription gate:** The app calls `GET /v1/pos/validate-key` on every launch.  
> If the API key is invalid, the account has no active subscription, or the current plan does not include the Ordering App, the app shows a clear error screen and does not proceed. Only paid accounts with Ordering App access can use the app.

---

## Quick Start (5 minutes)

```bash
# 1. Clone / fork the repo
git clone <repo-url>
cd "POS/Ordering App"

# 2. Run the interactive setup wizard
bash setup.sh
```

The wizard asks for:
- Your Xeboki **API Key** (from account.xeboki.com → Developer → API Keys)
- App name, tagline, business type
- Brand colours and font
- Currency and store info
- Order types (pickup / delivery / dine-in)
- Payment methods (cash / card + Stripe key / gift cards)

After setup:
```bash
# Run in development
flutter run --dart-define-from-file=.dart_defines.json

# Build for Android
bash scripts/build.sh android release

# Build for iOS
bash scripts/build.sh ios
```

---

## Getting Your API Key

1. Log in to **account.xeboki.com → Developer → API Keys**
2. Create a key with `pos:read` + `pos:write` scopes
3. Copy your **API Key** (`xbk_live_...`)

Your API key is specific to your subscription. Do not share it publicly — it controls access to your entire store catalog and order data.

### Enabling Ordering Per Branch

Open the **Xeboki Manager app** → **Locations** → tap a branch → enable the **Online Ordering** toggle.

| Enabled branches | What the app shows |
|---|---|
| 1 | Starts directly — no picker, seamless |
| 2 or more | Branch picker screen on first launch |
| 0 | "Ordering not available" screen until you enable at least one |

---

## Configuration Files

### `.dart_defines.json` — credentials (gitignored)

Created by `setup.sh`. Never commit this file.

```json
{
  "XEBOKI_API_KEY": "xbk_live_...",
  "XEBOKI_ENV":     "production"
}
```

Copy `.dart_defines.json.example`, rename to `.dart_defines.json`, and fill in your values if you prefer not to use the wizard.

---

### `assets/brand.json` — all branding & features

This is the single file that controls how the app looks and behaves. Edit it directly after running setup, or re-run `setup.sh` at any time.

See [`assets/brand.example.json`](assets/brand.example.json) for a fully-documented reference with every available field.

#### Top-level fields

| Field | Type | Description |
|---|---|---|
| `app_name` | string | Displayed in the app header and splash screen |
| `tagline` | string | Shown on the splash screen below the logo |
| `business_type` | string | Affects default UI layout and features — see options below |

**`business_type` options:**

| Value | Best for |
|---|---|
| `auto` | Let the app infer from context (recommended for most stores) |
| `restaurant` | Full-service restaurant with dine-in and table management |
| `bar` | Bar / pub with tabs and table ordering |
| `qsr` | Quick service / counter service (McDonald's-style) |
| `coffeeshop` | Coffee shop / grab & go |
| `bakery` | Bakery / patisserie |
| `cafe` | Casual café |
| `fastfood` | Fast food chain |
| `pizza` | Pizza / delivery-first |
| `foodtruck` | Food truck / pop-up |
| `retail` | General retail / shop |
| `salon` | Hair & beauty salon |
| `gym` | Fitness / gym |
| `service` | General service business |

---

#### `colors`

All hex strings (`#RRGGBB`). Choose colours that match your brand.

| Key | Description |
|---|---|
| `primary` | Main brand colour — buttons, active states, highlights |
| `secondary` | Accent colour — badges, secondary actions |
| `surface` | Card/sheet backgrounds (usually white or near-white) |
| `background` | Page background |
| `on_primary` | Text/icons on top of `primary` (usually white) |
| `on_secondary` | Text/icons on top of `secondary` |
| `on_surface` | Body text on cards |
| `success` | Confirmation messages |
| `warning` | Warning messages |
| `error` | Error states |

---

#### `typography`

| Key | Description |
|---|---|
| `font_family` | Any [Google Fonts](https://fonts.google.com) name (e.g. `Inter`, `Poppins`, `Lato`) |
| `scale` | Scales the entire type system. `1.0` = default, `0.9` = slightly smaller |

---

#### `logo` and `splash`

Place your logo at `assets/images/logo.png` (PNG or transparent PNG recommended). Update `logo.asset` if you use a different filename or sub-folder.

Set `logo.use_text_fallback: true` to show the app name as text if the image fails to load.

---

#### `store`

| Key | Example | Description |
|---|---|---|
| `currency_symbol` | `£` | Shown next to prices |
| `currency_code` | `GBP` | ISO 4217 code used by Stripe and formatting |
| `locale` | `en_GB` | Affects number and date formatting |
| `timezone` | `Europe/London` | [TZ database name](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) |
| `tax_label` | `VAT` | Label shown for tax in order summaries |
| `support_email` | `hi@yourdomain.com` | Shown in account and help screens |
| `support_phone` | `+44 20 0000 0000` | Optional, shown if non-empty |
| `address` | `123 High Street...` | Your store address |
| `website` | `https://yourdomain.com` | Linked from the about screen |

---

#### `features`

| Key | Default | Description |
|---|---|---|
| `customer_auth` | `true` | Customer login / register. Disable for anonymous-only ordering. |
| `firebase_auth` | `false` | Use Firebase Auth (email + password) instead of REST auth. Requires Pro Firebase enabled on your subscription. |
| `loyalty` | `true` | Loyalty points programme |
| `discount_codes` | `true` | Promo / discount code field at checkout |
| `order_scheduling` | `false` | Let customers schedule orders for a future time |
| `table_ordering` | `"auto"` | `"auto"` = on for restaurant/bar/cafe, off otherwise. Use `"true"` or `"false"` to override. |
| `appointments` | `"auto"` | `"auto"` = on for salon/gym/service types |
| `meal_deals` | `"auto"` | `"auto"` = on for food businesses |
| `tipping` | `false` | Tip selector at checkout |
| `dark_mode` | `true` | Let customers switch to dark theme |
| `reviews` | `false` | Customer reviews (coming soon) |
| `stripe_payments` | `false` | Enable Stripe card payments |
| `apple_pay` | `false` | Apple Pay (iOS only, requires `stripe_payments: true`) |
| `google_pay` | `false` | Google Pay (Android only, requires `stripe_payments: true`) |

---

#### `checkout`

| Key | Default | Description |
|---|---|---|
| `default_order_type` | `"pickup"` | Pre-selected order type: `pickup`, `delivery`, `dine_in`, `takeaway` |
| `allowed_order_types` | `["pickup"]` | Which types appear on the order-type selector |
| `payment_methods` | `["cash","card"]` | Display order matters — first = default selection |
| `stripe_publishable_key` | `""` | `pk_live_...` or `pk_test_...`. **Never** put your secret key here. |
| `stripe_connected_account_id` | `""` | Stripe Connect `acct_...` for Xeboki Launchpad payment routing. Leave empty for direct charges. |
| `minimum_spend` | `0` | Minimum order total. `0` = no minimum. |
| `tip_presets` | `[10,15,20]` | Percentage buttons shown (requires `tipping: true`) |
| `default_delivery_fee` | `0` | Flat delivery fee when no zone pricing is configured. |
| `free_delivery_threshold` | `0` | Orders at or above this total get free delivery. `0` = always charge. |
| `dine_in_discount_pct` | `0` | Auto-discount % for dine-in orders |
| `collection_discount_pct` | `0` | Auto-discount % for pickup/collection orders |

---

## Adding Your Logo

Replace `assets/images/logo.png` with your own logo.

- **Recommended size:** 400 × 140 px (PNG with transparent background)
- For a square logo, set `logo.width` and `logo.height` to equal values in `brand.json`
- The same image is used on the splash screen (`splash.logo_asset`)

---

## Building the App

### Android

```bash
# Release APK (sideloading / direct download)
bash scripts/build.sh android release

# Release AAB (Google Play Store)
bash scripts/build.sh android aab
```

**For a signed release build**, create `android/key.properties`:

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=<your-key-alias>
storeFile=<path-to-keystore.jks>
```

Then update `android/app/build.gradle` to reference it. See the [Flutter Android release guide](https://docs.flutter.dev/deployment/android).

**Change the App ID (Bundle ID):**  
In `android/app/build.gradle`, set `applicationId` to your own reverse-domain ID, e.g. `com.yourcompany.yourapp`.

---

### iOS

```bash
bash scripts/build.sh ios
```

**Requirements:** macOS, Xcode ≥ 15, active Apple Developer account.

**Change the Bundle ID:**  
Open `ios/Runner.xcodeproj` in Xcode → select the Runner target → change the Bundle Identifier, e.g. `com.yourcompany.yourapp`.

**Signing:**  
In Xcode → Signing & Capabilities, select your development team. Use automatic signing for development and manual for App Store distribution.

---

## Development Workflow

### VS Code

Open the `Ordering App` folder in VS Code. Four run configurations are pre-configured in `.vscode/launch.json`:

- **Xeboki Ordering (dev)** — standard debug run
- **Xeboki Ordering (profile)** — for performance testing
- **Xeboki Ordering (release)** — release mode on device
- **Xeboki Ordering (web)** — Chrome, CanvasKit renderer

All configurations automatically load credentials from `.dart_defines.json`.

### Command line

```bash
# Run on connected device
flutter run --dart-define-from-file=.dart_defines.json

# Hot reload is available while running (press 'r')
# Hot restart (press 'R')
```

### Code generation

Run after modifying any Freezed models or Riverpod providers:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Firebase Auth (Optional)

By default the app uses REST-based customer auth. To upgrade to Firebase Auth (email + password backed by your Pro Firebase project):

1. Enable Firebase on your Xeboki subscription (Dashboard → Settings → Firebase)
2. Set `features.firebase_auth: true` in `brand.json`
3. The app fetches the Firebase config at runtime — no `google-services.json` needed

---

## Stripe Payments

1. Set `features.stripe_payments: true` in `brand.json`
2. Add your Stripe publishable key to `checkout.stripe_publishable_key`
3. The Stripe secret key stays server-side — it is never in the app
4. Optionally enable `features.apple_pay` and/or `features.google_pay`

For **Xeboki Launchpad** payment routing, set `checkout.stripe_connected_account_id` to your Stripe Connect account ID (`acct_...`).

---

## Localization

The app ships with four languages: English (default), French, Spanish, Arabic.

To add a language, create `lib/l10n/app_XX.arb` following the pattern in `lib/l10n/app_en.arb`, then add the locale to `supportedLocales` in `main.dart` and run:

```bash
flutter gen-l10n
```

---

## Troubleshooting

### "XEBOKI_API_KEY is required"
You're running without the dart-define flag. Use:
```bash
flutter run --dart-define-from-file=.dart_defines.json
```
Or run `bash setup.sh` to create `.dart_defines.json`.

### Splash screen shows "Plan Upgrade Required" or "Feature Not Included"
Your Xeboki subscription does not include the Ordering App. Log in to the POS Dashboard and upgrade your plan.

### Splash screen shows "No Active Subscription"
Your API key is valid but the subscription has lapsed. Renew at xeboki.com/xe-pos.

### Splash screen shows "Invalid API Key"
The API key in `.dart_defines.json` is wrong or has been revoked. Get a fresh key from the POS Dashboard → Settings → Ordering App.

### `build_runner` errors on generated files
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### iOS build fails with "No signing certificate"
Open the project in Xcode and configure signing manually. See the [Flutter iOS deployment guide](https://docs.flutter.dev/deployment/ios).

---

## File Reference

```
Ordering App/
├── setup.sh                      ← Run this first
├── SETUP.md                      ← This file
├── .dart_defines.json            ← Your credentials (gitignored, created by setup.sh)
├── .dart_defines.json.example    ← Credential template
├── .gitignore
├── pubspec.yaml
│
├── assets/
│   ├── brand.json                ← Edit this to brand the app
│   ├── brand.example.json        ← Fully-documented reference
│   └── images/
│       └── logo.png              ← Replace with your logo
│
├── scripts/
│   └── build.sh                  ← Build helper (android / ios / web)
│
├── .vscode/
│   └── launch.json               ← VS Code run configurations
│
└── lib/
    ├── main.dart
    ├── core/
    │   ├── config/
    │   │   ├── app_config.dart   ← Build-time constants (do not edit)
    │   │   └── brand_config.dart ← Parses brand.json (do not edit)
    │   ├── services/             ← Stripe, Firebase, FCM services
    │   └── types.dart            ← SDK models and OrderingClient
    ├── features/                 ← Screens and widgets
    ├── providers/                ← Riverpod state
    └── router/                   ← Navigation
```

---

## Support

For subscription or billing: [xeboki.com/xe-pos](https://xeboki.com/xe-pos)  
For technical issues: open an issue in this repository.
