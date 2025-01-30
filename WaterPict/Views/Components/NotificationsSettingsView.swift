//
//  NotificationsSettingsView.swift
//  WaterPic
//
//  Created by Marius Bringsvor Rusten on 25/12/2024.
//

import SwiftUI
import UserNotifications

struct NotificationsSettingsView: View {
    @EnvironmentObject var sharedData: SharedData
    @State private var enableNotifications: Bool = true
    @State private var startHour: Date = Calendar.current.startOfDay(for: Date())
    @State private var endHour: Date = Calendar.current.date(byAdding: .hour, value: 12, to: Calendar.current.startOfDay(for: Date())) ?? Date()
    @State private var reminderInterval: Int = 2
    @State private var showSaveAlert = false

    var body: some View {
        ZStack {
            sharedData.selectedTheme.swiftBackgroundColor
                .ignoresSafeArea() // Background Color

            ScrollView {
                VStack(spacing: 20) {
                    if !sharedData.isPremiumUser {
                        BannerAdView(adUnitID: "ca-app-pub-2002393296074661/7345138591")
                            .frame(height: 50)
                            .padding(.horizontal)
                            .padding(.top, 20)
                    } else {
                        // Placeholder to maintain spacing
                        Color.clear
                            .frame(height: 50)
                            .padding(.horizontal)
                            .padding(.top, 20)
                    }
                    
                    // Header
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(sharedData.selectedTheme.swiftRimColor)
                            .padding(.horizontal)
                            .shadow(radius: 5)
                        Text("❗️ Notification Settings ❗️")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                            .padding()
                    }
                    // Enable Notifications Toggle
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
                    .padding(.horizontal)

                    if enableNotifications {
                        // Start Time and End Time
                        HStack(spacing: 20) {
                            VStack {
                                Text("Start Time")
                                    .font(.headline)
                                    .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                                DatePicker("", selection: $sharedData.startTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(WheelDatePickerStyle())
                                    .labelsHidden()
                                    .frame(width: UIScreen.main.bounds.width * 0.4) // Fit within the screen
                                    .clipped()
                            }

                            VStack {
                                Text("End Time")
                                    .font(.headline)
                                    .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                                DatePicker("", selection: $sharedData.endTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(WheelDatePickerStyle())
                                    .labelsHidden()
                                    .frame(width: UIScreen.main.bounds.width * 0.4) // Fit within the screen
                                    .clipped()
                            }
                        }
                        .padding()
                        .background(sharedData.selectedTheme.swiftRimColor)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal)

                        // Notification Interval
                        HStack {
                            Text("Notification interval:")
                                .font(.headline)
                                .foregroundColor(sharedData.selectedTheme.swiftTextColor)

                            Spacer()

                            HStack(spacing: 10) {
                                Button(action: { if reminderInterval > 1 { reminderInterval -= 1 } }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.title2)
                                }

                                Text("\(reminderInterval) hour(s)")
                                    .font(.headline)
                                    .foregroundColor(sharedData.selectedTheme.swiftTextColor)

                                Button(action: { reminderInterval += 1 }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title2)
                                }
                            }
                        }
                        .padding()
                        .background(sharedData.selectedTheme.swiftRimColor)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal)
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
                    .padding(.horizontal)
                    .alert(isPresented: $showSaveAlert) {
                        Alert(
                            title: Text("Settings Saved"),
                            message: Text("Your notification preferences have been updated."),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
            }
            .padding(.horizontal) // Ensure all content fits within the screen
        }
        .overlay(
            RoundedRectangle(cornerRadius: 60)
                .stroke(sharedData.selectedTheme.swiftRimColor, lineWidth: 25)
                .shadow(radius: 5)
                .ignoresSafeArea()
                .padding(.horizontal)
        )
    }

    private func saveNotificationSettings() {
        let startHourComponent = Calendar.current.component(.hour, from: startHour)
        let endHourComponent = Calendar.current.component(.hour, from: endHour)

        NotificationManager.shared.requestNotificationPermission { granted in
            if granted {
                NotificationManager.shared.scheduleNotifications(startHour: startHourComponent, endHour: endHourComponent, interval: reminderInterval)
            } else {
                print("Notification permissions not granted.")
            }
        }

        showSaveAlert = true
    }

    private func scheduleNotifications(startHour: Int, endHour: Int, interval: Int) {
        let center = UNUserNotificationCenter.current()

        // Remove existing notifications
        center.removeAllPendingNotificationRequests()

        for hour in stride(from: startHour, to: endHour, by: interval) {
            let content = UNMutableNotificationContent()
            content.sound = .default

            if hour == startHour {
                content.title = "Good Morning! 🌅"
                content.body = "Drink some water to start the day right! 💦"
            } else if hour + interval >= endHour {
                content.title = "Reminder! 🌙"
                content.body = "Drink some water before bed! 💦"
            } else {
                content.title = "Stay Hydrated! 💧"
                content.body = "Don't forget to drink water! 💦"
            }

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let identifier = "WaterNotification-\(hour)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            center.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsSettingsView()
            .environmentObject(SharedData())
    }
}
