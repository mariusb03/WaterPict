//
//  ImagePicker.swift
//  WaterPic
//
//  Created by Marius Rusten on 03/12/2024.
//

import SwiftUI
import UIKit
import WidgetKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage? // Ensure this is optional
    var completion: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image // Assign to the @Binding variable
                parent.completion(image) // Pass it to the completion closure

                // ✅ Immediately save image and update widget
                if let savedPath = saveImageToFileSystem(image: image) {
                    print("📸 Image successfully saved at: \(savedPath)")

                    // ✅ Update shared UserDefaults (App Group)
                    let defaults = UserDefaults(suiteName: "group.MBR.WaterPic")
                    defaults?.set(savedPath, forKey: "selectedImagePath")
                    defaults?.synchronize()

                    print("🔄 Widget refresh triggered!")
                    WidgetCenter.shared.reloadAllTimelines() // Refresh widget
                } else {
                    print("❌ Failed to save image!")
                }
            } else {
                parent.completion(nil)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.completion(nil)
            picker.dismiss(animated: true)
        }

        /// ✅ Saves the selected image in the App Group shared directory
        private func saveImageToFileSystem(image: UIImage) -> String? {
            guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }

            // ✅ Use the App Group shared container for storage
            guard let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.MBR.WaterPic") else {
                print("❌ Failed to access App Group container!")
                return nil
            }

            let fileURL = sharedContainerURL.appendingPathComponent(UUID().uuidString + ".jpg")

            do {
                try data.write(to: fileURL)
                return fileURL.path
            } catch {
                print("❌ Error saving image: \(error.localizedDescription)")
                return nil
            }
        }
    }
}
