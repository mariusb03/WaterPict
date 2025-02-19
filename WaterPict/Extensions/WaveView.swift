//
//  WaveView.swift
//  WaterPic
//
//  Created by Marius Bringsvor Rusten on 05/01/2025.
//


import SwiftUI

struct WaveView: View {
    var image: UIImage
    var progress: Double
    var phase: CGFloat
    var size: CGSize

    var body: some View {
        ZStack {
            // Background Image
            Image(uiImage: image)
                .resizable()
                .scaledToFill() // Ensure the image covers the entire area
                .frame(width: size.width, height: size.height)
                .clipped() // Clip any overflow
                .opacity(0.00001)
                .cornerRadius(25)

            // Secondary Wave (adds a background wave effect)
            Image(uiImage: image.resized(to: CGSize(width: size.width, height: size.height)))
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
                .mask(
                    WaveShape(phase: phase / 2, progress: progress)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.white, .white]),
                        startPoint: .top,
                        endPoint: .bottom
                        ))
                .frame(width: size.width, height: size.height)
                .opacity(0.3)
            )
            .cornerRadius(25)

            // Foreground Wave with Masked Image
            Image(uiImage: image)
                .resizable()
                .scaledToFill() // Ensures the image fills the wave area
                .frame(width: size.width, height: size.height)
                .clipped()
                .mask(
                    WaveShape(phase: phase, progress: progress)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.white, .white]),
                        startPoint: .top,
                        endPoint: .bottom
                        ))
                .frame(width: size.width, height: size.height)
            )
            .cornerRadius(25)
        }
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
