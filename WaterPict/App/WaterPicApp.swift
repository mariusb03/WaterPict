import SwiftUI
import GoogleMobileAds
import WidgetKit

@main
struct WaterPicApp: App {
    @StateObject var sharedData = SharedData()
    @Environment(\.scenePhase) var scenePhase

    init() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)

        // Request notification permissions
        NotificationManager.shared.requestNotificationPermission { granted in
            if granted {
                NotificationManager.shared.scheduleNotifications(startHour: 8, endHour: 22, interval: 2)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sharedData)
                .preferredColorScheme(.light)
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                // Recheck the subscription status when the app becomes active
                Task {
                    do {
                        try await SubscriptionManager.shared.restorePurchases()
                        DispatchQueue.main.async {
                            sharedData.updateSubscriptionStatus()
                        }
                    } catch {
                        print("Failed to restore purchases on launch: \(error.localizedDescription)")
                    }
                }
            default:
                break
            }
        }
    }
}

struct WaterPicApp_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewLayout(.device)
            .preferredColorScheme(.light)
            .environment(\.sizeCategory, .large)
            .environmentObject(SharedData())
    }
}
