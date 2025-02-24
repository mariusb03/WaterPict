//
//  WaterPicWidget.swift
//  WaterPicWidget
//
//  Created by Marius Bringsvor Rusten on 23/02/2025.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), progress: 0.5, imagePath: nil) // Placeholder with 50% progress
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), progress: loadProgress(), imagePath: loadImagePath())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let currentDate = Date()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)! // Refresh every minute
        let entry = SimpleEntry(date: currentDate, progress: loadProgress(), imagePath: loadImagePath())

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadProgress() -> Double {
        return UserDefaults.standard.double(forKey: "dailyProgress") // 0.0 - 1.0
    }

    private func loadImagePath() -> String? {
        let defaults = UserDefaults(suiteName: "group.MBR.WaterPic")
        let imagePath = defaults?.string(forKey: "selectedImagePath")

        if let path = imagePath {
            print("📷 Widget loading image path from App Group: \(path)")

            if FileManager.default.fileExists(atPath: path) {
                print("✅ Widget can access image file: \(path)")
            } else {
                print("❌ Widget CANNOT find image file! Clearing path.")
                defaults?.removeObject(forKey: "selectedImagePath")
                return nil
            }
        } else {
            print("❌ Widget has no image path in App Group UserDefaults!")
        }

        return imagePath
    }
}

// MARK: - Timeline Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let progress: Double
    let imagePath: String?
}

import SwiftUI
import WidgetKit

struct WaterPicWidgetEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        ZStack {
            // 🔹 Load the selected image
            if let imagePath = entry.imagePath,
               FileManager.default.fileExists(atPath: imagePath),
               let uiImage = UIImage(contentsOfFile: imagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()  // Ensure it fills the frame
                    .frame(width: 150, height: 150)
                    .clipped()
            } else {
                // 🔹 Default placeholder if no image is selected
                Color.gray.opacity(0.3)
                    .frame(width: 150, height: 150)
                    .cornerRadius(10)
                    .overlay(
                        Text("Tap to select an image")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .font(.caption)
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .containerBackground(Color.black.opacity(0.1), for: .widget)
        .overlay(
            RoundedRectangle(cornerRadius: 17)
                .stroke(Color.gray, lineWidth: 8)
                .shadow(radius: 2)
                .ignoresSafeArea()
        )
    }
}

// MARK: - **Better Wave Shape**
struct WaveShape: Shape {
    var progress: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let waterHeight = rect.height * (1 - CGFloat(progress)) // Adjust based on progress
        
        // Start from bottom-left
        path.move(to: CGPoint(x: 0, y: rect.height))
        
        // First wave curve (left to center)
        path.addCurve(
            to: CGPoint(x: rect.width * 0.5, y: waterHeight - 10),
            control1: CGPoint(x: rect.width * 0.25, y: waterHeight + 20),
            control2: CGPoint(x: rect.width * 0.35, y: waterHeight - 20)
        )
        
        // Second wave curve (center to right)
        path.addCurve(
            to: CGPoint(x: rect.width, y: waterHeight),
            control1: CGPoint(x: rect.width * 0.65, y: waterHeight + 20),
            control2: CGPoint(x: rect.width * 0.75, y: waterHeight - 20)
        )
        
        // Complete the shape
        path.addLine(to: CGPoint(x: rect.width, y: rect.height)) // Bottom-right
        path.addLine(to: CGPoint(x: 0, y: rect.height)) // Back to bottom-left
        path.closeSubpath()

        return path
    }
}


private func loadProgress() -> Double {
    let defaults = UserDefaults(suiteName: "group.MBR.WaterPic")
    let progress = defaults?.double(forKey: "dailyProgress") ?? 0.0

    print("📊 Widget loaded water intake progress: \(progress)")

    return progress
}

// MARK: - **Widget Configuration**
struct WaterPicWidget: Widget {
    let kind: String = "WaterPicWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WaterPicWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Water Intake")
        .description("Displays your daily water intake with a dynamic wave effect.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - **Preview**
struct WaterPicWidget_Previews: PreviewProvider {
    static var previews: some View {
        WaterPicWidgetEntryView(entry: SimpleEntry(date: Date(), progress: 0.5, imagePath: nil))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
