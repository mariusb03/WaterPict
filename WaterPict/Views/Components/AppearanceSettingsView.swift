//
//  AppearanceSettingsView.swift
//  WaterPic
//
//  Created by Marius Bringsvor Rusten on 26/12/2024.
//

import SwiftUI

struct Theme: Identifiable, Equatable {
    @EnvironmentObject var sharedData: SharedData
    var id: UUID = UUID()
    var backgroundColor: UIColor
    var rimColor: UIColor
    var textColor: UIColor

    var swiftBackgroundColor: Color { Color(backgroundColor) }
    var swiftRimColor: Color { Color(rimColor) }
    var swiftTextColor: Color { Color(textColor) }

    static let blueTheme = Theme(backgroundColor: .myBlue, rimColor: .myLightBlue, textColor: .white)
    static let darkTheme = Theme(backgroundColor: .myDark, rimColor: .myLighterDark, textColor: .white)
    
    static let redTheme = Theme(backgroundColor: .myRed, rimColor: .myLighterRed, textColor: .white)
    
    static let purpleTheme = Theme(backgroundColor: .purple, rimColor: .red, textColor: .white)
    
    static let beigeTheme = Theme(backgroundColor: .myBeige, rimColor: .myGreen, textColor: .myGreen)
    
    static let defaultTheme = blueTheme
    
    // Equatable implementation
    static func == (lhs: Theme, rhs: Theme) -> Bool {
        print("Comparing \(lhs) and \(rhs)")
        return lhs.backgroundColor == rhs.backgroundColor &&
               lhs.rimColor == rhs.rimColor &&
               lhs.textColor == rhs.textColor
    }
}

// Extend Theme to conform to Codable
extension Theme: Codable {
    enum CodingKeys: String, CodingKey {
        case id, backgroundColor, rimColor, textColor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        backgroundColor = UIColor(hex: try container.decode(String.self, forKey: .backgroundColor)) ?? .myBlue
        rimColor = UIColor(hex: try container.decode(String.self, forKey: .rimColor)) ?? .myLightBlue
        textColor = UIColor(hex: try container.decode(String.self, forKey: .textColor)) ?? .white
        
        backgroundColor = UIColor(hex: try container.decode(String.self, forKey: .backgroundColor)) ?? .myDark
        rimColor = UIColor(hex: try container.decode(String.self, forKey: .rimColor)) ?? .myLighterDark
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(backgroundColor.toHex() ?? "#0000FF", forKey: .backgroundColor)
        try container.encode(rimColor.toHex() ?? "#FFFFFF", forKey: .rimColor)
        try container.encode(textColor.toHex() ?? "#FFFFFF", forKey: .textColor)
    }
}

import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject var sharedData: SharedData
    @Binding var selectedTheme: Theme
    let themes: [Theme] = [.blueTheme, .darkTheme, .beigeTheme, .purpleTheme, .redTheme]

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            sharedData.selectedTheme.swiftBackgroundColor
                .ignoresSafeArea() // Background Color
            
            ScrollView {
                VStack(spacing: 20) {
                    BannerAdView(adUnitID: "ca-app-pub-2002393296074661/7345138591")
                        .frame(height: 50)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    Text("Select a Theme")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                        .padding(.top, 50)

                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(themes) { theme in
                            Button(action: {
                                selectedTheme = theme
                                sharedData.selectedTheme = theme
                                sharedData.saveToUserDefaults() // Save the selected theme
                            }) {
                                VStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(theme.swiftBackgroundColor)
                                        .frame(width: UIScreen.main.bounds.width * 0.35, height: UIScreen.main.bounds.width * 0.35)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(theme.swiftRimColor, lineWidth: 10)
                                                .shadow(radius: 1)
                                        )

                                    Text(themeName(for: theme))
                                        .font(.headline)
                                        .foregroundColor(theme.swiftTextColor)
                                }
                                .padding()
                                .background(selectedTheme == theme ? Color.myDark.opacity(0.1) : Color.clear)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .padding()
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 60)
                .stroke(sharedData.selectedTheme.swiftRimColor, lineWidth: 25)
                .shadow(radius: 5)
                .ignoresSafeArea()
        )
    }

    // Helper function to return theme names
    private func themeName(for theme: Theme) -> String {
        switch theme {
        case .blueTheme:
            return "Blue"
        case .darkTheme:
            return "Dark"
        case .redTheme:
            return "Red"
        case .purpleTheme:
            return "Purple"
        case .beigeTheme:
            return "Beige"
        default:
            return "Custom"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SharedData())
}
