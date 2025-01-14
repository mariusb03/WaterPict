//
//  CelebrationFireworksView.swift
//  WaterPic
//
//  Created by Marius Bringsvor Rusten on 05/01/2025.
//


import SwiftUI

struct CelebrationFireworksView: View {
    var geometry: GeometryProxy
    var showText: Bool
    var milestone: Int

    var body: some View {
        ZStack {
            // Add a blurred background when text is visible
            if showText {
                Color.white.opacity(0.3)
                    .ignoresSafeArea()
                    .blur(radius: 10) // Blur effect for background
                    .transition(.opacity)
            }
            
            // Predefined firework positions
            let fireworkCenters = [
                CGPoint(x: 0.3 * geometry.size.width, y: 0.2 * geometry.size.height),
                CGPoint(x: 0.7 * geometry.size.width, y: 0.3 * geometry.size.height),
                CGPoint(x: 0.5 * geometry.size.width, y: 0.5 * geometry.size.height),
                CGPoint(x: 0.3 * geometry.size.width, y: 0.8 * geometry.size.height),
                CGPoint(x: 0.7 * geometry.size.width, y: 0.7 * geometry.size.height)
            ]

            ForEach(fireworkCenters.indices, id: \.self) { index in
                FireworkWithDelayView(center: fireworkCenters[index], delay: Double(index) * 0.8)
            }

            if showText {
                VStack {
                    Text("🎉 \(milestone)% 🎉")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 10)

                    Text("🥳 Congratulations 🥳")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                }
                .transition(.scale(scale: 0.5, anchor: .center).combined(with: .opacity))
            }
        }
    }
}
