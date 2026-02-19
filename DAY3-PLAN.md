# Day 3 Plan — Claim Chowder iOS (Final Day)

## Where We Left Off (Day 2 Complete)

The app builds, runs, and is fully functional:
- Auth flow (login/signup) working
- 3-tab navigation (Dashboard, Subscriptions, Upcoming)
- Dashboard with summary cards and currency conversion
- Subscription list with search, tag filtering, swipe actions
- Add/edit/delete subscriptions
- Upcoming payments with urgency-coded sections
- PDF statement import with AMEX + Hang Seng parsing
- Profile screen with sign out

## Day 3 Goals

### 1. App Icon
- Design or generate an app icon (1024x1024)
- Add to Assets.xcassets/AppIcon.appiconset
- Xcode auto-generates all required sizes

### 2. Launch Screen
- Simple branded launch screen (app name + icon)
- Uses the auto-generated launch storyboard

### 3. Polish & Bug Fixes
- Test all flows end-to-end on simulator
- Fix any UI rough edges (spacing, alignment, dark mode)
- Add error alerts when network calls fail
- Add haptic feedback on key actions (add, delete, toggle)

### 4. App Store Connect Prep
- Set app display name in Info.plist
- Write App Store description and keywords
- Take screenshots on iPhone 15 Pro and iPhone 15 Pro Max simulators
- Prepare privacy policy URL (required for apps with login)
- Set age rating

### 5. Archive & Submit
- In Xcode: Product → Archive
- Upload to App Store Connect
- Fill in app metadata
- Submit for review

## How to Start Day 3

1. Open this project in Claude Code
2. Say: **"Let's start Day 3"**
3. Mention any bugs or UI issues you noticed while testing
4. We'll work through polish, then prep for submission

## App Store Submission Checklist

Before submitting, make sure you have:
- [ ] Apple Developer account ($99/year) — enrolled and active
- [ ] App icon (1024x1024 PNG, no alpha channel)
- [ ] Screenshots for at least one device size
- [ ] App description (up to 4000 chars)
- [ ] Keywords (up to 100 chars)
- [ ] Privacy policy URL
- [ ] Support URL
- [ ] Category selected (Finance)
- [ ] Age rating completed
- [ ] Build uploaded via Xcode archive
