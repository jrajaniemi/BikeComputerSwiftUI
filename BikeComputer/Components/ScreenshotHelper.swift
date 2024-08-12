import UIKit
import Photos
import SwiftUI

struct ScreenshotHelper: UIViewRepresentable {
    class Coordinator {
        var parent: ScreenshotHelper

        init(parent: ScreenshotHelper) {
            self.parent = parent
            NotificationCenter.default.addObserver(self, selector: #selector(captureScreenshot), name: Notification.Name("takeScreenshot"), object: nil)
        }

        @objc func captureScreenshot() {
#if DEBUG
            print("captureScreenshot() called")
#endif
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootView = window.rootViewController?.view else {

                return
            }

            let renderer = UIGraphicsImageRenderer(size: rootView.bounds.size)
            let image = renderer.image { ctx in
                rootView.drawHierarchy(in: rootView.bounds, afterScreenUpdates: true)
            }

            // Save the image to the Photos library
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { success, error in
                if success {
#if DEBUG
                    print("Screenshot saved to Photos")
#endif
                } else if error != nil {

                }
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
        self.background(ScreenshotHelper())
    }
}
