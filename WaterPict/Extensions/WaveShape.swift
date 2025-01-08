//
//  WaveShape.swift
//  WaterPic
//
//  Created by Marius Bringsvor Rusten on 03/01/2025.
//

import SwiftUI

struct WaveShape: Shape {
    var phase: CGFloat
    var progress: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, progress) }
        set {
            phase = newValue.first
            progress = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let waveHeight = rect.height * 0.025 // Reduce the wave height (5% of the container height)
        let yOffset = rect.height * (1.0 - progress)

        path.move(to: CGPoint(x: 0, y: yOffset))
        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            let sine = sin((relativeX + phase) * .pi * 2)
            let y = yOffset + waveHeight * CGFloat(sine)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}
