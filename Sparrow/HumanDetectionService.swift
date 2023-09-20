//Created for Sparrow in 2023
// Using Swift 5.0

import CoreML
import UIKit
import Vision

/**
The HumanDetectionServiceProtocol protocol defines the methods required for human detection and tracking services.
*/

protocol HumanDetectionServiceProtocol {
    /**
     Detects a person in the given CMSampleBuffer and returns a PersonModel if a person is detected.
     
     - Parameter image: The CMSampleBuffer containing the image data to perform the detection on.
     - Returns: A PersonModel object representing the detected person, or nil if no person is detected.
     */
    
    func detectPerson(in image: CMSampleBuffer) -> PersonModel?
    
    /**
     Tracks a person within the specified bounding box in the given CMSampleBuffer and returns a PersonModel for the tracked person.
     
     - Parameters:
        - bondigBox: The CGRect bounding box representing the initial location of the person to track.
        - image: The CMSampleBuffer containing the image data to perform the tracking on.
     - Returns: A PersonModel object representing the tracked person, or nil if tracking fails or no person is found.
     */
    
    func trackPerson(bondigBox : CGRect, image: CMSampleBuffer) -> PersonModel?

}

/**
The HumanDetectionService class implements the HumanDetectionServiceProtocol protocol and provides human detection and tracking functionality.
*/
class HumanDetectionService: HumanDetectionServiceProtocol {
    
    private let detectionModel: VNCoreMLModel
    /**
     Initialize the HumanDetectionService with the specified Core ML model.
     
     - Parameter model: The VNCoreMLModel to be used for person detection.
     */
    init(model: VNCoreMLModel) {
        self.detectionModel = model
    }
    
    ///Use YOLO model's request handler in order to request for detection
    func detectPerson(in image: CMSampleBuffer) -> PersonModel? {
        
        var personModel : PersonModel!
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(image) else {
                    return nil
                }
        
        let request = VNCoreMLRequest(model: detectionModel) { request, error in
                guard let results = request.results as? [VNRecognizedObjectObservation],
                      let personObservation = results.first(where: { $0.labels.first?.identifier == "person" }) else {
                    return
                }

                let boundingBox = personObservation.boundingBox
                personModel = PersonModel(confidence: personObservation.confidence , location: boundingBox)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform object detection request: \(error)")
        }
        
        return personModel
    }
    
    ///Use YOLO model's request handler in order to request for Tracking already detected human

    func trackPerson(bondigBox : CGRect, image: CMSampleBuffer) -> PersonModel?{

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(image) else {
                    return nil
                }
        
        var inputObservation = VNDetectedObjectObservation(boundingBox: bondigBox)
        let requestHandler = VNSequenceRequestHandler()
        let request = VNTrackObjectRequest(detectedObjectObservation: inputObservation)

        do {
            try requestHandler.perform([request], on: pixelBuffer, orientation: .up)
           } catch {
            print("Tracking failed.")
           }
        guard let observation = request.results?.first as? VNDetectedObjectObservation else { return nil }
        inputObservation = observation
        
        let personModel = PersonModel(confidence: observation.confidence , location: observation.boundingBox)

        return personModel
    }
}
/*
The code above defines a protocol `HumanDetectionServiceProtocol` that outlines the methods required for human detection and tracking services. The `HumanDetectionService` class implements this protocol and provides the actual implementation for detecting and tracking persons using Core ML and Vision frameworks.

The `HumanDetectionService` class has a private property `detectionModel` of type `VNCoreMLModel`, which represents the Core ML model used for person detection. This model is initialized in the constructor.

The class implements the `detectPerson(in:)` method to perform person detection on a given `CMSampleBuffer`. It uses the `VNCoreMLRequest` class to make a request using the detection model. The results are processed to find the first observation with a label identifier of "person". The bounding box and confidence level of the person observation are then used to create a `PersonModel` object, which is returned.

The `trackPerson(bondigBox:image:)` method is responsible for tracking a person within a specified bounding box. It takes the initial bounding box, represented by a `CGRect`, and the image buffer in the form of a `CMSampleBuffer`. It uses the `VNSequenceRequestHandler` and `VNTrackObjectRequest` classes for performing the tracking. The resulting observation is then used to create a `PersonModel` object, which is returned.

Both methods handle errors that may occur during the detection or tracking process and provide appropriate error messages.
*/
