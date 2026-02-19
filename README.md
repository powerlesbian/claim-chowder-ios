# Claim Chowder iOS

Native SwiftUI iOS app for tracking subscriptions and recurring payments. Companion to the [Claim Chowder PWA](https://claim-chowder.vercel.app/).

## Tech Stack

- **SwiftUI** — Native iOS UI framework
- **Supabase Swift SDK** — Authentication and PostgreSQL backend
- **Swift Package Manager** — Dependency management

## Project Structure

```
ClaimChowder/
├── ClaimChowderApp.swift              # App entry point (auth-gated routing)
├── ContentView.swift                  # Root view (auth check → login or main)
├── SupabaseClient.swift               # Supabase client configuration
├── Auth/
│   ├── AuthManager.swift              # Session management, signIn/Up/Out
│   └── AuthView.swift                 # Login & signup screen
├── Models/
│   └── Subscription.swift             # Data models (Subscription, enums)
├── Networking/
│   └── SubscriptionService.swift      # Supabase CRUD operations
└── Views/
    ├── SubscriptionListView.swift     # Main list with swipe actions
    ├── SubscriptionFormView.swift     # Add/edit subscription form
    ├── SubscriptionViewModel.swift    # State management & business logic
    └── ProfileView.swift             # User profile & sign out
```

## Features

### Implemented (Day 1)
- Email/password authentication via Supabase
- Subscription list with active/cancelled sections
- Add, edit, delete subscriptions
- Swipe actions (edit, cancel, reactivate, delete)
- Multi-currency support (HKD, SGD, USD)
- Frequency options (daily, weekly, monthly, yearly, one-off)
- Tag support (Personal, Business)
- Monthly cost summary
- Next payment date calculation
- Pull-to-refresh
- Profile screen with sign out

### Planned (Day 2)
- Dashboard with summary charts
- Upcoming payments view
- Category filtering
- PDF bank statement import via PDFKit

### Planned (Day 3)
- App icon and launch screen
- Offline caching with SwiftData
- Polish and device testing
- App Store submission

## Shared Backend

Both the PWA and iOS app share the same Supabase backend:
- PostgreSQL with Row-Level Security
- `subscriptions` table with per-user isolation
- Supabase Auth for user management

## Requirements

- Xcode 16+
- iOS 17+
- Swift 5.9+

## Setup

1. Clone the repo
2. Open `ClaimChowder/ClaimChowder.xcodeproj` in Xcode
3. Supabase credentials are preconfigured in `SupabaseClient.swift`
4. Build and run on simulator or device
