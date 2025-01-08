//
//  SettingsView.swift
//  WaterPic
//
//  Created by Marius Rusten on 03/12/2024.
//

import SwiftUI

// Define the ActiveSheet enum
enum ActiveSheet: Identifiable {
    case dailyGoal
    case preferredAmount
    case appearance
    case notifications
    case helpSupport

    var id: Int { hashValue }
}

struct SettingsView: View {
    @EnvironmentObject var sharedData: SharedData
    @Binding var preferredAmount: Double
    @Binding var showInvalidInputAlert: Bool
    @Binding var invalidInputMessage: String
    @Binding var selectedTheme: Theme

    @State private var activeSheet: ActiveSheet? = nil
    @State private var showEraseDataAlert = false
    @State private var showSuccessAlert = false

    var body: some View {
        ScrollView {
            ZStack {
                sharedData.selectedTheme.swiftBackgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    BannerAdView(adUnitID: "ca-app-pub-2002393296074661/7345138591")
                        .frame(height: 50)
                        .padding(.horizontal)
                    
                    settingsHeader
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(SettingsOption.allCases, id: \.self) { option in
                            settingsAction(option: option) {
                                handleAction(for: option)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Text("App Version: 1.0.0")
                        .font(.footnote)
                        .foregroundColor(sharedData.selectedTheme.swiftTextColor.opacity(0.7))
                        .padding(.top, 20)
                    
                    Spacer()
                }
                
                .sheet(item: $activeSheet) { sheet in
                    switch sheet {
                    case .dailyGoal:
                        DailyGoalView()
                            .presentationCornerRadius(60)
                    case .preferredAmount:
                        PreferredAmountView()
                            .presentationCornerRadius(60)
                    case .appearance:
                        AppearanceSettingsView(selectedTheme: $sharedData.selectedTheme)
                            .presentationCornerRadius(60)
                    case .notifications:
                        NotificationsSettingsView()
                            .presentationCornerRadius(60)
                    case .helpSupport:
                        HelpSupportView()
                            .presentationCornerRadius(60)
                    }
                }
                .alert(isPresented: $showEraseDataAlert) {
                    Alert(
                        title: Text("Erase All Data"),
                        message: Text("Are you sure you want to reset all app data? This action cannot be undone."),
                        primaryButton: .destructive(Text("Erase")) {
                            sharedData.resetAllData()
                            showSuccessAlert = true
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: Settings Header
    private var settingsHeader: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(sharedData.selectedTheme.swiftRimColor)
                .padding(.horizontal)
                .shadow(radius: 5)
            Text("⚙️ Settings ⚙️")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                .padding(.vertical)
        }
    }

    // MARK: Settings Action
    private func settingsAction(option: SettingsOption, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack {
                Image(systemName: option.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
                    .padding()
                    .background(option.color)
                    .cornerRadius(20)
                
                Text(option.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: 120)
            .background(option.color.opacity(0.2))
            .cornerRadius(20)
            .shadow(radius: 5)
        }
        .shadow(radius: 5)
    }

    // MARK: Handle Action
    private func handleAction(for option: SettingsOption) {
        hapticFeedback()
        switch option {
        case .dailyGoal:
            animatePress { activeSheet = .dailyGoal }
        case .preferredAmount:
            animatePress { activeSheet = .preferredAmount }
        case .appearance:
            animatePress { activeSheet = .appearance }
        case .notifications:
            animatePress { activeSheet = .notifications }
        case .resetData:
            showEraseDataAlert = true
        case .helpSupport:
            animatePress { activeSheet = .helpSupport }
        }
    }
    
    // MARK: Haptic Feedback
    private func hapticFeedback() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    // MARK: Animate Press
    private func animatePress(action: @escaping () -> Void) {
        withAnimation(.easeInOut(duration: 2)) {
            action()
        }
    }
}

// MARK: Settings Option
enum SettingsOption: CaseIterable {
    case dailyGoal
    case preferredAmount
    case appearance
    case notifications
    case resetData
    case helpSupport
    
    var title: String {
        switch self {
        case .dailyGoal: return "Daily Goal"
        case .preferredAmount: return "Preferred +/-"
        case .appearance: return "Appearance"
        case .notifications: return "Notifications"
        case .resetData: return "Reset Data"
        case .helpSupport: return "Help & Support"
        }
    }
    
    var iconName: String {
        switch self {
        case .dailyGoal: return "target"
        case .preferredAmount: return "plusminus.circle"
        case .appearance: return "paintbrush"
        case .notifications: return "bell"
        case .resetData: return "trash"
        case .helpSupport: return "questionmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .dailyGoal: return .blue
        case .preferredAmount: return .green
        case .appearance: return .purple
        case .notifications: return .orange
        case .resetData: return .red
        case .helpSupport: return .yellow
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SharedData())
}
