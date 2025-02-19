//
//  EraseDataConfirmationView.swift
//  WaterPict
//
//  Created by Marius Bringsvor Rusten on 19/02/2025.
//


import SwiftUI

struct EraseDataConfirmationView: View {
    @EnvironmentObject var sharedData: SharedData
    @Environment(\.presentationMode) var presentationMode // To dismiss the sheet

    var body: some View {
        ZStack {
            sharedData.selectedTheme.swiftBackgroundColor
                .ignoresSafeArea()
            
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
                        
                        Text("⚠️ Reset All Data ⚠️")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                            .padding()
                    }
                    .padding(.top, 20)
                    
                    // Warning Message
                    Text("This will erase all your stored data including:")
                        .font(.headline)
                        .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        warningItem(text: "🖼 Stored images will be deleted")
                        warningItem(text: "📊 Water intake history will be erased")
                        warningItem(text: "🎯 All progress & goals will be reset")
                        warningItem(text: "💧 Daily goal & preferences will be removed")
                        warningItem(text: "🎨 Appearance settings will be reset")
                        warningItem(text: "🔔 Notification settings will be removed")
                    }
                    .padding()
                    .background(sharedData.selectedTheme.swiftRimColor)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    
                    Spacer()
                    
                    // Buttons
                    HStack(spacing: 20) {
                        cancelButton
                        eraseButton
                    }
                    .padding(.bottom, 20)
                    .padding(.horizontal)
                }
                .padding(.horizontal)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 60)
                    .stroke(sharedData.selectedTheme.swiftRimColor, lineWidth: 25)
                    .shadow(radius: 5)
                    .ignoresSafeArea()
            )
        }
    }
    
    // Helper for warning messages
    private func warningItem(text: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text(text)
                .foregroundColor(sharedData.selectedTheme.swiftTextColor)
        }
    }

    // Cancel Button
    private var cancelButton: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Text("Cancel")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray)
                .cornerRadius(10)
        }
    }

    // Erase Button
    private var eraseButton: some View {
        Button(action: {
            sharedData.resetAllData()
            presentationMode.wrappedValue.dismiss()
        }) {
            Text("Erase All Data")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .cornerRadius(10)
                .shadow(radius: 5)
        }
    }
}
