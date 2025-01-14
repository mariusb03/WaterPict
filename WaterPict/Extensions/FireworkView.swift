//
//  FireworkView.swift
//  WaterPic
//
//  Created by Marius Bringsvor Rusten on 03/01/2025.
//

import SwiftUI

struct RealisticFireworkView: View {
    let center: CGPoint
    @State private var particles: [Particle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .animation(particle.animation, value: particle.opacity)
            }
        }
        .onAppear {
            generateFireworkParticles()
        }
    }

    private func generateFireworkParticles() {
        let particleCount = Int.random(in: 15...30) // Increased number of particles for bigger fireworks

        for _ in 0..<particleCount {
            let angle = Double.random(in: 0..<2 * .pi)
            let distance = CGFloat.random(in: 100...250) // Increased spread distance for particles
            let xOffset = cos(angle) * distance
            let yOffset = sin(angle) * distance

            let particle = Particle(
                id: UUID(),
                position: center,
                size: CGFloat.random(in: 7...15), // Larger particle sizes
                color: Color.random(),
                animation: Animation.easeOut(duration: 3.0),
                opacity: 1.0
            )

            particles.append(particle)

            // Update particle position and fade-out effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                    withAnimation {
                        particles[index].position = CGPoint(x: center.x + xOffset, y: center.y + yOffset)
                        particles[index].opacity = 0.0
                    }
                }
            }
        }
    }
}

struct FireworkWithDelayView: View {
    let center: CGPoint
    let delay: Double
    @State private var isVisible = false

    var body: some View {
        ZStack {
            if isVisible {
                RealisticFireworkView(center: center)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Trigger the firework display with a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(Animation.easeInOut(duration: 0.5)) {
                    isVisible = true
                }
                // Remove the firework after a duration
                DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                    withAnimation(Animation.easeOut(duration: 2.0)) {
                        isVisible = false
                    }
                }
            }
        }
    }
}


// Particle Model
struct Particle: Identifiable {
    let id: UUID
    var position: CGPoint
    let size: CGFloat
    let color: Color
    let animation: Animation
    var opacity: Double
}

// Random Color Extension
extension Color {
    static func random() -> Color {
        return Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }
}
