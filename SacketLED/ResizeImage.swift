//
//  ResizeImage.swift
//  SacketLED
//
//  Created by Oliver Elliott on 11/8/21.
//

import UIKit

extension UIImage {
    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
        
        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: targetSize.width,
            height: targetSize.height
        )

        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )

        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        
        return scaledImage
    }
}
