//
//  SharedData.swift
//  WaterPic
//
//  Created by Marius Bringsvor Rusten on 25/12/2024.
//

import UserNotifications
import SwiftUI

class SharedData: ObservableObject {
    @Published var selectedTheme: Theme = Theme.defaultTheme {
        didSet {
            saveToUserDefaults()
        }
    }
    
    @Published var imagesByDate: [String: UIImage] = [:]{
        didSet {
            saveToUserDefaults()
        }
    }
    
    @Published var progressByDate: [String: Double] = [:]{
        didSet {
            saveToUserDefaults()
        }
    }
    
    @Published var waterIntake: Double = 0.0{
        didSet {
            saveToUserDefaults()
        }
    }
    
    @Published var dailyGoal: Double = 2000.0{
        didSet {
            saveToUserDefaults()
        }
    }
    
    @Published var preferredAmount: Double = 200.0{
        didSet {
            saveToUserDefaults()
        }
    }

    @Published var pastWaterData: [String: Double] = [:]{
        didSet {
            saveToUserDefaults()
        }
    }
    
    @Published var notificationStartHour: Int = 8 {
        didSet {
            saveToUserDefaults() }
    }
    
    @Published var notificationEndHour: Int = 22 {
        didSet {
            saveToUserDefaults() }
    }
    
    @Published var notificationInterval: Int = 2 {
        didSet {
            saveToUserDefaults() }
    }
    
    @Published var startTime: Date = Calendar.current.startOfDay(for: Date()) {
        didSet {
            saveToUserDefaults()
        }
    }

    @Published var endTime: Date = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) ?? Date() {
        didSet {
            saveToUserDefaults()
        }
    }
    
    
    @Published var weeklyProgress: Double = 0.0 // Progress for the week
       
    @Published var monthlyProgress: Double = 0.0 // Progress for the month
    
    @Published var yearlyProgress: Double = 0.0 // Progress for the year
    
    @Published var waterIntakeByDate: [String: Double] = [:]
    
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var streakDays: [Date] = [] // Dates in the current streak
    
    @Published var weeklyGraphData: [Double] = []
    @Published var monthlyGraphData: [Double] = []
    @Published var yearlyGraphData: [Double] = []
    
    @Published var supportEmail: String = "mariusbr6@gmail.com"
    @Published var supportWebsite: String = "https://www.yourapp.com"
    
    @Published var showInvalidInputAlert: Bool = false
    @Published var invalidInputMessage: String = ""
    
    @Published var isPremiumUser: Bool = false {
            didSet {
                print("Premium user status updated: \(isPremiumUser)")
            }
        }
    
    private var subscriptionManager = SubscriptionManager.shared
    
    private var saveTask: DispatchWorkItem?

    public let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    private let calendar: Calendar = {
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            calendar.firstWeekday = 2 // Set the first day of the week to Monday (or adjust as needed)
            return calendar
        }()

    private let themeKey = "selectedTheme"
    private let dailyGoalKey = "dailyGoal"
    private let preferredAmountKey = "preferredAmount"
    private let pastWaterDataKey = "pastWaterData"
    private let progressByDateKey = "progressByDate"
    private let imagesByDateKey = "imagesByDate"
    private let waterIntakeKey = "waterIntake"

    init() {
        if UserDefaults.standard.bool(forKey: "hasLaunchedBefore") == false {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            saveToUserDefaults()
        } else {
            loadFromUserDefaults()
        }
        updateGraphData()
        updateStreaks() // Ensure streaks are calculated after loading data

        // Fetch subscription data
        Task { [weak self] in
            guard let self = self else { return }
            await self.subscriptionManager.fetchProducts()
            await self.subscriptionManager.checkSubscriptionStatus()
            DispatchQueue.main.async {
                self.updateSubscriptionStatus()
            }
        }
    }

    // MARK: - Helper Methods
    func formattedDate(_ date: Date, format: String = "yyyy-MM-dd") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    @MainActor
    func updateWaterIntake(amount: Double, for date: Date) {
        let formattedDate = formattedDate(date)
        let currentIntake = pastWaterData[formattedDate] ?? 0.0
        let updatedIntake = max(0, currentIntake + amount)

        if updatedIntake != currentIntake {
            pastWaterData[formattedDate] = updatedIntake
            progressByDate[formattedDate] = updatedIntake / dailyGoal
            waterIntake = updatedIntake // Update the current water intake
            updateGraphData()
            updateProgress()
            updateStreaks() // Trigger streak update
            saveToUserDefaults() // Ensure data is saved immediately
        }
    }

    func loadWaterIntake(for date: Date) {
            let formattedDate = formattedDate(date)
            waterIntake = pastWaterData[formattedDate] ?? 0.0
        }

    func updateGraphData() {
        weeklyGraphData = calculateWeeklyGraphData()
        monthlyGraphData = calculateMonthlyGraphData()
        yearlyGraphData = calculateYearlyGraphData()
    }

    func loadTodayData() {
        let currentDate = formattedDate(Date())
        waterIntake = pastWaterData[currentDate] ?? 0.0
        progressByDate[currentDate] = waterIntake / dailyGoal
        updateProgress()
        updateStreaks() // Ensure streaks reflect today's data
        print("Today's water intake loaded: \(waterIntake)") // Debugging log
    }

    
    // Method to update progress values
        func updateProgress() {
            // Calculate weekly progress
            weeklyProgress = calculateProgress(for: 7)

            // Calculate monthly progress
            monthlyProgress = calculateProgress(for: 30)

            // Calculate yearly progress
            yearlyProgress = calculateProgress(for: 365)
        }
    
    private func calculateProgress(for days: Int) -> Double {
        let today = Date()
        
        // Get dates for the last `days` days
        let recentDates = (0..<days).compactMap { dayOffset -> String? in
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                return formattedDate(date)
            }
            return nil
        }

        // Total intake for recent days
        let totalIntake = recentDates.reduce(0.0) { total, date in
            total + (pastWaterData[date] ?? 0.0) // Use pastWaterData instead of waterIntakeByDate
        }

        // Total goal over the period
        let totalGoal = Double(days) * dailyGoal

        // Calculate progress as a percentage (0.0 to 1.0)
        return totalGoal > 0 ? min(totalIntake / totalGoal, 1.0) : 0.0
    }
    
    func updateStreaks() {
        let sortedDates = pastWaterData.keys.compactMap { dateFormatter.date(from: $0) }.sorted()
        var currentStreakDates: [Date] = []
        var longestStreakCount = 0
        var longestStreakDates: [Date] = []

        var currentStreakCount = 0
        var previousDate: Date? = nil

        for date in sortedDates {
            let formattedDate = dateFormatter.string(from: date)
            let waterIntake = pastWaterData[formattedDate] ?? 0.0
            let isGoalMet = waterIntake >= dailyGoal // Check if the goal is 100% met

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

        // Final check for the last streak
        if currentStreakCount > longestStreakCount {
            longestStreakCount = currentStreakCount
            longestStreakDates = currentStreakDates
        }

        // Update shared properties
        currentStreak = currentStreakCount
        longestStreak = longestStreakCount
        streakDays = currentStreakDates

        print("Final Streak: Current: \(currentStreak), Longest: \(longestStreak), Streak Dates: \(streakDays)")
    }
    
    
    // MARK: - Graph Data Calculations
    func calculateWeeklyGraphData() -> [Double] {
        var weeklyData: [Double] = Array(repeating: 0.0, count: 7)
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current // Ensure the calendar uses the correct time zone
        
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else {
            return weeklyData
        }
        
        // Adjust for time zone to ensure today matches local time
        let correctedStartOfWeek = calendar.startOfDay(for: startOfWeek)
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: correctedStartOfWeek) else {
                continue
            }
            let weekdayIndex = (calendar.component(.weekday, from: date) + 5) % 7 // Map Sunday to 6, Monday to 0
            let formattedDate = self.formattedDate(date)
            weeklyData[weekdayIndex] = (pastWaterData[formattedDate] ?? 0.0) / 1000.0
        }
        return weeklyData
    }
    
    func calculateMonthlyGraphData() -> [Double] {
        var monthlyData: [Double] = []
        let calendar = Calendar.current

        for week in 1...4 {
            let weekData = pastWaterData.compactMap { (key, value) -> Double? in
                guard let date = dateFormatter.date(from: key) else { return nil }
                return calendar.component(.weekOfMonth, from: date) == week ? value / 1000.0 : nil // Convert to liters
            }
            monthlyData.append(weekData.reduce(0, +))
        }
        return monthlyData
    }
    
    func calculateYearlyGraphData() -> [Double] {
        var yearlyData: [Double] = []
        let calendar = Calendar.current

        for month in 1...12 {
            let monthData = pastWaterData.compactMap { (key, value) -> Double? in
                guard let date = dateFormatter.date(from: key) else { return nil }
                return calendar.component(.month, from: date) == month ? value / 1000.0 : nil // Convert to liters
            }
            yearlyData.append(monthData.reduce(0, +))
        }
        return yearlyData
    }

    // MARK: - UserDefaults Management
    func saveToUserDefaults() {
        saveTask?.cancel()
        saveTask = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let encoder = JSONEncoder()

            // Save theme
            if let encodedTheme = try? encoder.encode(self.selectedTheme) {
                UserDefaults.standard.set(encodedTheme, forKey: self.themeKey)
            }

            // Save other data
            UserDefaults.standard.set(self.dailyGoal, forKey: self.dailyGoalKey)
            UserDefaults.standard.set(self.preferredAmount, forKey: self.preferredAmountKey)

            // Save pastWaterData (including today's intake)
            if let encodedPastWaterData = try? encoder.encode(self.pastWaterData) {
                UserDefaults.standard.set(encodedPastWaterData, forKey: self.pastWaterDataKey)
                print("Saving pastWaterData: \(self.pastWaterData)") // Debugging log
            } else {
                print("Failed to encode pastWaterData")
            }

            // Save progressByDate
            if let encodedProgressByDate = try? encoder.encode(self.progressByDate) {
                UserDefaults.standard.set(encodedProgressByDate, forKey: self.progressByDateKey)
                print("Saving progressByDate: \(self.progressByDate)") // Debugging log
            } else {
                print("Failed to encode progressByDate")
            }

            // Save imagesByDate
            let imagesData = self.imagesByDate.mapValues { $0.pngData() }
            if let encodedImages = try? encoder.encode(imagesData) {
                UserDefaults.standard.set(encodedImages, forKey: self.imagesByDateKey)
            }

            // Save water intake
            UserDefaults.standard.set(self.waterIntake, forKey: self.waterIntakeKey)
            
            // Save startTime
            UserDefaults.standard.set(startTime, forKey: "startTime")

            // Save endTime
            UserDefaults.standard.set(endTime, forKey: "endTime")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: saveTask!)
    }
    
    func loadFromUserDefaults() {
        let decoder = JSONDecoder()

        // Load theme
        if let savedThemeData = UserDefaults.standard.data(forKey: themeKey),
           let decodedTheme = try? decoder.decode(Theme.self, from: savedThemeData) {
            selectedTheme = decodedTheme
        }

        // Load other data
        dailyGoal = UserDefaults.standard.double(forKey: dailyGoalKey)
        preferredAmount = UserDefaults.standard.double(forKey: preferredAmountKey)

        // Load pastWaterData
        if let savedPastWaterData = UserDefaults.standard.data(forKey: pastWaterDataKey),
           let decodedPastWaterData = try? decoder.decode([String: Double].self, from: savedPastWaterData) {
            pastWaterData = decodedPastWaterData
            print("Loaded pastWaterData: \(pastWaterData)") // Debugging log
        } else {
            print("Failed to load pastWaterData")
        }

        // Load progressByDate
        if let savedProgressByDate = UserDefaults.standard.data(forKey: progressByDateKey),
           let decodedProgressByDate = try? decoder.decode([String: Double].self, from: savedProgressByDate) {
            progressByDate = decodedProgressByDate
            print("Loaded progressByDate: \(progressByDate)") // Debugging log
        } else {
            print("Failed to load progressByDate")
        }

        // Load imagesByDate
        if let savedImagesData = UserDefaults.standard.data(forKey: imagesByDateKey),
           let decodedImagesData = try? decoder.decode([String: Data].self, from: savedImagesData) {
            imagesByDate = decodedImagesData.compactMapValues { UIImage(data: $0) }
        }
        
        // Load startTime
        if let savedStartTime = UserDefaults.standard.object(forKey: "startTime") as? Date {
            startTime = savedStartTime
        }

        // Load endTime
        if let savedEndTime = UserDefaults.standard.object(forKey: "endTime") as? Date {
            endTime = savedEndTime
        }

        // Load water intake for today
        loadTodayData()
    }
    
    func updateSubscriptionStatus() {
            isPremiumUser = subscriptionManager.currentSubscription != nil
        }

    // MARK: Notification Manager
    class NotificationManager {
        static let shared = NotificationManager()

        func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }

    func resetAllData() {
        dailyGoal = 2000.0
        preferredAmount = 200.0
        waterIntake = 0.0
        imagesByDate.removeAll()
        progressByDate.removeAll()
        pastWaterData.removeAll()
        selectedTheme = Theme.defaultTheme

        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
    }
}

// MARK: Average Goal Achievement
extension SharedData {
    func averageGoalAchievement(for data: [Double], totalDays: Int) -> Double {
        guard !data.isEmpty, dailyGoal > 0 else { return 0.0 }
        let totalIntake = data.reduce(0.0, +)
        let totalGoal = dailyGoal * Double(totalDays)
        return (totalIntake / totalGoal) * 100000
    }

    var weeklyAverageGoalAchievement: Double {
        return averageGoalAchievement(for: weeklyGraphData, totalDays: 7)
    }

    var monthlyAverageGoalAchievement: Double {
        return averageGoalAchievement(for: monthlyGraphData, totalDays: 7 * 4)
    }

    var yearlyAverageGoalAchievement: Double {
        return averageGoalAchievement(for: yearlyGraphData, totalDays: 7 * 4 * 12)
    }
}
