import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "chart.bar.fill",
            iconColor: .blue,
            title: "Track every expense",
            body: "Track every expense and subscription across multiple currencies, all in one place."
        ),
        OnboardingPage(
            icon: "square.and.arrow.up",
            iconColor: .green,
            title: "Your data, your backup",
            body: "Export your data as a CSV anytime and keep your own copy. You're always in control."
        ),
        OnboardingPage(
            icon: "lock.fill",
            iconColor: .orange,
            title: "Private by design",
            body: "Your data is stored securely and privately. It is only accessible to a dedicated support person if you explicitly request assistance — otherwise we never see it, and we never share it with anyone."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    hasSeenOnboarding = true
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding()
            }

            // Page content
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.blue : Color.secondary.opacity(0.3))
                        .frame(width: index == currentPage ? 20 : 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.bottom, 32)

            // Next / Get Started button
            Button {
                if currentPage < pages.count - 1 {
                    currentPage += 1
                } else {
                    hasSeenOnboarding = true
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let body: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 72))
                .foregroundStyle(page.iconColor)
                .padding(28)
                .background(page.iconColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 28))

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}
