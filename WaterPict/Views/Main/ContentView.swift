//
//  ContentView.swift
//  WaterPic
//
//  Created by Marius Rusten on 03/12/2024.
//

import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var sharedData: SharedData
    @State private var selectedTab = 0
    @State private var showImagePicker = false
    @State private var selectedDate: Date = Date()
    @State private var continuousPhase: CGFloat = 0.0
    @State private var displayedProgress: Double = 0.0
    @State private var showCelebration = false
    @State private var lastCelebratedMilestone: Int = 0
    @State private var showCongratulatoryText = false

    var body: some View {
        ZStack {
            sharedData.selectedTheme.swiftBackgroundColor
                .ignoresSafeArea()
            
            VStack {
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
        
    }
    
    // MARK: Custom Tab Bar
    private var customTabBar: some View {
        HStack {
            tabBarItem(icon: "calendar", title: "Statistics", tag: 1)
                .padding()
            tabBarItem(icon: "drop.fill", title: "Water Intake", tag: 0)
                .padding()
            tabBarItem(icon: "gearshape.fill", title: "Settings", tag: 2)
                .padding()
        }
        
        .background(sharedData.selectedTheme.swiftBackgroundColor)
        
    }
    
    // MARK: Tab bar item
    private func tabBarItem(icon: String, title: String, tag: Int) -> some View {
        VStack {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 24)
                .foregroundColor(tabColor(for: tag))
            Text(title)
                .font(.caption)
                .foregroundColor(tabColor(for: tag))
        }
        .padding(.vertical, 10)
        .onTapGesture {
            withAnimation { selectedTab = tag }
        }
    }
    
    // MARK: Tab Color
    private func tabColor(for tag: Int) -> Color {
        selectedTab == tag ? sharedData.selectedTheme.swiftTextColor : sharedData.selectedTheme.swiftTextColor.opacity(0.6)
    }
    
    // MARK: Water Intake Tab
    private var waterIntakeTab: some View {
        ScrollView {
            ZStack {
                sharedData.selectedTheme.swiftBackgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    BannerAdView(adUnitID: "ca-app-pub-2002393296074661/7345138591")
                        .frame(height: 50)
                        .padding(.horizontal)
                    
                    sectionHeader(title: "💧 Today's Intake 💧")
                    
                    GeometryReader { geometry in
                        VStack {
                            Spacer()
                            waterWaveView(geometry: geometry)
                            Spacer()
                        }
                    }
                    .frame(height: 300) // Consistent height for wave section
                    .onAppear {
                        sharedData.loadTodayData()
                        sharedData.updateGraphData()
                    }
                    
                    waterIntakeSummary
                    
                    waterIntakeButtons
                        .padding(.top, 10)
                }
                
                .padding(.horizontal)
                
            }
        }
    }
    
    // MARK: Wave View
    private func waterWaveView(geometry: GeometryProxy) -> some View {
        ZStack {
            if let image = sharedData.imagesByDate[sharedData.formattedDate(Date())] {
                WaveView(
                    image: image,
                    progress: displayedProgress,
                    phase: continuousPhase,
                    size: CGSize(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
                )
                .onAppear {
                    Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                        continuousPhase += 0.004
                    }
                    displayedProgress = sharedData.progressByDate[sharedData.formattedDate(Date())] ?? 0.0
                }
                .onChange(of: sharedData.progressByDate[sharedData.formattedDate(Date())]) { newProgress in
                    handleProgressChange(newProgress)
                }
            } else {
                placeholderImage(geometry: geometry)
            }
        }
        .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8) // Consistent frame size
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(sharedData.selectedTheme.swiftRimColor, lineWidth: 12)
                .shadow(radius: 8)
        )
        .frame(maxWidth: .infinity, alignment: .center) // Center within the available space
    }
    
    // MARK: Placeholder image
    private func placeholderImage(geometry: GeometryProxy) -> some View {
        Text("Tap to select an image")
            .foregroundColor(.black)
            .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 25)) // Match frame corner radius
            .onTapGesture {
                showImagePicker = true
            }
    }
    
    // MARK: Intake summary
    private var waterIntakeSummary: some View {
        sectionHeader(
            title: String(
                format: "%.1f L / %.1f L",
                (sharedData.pastWaterData[sharedData.formattedDate(selectedDate)] ?? 0.0) / 1000,
                sharedData.dailyGoal / 1000
            )
        )
        .padding(.top)
    }
    
    // MARK: Buttons
    private var waterIntakeButtons: some View {
        HStack(spacing: 30) {
            actionButton(title: "-", color: .red) {
                sharedData.updateWaterIntake(amount: -sharedData.preferredAmount, for: Date())
            }
            actionButton(title: "+", color: .green) {
                sharedData.updateWaterIntake(amount: sharedData.preferredAmount, for: selectedDate)
            }
        }
    }
    
    // MARK: Action button
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
    
    // MARK: Header
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
    
    // MARK: Handle progress change
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
    
    // MARK: Celebration
    private var celebrationOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                if showCelebration {
                    CelebrationFireworksView(geometry: geometry, showText: showCongratulatoryText, milestone: lastCelebratedMilestone)
                }
            }
        }
    }
    
    // MARK: Trigger celebration
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
    
    // MARK: Image picker sheet
    private var imagePickerSheet: some View {
        ImagePicker(selectedImage: Binding(
            get: { sharedData.imagesByDate[sharedData.formattedDate(selectedDate)] },
            set: { newImage, _ in
                if let validImage = newImage as? UIImage {
                    sharedData.imagesByDate[sharedData.formattedDate(selectedDate)] = validImage
                    sharedData.saveToUserDefaults()
                }
            }
        ), completion: { image in
            if let validImage = image {
                let formattedDate = sharedData.formattedDate(selectedDate)
                sharedData.imagesByDate[formattedDate] = validImage
                sharedData.saveToUserDefaults()
            }
        })
    }
}

// MARK: Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SharedData())
    }
}
