import SwiftUI
import GoogleMobileAds

@main
struct WaterPicApp: App {
    @StateObject var sharedData = SharedData()

    init() {
        // Initialize Google Mobile Ads SDK
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        // Request notification permissions and schedule notifications
        NotificationManager.shared.requestNotificationPermission { granted in
            if granted {
                NotificationManager.shared.scheduleNotifications(startHour: 8, endHour: 22, interval: 2)
            } else {
                print("Notification permissions not granted.")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sharedData)
                .preferredColorScheme(.light)
                .onAppear {
                    Task { [weak sharedData] in
                        await SubscriptionManager.shared.checkSubscriptionStatus()
                        DispatchQueue.main.async {
                            sharedData?.updateSubscriptionStatus()
                        }
                    }
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
