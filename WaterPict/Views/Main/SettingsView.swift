//
//  SettingsView.swift
//  WaterPic
//
//  Created by Marius Rusten on 03/12/2024.
//

import SwiftUI

enum ActiveSheet: Identifiable {
    case dailyGoal
    case preferredAmount
    case appearance
    case notifications
    case helpSupport
    case resetData
    


    var id: Int { hashValue }
}

struct SettingsView: View {
    @EnvironmentObject var sharedData: SharedData
    @Binding var preferredAmount: Double
    @Binding var showInvalidInputAlert: Bool
    @Binding var invalidInputMessage: String
    @Binding var selectedTheme: Theme

    @State private var activeSheet: ActiveSheet? = nil
    @State private var showEraseDataSheet = false
    @State private var showRestoreSuccessAlert = false
    @State private var restoreErrorMessage: String = ""
    @State private var showRestoreErrorAlert = false

    var body: some View {
        ScrollView {
            ZStack {
                sharedData.selectedTheme.swiftBackgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if !sharedData.isPremiumUser {
                        BannerAdView(adUnitID: "ca-app-pub-2002393296074661/7345138591")
                            .frame(height: 50)
                            .padding(.horizontal)
                    } else {
                        // Placeholder to maintain spacing
                        Color.clear
                            .frame(height: 50)
                            .padding(.horizontal)
                    }
                    
                    settingsHeader
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(SettingsOption.allCases, id: \.self) { option in
                            settingsAction(option: option) {
                                handleAction(for: option)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    restorePurchasesButton
                    
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
                    case .resetData:
                                EraseDataConfirmationView()
                                    .environmentObject(sharedData)
                                    .presentationCornerRadius(60) // Matches other sheets
                    }
                }
                
                .alert("Restore Successful", isPresented: $showRestoreSuccessAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Your purchases have been successfully restored.")
                }
                .alert("Restore Failed", isPresented: $showRestoreErrorAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(restoreErrorMessage)
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

    // MARK: Restore Purchases Button
    private var restorePurchasesButton: some View {
        Button(action: restorePurchases) {
            Text("Restore Purchases")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.horizontal)
        }
    }

    // MARK: Restore Purchases Action
    private func restorePurchases() {
        Task {
            do {
                try await SubscriptionManager.shared.restorePurchases()
                showRestoreSuccessAlert = true
                sharedData.updateSubscriptionStatus()
            } catch {
                restoreErrorMessage = error.localizedDescription
                showRestoreErrorAlert = true
            }
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
            activeSheet = .dailyGoal
        case .preferredAmount:
            activeSheet = .preferredAmount
        case .appearance:
            activeSheet = .appearance
        case .notifications:
            activeSheet = .notifications
        case .resetData:
            activeSheet = .resetData
        case .helpSupport:
            activeSheet = .helpSupport
        }
    }
    
    // MARK: Haptic Feedback
    private func hapticFeedback() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
