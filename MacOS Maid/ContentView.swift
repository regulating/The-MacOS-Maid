import SwiftUI
import AppKit // Needed for NSVisualEffectView and related types
import Foundation

// MARK: - Main Content View Structure

struct ContentView: View {
    @State private var currentStage: AppStage = .welcome
    @State private var transition: AnyTransition = .opacity // Default transition

    var body: some View {
        ZStack {
            // Background blur
            AppKitVisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                .edgesIgnoringSafeArea(.all)

            // View switching logic
            Group {
                switch currentStage {
                case .welcome:
                    WelcomeView { // Action to perform on continue
                        // Set up transition *before* changing stage
                        transition = .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                        currentStage = .terms
                    }
                case .terms:
                    TermsView { // Action to perform on continue
                        transition = .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .scale(scale: 0.9).combined(with: .opacity)
                        )
                        currentStage = .main
                    }
                case .main:
                    MainAppView()
                }
            }
            .transition(transition) // Apply the currently set transition
            // Smooth animation for stage changes
            .animation(.interpolatingSpring(stiffness: 100, damping: 15), value: currentStage)
        }
        .frame(minWidth: 800, minHeight: 600) // Sensible minimum size
    }
}

// MARK: - App Stages Enum

enum AppStage {
    case welcome, terms, main
}

// MARK: - Welcome View

struct WelcomeView: View {
    var onContinue: () -> Void // Callback to advance stage
    @State private var isIconAnimating = false
    @State private var showContent = false // For staggered appearance

    let brandGradient = LinearGradient(
        gradient: Gradient(colors: [Color.accentColor, Color.cyan.opacity(0.8)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Animated Icon & Title
            VStack(spacing: 20) {
                ZStack {
                    // Pulsating background glow
                    Circle()
                        .fill(brandGradient)
                        .frame(width: 120, height: 120)
                        .blur(radius: isIconAnimating ? 30 : 20)
                        .opacity(isIconAnimating ? 0.6 : 0.4)
                        .scaleEffect(isIconAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isIconAnimating)

                    // Main Icon
                    Image(systemName: "wand.and.stars")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        .rotationEffect(.degrees(isIconAnimating ? -10 : 10))
                        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(0.1), value: isIconAnimating)
                }
                .onAppear { isIconAnimating = true }

                Text("macOS Maid")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(brandGradient)
                    .shadow(color: .black.opacity(0.1), radius: 3, y: 2)

                Text("Your Personal Mac Butler")
                    .font(.title2.weight(.medium))
                    .foregroundColor(.primary.opacity(0.8))
            }
            .scaleEffect(showContent ? 1 : 0.9)
            .opacity(showContent ? 1 : 0)

            Text("Effortlessly clean, optimise, and secure your Mac. Keep your system pristine and performing at its best.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 80)
                .fixedSize(horizontal: false, vertical: true) // Allow text wrapping
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: showContent)

            Spacer()
            Spacer()

            // Continue Button
            PremiumButton(label: "Get Started", systemImage: "arrow.right.circle.fill", action: onContinue)
                .padding(.bottom, 50)
                .scaleEffect(showContent ? 1 : 0.9)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: showContent)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .onAppear {
            // Trigger staggered animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }
        }
    }
}

// MARK: - Terms View (FIXED SCROLL DETECTION)

struct TermsView: View {
    var onContinue: () -> Void
    @State private var hasReachedBottom = false

    // Adaptive color for scroll fade effect
    private var gradientFadeColor: Color { Color(.windowBackgroundColor) }

    var body: some View {
        VStack(spacing: 25) {
            // Header
            VStack(spacing: 8) {
                Text("Terms of Service")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient(
                        colors: [Color.accentColor, Color.cyan],
                        startPoint: .leading,
                        endPoint: .trailing))

                Text("Please review carefully before proceeding")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 30)

            // Scrollable Terms Content
            // GeometryReader reads the available size for the ScrollView
            GeometryReader { fullViewGeo in
                ScrollViewReader { scrollProxy in // Allows programmatic scrolling (not used here, but often useful)
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 20) {
                            // Your terms content here
                            ForEach(0..<7) { index in // Example content
                                TermsSectionView(index: index + 1, text: sampleTermsText)
                            }

                            // --- BOTTOM DETECTOR ---
                            // Invisible marker at the end of the scrollable content.
                            Color.clear
                                .frame(height: 1) // Must have non-zero height
                                .overlay(
                                    // GeometryReader reads the marker's position
                                    GeometryReader { markerGeo in
                                        Color.clear // The view that triggers the checks
                                            .onAppear { // Check when marker first appears
                                                checkIfAtBottom(markerFrame: markerGeo.frame(in: .global),
                                                                scrollViewFrame: fullViewGeo.frame(in: .global))
                                            }
                                            // Also check when marker's frame changes (robust!)
                                            .onChange(of: markerGeo.frame(in: .global)) { newMarkerFrame in
                                                 checkIfAtBottom(markerFrame: newMarkerFrame,
                                                                 scrollViewFrame: fullViewGeo.frame(in: .global))
                                            }
                                    }
                                )
                            // --- END BOTTOM DETECTOR ---

                        } // End Content VStack
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                    } // End ScrollView
                    // Styling for the ScrollView container
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                           .fill(Material.ultraThick)
                           .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    )
                    .overlay( // Subtle border
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                    )
                    // Fade effect at the bottom when not scrolled to end
                    .overlay(alignment: .bottom) {
                        LinearGradient(colors: [.clear, gradientFadeColor.opacity(0.9), gradientFadeColor], startPoint: .top, endPoint: .bottom)
                            .frame(height: 50)
                            .allowsHitTesting(false) // Don't block clicks
                            .opacity(hasReachedBottom ? 0 : 1)
                            .animation(.easeInOut, value: hasReachedBottom)
                    }
                    // Scroll down indicator
                    .overlay(alignment: .bottom) {
                        ScrollIndicatorView()
                            .opacity(hasReachedBottom ? 0 : 1)
                            .animation(.easeInOut(duration: 0.5), value: hasReachedBottom)
                            .padding(.bottom, 15)
                            .allowsHitTesting(false)
                    }
                } // End ScrollViewReader
            } // End GeometryReader (fullViewGeo)
            .padding(.horizontal, 40) // Padding around the scroll view

            // Accept Button & Helper Text
            VStack(spacing: 10) {
                 PremiumButton(
                     label: "Agree and Continue",
                     systemImage: "checkmark.seal.fill",
                     isEnabled: hasReachedBottom, // Enabled only when scrolled to bottom
                     action: onContinue
                 )

                Text(hasReachedBottom ? "Thank you!" : "Scroll to the end to agree")
                    .font(.caption)
                    .foregroundColor(hasReachedBottom ? .green : .secondary)
                    .animation(.easeInOut, value: hasReachedBottom) // Animate color change
            }
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // Function to check scroll position
    private func checkIfAtBottom(markerFrame: CGRect, scrollViewFrame: CGRect) {
        // Only proceed if we haven't already detected the bottom
        guard !hasReachedBottom else { return }

        let buffer: CGFloat = 10 // Small tolerance

        // Check if the marker's bottom edge is at or below the scroll view's visible bottom edge
        if markerFrame.maxY.rounded() <= scrollViewFrame.maxY.rounded() + buffer {
            // Update state on the main thread with animation
            DispatchQueue.main.async {
                 withAnimation(.easeInOut) {
                     hasReachedBottom = true
                 }
            }
        }
    }

    // Placeholder text
    private let sampleTermsText = """
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    """
}

// Helper View for Terms Section
struct TermsSectionView: View {
    let index: Int
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Section \(index): Important Clause")
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)
            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
}

// Helper View for Scroll Down Indicator
struct ScrollIndicatorView: View {
    @State private var isAnimating = false
    var body: some View {
        VStack(spacing: 3) {
            Text("Scroll Down")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
            Image(systemName: "chevron.down")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.accentColor)
                .offset(y: isAnimating ? 5 : 0) // Bounce animation
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
                .onAppear { isAnimating = true }
        }
        .padding(8)
        .background(.regularMaterial, in: Capsule())
    }
}


// MARK: - Main Application View

struct MainAppView: View {
    // Enum for tab identification
    enum Tab {
        case dashboard, clean, optimise, privacy, settings
    }

    @State private var selectedTab: Tab = .dashboard
    @State private var systemStatus: (message: String, color: Color, icon: String) = ("System Health: Good", .green, "checkmark.circle.fill")
    @State private var isPerformingAction = false // Indicates if a task like scanning is running
    @State private var actionProgress: Double = 0.0 // For ProgressView (0.0 to 1.0)

    // Define features, linking them to tabs via their ID
    private let features = [
        FeatureInfo(id: .clean, title: "Cache & Junk", icon: "trash.circle.fill", description: "Clear temp files, logs, and app caches.", color: .blue),
        FeatureInfo(id: .optimise, title: "System Speedup", icon: "hare.fill", description: "Optimise settings and manage startup items.", color: .orange),
        FeatureInfo(id: .privacy, title: "Privacy Guard", icon: "lock.shield.fill", description: "Secure browser history and app permissions.", color: .red),
        FeatureInfo(id: .settings, title: "App Settings", icon: "gearshape.fill", description: "Configure macOS Maid preferences.", color: .gray)
    ]

    var body: some View {
        // Standard macOS sidebar layout
        HSplitView {
            SidebarView(selectedTab: $selectedTab)
                .frame(minWidth: 200, idealWidth: 220, maxWidth: 300) // Sidebar size constraints

            // Main content area changes based on selected tab
            MainContentView(
                selectedTab: $selectedTab,
                systemStatus: $systemStatus,
                isPerformingAction: $isPerformingAction,
                actionProgress: $actionProgress,
                features: features,
                performScanAction: startSimulatedScan // Pass the action function
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill remaining space
        }
        // Optional: Apply background to the whole split view container
        // .background(AppKitVisualEffectView(material: .windowBackground, blendingMode: .behindWindow))
    }

    // Example action (replace with real logic)
    func startSimulatedScan() {
        isPerformingAction = true
        actionProgress = 0.0
        systemStatus = ("Scanning...", .orange, "magnifyingglass")

        // Simulate work being done over time
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            actionProgress += 0.02
            if actionProgress >= 1.0 {
                timer.invalidate() // Stop timer
                isPerformingAction = false
                systemStatus = ("Scan Complete: Optimised!", .green, "checkmark.circle.fill")
                actionProgress = 0 // Reset progress for visual clarity if needed
            }
        }
    }
}

// MARK: - Sidebar (Navigation)

//struct SidebarView: View {
//    @Binding var selectedTab: MainAppView.Tab
//
//    let brandGradient = LinearGradient(
//        gradient: Gradient(colors: [Color.accentColor, Color.cyan.opacity(0.8)]),
//        startPoint: .topLeading,
//        endPoint: .bottomTrailing
//    )
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            // App Title Area
//            HStack {
//                Image(systemName: "wand.and.stars.inverse")
//                     .resizable()
//                     .scaledToFit()
//                     .frame(width: 28, height: 28)
//                     .foregroundStyle(brandGradient)
//                     .padding(8)
//                     .background(.ultraThinMaterial, in: Circle())
//
//                Text("macOS Maidddd")
//                    .font(.title3.weight(.bold))
//                    .foregroundStyle(.primary)
//                Spacer()
//            }
//            .padding()
//            .padding(.bottom, 10)

// Get the short username from the system
func getMacUsername() -> String {
    return NSUserName()
}

struct SidebarView: View {
    @Binding var selectedTab: MainAppView.Tab

    let brandGradient = LinearGradient(
        gradient: Gradient(colors: [Color.accentColor, Color.cyan.opacity(0.8)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App Title Area
            HStack {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(brandGradient)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())

                Text(getMacUsername().capitalized)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding()
            .padding(.bottom, 10)

            // Navigation Links
            SidebarButton(icon: "gauge.high", label: "Dashboard", tab: .dashboard, selectedTab: $selectedTab)
            SidebarButton(icon: "trash", label: "Clean", tab: .clean, selectedTab: $selectedTab)
            SidebarButton(icon: "bolt", label: "Optimise", tab: .optimise, selectedTab: $selectedTab)
            SidebarButton(icon: "shield.lefthalf.filled", label: "Privacy", tab: .privacy, selectedTab: $selectedTab)

            Spacer() // Pushes Settings to the bottom

            Divider().padding(.horizontal)

            SidebarButton(icon: "gear", label: "Settings", tab: .settings, selectedTab: $selectedTab)
                .padding(.bottom, 10)
        }
        // Apply visual effect background to the sidebar itself
        .background(AppKitVisualEffectView(material: .sidebar, blendingMode: .behindWindow))
    }
}

// Reusable Sidebar Button Component
struct SidebarButton: View {
    let icon: String
    let label: String
    let tab: MainAppView.Tab
    @Binding var selectedTab: MainAppView.Tab
    @State private var isHovering = false

    var isSelected: Bool { selectedTab == tab }

    var body: some View {
        Button { // Action: Change selected tab
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 24) // Align icons
                    .foregroundColor(isSelected ? .white : .secondary)

                Text(label)
                    .font(.headline.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .primary)

                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background { // Dynamic background for selection/hover
                ZStack {
                    // Selection highlight (Accent Color)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor)
                        .opacity(isSelected ? 1.0 : 0)

                    // Hover highlight (Subtle Gray) - only show if not selected
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.1))
                        .opacity(isHovering && !isSelected ? 1.0 : 0)
                }
                .padding(.horizontal, 8) // Indent the background slightly
            }
            .contentShape(Rectangle()) // Make entire area tappable
        }
        .buttonStyle(.plain) // Use plain style for custom background handling
        .onHover { hovering in // Detect mouse hover
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovering = hovering
            }
        }
        .scaleEffect(isHovering && !isSelected ? 0.98 : 1.0) // Subtle press effect on hover
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
        .animation(.easeInOut(duration: 0.2), value: isSelected) // Animate selection state change
    }
}


// MARK: - Main Content Area (Switches based on Tab)

struct MainContentView: View {
    @Binding var selectedTab: MainAppView.Tab
    @Binding var systemStatus: (message: String, color: Color, icon: String)
    @Binding var isPerformingAction: Bool
    @Binding var actionProgress: Double
    let features: [FeatureInfo]
    let performScanAction: () -> Void // Passed in from MainAppView

    var body: some View {
        VStack(spacing: 0) { // No spacing between status bar and content
            // Top Status Bar
            TopStatusBar(systemStatus: $systemStatus)

            // Tab Content Area
            Group { // Group allows applying modifiers to the switched views
                switch selectedTab {
                case .dashboard:
                    DashboardView(
                        isPerformingAction: $isPerformingAction,
                        actionProgress: $actionProgress,
                        features: features,
                        performScanAction: performScanAction
                    )
                case .clean:
                    GenericTabView(title: "Clean Tools", icon: "trash.fill")
                case .optimise:
                    GenericTabView(title: "Optimisation", icon: "bolt.fill")
                case .privacy:
                    GenericTabView(title: "Privacy Settings", icon: "shield.lefthalf.filled")
                case .settings:
                    GenericTabView(title: "Application Settings", icon: "gearshape.fill")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill available space
            // Subtle transition between tabs
            .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            .animation(.easeInOut(duration: 0.2), value: selectedTab)

        }
        // Background for the main content area (distinct from sidebar)
        .background(AppKitVisualEffectView(material: .windowBackground, blendingMode: .behindWindow))
    }
}

// Top Status Bar Component
struct TopStatusBar: View {
    @Binding var systemStatus: (message: String, color: Color, icon: String)

    var body: some View {
        HStack {
            // Display current system status
            Label(systemStatus.message, systemImage: systemStatus.icon)
                .font(.headline)
                .foregroundColor(systemStatus.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(systemStatus.color.opacity(0.15), in: Capsule())
                .animation(.easeInOut, value: systemStatus.message) // Animate text changes

            Spacer()

            // Example: Help Button
            Button { /* Help action */ } label: {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Get Help") // Tooltip
        }
        .padding()
        .overlay(alignment: .bottom) { Divider() } // Bottom border
        // Optional distinct background for the status bar
        // .background(.thinMaterial)
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    @Binding var isPerformingAction: Bool
    @Binding var actionProgress: Double // 0.0 to 1.0
    let features: [FeatureInfo]
    let performScanAction: () -> Void

    // Layout for the feature cards
    let gridColumns = [
        GridItem(.flexible(minimum: 200), spacing: 20),
        GridItem(.flexible(minimum: 200), spacing: 20)
    ]

    var body: some View {
        ScrollView { // Make dashboard content scrollable if needed
            VStack(alignment: .leading, spacing: 30) {
                Text("System Dashboard")
                    .font(.largeTitle.weight(.bold))
                    .padding(.bottom, 10)

                // Quick Scan Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Quick Scan")
                        .font(.title2.weight(.semibold))

                    if isPerformingAction { // Show progress bar
                        VStack(spacing: 8) {
                            ProgressView(value: actionProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color.accentColor))
                                .frame(height: 8)
                                .animation(.easeInOut, value: actionProgress)

                            Text("Working... \(Int(actionProgress * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else { // Show description and scan button
                        Text("Perform a quick scan to check system health and find easy optimisations.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        PremiumButton(
                             label: "Start Quick Scan",
                             systemImage: "play.circle.fill",
                             action: performScanAction
                         )
                         .padding(.top, 5)
                    }
                }
                .padding(20)
                .background(Material.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.primary.opacity(0.1), lineWidth: 1))

                // Features Grid Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Core Features")
                        .font(.title2.weight(.semibold))

                    LazyVGrid(columns: gridColumns, spacing: 20) {
                        ForEach(features) { feature in
                            FeatureCard(feature: feature)
                                .onTapGesture {
                                    print("Tapped on \(feature.title)")
                                    // TODO: Navigate to the feature's tab or perform its action
                                }
                        }
                    }
                }

                Spacer() // Pushes content upwards

            }
            .padding(30) // Padding around the entire dashboard content
        }
    }
}


// MARK: - Placeholder View for Other Tabs

struct GenericTabView: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.secondary.opacity(0.5))
            Text(title)
                .font(.largeTitle.weight(.semibold))
                .foregroundColor(.secondary)
            Text("Detailed controls and information for this section will be available here.")
                .font(.title3)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 50)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}


// MARK: - Supporting Components & Models

// MARK: Premium Button Style

struct PremiumButton: View {
    var label: String
    var systemImage: String
    var isEnabled: Bool = true
    var action: () -> Void

    @State private var isHovering = false

    // Dynamic gradient based on enabled state
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: isEnabled
                ? [Color.accentColor, Color.accentColor.opacity(0.7), Color.cyan.opacity(0.8)]
                : [Color.gray.opacity(0.5), Color.gray.opacity(0.3)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.medium))
                Text(label)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(minWidth: 180)
            .foregroundColor(isEnabled ? .white : .white.opacity(0.6))
            .background(backgroundGradient)
            .clipShape(Capsule())
            .shadow(color: isEnabled ? Color.accentColor.opacity(isHovering ? 0.5 : 0.3) : .clear,
                    radius: isEnabled ? (isHovering ? 12 : 8) : 0, // Enhanced shadow on hover
                    y: isEnabled ? (isHovering ? 6 : 4) : 0)
            .overlay( // Subtle inner glow on hover
                Capsule()
                    .stroke(Color.white.opacity(isHovering && isEnabled ? 0.3 : 0), lineWidth: 1.5)
                    .blur(radius: 2)
            )
            .scaleEffect(isHovering && isEnabled ? 1.04 : 1.0) // Scale effect on hover
            .opacity(isEnabled ? 1.0 : 0.6) // Dim when disabled
        }
        .buttonStyle(PlainButtonStyle()) // Needed for custom background/overlay
        .disabled(!isEnabled)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { // Springy hover animation
                isHovering = hovering && isEnabled
            }
        }
    }
}

// MARK: Feature Card

struct FeatureCard: View {
    var feature: FeatureInfo
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: feature.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(feature.color) // Use feature's color
                    .frame(width: 30, alignment: .leading)

                Spacer()

                // Indicator arrow shows on hover
                Image(systemName: "arrow.forward.circle.fill")
                    .foregroundColor(feature.color.opacity(0.7))
                    .font(.title3)
                    .opacity(isHovering ? 1 : 0)
                    .scaleEffect(isHovering ? 1 : 0.8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)

                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2) // Limit description lines
                    .fixedSize(horizontal: false, vertical: true) // Allow wrapping
            }
            Spacer() // Push content to top
        }
        .padding(18)
        .frame(minHeight: 120)
        .background(.regularMaterial) // Card background material
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay( // Border highlights on hover
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.primary.opacity(isHovering ? 0.2 : 0.1), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(isHovering ? 0.12 : 0.06), // Shadow enhances on hover
                radius: isHovering ? 10 : 6,
                y: isHovering ? 5 : 3)
        .scaleEffect(isHovering ? 1.03 : 1.0) // Scale effect on hover
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isHovering) // Spring animation
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Data Models

// Info for displaying feature cards and linking to tabs
struct FeatureInfo: Identifiable {
    var id: MainAppView.Tab // Use Tab enum for ID
    var title: String
    var icon: String
    var description: String
    var color: Color // Color for visual identity
}


// MARK: - Visual Effect View Helper (macOS Blur)

struct AppKitVisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.state = .active // Ensure effect is active
        view.material = material
        view.blendingMode = blendingMode
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview different states/components
        Group {
            ContentView() // Start at Welcome
                .previewDisplayName("Full App Flow")

            TermsView(onContinue: {}) // Just Terms view
                 .previewDisplayName("Terms View Only")
                 .frame(width: 800, height: 600)
                 .environment(\.colorScheme, .dark) // Example: Preview dark mode

            MainAppView() // Just Main App view
                 .previewDisplayName("Main App View Only")
                 .frame(width: 800, height: 600)

            SidebarButton(icon: "gauge.high", label: "Dashboard", tab: .dashboard, selectedTab: .constant(.dashboard))
                 .padding()
                 .background(Color.black.opacity(0.2)) // Add background for contrast
                 .previewDisplayName("Sidebar Button (Selected)")

            SidebarButton(icon: "trash", label: "Clean", tab: .clean, selectedTab: .constant(.dashboard))
                 .padding()
                 .background(Color.black.opacity(0.2))
                 .previewDisplayName("Sidebar Button (Deselected)")

            FeatureCard(feature: FeatureInfo(id: .clean, title: "Cache & Junk", icon: "trash.circle.fill", description: "Clear temp files, logs, and app caches.", color: .blue))
                 .padding()
                 .previewDisplayName("Feature Card")
                 .frame(width: 250)

             PremiumButton(label: "Test Button", systemImage: "star.fill", action: {})
                  .padding()
                  .previewDisplayName("Premium Button Enabled")

            PremiumButton(label: "Disabled", systemImage: "xmark.octagon.fill", isEnabled: false, action: {})
                  .padding()
                  .previewDisplayName("Premium Button Disabled")
        }
    }
}

// Note: Removed the NSVisualEffectView.Material.color extension as it wasn't actively used
// and provides only approximations. It's better to use actual Material backgrounds or
// adaptive colors like Color(.windowBackgroundColor) directly where needed.

// Note: Removed ScrollOffsetPreferenceKey as it wasn't used in the final scroll detection logic.
