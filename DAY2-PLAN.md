# Day 2 Plan — Claim Chowder iOS

## Where We Left Off (Day 1 Complete)

We replaced the WebView wrapper with a full native SwiftUI app:
- Auth flow (login/signup)
- Subscription list with swipe actions
- Add/edit/delete subscriptions
- Profile screen with sign out
- All wired to your existing Supabase backend

**Before starting Day 2**, make sure Day 1 builds in Xcode:
1. Open `ClaimChowder/ClaimChowder.xcodeproj`
2. Wait for SPM to resolve the Supabase package (may take a minute)
3. Build and run on simulator (Cmd+R)
4. Test: sign in with an existing account → you should see your subscriptions
5. Note any compile errors or issues to fix first

## Day 2 Goals

### 1. Dashboard View
- Summary cards: monthly total, active count, payments due this week
- Breakdown by currency (HKD, SGD, USD)
- Tab-based navigation (Dashboard / Subscriptions)

### 2. Upcoming Payments View
- List of next payments sorted by due date
- Color-coded urgency (red = due today, orange = this week, default = later)
- Integrated into the dashboard or as its own tab

### 3. Category Filtering
- Filter subscriptions by tag (Personal / Business)
- Search bar to find subscriptions by name

### 4. PDF Statement Import
- Use Swift's PDFKit to extract text from bank statement PDFs
- Parse transactions (matching your existing AMEX / Hang Seng parsers)
- Preview detected transactions before importing
- Document picker to select PDF from Files app

## How to Start Day 2

1. Open this project in Claude Code
2. Say: **"Let's start Day 2 — build the dashboard and upcoming payments"**
3. If there were any Xcode build errors from Day 1, mention them first so we can fix before moving on
4. We'll work through features one at a time, testing each before moving to the next

## Day 3 Preview (Final Day)

- App icon and launch screen
- Offline caching
- Device testing and polish
- App Store Connect screenshots
- Submit for review
