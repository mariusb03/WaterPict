//
//  HelpSupportView.swift
//  WaterPic
//
//  Created by Marius Bringsvor Rusten on 30/12/2024.
//


import SwiftUI

struct HelpSupportView: View {
    @EnvironmentObject var sharedData: SharedData
    
    var body: some View {
        NavigationView {
            ZStack {
                sharedData.selectedTheme.swiftBackgroundColor.edgesIgnoringSafeArea(.all) // Background color

                VStack(spacing: 20) {
                    Text(NSLocalizedString("Help & Support", comment: "Title for help and support view"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // FAQ Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text(NSLocalizedString("Frequently Asked Questions", comment: "FAQ section header"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)

                        faqItem(
                            question: NSLocalizedString("How do I track my water intake?", comment: "FAQ question"),
                            answer: NSLocalizedString("Go to the Water Intake tab and use the '+' or '-' buttons to adjust your intake!", comment: "FAQ answer")
                        )
                        faqItem(
                            question: NSLocalizedString("How do I set my daily goal?", comment: "FAQ question"),
                            answer: NSLocalizedString("Go to Settings and select 'Daily Goal' to update your target!", comment: "FAQ answer")
                        )
                    }
                    .padding()
                    .background(sharedData.selectedTheme.swiftRimColor)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .multilineTextAlignment(.center)

                    // Contact Us Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text(NSLocalizedString("Contact Us", comment: "Contact Us section header"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Button(action: openEmail) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.white)
                                Text(NSLocalizedString("Email Support", comment: "Email Support button"))
                                    .foregroundColor(.white)
                                    .underline()
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }

                        Button(action: openWebsite) {
                            HStack {
                                Image(systemName: "safari.fill")
                                    .foregroundColor(.white)
                                Text(NSLocalizedString("Visit Our Website", comment: "Visit website button"))
                                    .foregroundColor(.white)
                                    .underline()
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding()
                    .background(sharedData.selectedTheme.swiftRimColor)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .multilineTextAlignment(.center)

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

    // FAQ Item Helper
    private func faqItem(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(question)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                .underline()
                .frame(maxWidth: .infinity, alignment: .center)

            Text(answer)
                .font(.subheadline)
                .foregroundColor(sharedData.selectedTheme.swiftTextColor)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // Open Email Action
    private func openEmail() {
        let supportEmail = sharedData.supportEmail
        if let url = URL(string: "mailto:\(supportEmail)") {
            UIApplication.shared.open(url)
        }
    }

    // Open Website Action
    private func openWebsite() {
        let supportWebsite = sharedData.supportWebsite
        if let url = URL(string: supportWebsite) {
            UIApplication.shared.open(url)
        }
    }
}

struct HelpSupportView_Previews: PreviewProvider {
    static var previews: some View {
        HelpSupportView()
            .environmentObject(SharedData())
    }
}
