#!/usr/bin/env bash
# =============================================================================
# Xeboki Ordering App — Interactive Setup Wizard
#
# Run from the root of the ordering app:
#   bash setup.sh
#
# What this does:
#   1. Checks prerequisites (Flutter, Python 3)
#   2. Asks for your Xeboki API credentials
#   3. Configures basic branding (name, colours, currency, order types)
#   4. Configures payment methods (incl. Stripe publishable key if needed)
#   5. Writes .dart_defines.json  (gitignored — your secrets live here)
#   6. Updates assets/brand.json
#   7. Runs flutter pub get
# =============================================================================
set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${CYAN}  $*${NC}"; }
success() { echo -e "${GREEN}  ✓ $*${NC}"; }
warn()    { echo -e "${YELLOW}  ⚠ $*${NC}"; }
error()   { echo -e "${RED}  ✗ $*${NC}"; }
step()    { echo -e "\n${BOLD}${BLUE}▸ $*${NC}"; }

prompt() {
  # prompt <var_name> <label> [default]
  local var="$1" label="$2" default="${3:-}"
  if [ -n "$default" ]; then
    read -rp "  ${label} [${default}]: " _val
    eval "$var=\"\${_val:-$default}\""
  else
    read -rp "  ${label}: " _val
    eval "$var=\"\$_val\""
  fi
}

prompt_yn() {
  # prompt_yn <var_name> <label> <default: y|n>
  local var="$1" label="$2" default="${3:-n}"
  read -rp "  ${label} (y/n) [${default}]: " _yn
  _yn="${_yn:-$default}"
  if [[ "$_yn" =~ ^[Yy]$ ]]; then eval "$var=true"
  else eval "$var=false"; fi
}

# ── Banner ────────────────────────────────────────────────────────────────────
clear
echo ""
echo -e "${CYAN}${BOLD}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║                                                   ║"
echo "  ║   X E B O K I   O R D E R I N G   A P P          ║"
echo "  ║   Setup Wizard                                    ║"
echo "  ║                                                   ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  Run this once to configure the app for your store."
echo -e "  All secrets go into ${BOLD}.dart_defines.json${NC} which is gitignored."
echo ""

# ── Prerequisites ─────────────────────────────────────────────────────────────
step "Checking prerequisites"

check_cmd() {
  if command -v "$1" &>/dev/null; then success "$1 found ($(command -v "$1"))"
  else error "'$1' not found — please install it first."; exit 1; fi
}

check_cmd flutter
check_cmd python3

# Verify we're in the ordering app directory
if [ ! -f "pubspec.yaml" ] || ! grep -q "xeboki_ordering" pubspec.yaml 2>/dev/null; then
  error "Run this script from the root of the Xeboki Ordering App directory."
  info  "  cd 'POS/Ordering App' && bash setup.sh"
  exit 1
fi
success "Working directory is correct"

# ── Step 1: Xeboki Credentials ────────────────────────────────────────────────
step "Step 1 / 5 — Xeboki Credentials"
echo ""
info "Get your API key from: account.xeboki.com → Developer → API Keys"
info "A paid Xeboki POS subscription with Ordering App access is required."
info "Free plan accounts will be blocked at app startup."
echo ""
info "No Location ID needed — the app discovers your ordering-enabled branches"
info "automatically at runtime. Enable ordering per branch in the Manager app:"
info "  Manager → Locations → Edit branch → Online Ordering toggle"
echo ""

while true; do
  prompt API_KEY "API Key (xbk_live_...)"
  if [ -z "$API_KEY" ]; then
    warn "API key is required."
  elif [[ ! "$API_KEY" =~ ^xbk_(live|test)_ ]]; then
    warn "API key should start with xbk_live_ or xbk_test_ — continue anyway? (y/n)"
    read -rn1 _c; echo
    [[ "$_c" =~ ^[Yy]$ ]] && break
  else
    break
  fi
done

# Read current brand.json values as defaults
_bj() { python3 -c "import json,sys; d=json.load(open('assets/brand.json')); print(d$1)" 2>/dev/null || echo "$2"; }

# ── Step 2: App Branding ──────────────────────────────────────────────────────
step "Step 2 / 5 — App Branding"
echo ""
info "Press Enter to keep the current value shown in [brackets]."
echo ""

CUR_NAME=$(_bj "['app_name']" "My Store")
CUR_TAGLINE=$(_bj "['tagline']" "")
CUR_BT=$(_bj "['business_type']" "auto")
CUR_FONT=$(_bj "['typography']['font_family']" "Inter")
CUR_PRIMARY=$(_bj "['colors']['primary']" "#1A1A2E")
CUR_SECONDARY=$(_bj "['colors']['secondary']" "#E94560")

prompt APP_NAME   "App name"                       "$CUR_NAME"
prompt TAGLINE    "Tagline (shown on splash)"       "$CUR_TAGLINE"

echo ""
info "Business types:"
info "  auto, restaurant, bar, qsr, coffeeshop, bakery, cafe, fastfood,"
info "  pizza, foodtruck, retail, salon, gym, service"
prompt BUSINESS_TYPE "Business type" "$CUR_BT"

echo ""
info "Font family — any Google Fonts name, e.g. Inter, Poppins, Lato, Montserrat"
prompt FONT_FAMILY "Font family" "$CUR_FONT"

echo ""
info "Hex colours (format: #RRGGBB)"
prompt PRIMARY_COLOR   "Primary brand colour"   "$CUR_PRIMARY"
prompt SECONDARY_COLOR "Secondary accent colour" "$CUR_SECONDARY"

# ── Step 3: Store & Currency ──────────────────────────────────────────────────
step "Step 3 / 5 — Store Details & Currency"
echo ""

CUR_SYM=$(_bj "['store']['currency_symbol']" "\$")
CUR_CODE=$(_bj "['store']['currency_code']" "USD")
CUR_LOCALE=$(_bj "['store']['locale']" "en_US")
CUR_TZ=$(_bj "['store']['timezone']" "UTC")
CUR_TAX=$(_bj "['store']['tax_label']" "Tax")
CUR_EMAIL=$(_bj "['store']['support_email']" "")
CUR_PHONE=$(_bj "['store']['support_phone']" "")

prompt CURRENCY_SYMBOL "Currency symbol (e.g. $, £, €)"  "$CUR_SYM"
prompt CURRENCY_CODE   "Currency code (e.g. USD, GBP, EUR)" "$CUR_CODE"
prompt STORE_LOCALE    "Locale (e.g. en_US, en_GB, fr_FR)"  "$CUR_LOCALE"
prompt TIMEZONE        "Timezone (e.g. Europe/London)"       "$CUR_TZ"
prompt TAX_LABEL       "Tax label (e.g. VAT, Tax, GST)"     "$CUR_TAX"
prompt SUPPORT_EMAIL   "Support email"                       "$CUR_EMAIL"
prompt SUPPORT_PHONE   "Support phone (optional)"            "$CUR_PHONE"

# ── Step 4: Order Types ───────────────────────────────────────────────────────
step "Step 4 / 5 — Order Types & Checkout"
echo ""

info "Which order types will you support? (select all that apply)"
echo ""
prompt_yn OT_PICKUP   "Collection / Pickup"  "y"
prompt_yn OT_DELIVERY "Delivery"             "n"
prompt_yn OT_DINEIN   "Dine-in"              "n"

# Build allowed_order_types list
ALLOWED_OT='[]'
DEFAULT_OT="pickup"
OT_ARRAY=()
$OT_PICKUP   && OT_ARRAY+=("\"pickup\"")   && DEFAULT_OT="pickup"
$OT_DELIVERY && OT_ARRAY+=("\"delivery\"") && [ "${#OT_ARRAY[@]}" -eq 1 ] && DEFAULT_OT="delivery"
$OT_DINEIN   && OT_ARRAY+=("\"dine_in\"")  && [ "${#OT_ARRAY[@]}" -eq 1 ] && DEFAULT_OT="dine_in"
if [ "${#OT_ARRAY[@]}" -gt 0 ]; then
  ALLOWED_OT="[$(IFS=,; echo "${OT_ARRAY[*]}")]"
else
  warn "No order types selected — defaulting to pickup."
  ALLOWED_OT='["pickup"]'
fi

if [ "${#OT_ARRAY[@]}" -gt 1 ]; then
  echo ""
  info "Which is the default order type?"
  prompt DEFAULT_OT "Default order type" "$DEFAULT_OT"
fi

if $OT_DELIVERY; then
  echo ""
  prompt DELIVERY_FEE      "Default delivery fee (0 = free)"           "0.00"
  prompt FREE_DEL_THRESHOLD "Free delivery above this order total (0 = always charge)" "0.00"
else
  DELIVERY_FEE="0.00"
  FREE_DEL_THRESHOLD="0.00"
fi

# ── Step 5: Payments ──────────────────────────────────────────────────────────
step "Step 5 / 5 — Payment Methods"
echo ""

prompt_yn PAY_CASH     "Accept cash payments"       "y"
prompt_yn PAY_CARD     "Accept card payments (Stripe)" "n"
prompt_yn PAY_GIFT_CARD "Accept gift cards"           "n"

STRIPE_KEY=""
ENABLE_STRIPE="false"
ENABLE_APPLE_PAY="false"
ENABLE_GOOGLE_PAY="false"

if $PAY_CARD; then
  echo ""
  info "Stripe publishable key (pk_live_... or pk_test_...). Secret key stays server-side."
  prompt STRIPE_KEY "Stripe publishable key" ""
  ENABLE_STRIPE="true"
  echo ""
  prompt_yn ENABLE_APPLE_PAY  "Enable Apple Pay (iOS)"    "n"
  prompt_yn ENABLE_GOOGLE_PAY "Enable Google Pay (Android)" "n"
fi

PM_ARRAY=()
$PAY_CASH      && PM_ARRAY+=("\"cash\"")
$PAY_CARD      && PM_ARRAY+=("\"card\"")
$PAY_GIFT_CARD && PM_ARRAY+=("\"gift_card\"")
[ "${#PM_ARRAY[@]}" -eq 0 ] && PM_ARRAY+=("\"cash\"") && warn "No payment methods selected — defaulting to cash."
PAYMENT_METHODS="[$(IFS=,; echo "${PM_ARRAY[*]}")]"

# ── Features ──────────────────────────────────────────────────────────────────
echo ""
step "Optional Features"
echo ""

prompt_yn FEAT_LOYALTY   "Enable loyalty points programme" "y"
prompt_yn FEAT_DISCOUNTS "Enable discount / promo codes"   "y"
prompt_yn FEAT_TIPPING   "Enable tipping at checkout"      "n"
prompt_yn FEAT_DARK_MODE "Allow customers to use dark mode" "y"
prompt_yn FEAT_FIREBASE  "Use Firebase Auth for customers (requires Pro Firebase)" "n"

# ── Apply configuration ───────────────────────────────────────────────────────
step "Applying configuration"
echo ""

# Export all values so Python can read them safely (handles special chars in input)
export XBK_APP_NAME="$APP_NAME"
export XBK_TAGLINE="$TAGLINE"
export XBK_BUSINESS_TYPE="$BUSINESS_TYPE"
export XBK_FONT_FAMILY="$FONT_FAMILY"
export XBK_PRIMARY="$PRIMARY_COLOR"
export XBK_SECONDARY="$SECONDARY_COLOR"
export XBK_CURRENCY_SYMBOL="$CURRENCY_SYMBOL"
export XBK_CURRENCY_CODE="$CURRENCY_CODE"
export XBK_LOCALE="$STORE_LOCALE"
export XBK_TIMEZONE="$TIMEZONE"
export XBK_TAX_LABEL="$TAX_LABEL"
export XBK_SUPPORT_EMAIL="$SUPPORT_EMAIL"
export XBK_SUPPORT_PHONE="$SUPPORT_PHONE"
export XBK_DEFAULT_OT="$DEFAULT_OT"
export XBK_ALLOWED_OT="$ALLOWED_OT"
export XBK_PAYMENT_METHODS="$PAYMENT_METHODS"
export XBK_STRIPE_KEY="$STRIPE_KEY"
export XBK_ENABLE_STRIPE="$ENABLE_STRIPE"
export XBK_ENABLE_APPLE_PAY="$ENABLE_APPLE_PAY"
export XBK_ENABLE_GOOGLE_PAY="$ENABLE_GOOGLE_PAY"
export XBK_DELIVERY_FEE="$DELIVERY_FEE"
export XBK_FREE_DEL_THRESHOLD="$FREE_DEL_THRESHOLD"
export XBK_FEAT_LOYALTY="$FEAT_LOYALTY"
export XBK_FEAT_DISCOUNTS="$FEAT_DISCOUNTS"
export XBK_FEAT_TIPPING="$FEAT_TIPPING"
export XBK_FEAT_DARK_MODE="$FEAT_DARK_MODE"
export XBK_FEAT_FIREBASE="$FEAT_FIREBASE"

python3 - <<'PYEOF'
import json, os

def env(k, default=''):
    return os.environ.get(k, default)

def envbool(k):
    return os.environ.get(k, 'false').lower() == 'true'

def envfloat(k, default=0.0):
    try: return float(os.environ.get(k, str(default)))
    except: return default

with open('assets/brand.json', 'r', encoding='utf-8') as f:
    d = json.load(f)

# Top-level
d['app_name']      = env('XBK_APP_NAME', 'My Store')
d['tagline']       = env('XBK_TAGLINE')
d['business_type'] = env('XBK_BUSINESS_TYPE', 'auto')

# Typography
d.setdefault('typography', {})
d['typography']['font_family'] = env('XBK_FONT_FAMILY', 'Inter')

# Colors
d.setdefault('colors', {})
d['colors']['primary']   = env('XBK_PRIMARY',   '#1A1A2E')
d['colors']['secondary'] = env('XBK_SECONDARY', '#E94560')

# Store
d.setdefault('store', {})
d['store']['currency_symbol'] = env('XBK_CURRENCY_SYMBOL', '$')
d['store']['currency_code']   = env('XBK_CURRENCY_CODE',   'USD')
d['store']['locale']          = env('XBK_LOCALE',    'en_US')
d['store']['timezone']        = env('XBK_TIMEZONE',  'UTC')
d['store']['tax_label']       = env('XBK_TAX_LABEL', 'Tax')
d['store']['support_email']   = env('XBK_SUPPORT_EMAIL')
d['store']['support_phone']   = env('XBK_SUPPORT_PHONE')

# Checkout
d.setdefault('checkout', {})
d['checkout']['default_order_type'] = env('XBK_DEFAULT_OT', 'pickup')
d['checkout']['allowed_order_types'] = json.loads(env('XBK_ALLOWED_OT', '["pickup"]'))
d['checkout']['payment_methods']     = json.loads(env('XBK_PAYMENT_METHODS', '["cash"]'))
d['checkout']['stripe_publishable_key'] = env('XBK_STRIPE_KEY')
d['checkout']['default_delivery_fee']   = envfloat('XBK_DELIVERY_FEE')
d['checkout']['free_delivery_threshold'] = envfloat('XBK_FREE_DEL_THRESHOLD')

# Features
d.setdefault('features', {})
d['features']['stripe_payments'] = envbool('XBK_ENABLE_STRIPE')
d['features']['apple_pay']       = envbool('XBK_ENABLE_APPLE_PAY')
d['features']['google_pay']      = envbool('XBK_ENABLE_GOOGLE_PAY')
d['features']['loyalty']         = envbool('XBK_FEAT_LOYALTY')
d['features']['discount_codes']  = envbool('XBK_FEAT_DISCOUNTS')
d['features']['tipping']         = envbool('XBK_FEAT_TIPPING')
d['features']['dark_mode']       = envbool('XBK_FEAT_DARK_MODE')
d['features']['firebase_auth']   = envbool('XBK_FEAT_FIREBASE')

with open('assets/brand.json', 'w', encoding='utf-8') as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
    f.write('\n')

print('  assets/brand.json updated')
PYEOF
success "assets/brand.json updated"

# Write .dart_defines.json
python3 - <<PYEOF2
import json
d = {
    "XEBOKI_API_KEY": "$API_KEY",
    "XEBOKI_ENV":     "production"
}
with open('.dart_defines.json', 'w') as f:
    json.dump(d, f, indent=2)
    f.write('\n')
print('  .dart_defines.json written')
PYEOF2
success ".dart_defines.json written (gitignored)"

# ── flutter pub get ───────────────────────────────────────────────────────────
echo ""
info "Running flutter pub get..."
flutter pub get
success "Dependencies installed"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║   Setup complete!                                 ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "  ${BOLD}Next steps:${NC}"
echo ""
echo -e "  1. Add your logo image:"
echo -e "       ${CYAN}assets/images/logo.png${NC}  (replace the placeholder)"
echo ""
echo -e "  2. Fine-tune branding in:"
echo -e "       ${CYAN}assets/brand.json${NC}  (colours, features, social links, etc.)"
echo ""
echo -e "  3. Build the app:"
echo -e "       ${CYAN}bash scripts/build.sh android${NC}   → APK / AAB"
echo -e "       ${CYAN}bash scripts/build.sh ios${NC}       → IPA (requires macOS + Xcode)"
echo ""
echo -e "  4. Run for development:"
echo -e "       ${CYAN}flutter run --dart-define-from-file=.dart_defines.json${NC}"
echo ""
echo -e "  See ${CYAN}SETUP.md${NC} for the full configuration reference."
echo ""
