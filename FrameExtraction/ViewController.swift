//
//  ViewController.swift
//  FrameExtraction
//
//  Created by admin on 2020. 10. 08..
//  Copyright © 2020. admin. All rights reserved.
//

import UIKit
import AVFoundation
import MLKit

class ViewController: UIViewController, FrameExtractorDelegate {

    @IBOutlet weak var imageView: UIImageView!
    var frameExtractor: FrameExtractor!
    var faceDetector: FaceDetector!
    
    /// An overlay view that displays detection annotations.
    private lazy var annotationOverlayView: UIView = {
      precondition(isViewLoaded)
      let annotationOverlayView = UIView(frame: .zero)
      annotationOverlayView.translatesAutoresizingMaskIntoConstraints = false
      return annotationOverlayView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self
        
        imageView.addSubview(annotationOverlayView)
        NSLayoutConstraint.activate([
          annotationOverlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
          annotationOverlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
          annotationOverlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
          annotationOverlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
        ])
        
        // High-accuracy landmark detection and face classification
        let options = FaceDetectorOptions()
        options.performanceMode = .accurate
        options.landmarkMode = .all
        options.classificationMode = .all
        options.contourMode = .all
        
        faceDetector = FaceDetector.faceDetector(options: options)
    }

    func captured(image: UIImage) {
        imageView.image = image
        removeDetectionAnnotations()
        setupFaceDetection(imageTaken: image)
    }
    
    func setupFaceDetection(imageTaken: UIImage){
        
        
        // Initialize a VisionImage object with the given UIImage.
        let visionImage = VisionImage(image: imageTaken)
        visionImage.orientation = imageTaken.imageOrientation
        
        faceDetector.process(visionImage) { faces, error in
                guard error == nil, let faces = faces, !faces.isEmpty else {
                  // ...
                  return
                }

                // Faces detected
                // ...
                  print("face found")
                  for face in faces {
                      
                      
                      
                      let transform = self.transformMatrix()
                      let transformedRect = face.frame.applying(transform)
                      UIUtilities.addRectangle(
                        transformedRect,
                        to: self.annotationOverlayView,
                        color: UIColor.green
                      )
                      
                  }

              }
        
    }
    
    private func transformMatrix() -> CGAffineTransform {
      guard let image = imageView.image else { return CGAffineTransform() }
      let imageViewWidth = imageView.frame.size.width
      let imageViewHeight = imageView.frame.size.height
      let imageWidth = image.size.width
      let imageHeight = image.size.height

      let imageViewAspectRatio = imageViewWidth / imageViewHeight
      let imageAspectRatio = imageWidth / imageHeight
      let scale =
        (imageViewAspectRatio > imageAspectRatio)
        ? imageViewHeight / imageHeight : imageViewWidth / imageWidth

      // Image view's `contentMode` is `scaleAspectFit`, which scales the image to fit the size of the
      // image view by maintaining the aspect ratio. Multiple by `scale` to get image's original size.
      let scaledImageWidth = imageWidth * scale
      let scaledImageHeight = imageHeight * scale
      let xValue = (imageViewWidth - scaledImageWidth) / CGFloat(2.0)
      let yValue = (imageViewHeight - scaledImageHeight) / CGFloat(2.0)

      var transform = CGAffineTransform.identity.translatedBy(x: xValue, y: yValue)
      transform = transform.scaledBy(x: scale, y: scale)
      return transform
    }
    
    /// Removes the detection annotations from the annotation overlay view.
    private func removeDetectionAnnotations() {
      for annotationView in annotationOverlayView.subviews {
        annotationView.removeFromSuperview()
      }
    }
    
}

