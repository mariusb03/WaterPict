//
//  DailyGoalView.swift
//  WaterPic
//
//  Created by Marius Bringsvor Rusten on 25/12/2024.
//

import SwiftUI

struct DailyGoalView: View {
    @EnvironmentObject var sharedData: SharedData
    @State private var newDailyGoal: String = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @Environment(\.presentationMode) var presentationMode // For dismissing the view

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
                    
                    VStack(spacing: 20) {
                        // Header
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(sharedData.selectedTheme.swiftRimColor)
                                .padding(.horizontal)
                                .shadow(radius: 5)
                            Text("💧 Set Your Daily Goal 💧")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                                .padding()
                        }
                        
                        // Current Goal
                        VStack(spacing: 10) {
                            Text("Current Daily Goal")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("\(String(format: "%.1f", sharedData.dailyGoal / 1000)) L")
                                .font(.system(size: 50, weight: .bold, design: .rounded))
                                .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                        }
                        .padding()
                        
                        // Input Field
                        Text("Enter New Goal (Liters)")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                            .padding(.top, 20)
                        
                        TextField("e.g., 2.5", text: $newDailyGoal)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        // Save Button
                        Button(action: saveGoal) {
                            Text("Save Goal")
                                .font(.headline)
                                .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .presentationCornerRadius(60)
                    .background(sharedData.selectedTheme.swiftBackgroundColor.edgesIgnoringSafeArea(.all))
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text(alertTitle),
                            message: Text(alertMessage),
                            dismissButton: .default(Text("OK"), action: {
                                if alertTitle == "Success" {
                                    presentationMode.wrappedValue.dismiss() // Dismiss the view on success
                                }
                            })
                        )
                    }
                    .onTapGesture {
                        hideKeyboard()
                    } // Dismiss keyboard on tap outside
                }
                
            }
            .overlay(
                RoundedRectangle(cornerRadius: 60)
                    .stroke(sharedData.selectedTheme.swiftRimColor, lineWidth: 25)
                    .shadow(radius: 5)
                    .ignoresSafeArea()
            )
        }
    }

    private func saveGoal() {
        if let newGoalInLiters = Double(newDailyGoal.replacingOccurrences(of: ",", with: ".")), newGoalInLiters > 0 {
            sharedData.dailyGoal = newGoalInLiters * 1000 // Convert to milliliters
            sharedData.saveToUserDefaults() // Save immediately

            alertTitle = "Success"
            alertMessage = String(format: "Daily Goal updated to %.1f liters!", newGoalInLiters)
        } else {
            alertTitle = "Invalid Input"
            alertMessage = "Please enter a valid number greater than 0."
        }
        showAlert = true
    }

    // Helper to hide the keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct DailyGoalView_Previews: PreviewProvider {
    static var previews: some View {
        DailyGoalView()
            .environmentObject(SharedData())
    }
}
