//
//  NotificationsSettingsView.swift
//  WaterPic
//
//  Created by Marius Bringsvor Rusten on 25/12/2024.
//

import SwiftUI

struct NotificationsSettingsView: View {
    @EnvironmentObject var sharedData: SharedData
    @State private var enableNotifications: Bool = true
    @State private var reminderInterval: Int = 2
    @State private var showSaveAlert = false

    var body: some View {
        ZStack {
            sharedData.selectedTheme.swiftBackgroundColor
                .ignoresSafeArea() // Background Color

            VStack(spacing: 20) {
                // Header
                Text("Notification Settings")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                    .padding(.top, 50)

                // Toggle for Notifications
                HStack {
                    Text("Enable Notifications")
                        .font(.headline)
                        .foregroundColor(sharedData.selectedTheme.swiftTextColor)

                    Spacer()

                    Toggle("", isOn: $enableNotifications)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                }
                .padding()
                .background(sharedData.selectedTheme.swiftRimColor)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.horizontal, 20)

                if enableNotifications {
                    // Reminder Interval Stepper
                    HStack {
                        Text("Reminder every \(reminderInterval) hour(s)")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(sharedData.selectedTheme.swiftTextColor)

                        Spacer()

                        Stepper("", value: $reminderInterval, in: 1...12)
                            .labelsHidden()
                    }
                    .padding()
                    .background(sharedData.selectedTheme.swiftRimColor)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding(.horizontal, 20)
                }

                Spacer()

                // Save Button
                Button(action: saveNotificationSettings) {
                    Text("Save Settings")
                        .font(.headline)
                        .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .alert(isPresented: $showSaveAlert) {
                    Alert(
                        title: Text("Settings Saved"),
                        message: Text("Your notification preferences have been updated."),
                        dismissButton: .default(Text("OK"))
                    )
                }

                Spacer()
            }
            .padding()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 60)
                .stroke(sharedData.selectedTheme.swiftRimColor, lineWidth: 25)
                .shadow(radius: 5)
                .ignoresSafeArea()
        )
    }

    private func saveNotificationSettings() {
        // Save to UserDefaults or update SharedData
        sharedData.saveToUserDefaults()
        showSaveAlert = true
    }
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsSettingsView()
            .environmentObject(SharedData())
    }
}
