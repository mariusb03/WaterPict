//
//  CalendarView.swift
//  WaterPic
//
//  Created by Marius Rusten on 04/12/2024.
//

import SwiftUI
import Charts

// MARK: - CalendarView with Timer Management
struct CalendarView: View {
    @EnvironmentObject var sharedData: SharedData
    @State private var selectedDate: Date = Date()
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedGraphTab: String = "Week" // Options: "Week", "Month", "Year"
    @State private var continuousPhase: CGFloat = 0.0
    @State private var showUpgradeSheet = false
    @State private var waveTimer: Timer?

    var body: some View {
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
                        // Placeholder to maintain spacing
                        Color.clear
                            .frame(height: 50)
                            .padding(.horizontal)
                    }
                    
                    // Title Section
                    sectionHeader(title: "📊 Statistics 📊", fontSize: .largeTitle)
                    
                    // Calendar Section
                    calendarSection
                        .shadow(radius: 5)
                    
                    // Image and Progress Section
                    if canViewSelectedDate() {
                        if let image = sharedData.imagesByDate[sharedData.formattedDate(selectedDate)] {
                            progressSection(image: image)
                        } else {
                            noImagePlaceholder
                        }
                    } else {
                        lockedFeaturePlaceholder(message: "Unlock WaterPic+ to view older pictures!")
                    }
                    
                    // Graph Tabs Section
                    sectionHeader(title: "📈 Water Statistics 📉", fontSize: .title)
                    
                    graphTabs
                        .padding(.vertical)
                    
                    renderGraph(for: selectedGraphTab)
                        .frame(maxWidth: .infinity)
                        .shadow(radius: 5)
                    
                    // Average Goal Achievement Section (Premium Only)
                    averageGoalAchievement
                    
                    if !sharedData.isPremiumUser {
                        lockedFeaturePlaceholder(message: "Unlock WaterPic+ to view monthly and yearly statistics!")
                    }
                }
            }
            .padding(.horizontal)
            .onChange(of: selectedDate) { newDate in
                handleDateChange(newDate)
            }
            .onAppear {
                startWaveTimer()
            }
            .onDisappear {
                stopWaveTimer()
            }
            .sheet(isPresented: $showImagePicker) {
                imagePickerSheet
            }
            .sheet(isPresented: $showUpgradeSheet) {
                UpgradeView() // Upgrade Sheet
                    .environmentObject(sharedData)
                    .presentationCornerRadius(60)
            }
        }
    }

    // MARK: - Calendar Section
    private var calendarSection: some View {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .padding(.horizontal, 20)
            .shadow(radius: 5)
        }

    // MARK: - Wave Timer Management
        private func startWaveTimer() {
            waveTimer?.invalidate() // Stop any existing timer
            waveTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                continuousPhase += 0.004
            }
        }

        private func stopWaveTimer() {
            waveTimer?.invalidate()
            waveTimer = nil
        }

        // MARK: - Progress Section
    private func progressSection(image: UIImage) -> some View {
        VStack(spacing: 10) {
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                let progressValue = sharedData.progressByDate[sharedData.formattedDate(selectedDate)] ?? 0.0
                let clampedProgress = min(max(progressValue, 0.0), 1.0)

                ZStack {
                    WaveView(image: image, progress: clampedProgress, phase: continuousPhase, size: CGSize(width: size, height: size))
                }
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(sharedData.selectedTheme.swiftRimColor, lineWidth: 10)
                        .shadow(radius: 5)
                )
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .frame(height: 300)

            // Daily Progress Text
            let displayedProgress = Int((sharedData.progressByDate[sharedData.formattedDate(selectedDate)] ?? 0.0) * 100)
            Text("Daily Progress: \(displayedProgress)%")
                .font(.headline)
                .foregroundColor(sharedData.selectedTheme.swiftTextColor)
            
            // Change Image Button
            customButton(title: "Change Image", color: sharedData.selectedTheme.swiftRimColor) {
                showImagePicker = true
            }
        }
    }

    // MARK: No Image Placeholder
        private var noImagePlaceholder: some View {
            VStack(spacing: 20) {
                Image(systemName: "photo.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(sharedData.selectedTheme.swiftTextColor.opacity(0.5))

                Text("No image selected for this date")
                    .foregroundColor(sharedData.selectedTheme.swiftTextColor)

                customButton(title: "Choose Image", color: sharedData.selectedTheme.swiftRimColor) {
                    showImagePicker = true
                }
            }
        }

    // MARK: Locked Feature Placeholder
        private func lockedFeaturePlaceholder(message: String) -> some View {
            VStack(spacing: 20) {
                Image(systemName: "lock.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)

                Text(message)
                    .font(.headline)
                    .foregroundColor(sharedData.selectedTheme.swiftTextColor)

                customButton(title: "Upgrade to WaterPic+", color: .green) {
                    // Navigate to subscription page or show upgrade prompt
                    showUpgradeSheet = true
                }
            }
        }

    // MARK: Determine if Date is Accessible
    private func canViewSelectedDate() -> Bool {
        guard !sharedData.isPremiumUser else { return true }
        
        let calendar = Calendar.current
        guard let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) else {
            return true
        }
        return selectedDate >= oneMonthAgo
    }

    // MARK: Check if Date is in Current Month
    private func isInCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        let dateMonth = calendar.component(.month, from: date)
        let dateYear = calendar.component(.year, from: date)
        
        return currentMonth == dateMonth && currentYear == dateYear
    }

    // MARK: Graph Tabs
        private var graphTabs: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(sharedData.selectedTheme.swiftRimColor)
                    .padding(.horizontal)
                    .shadow(radius: 5)
                
                HStack {
                    Button(action: { selectedGraphTab = "Week" }) {
                        Text("Week")
                            .padding()
                            .background(selectedGraphTab == "Week" ? sharedData.selectedTheme.swiftBackgroundColor : Color.clear)
                            .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                            .cornerRadius(10)
                    }
                    .padding(.vertical)
                    
                    // Disable or hide "Month" and "Year" for non-premium users
                    if sharedData.isPremiumUser {
                        Button(action: { selectedGraphTab = "Month" }) {
                            Text("Month")
                                .padding()
                                .background(selectedGraphTab == "Month" ? sharedData.selectedTheme.swiftBackgroundColor : Color.clear)
                                .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                                .cornerRadius(10)
                        }
                        .padding(.vertical)
                        
                        Button(action: { selectedGraphTab = "Year" }) {
                            Text("Year")
                                .padding()
                                .background(selectedGraphTab == "Year" ? sharedData.selectedTheme.swiftBackgroundColor : Color.clear)
                                .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                                .cornerRadius(10)
                        }
                        .padding(.vertical)
                    }
                }
                .padding(.horizontal)
            }
        }

    // MARK: - Render Graph
    private func renderGraph(for tab: String) -> some View {
        let (data, labels) = graphData(for: tab)

        return Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                BarMark(
                    x: .value("Label", labels[index]),
                    y: .value("Water Intake", value)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [sharedData.selectedTheme.swiftRimColor]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let yValue = value.as(Double.self) {
                    AxisValueLabel {
                        Text(String(format: "%.1f L", yValue)) // Display as liters
                    }
                }
            }
        }
        .chartYScale(domain: 0...(data.max() ?? 1.0) * 1.1) // Extend Y-axis above max value
        .frame(height: 300)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(radius: 5)
        )
        .padding(.horizontal)
    }

    // MARK: Bar Marks
        private func barMarks(data: [Double], labels: [String]) -> some ChartContent {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                if index < labels.count {
                    BarMark(
                        x: .value("Label", labels[index]),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [sharedData.selectedTheme.swiftRimColor]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
        }
    
    // MARK: Graph Data
        private func graphData(for tab: String) -> ([Double], [String]) {
            switch tab {
            case "Week":
                return (sharedData.weeklyGraphData, ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
            case "Month":
                return (sharedData.monthlyGraphData, ["Week 1", "Week 2", "Week 3", "Week 4"])
            case "Year":
                return (sharedData.yearlyGraphData, Calendar.current.shortMonthSymbols)
            default:
                return ([], [])
            }
        }

    // MARK: - Average Goal Achievement
    private var averageGoalAchievement: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(sharedData.selectedTheme.swiftRimColor)
                .padding(.horizontal)
                .shadow(radius: 5)

            HStack {
                Text("Average Goal Achievement:")
                    .font(.headline)
                    .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                    .padding(.vertical)

                Text(averageGoalAchievementText(for: selectedGraphTab))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(sharedData.selectedTheme.swiftTextColor)
            }
        }
    }

    // MARK: Average Goal Achievement
    private func averageGoalAchievementText(for tab: String) -> String {
        let average = {
            switch tab {
            case "Week": return sharedData.weeklyAverageGoalAchievement
            case "Month": return sharedData.monthlyAverageGoalAchievement
            case "Year": return sharedData.yearlyAverageGoalAchievement
            default: return 0.0
            }
        }()
        return String(format: "%.1f%%", average)
    }

    // MARK: - Image Picker
    private var imagePickerSheet: some View {
        ImagePicker(selectedImage: $selectedImage) { image in
            if let validImage = selectedImage {
                let formattedDate = sharedData.formattedDate(selectedDate)
                sharedData.imagesByDate[formattedDate] = validImage
                sharedData.saveToUserDefaults()
            }
        }
    }

    // MARK: - Section Header
    private func sectionHeader(title: String, fontSize: Font = .headline) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(sharedData.selectedTheme.swiftRimColor)
                .padding(.horizontal)
                .shadow(radius: 5)
            Text(title)
                .font(fontSize)
                .fontWeight(.bold)
                .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                .padding(.vertical)
        }
    }

    // MARK: - Custom Button
    private func customButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                .padding()
                .frame(maxWidth: .infinity)
                .background(color)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.horizontal)
        }
    }

    // MARK: - Date Change Handler
    private func handleDateChange(_ newDate: Date) {
        sharedData.loadWaterIntake(for: newDate)
        let formattedDate = sharedData.formattedDate(newDate)
        sharedData.progressByDate[formattedDate] = (sharedData.pastWaterData[formattedDate] ?? 0.0) / sharedData.dailyGoal
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        let sharedData = SharedData()
        sharedData.isPremiumUser = false // Set to true to enable premium preview

        return CalendarView()
            .environmentObject(sharedData)
            .previewDisplayName("Premium View")
    }
}
