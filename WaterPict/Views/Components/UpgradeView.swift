//
//  UpgradeView.swift
//  WaterPic
//
//  Created by Marius Rusten on 09/01/2025.
//

import SwiftUI
import StoreKit

struct UpgradeView: View {
    @EnvironmentObject var sharedData: SharedData
    @Environment(\.presentationMode) var presentationMode // To dismiss the view
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isLoading = true
    @State private var products: [Product] = []

    var body: some View {
        ZStack {
            sharedData.selectedTheme.swiftBackgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        // Title Section
                        RoundedRectangle(cornerRadius: 10)
                            .fill(sharedData.selectedTheme.swiftRimColor)
                            .padding(.horizontal)
                            .shadow(radius: 5)
                        Text("💎 Upgrade to WaterPic+ 💎")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                            .padding()
                    }
                    .padding(.top, 20)
                    
                    // Features Section
                    VStack(alignment: .leading, spacing: 20) {
                        upgradeFeatureRow(title: "🙄 Remove ads")
                        
                        upgradeFeatureRow(title: "📷 View all your used pictures")
                        
                        upgradeFeatureRow(title: "📈 Access to detailed statistics")
                        
                    }
                    .padding()
                    .background(sharedData.selectedTheme.swiftRimColor)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding(.horizontal)

                    // Subscription Options
                    if isLoading {
                        ProgressView("Loading subscriptions...")
                            .padding()
                    } else {
                        ForEach(products, id: \.id) { product in
                            subscriptionOption(product: product)
                        }
                        
                    }

                    // Links to Privacy Policy and EULA
                    VStack(alignment: .leading, spacing: 10) {
                        Text("By subscribing, you agree to the following:")
                            .font(.subheadline)
                            .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                            .frame(maxWidth: .infinity)

                        // Privacy Policy Link
                        Link("📜 Privacy Policy", destination: URL(string: "https://sites.google.com/view/waterpic/privacy-policy")!)
                            .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                            .font(.subheadline)
                            .underline()
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        // Apple Standard EULA Link
                        Link("📄 Apple's Standard EULA", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                            .font(.subheadline)
                            .underline()
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(sharedData.selectedTheme.swiftRimColor)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                    
                    // Restore Purchases Button
                    Button(action: restorePurchases) {
                        Text("Restore Purchases")
                            .font(.headline)
                            .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                    }
                    .padding(.top, 10)
                    
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                            .padding()
                    }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .task {
            await fetchProducts()
        }
    }
    
    // MARK: - Upgrade Feature Row
    private func upgradeFeatureRow(title: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
            Text(title)
                .font(.headline)
                .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                .padding(.leading, 5)
        }
    }

    // MARK: - Subscription Option
    private func subscriptionOption(product: Product) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(product.displayName)
                    .font(.headline)
                    .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                Spacer()
                Text(product.displayPrice)
                    .font(.headline)
                    .foregroundColor(.green)
                    .shadow(radius: 1)
            }
            
            
            Text(product.description)
                .font(.subheadline)
                .foregroundColor(sharedData.selectedTheme.swiftTextColor.opacity(0.7))

            Button(action: {
                Task {
                    await subscribeTo(product)
                }
            }) {
                Text("Subscribe")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
        }
        .padding()
        .background(sharedData.selectedTheme.swiftRimColor)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal)
    }

    // MARK: - Fetch Products
    private func fetchProducts() async {
        isLoading = true
        do {
            let fetchedProducts = try await Product.products(for: SubscriptionManager.shared.productIDs)
            // Sort the products by price in ascending order
            DispatchQueue.main.async {
                self.products = fetchedProducts.sorted { $0.price < $1.price }
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.alertTitle = "Error"
                self.alertMessage = "Failed to load subscription options. Please try again later."
                self.showAlert = true
                self.isLoading = false
            }
        }
    }

    // MARK: - Subscribe to Product
    private func subscribeTo(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Access granted
                    await transaction.finish()
                    DispatchQueue.main.async {
                        sharedData.isPremiumUser = true
                        alertTitle = "Success"
                        alertMessage = "Thank you for subscribing to WaterPic+! Enjoy the premium features."
                        showAlert = true
                        presentationMode.wrappedValue.dismiss()
                    }
                case .unverified(_, let error):
                    print("Unverified transaction: \(error.localizedDescription)")
                }
            case .pending:
                alertTitle = "Pending"
                alertMessage = "Your purchase is pending. Please wait."
                showAlert = true
            case .userCancelled:
                print("User cancelled the purchase.")
            @unknown default:
                break
            }
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to complete the purchase. Please try again later."
            showAlert = true
        }
    }

    // MARK: - Restore Purchases
    private func restorePurchases() {
        Task {
            do {
                try await AppStore.sync()
                await SubscriptionManager.shared.checkSubscriptionStatus()
                alertTitle = "Success"
                alertMessage = "Your purchases have been successfully restored."
                showAlert = true
            } catch {
                alertTitle = "Error"
                alertMessage = "Failed to restore purchases. Please try again later."
                showAlert = true
            }
        }
    }
}

struct UpgradeView_Previews: PreviewProvider {
    static var previews: some View {
        let sharedData = SharedData()
        return UpgradeView().environmentObject(sharedData)
    }
}
