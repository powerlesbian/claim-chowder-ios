# Claim Chowder — TODO

## Security

### [ ] Enable email verification on sign-up
**What:** Toggle "Enable email confirmations" in Supabase → Authentication → Settings.
**Why:** Blocks bots from creating accounts with fake emails and writing junk data.
**When to do this — switch when ANY of these is true:**
- App is publicly listed on the App Store (becomes discoverable)
- Registered user count exceeds ~50 (beyond personal/friends circle)
- Repo or app gets any public profile (website, press, social media)
- A spam account or junk data row is observed in the Supabase dashboard

**Why not now:** App not yet publicly discoverable, user base is just the developer, simple login reduces friction during active development.
**Implementation notes:**
- Handle `unconfirmed` auth state in `AuthManager` — show "Check your email" screen
- Optionally add a resend confirmation button in `AuthView`

---

## v1.1 Features (in progress)

### [x] Sort options (Name, Amount, Due Soon, Date Added)
### [x] Batch select + delete
### [x] Duplicate detection
### [x] CSV export
### [x] Custom tags
### [x] HKD conversion bug fix
### [x] Tap-to-edit subscription rows
### [x] Live exchange rates (RateService, 4hr cache)
### [x] New currencies: MYR, GBP, CNY, EUR
### [x] Dashboard greeting + tappable cards
### [x] Replaced redundant stat pills

---

## Onboarding & UX Polish

### [ ] Privacy reassurance on sign-up form
When the user is on the sign-up screen, show a small line beneath the Create Account button:
*"🔒 Your data is stored securely and privately. It is only accessible to a dedicated support person if you explicitly request assistance — otherwise we never see it, and we never share it with anyone."*
Only visible on sign-up, not sign-in. No modal, just a quiet one-liner.
**Effort:** Very low

### [ ] Improve empty state on first login
New users land on an empty subscription list with a generic prompt. Make it warmer and more guiding:
- Primary message: "No expenses yet"
- Sub-message: "Add your first expense manually, or import a bank statement PDF to get started quickly"
- Two buttons: "Add Expense" and "Import PDF"
**Effort:** Low

> **Future improvement:** Tell the user what the default currency and frequency are when adding an expense, and how to change them before saving.

### [ ] Humanise auth error messages
Translate Supabase's raw error strings into friendly copy:
- "Invalid login credentials" → "Wrong email or password. Please try again."
- "User already registered" → "An account with that email already exists. Try signing in instead."
- "Password should be at least 6 characters" → leave as-is, already clear
**Effort:** Low

### [ ] Onboarding carousel (first launch only)
A 3-screen swipeable intro shown once on first install, before the auth screen. Skippable. Controlled by a `UserDefaults` flag.
- **Screen 1** — what the app does: "Track every expense and subscription across multiple currencies, all in one place"
- **Screen 2** — your data, your backup: "Export your data as a CSV anytime and keep your own copy. You're always in control."
- **Screen 3** — privacy promise: "Your data is stored securely and privately. It is only accessible to a dedicated support person if you explicitly request assistance — otherwise we never see it, and we never share it with anyone."
**Effort:** Medium

### [ ] Password UX improvements in AuthView
Two small additions to make login/signup less painful:
1. **Eye icon** — toggle password visibility. Replace `SecureField` with a `@State private var showPassword = false` that switches between `SecureField` and `TextField`. Eye icon as trailing overlay on the field.
2. **Forgot password? link** — triggers Supabase's built-in password reset email (`supabase.auth.resetPasswordForEmail(email)`). Real safety net if someone mistypes their password on signup. Show only on the sign-in screen, not sign-up.
**Effort:** Low

---

## v1.2 Ideas (priority order)

### [ ] Spending chart (pie/bar by category or currency)
**Effort:** Medium

### [ ] CSV import
**Effort:** Medium

### [ ] Push notifications for upcoming payments
**Effort:** High

### [ ] Home screen widget
**Effort:** High

### [ ] Per-entry exchange rate storage (Option C)
Store the exchange rate at time of entry in Supabase. Historically accurate but requires a new `exchange_rate` column and migration.
**Effort:** Medium — revisit if currency volatility becomes a real pain point
