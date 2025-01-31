//
//  SubscriptionManager.swift
//  WaterPict
//
//  Created by Marius Bringsvor Rusten on 09/01/2025.
//


import StoreKit

class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    private init() { } // Singleton pattern to prevent accidental reinitialization

    @Published var products: [Product] = []
    @Published var currentSubscription: Product? = nil

    // Your Product IDs from App Store Connect
    let productIDs = [
        "WaterPicMonthly",
        "WaterPicHalfYearly",
        "WaterPicYearly"
    ]

    func fetchProducts() async {
        do {
            let products = try await Product.products(for: productIDs)
            DispatchQueue.main.async {
                self.products = products
            }
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }

    private func notifySubscriptionChange() {
        DispatchQueue.main.async {
            SharedData().updateSubscriptionStatus()
        }
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    DispatchQueue.main.async {
                        self.currentSubscription = product
                        self.saveSubscriptionStatus(productID: product.id)
                        self.notifySubscriptionChange() // Notify SharedData
                    }
                case .unverified(_, let error):
                    print("Unverified transaction: \(error.localizedDescription)")
                }
            case .pending:
                print("Purchase is pending")
            case .userCancelled:
                print("Purchase cancelled by user")
            @unknown default:
                break
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }

    func checkSubscriptionStatus() async {
        do {
            // Fetch the list of products
            await fetchProducts()
            
            // Check for current entitlements
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    // If the transaction matches any subscription product
                    if productIDs.contains(transaction.productID) {
                        DispatchQueue.main.async {
                            self.currentSubscription = self.products.first(where: { $0.id == transaction.productID })
                            self.saveSubscriptionStatus(productID: transaction.productID)
                            print("Verified subscription for product ID: \(transaction.productID)")
                        }
                    }
                case .unverified(_, let error):
                    print("Unverified transaction: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Error checking subscription status: \(error.localizedDescription)")
        }
    }
    
    // Restore Purchases
    func restorePurchases() async throws {
        print("Attempting to restore purchases...")

        var foundRestoredProduct = false

        // Check current entitlements
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                print("Found current entitlement: \(transaction.productID)")
                if productIDs.contains(transaction.productID) {
                    DispatchQueue.main.async {
                        self.currentSubscription = self.products.first(where: { $0.id == transaction.productID })
                    }
                    foundRestoredProduct = true
                }
            case .unverified(_, let error):
                print("Unverified entitlement: \(error.localizedDescription)")
            }
        }

        // If no restored product found, use updates
        if !foundRestoredProduct {
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    print("Verified restored transaction: \(transaction.productID)")
                    if productIDs.contains(transaction.productID) {
                        DispatchQueue.main.async {
                            self.currentSubscription = self.products.first(where: { $0.id == transaction.productID })
                        }
                        return
                    }
                case .unverified(_, let error):
                    print("Unverified restored transaction: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func saveSubscriptionStatus(productID: String) {
        UserDefaults.standard.set(productID, forKey: "activeSubscriptionID")
        UserDefaults.standard.synchronize()
        print("Saved subscription: \(productID)")
    }

    func loadSubscriptionStatus() -> String? {
        let productID = UserDefaults.standard.string(forKey: "activeSubscriptionID")
        print("Loaded subscription: \(productID ?? "None")")
        return productID
    }
}
