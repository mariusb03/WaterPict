import SwiftUI
import GoogleMobileAds

@main
struct WaterPicApp: App {
    @StateObject var sharedData = SharedData()

    init() {
        // Initialize Google Mobile Ads SDK
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sharedData)
                .preferredColorScheme(.light)
            
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
