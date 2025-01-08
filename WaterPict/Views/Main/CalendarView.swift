//
//  CalendarView.swift
//  WaterPic
//
//  Created by Marius Rusten on 04/12/2024.
//

import SwiftUI
import Charts

struct CalendarView: View {
    @EnvironmentObject var sharedData: SharedData
    @State private var selectedDate: Date = Date()
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedGraphTab: String = "Week" // Options: "Week", "Month", "Year"
    @State private var continuousPhase: CGFloat = 0.0

    var body: some View {
        ScrollView {
            ZStack {
                sharedData.selectedTheme.swiftBackgroundColor
                    .ignoresSafeArea()
                VStack(spacing: 20) {
                    BannerAdView(adUnitID: "ca-app-pub-2002393296074661/7345138591")
                        .frame(height: 50)
                        .padding(.horizontal)
                    
                    // Title Section
                    sectionHeader(title: "📊 Statistics 📊", fontSize: .largeTitle)
                    
                    // Calendar Section
                    calendarSection
                        .shadow(radius: 5)
                    
                    // Image and Progress Section
                    if let image = sharedData.imagesByDate[sharedData.formattedDate(selectedDate)] {
                        progressSection(image: image)
                    } else {
                        noImagePlaceholder
                    }
                    
                    // Graph Tabs Section
                    sectionHeader(title: "📈 Water Statistics 📉", fontSize: .title)
                    
                    graphTabs
                        .padding(.vertical)
                    
                    // Graph View
                    renderGraph(for: selectedGraphTab)
                        .frame(maxWidth: .infinity)
                        .shadow(radius: 5)
                    
                    // Average Goal Achievement Section
                    averageGoalAchievement
                }
                
            }
            .padding(.horizontal)
            .onChange(of: selectedDate) { newDate in
                handleDateChange(newDate)
            }
            .sheet(isPresented: $showImagePicker) {
                imagePickerSheet
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

    // MARK: - Progress Section
    private func progressSection(image: UIImage) -> some View {
        VStack(spacing: 10) {
            
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height) * 1
                let progressValue = sharedData.progressByDate[sharedData.formattedDate(selectedDate)] ?? 0.0
                let clampedProgress = min(max(progressValue, 0.0), 1.0)

                ZStack {
                    // Wave Animation
                    WaveView(image: image, progress: clampedProgress, phase: continuousPhase, size: CGSize(width: size, height: size))
                        .onAppear {
                            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                                continuousPhase += 0.004
                            }
                        }
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
        }
        .padding(.horizontal)
    }

    // MARK: No image Place Holder
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

    // MARK: - Graph Tabs
    private var graphTabs: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(sharedData.selectedTheme.swiftRimColor)
                .padding(.horizontal)
                .shadow(radius: 5)
            HStack {
                ForEach(["Week", "Month", "Year"], id: \.self) { tab in
                    Button(action: { selectedGraphTab = tab }) {
                        Text(tab)
                            .padding()
                            .background(selectedGraphTab == tab ? sharedData.selectedTheme.swiftBackgroundColor : Color.clear)
                            .foregroundColor(selectedGraphTab == tab ? .white : sharedData.selectedTheme.swiftTextColor)
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
            barMarks(data: data, labels: labels)
        }
        .chartYScale(domain: 0...(data.max() ?? 1.0) * 1.1)
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

    // MARK: Y-axis Customization
    @AxisContentBuilder
    private func yAxisCustomization() -> some AxisContent {
        AxisMarks(position: .automatic) { value in
            AxisValueLabel {
                if let doubleValue = value.as(Double.self) {
                    Text(String(format: "%.1f L", doubleValue))// Format as liters
                        .padding()
                }
            }
        }
    }

    // MARK: X-axis Customization
    @AxisContentBuilder
    private func xAxisCustomization() -> some AxisContent {
        AxisMarks { AxisValueLabel() }
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
        return CalendarView().environmentObject(sharedData)
    }
}
