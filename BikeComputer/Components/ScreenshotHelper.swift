import Photos
import SwiftUI
import UIKit

struct ScreenshotHelper: UIViewRepresentable {
    class Coordinator {
        var parent: ScreenshotHelper

        init(parent: ScreenshotHelper) {
            self.parent = parent
            NotificationCenter.default.addObserver(self, selector: #selector(captureScreenshot), name: Notification.Name("takeScreenshot"), object: nil)
        }

        @objc func captureScreenshot() {
            debugPrint(msg: "captureScreenshot() called")
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootView = window.rootViewController?.view
            else {
                return
            }

            let renderer = UIGraphicsImageRenderer(size: rootView.bounds.size)
            let image = renderer.image { _ in
                rootView.drawHierarchy(in: rootView.bounds, afterScreenUpdates: true)
            }

            // Save the image to the Photos library
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { success, error in
                if success {
                    debugPrint(msg: "Screenshot saved to Photos")
                } else if error != nil {}
            })
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

extension View {
    func screenshotHelper() -> some View {
        background(ScreenshotHelper())
    }
}
