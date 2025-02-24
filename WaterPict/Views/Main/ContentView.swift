//
//  ContentView.swift
//  WaterPic
//
//  Created by Marius Rusten on 03/12/2024.
//

import SwiftUI
import Combine
import WidgetKit

struct ContentView: View {
    @EnvironmentObject var sharedData: SharedData
    @State private var selectedTab = 0
    @State private var showImagePicker = false
    @State private var continuousPhase: CGFloat = 0.0
    @State private var displayedProgress: Double = 0.0
    @State private var showCelebration = false
    @State private var lastCelebratedMilestone: Int = 0
    @State private var showCongratulatoryText = false
    @State private var waveTimer: Timer?

    var body: some View {
        ZStack {
            sharedData.selectedTheme.swiftBackgroundColor
                .ignoresSafeArea()

            VStack {
                // TabView with lazy views
                TabView(selection: $selectedTab) {
                    CalendarView()
                        .environmentObject(sharedData)
                        .tag(1)

                    waterIntakeTab
                        .tag(0)

                    SettingsView(
                        preferredAmount: $sharedData.preferredAmount,
                        showInvalidInputAlert: $sharedData.showInvalidInputAlert,
                        invalidInputMessage: $sharedData.invalidInputMessage,
                        selectedTheme: $sharedData.selectedTheme
                    )
                    .environmentObject(sharedData)
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // Custom Tab Bar
                customTabBar
            }

            // Celebration Overlay
            if showCelebration {
                celebrationOverlay
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 60)
                .stroke(sharedData.selectedTheme.swiftRimColor, lineWidth: 20)
                .shadow(radius: 5)
                .ignoresSafeArea()
        )
        .sheet(isPresented: $showImagePicker) {
            imagePickerSheet
        }
        .onAppear {
            sharedData.updateCurrentDate()
            startWaveTimer()
        }
        .onDisappear {
            sharedData.stopDateUpdateTimer()
            stopWaveTimer()
        }
    }

    // MARK: Custom Tab Bar
    private var customTabBar: some View {
        HStack {
            tabBarItem(icon: "calendar", title: "Statistics", tag: 1)
            tabBarItem(icon: "drop.fill", title: "Water Intake", tag: 0)
            tabBarItem(icon: "gearshape.fill", title: "Settings", tag: 2)
        }
        .background(sharedData.selectedTheme.swiftBackgroundColor)
    }

    private func tabBarItem(icon: String, title: String, tag: Int) -> some View {
        VStack {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 24)
                .foregroundColor(selectedTab == tag ? sharedData.selectedTheme.swiftTextColor : sharedData.selectedTheme.swiftTextColor.opacity(0.6))
            Text(title)
                .font(.caption)
                .foregroundColor(selectedTab == tag ? sharedData.selectedTheme.swiftTextColor : sharedData.selectedTheme.swiftTextColor.opacity(0.6))
        }
        .padding(.vertical, 10)
        .onTapGesture {
            withAnimation { selectedTab = tag }
        }
    }

    // MARK: Water Intake Tab
    private var waterIntakeTab: some View {
        ScrollView {
            ZStack {
                sharedData.selectedTheme.swiftBackgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    if !sharedData.isPremiumUser {
                        BannerAdView(adUnitID: "ca-app-pub-2002393296074661/7345138591")
                            .frame(height: 50)
                            .padding(.horizontal)
                    } else {
                        Color.clear
                            .frame(height: 50)
                            .padding(.horizontal)
                    }

                    sectionHeader(title: "💧 Today's Intake 💧")

                    // ✅ Use a fixed frame width for better scaling
                    VStack {
                        waterWaveView()
                    }
                   
                    .frame(maxWidth: 500) // ✅ Set a max width to prevent unwanted stretching
                    .frame(height: 300) // ✅ Fixed height
                    .padding(.top, 30)
                    .padding(.bottom, 10)

                    waterIntakeSummary
                    waterIntakeButtons
                        .padding(.top, 10)
                }
                .frame(maxWidth: 600) // ✅ Ensures a readable width on iPads
                .padding(.horizontal)
            }
        }
    }

    // MARK: Water wave view
    private func waterWaveView() -> some View {
        ZStack {
            if let imagePath = sharedData.imagesByDate[sharedData.formattedDate(sharedData.currentDate)],
               FileManager.default.fileExists(atPath: imagePath),
               let image = UIImage(contentsOfFile: imagePath) {
                WaveView(
                    image: image,
                    progress: displayedProgress,
                    phase: continuousPhase,
                    size: CGSize(width: 350, height: 350) // ✅ Fixed size for iPads
                )
                .onAppear {
                    displayedProgress = sharedData.progressByDate[sharedData.formattedDate(sharedData.currentDate)] ?? 0.0
                }
                .onChange(of: sharedData.progressByDate[sharedData.formattedDate(sharedData.currentDate)]) { newProgress in
                    handleProgressChange(newProgress)
                }
            } else {
                placeholderImage()
            }
        }
        .frame(width: 350, height: 350) // ✅ Ensure a consistent size
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(sharedData.selectedTheme.swiftRimColor, lineWidth: 12)
                .shadow(radius: 8)
        )
    }

    private func placeholderImage() -> some View {
        Text("Tap to select an image")
            .foregroundColor(.black)
            .frame(width: 250, height: 250) // ✅ Use fixed size
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .onTapGesture {
                showImagePicker = true
            }
    }

    // MARK: Water Intake Summary
    private var waterIntakeSummary: some View {
        sectionHeader(
            title: String(
                format: "%.1f L / %.1f L",
                (sharedData.pastWaterData[sharedData.formattedDate(sharedData.currentDate)] ?? 0.0) / 1000,
                sharedData.dailyGoal / 1000
            )
        )
        .padding(.top)
    }

    // MARK: Buttons
    private var waterIntakeButtons: some View {
        HStack(spacing: 30) {
            actionButton(title: "-", color: .red) {
                sharedData.updateWaterIntake(amount: -sharedData.preferredAmount, for: sharedData.currentDate)
            }
            actionButton(title: "+", color: .green) {
                sharedData.updateWaterIntake(amount: sharedData.preferredAmount, for: sharedData.currentDate)
            }
        }
    }

    private func actionButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.largeTitle)
                .frame(width: 70, height: 70)
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(25)
                .shadow(radius: 5)
        }
    }

    // MARK: Section Header
    private func sectionHeader(title: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(sharedData.selectedTheme.swiftRimColor)
                .padding(.horizontal)
                .shadow(radius: 5)
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                .padding(.vertical)
        }
    }

    // MARK: Celebration
    private var celebrationOverlay: some View {
        GeometryReader { geometry in
            if showCelebration {
                CelebrationFireworksView(geometry: geometry, showText: showCongratulatoryText, milestone: lastCelebratedMilestone)
            }
        }
    }

    private func handleProgressChange(_ newProgress: Double?) {
        guard let newProgress = newProgress else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            displayedProgress = newProgress
        }
        let milestone = Int(newProgress * 100) / 100 * 100
        if milestone > lastCelebratedMilestone {
            triggerCelebration(for: milestone)
        }
    }

    private func triggerCelebration(for milestone: Int) {
        lastCelebratedMilestone = milestone
        withAnimation {
            showCelebration = true
            showCongratulatoryText = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeOut(duration: 1.5)) {
                showCongratulatoryText = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            withAnimation {
                showCelebration = false
            }
        }
    }

    // MARK: Image Picker
    private var imagePickerSheet: some View {
        ImagePicker(
            selectedImage: Binding(
                get: {
                    if let imagePath = sharedData.imagesByDate[sharedData.formattedDate(sharedData.currentDate)] {
                        return UIImage(contentsOfFile: imagePath) // Convert file path to UIImage
                    }
                    return nil
                },
                set: { newImage, _ in
                    if let validImage = newImage {
                        // Save the image to file system and store the file path in sharedData
                        if let filePath = saveImageToFileSystem(image: validImage) {
                            sharedData.imagesByDate[sharedData.formattedDate(sharedData.currentDate)] = filePath
                            sharedData.saveToUserDefaults()
                        }
                    }
                }
            ),
            completion: { image in
                if let validImage = image {
                    if let filePath = saveImageToFileSystem(image: validImage) {
                        sharedData.imagesByDate[sharedData.formattedDate(sharedData.currentDate)] = filePath
                        sharedData.saveToUserDefaults()
                    }
                }
            }
        )
    }

    func saveImageToFileSystem(image: UIImage) -> String? {
        if let data = image.jpegData(compressionQuality: 0.8) {
            let filename = UUID().uuidString + ".jpg" // Unique filename
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

            do {
                try data.write(to: fileURL)
                return fileURL.path // Return the saved file path
            } catch {
                print("❌ Failed to save image: \(error.localizedDescription)")
                return nil
            }
        }
        return nil
    }
    
    // MARK: Wave Timer Management
    private func startWaveTimer() {
        waveTimer?.invalidate()
        waveTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            continuousPhase += 0.008
        }
    }

    private func stopWaveTimer() {
        waveTimer?.invalidate()
        waveTimer = nil
    }
}

// MARK: LazyView Wrapper
struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}

// MARK: Preview
struct ContentView_PremiumPreview: PreviewProvider {
    static var previews: some View {
        let premiumUserData = SharedData()
        premiumUserData.isPremiumUser = true // Set as a premium user

        return ContentView()
            .environmentObject(premiumUserData)
            .previewDisplayName("Premium User View")
    }
}
