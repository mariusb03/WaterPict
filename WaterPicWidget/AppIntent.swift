//
//  AppIntent.swift
//  WaterPicWidget
//
//  Created by Marius Bringsvor Rusten on 23/02/2025.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}

// MARK: - Add Water Intent
struct AddWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Water"

    func perform() async throws -> some IntentResult {
        let amountToAdd: Double = 200.0 // Modify based on preferred amount
        updateWaterIntake(amount: amountToAdd)
        return .result()
    }
}

// MARK: - Remove Water Intent
struct RemoveWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Remove Water"

    func perform() async throws -> some IntentResult {
        let amountToRemove: Double = -200.0 // Modify based on preferred amount
        updateWaterIntake(amount: amountToRemove)
        return .result()
    }
}

// MARK: - Update Water Intake & Refresh Widget
func updateWaterIntake(amount: Double) {
    let currentIntake = UserDefaults.standard.double(forKey: "dailyProgress")
    let updatedIntake = max(0, min(1.0, currentIntake + amount / 3400.0)) // Normalize intake to daily goal

    UserDefaults.standard.set(updatedIntake, forKey: "dailyProgress")
    WidgetCenter.shared.reloadAllTimelines() // ✅ Refresh widget
}
