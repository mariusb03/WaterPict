//
//  PreferredAmountView.swift
//  WaterPic
//
//  Created by Marius Bringsvor Rusten on 25/12/2024.
//

import SwiftUI

struct PreferredAmountView: View {
    @EnvironmentObject var sharedData: SharedData
    @State private var newPreferredAmount: String = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            sharedData.selectedTheme.swiftBackgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    BannerAdView(adUnitID: "ca-app-pub-2002393296074661/7345138591")
                        .frame(height: 50)
                        .padding(.horizontal)
                        .padding(.top,20)
                    
                    headerSection
                    currentPreferredIncrementSection
                    premadeOptionsSection
                    customAmountSection
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(sharedData.selectedTheme.swiftBackgroundColor.edgesIgnoringSafeArea(.all))
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text(alertTitle),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
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

    // MARK: - Header Section
    private var headerSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(sharedData.selectedTheme.swiftRimColor)
                .padding(.horizontal)
                .shadow(radius: 5)
            Text("Set Preferred Increment")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                .padding()
        }
    }
    // MARK: - Current Preferred Increment Section
    private var currentPreferredIncrementSection: some View {
        VStack(spacing: 10) {
            Text("Current Preferred Increment")
                .font(.headline)
                .foregroundColor(sharedData.selectedTheme.swiftTextColor.opacity(0.8))
            Text("\(formattedPreferredAmount()) L")
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .foregroundColor(sharedData.selectedTheme.swiftTextColor)
        }
        .padding()
    }

    // MARK: - Premade Options Section
    private var premadeOptionsSection: some View {
        HStack(spacing: 20) {
            ForEach([0.2, 0.5, 1.0, 1.5], id: \.self) { amount in
                premadeOptionButton(for: amount)
            }
        }
        .padding(.horizontal, 20)
    }

    private func premadeOptionButton(for amount: Double) -> some View {
        Button(action: {
            updatePreferredAmount(to: amount * 1000) // Convert liters to milliliters
        }) {
            VStack {
                Image(systemName: "drop.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
                Text("\(String(format: "%.1f", amount)) L")
                    .font(.headline)
                    .foregroundColor(.black)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Custom Amount Section
    private var customAmountSection: some View {
        VStack(spacing: 10) {
            Text("Enter Custom Amount (Liters)")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(sharedData.selectedTheme.swiftTextColor)

            TextField("Enter Value", text: $newPreferredAmount)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Button(action: saveCustomPreferredAmount) {
                Text("Save Preferred Amount")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Scale Button Style
    struct ScaleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
        }
    }

    // MARK: - Helper Functions
    private func formattedPreferredAmount() -> String {
        String(format: "%.1f", sharedData.preferredAmount / 1000)
    }

    private func updatePreferredAmount(to amount: Double) {
        sharedData.preferredAmount = amount
        sharedData.saveToUserDefaults()
        let formattedAmount = String(format: "%.1f", amount / 1000)
        showAlert(title: "Success", message: "Preferred amount updated to \(formattedAmount) liters!")
    }

    private func saveCustomPreferredAmount() {
        if let newAmountInLiters = Double(newPreferredAmount.replacingOccurrences(of: ",", with: ".")), newAmountInLiters > 0 {
            updatePreferredAmount(to: newAmountInLiters * 1000) // Convert liters to milliliters
        } else {
            showAlert(title: "Invalid Input", message: "Please enter a valid number greater than 0.")
        }
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

struct PreferredAmountView_Previews: PreviewProvider {
    static var previews: some View {
        PreferredAmountView()
            .environmentObject(SharedData())
    }
}
