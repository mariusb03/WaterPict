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
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
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
                        if let imagePath = sharedData.imagesByDate[sharedData.formattedDate(selectedDate)],
                           let image = UIImage(contentsOfFile: imagePath) { // Convert file path to UIImage
                            progressSection(image: image)
                        } else {
                            noImagePlaceholder
                        }
                    } else {
                        lockedFeaturePlaceholder(message: "Unlock WaterPic+ to view older pictures!")
                    }

                    progressCirclesSection
                    
                    if sharedData.isPremiumUser {
                        streakBoxSection
                    }
                    
                    
                    if !sharedData.isPremiumUser {
                        lockedFeaturePlaceholder(message: "Upgrade to WaterPic+ to get the rest!")
                    }
                }
            }
            .padding(.horizontal)
            .onChange(of: selectedDate) { newDate in
                handleDateChange(newDate)
                sharedData.loadWaterIntake(for: newDate)
                    sharedData.updateProgress()
                    
                    // Recheck subscription status if needed
                    Task {
                        await SubscriptionManager.shared.checkSubscriptionStatus()
                        DispatchQueue.main.async {
                            sharedData.updateSubscriptionStatus()
                        }
                    }
                }
            
        
            .onAppear {
                // Sync selectedDate with the current date if outdated
                if !Calendar.current.isDate(selectedDate, inSameDayAs: Date()) {
                    selectedDate = Calendar.current.startOfDay(for: Date())
                    handleDateChange(selectedDate)
                }

                startWaveTimer()
                sharedData.updateProgress() // Ensure progress data is recalculated when the view loads
                sharedData.updateStreaks()
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
        let calendar = Calendar.current
        let formattedDate = sharedData.formattedDate

        // Convert ClosedRange to Range
        let daysInMonth: Range<Int> = {
            if let range = calendar.range(of: .day, in: .month, for: selectedDate) {
                return range.lowerBound..<range.upperBound
            }
            return 1..<31 // Default fallback range
        }()

        return VStack {
            // Month and Year Header
            HStack {
                Button(action: {
                    if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
                        selectedDate = newDate
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(sharedData.selectedTheme.swiftRimColor)
                        .font(.title2)
                        .padding(.trailing, 10)
                }

                VStack {
                    Text(calendarMonthYear(selectedDate))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(sharedData.selectedTheme.swiftRimColor)
                    Divider()
                        .frame(width: 100, height: 2)
                        .background(sharedData.selectedTheme.swiftRimColor)
                }

                Button(action: {
                    if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
                        selectedDate = newDate
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(sharedData.selectedTheme.swiftRimColor)
                        .font(.title2)
                        .padding(.leading, 10)
                }
            }
            .padding(.vertical)
            

            // Grid of Days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(daysInMonth, id: \.self) { day in
                    if let date = calendar.date(from: DateComponents(
                        year: calendar.component(.year, from: selectedDate),
                        month: calendar.component(.month, from: selectedDate),
                        day: day
                    )) {
                        let progress = sharedData.progressByDate[sharedData.formattedDate(date, format: "yyyy-MM-dd")] ?? 0.0

                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                            if progress > 0 {
                                Circle()
                                    .trim(from: 0, to: CGFloat(progress))
                                    .stroke(progressColor(for: progress), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                            }
                            Text("\(day)")
                                .font(.footnote)
                                .foregroundColor(date == selectedDate ? .white : .black)
                                .padding(8)
                                .background(date == selectedDate ? sharedData.selectedTheme.swiftRimColor : Color.clear)
                                .clipShape(Circle())
                        }
                        .frame(height: 40)
                        .onTapGesture {
                            selectedDate = date
                            sharedData.updateProgress() // Update progress after selecting a new date
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal)
    }

    private func calendarMonthYear(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy" // e.g., "January 2025"
        return dateFormatter.string(from: date)
    }
    
    // Helper for Progress Colors
    private func progressColor(for progress: Double) -> Color {
        if progress < 0.3 {
            return .red
        } else if progress < 0.7 {
            return .yellow
        } else {
            return .green
        }
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
    
    // MARK: Streak Box section
    private var streakBoxSection: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(sharedData.selectedTheme.swiftRimColor)
                    .padding(.horizontal)
                    .shadow(radius: 5)
                
                VStack(spacing: 20) {
                    // Title
                    Text("🔥 Streak 🔥")
                        .font(.title2)
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                    
                    // Current and Longest Streak
                    HStack(spacing: 30) {
                        VStack {
                            Text("Current Streak")
                                .font(.subheadline)
                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                .foregroundColor(.white)
                            Text("\(sharedData.currentStreak)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        VStack {
                            Text("Longest Streak")
                                .font(.subheadline)
                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                .foregroundColor(.white)
                            Text("\(sharedData.longestStreak)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    // Horizontal Scroll View for Streak Days
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(sharedData.streakDays, id: \.self) { day in
                                streakDayView(date: day)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
        }
        .padding(.vertical)
    }
    
    // MARK: Streak Day View
    private func streakDayView(date: Date) -> some View {
        VStack {
            Text(sharedData.formattedDate(date, format: "MMM d"))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 5)

                Circle()
                    .trim(from: 0, to: 1.0)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("🔥")
                    .font(.largeTitle)
            }
            .frame(width: 50, height: 50)
        }
        .frame(width: 80)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)))
        .padding(5)
    }
    
    // MARK: Update Streaks
    func updateStreaks() {
        let sortedDates = sharedData.pastWaterData.keys.compactMap { sharedData.dateFormatter.date(from: $0) }.sorted()
        var currentStreakDates: [Date] = []
        var longestStreakCount = 0
        var longestStreakDates: [Date] = []

        var currentStreakCount = 0
        var previousDate: Date? = nil

        for date in sortedDates {
            let formattedDate = sharedData.formattedDate(date, format: "yyyy-MM-dd")
            let waterIntake = sharedData.pastWaterData[formattedDate] ?? 0.0
            let isGoalMet = waterIntake >= sharedData.dailyGoal

            print("Date: \(formattedDate), Water Intake: \(waterIntake), Goal Met: \(isGoalMet)")

            if isGoalMet {
                if let previous = previousDate {
                    // Check if the current date is the next consecutive day
                    if Calendar.current.isDate(date, inSameDayAs: Calendar.current.date(byAdding: .day, value: 1, to: previous)!) {
                        currentStreakCount += 1
                        currentStreakDates.append(date)
                    } else {
                        // Reset streak if not consecutive
                        if currentStreakCount > longestStreakCount {
                            longestStreakCount = currentStreakCount
                            longestStreakDates = currentStreakDates
                        }
                        currentStreakCount = 1
                        currentStreakDates = [date]
                    }
                } else {
                    currentStreakCount = 1
                    currentStreakDates = [date]
                }
                previousDate = date
            } else {
                // Reset streak if daily goal is not met
                if currentStreakCount > longestStreakCount {
                    longestStreakCount = currentStreakCount
                    longestStreakDates = currentStreakDates
                }
                currentStreakCount = 0
                currentStreakDates = []
                previousDate = nil
            }
        }

        // Final check after loop
        if currentStreakCount > longestStreakCount {
            longestStreakCount = currentStreakCount
            longestStreakDates = currentStreakDates
        }

        // Update shared properties
        sharedData.currentStreak = currentStreakCount
        sharedData.longestStreak = longestStreakCount
        sharedData.streakDays = currentStreakDates

        print("Final Streak: Current: \(currentStreakCount), Longest: \(longestStreakCount), Streak Days: \(currentStreakDates)")
    }
    
    // MARK: Formatted date
    func formattedDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
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

    // MARK: Progress cicle
    private func progressCircle(title: String, progress: Double, isLocked: Bool, action: @escaping () -> Void) -> some View {
        ZStack {
            // More visible background circle
            Circle()
                .stroke(Color.white.opacity(0.4), lineWidth: 10) // Increased opacity and width
            
            if !isLocked {
                // Brighter and thicker progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(progressColor(for: progress), style: StrokeStyle(lineWidth: 10, lineCap: .round)) // Thicker line width
                    .rotationEffect(.degrees(-90))
            }
            
            VStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white) // Use white for better contrast with background
                
                if isLocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.title)
                } else {
                    Text("\(Int(progress * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(progressColor(for: progress))
                }
            }
        }
        .frame(width: 90, height: 90) // Slightly larger circle for visibility
        .onTapGesture {
                if isLocked {
                    action() // Trigger the upgrade view when locked
            }
        }
    }
    
    
    // MARK: Progress circle section
    private var progressCirclesSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(sharedData.selectedTheme.swiftRimColor)
                .padding(.horizontal)
                .shadow(radius: 5)
            
            VStack {
                Text ("🎯 Goals  🎯")
                    .font(.title2)
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                
                HStack(spacing: 20) {
                    // Weekly Progress Circle (always accessible)
                    progressCircle(title: "Week", progress: sharedData.weeklyProgress, isLocked: false) {
                        // No action for unlocked progress circles
                    }
                    
                    // Monthly Progress Circle
                    progressCircle(title: "Month", progress: sharedData.monthlyProgress, isLocked: !sharedData.isPremiumUser) {
                        if !sharedData.isPremiumUser {
                            showUpgradeSheet = true // Show upgrade sheet for non-premium users
                        }
                    }
                    
                    // Yearly Progress Circle
                    progressCircle(title: "Year", progress: sharedData.yearlyProgress, isLocked: !sharedData.isPremiumUser) {
                        if !sharedData.isPremiumUser {
                            showUpgradeSheet = true // Show upgrade sheet for non-premium users
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    
    // MARK: - Image Picker
    private var imagePickerSheet: some View {
        ImagePicker(selectedImage: $selectedImage) { image in
            if let validImage = selectedImage {
                let formattedDate = sharedData.formattedDate(selectedDate.startOfDay())
                
                // Save the image to disk and get the file path
                if let filePath = saveImageToFile(validImage, withName: formattedDate) {
                    sharedData.imagesByDate[formattedDate] = filePath // Store file path, not UIImage
                    sharedData.saveToUserDefaults()
                    sharedData.updateProgress()
                }
            }
        }
    }
    
    func saveImageToFile(_ image: UIImage, withName name: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = directory.appendingPathComponent("\(name).jpg") // Save as JPG
        
        do {
            try data.write(to: fileURL)
            return fileURL.path // Return the file path
        } catch {
            print("Error saving image: \(error.localizedDescription)")
            return nil
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
        sharedData.updateProgress() // Update weekly, monthly, and yearly progress
    }
}

    //MARK: Date extension
    extension Date {
        func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
        }
    }

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        let sharedData = SharedData()
        sharedData.isPremiumUser = true // Set to true to enable premium preview

        return CalendarView()
            .environmentObject(sharedData)
            .previewDisplayName("Premium View")
    }
}
