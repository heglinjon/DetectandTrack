//Created for Sparrow in 2023
// Using Swift 5.0

import Foundation
import UIKit
import AVFoundation

/**
The DetectionViewModel class provides a view model for interacting with the human detection functionality.
It utilizes an underlying HumanDetectionServiceProtocol to perform person detection and tracking operations.
*/
class DetectionViewModel {
    private let detectionService: HumanDetectionServiceProtocol
    
    /**
     Initializes a new instance of the `DetectionViewModel` class.
     
     - Parameter detectionService: An object conforming to the `HumanDetectionServiceProtocol` that provides the human detection functionality.
     */
    init(detectionService: HumanDetectionServiceProtocol) {
        self.detectionService = detectionService
    }
    
    /**
     Detects a person in the given image using the underlying detection service.
     
     - Parameter image: A `CMSampleBuffer` representing the image to perform the detection on.
     
     - Returns: A `PersonModel` object representing the detected person, or `nil` if no person was detected.
     */
    func detectPerson(in image: CMSampleBuffer) -> PersonModel? {
        return detectionService.detectPerson(in: image)
    }
    
    /**
     Tracks a person using the provided bounding box and image using the underlying detection service.
     
     - Parameter boundingBox: A `CGRect` representing the bounding box of the person to track.
     - Parameter image: A `CMSampleBuffer` representing the image to perform the tracking on.
     
     - Returns: A `PersonModel` object representing the tracked person, or `nil` if the tracking failed.
     */
    func trackPerson(bondigBox : CGRect, image: CMSampleBuffer)  -> PersonModel? {
        return detectionService.trackPerson(bondigBox : bondigBox, image: image)
    }
}
/*
The `DetectionViewModel` class acts as a mediator between the UI and the underlying `HumanDetectionServiceProtocol`. It provides convenient methods to detect and track a person in an image by utilizing the methods exposed by the `HumanDetectionServiceProtocol` implementation.

To use the `DetectionViewModel`, you need to initialize an instance of it with a concrete implementation of the `HumanDetectionServiceProtocol`. Then, you can call the `detectPerson` and `trackPerson` methods on the view model to perform the respective operations.
*/
