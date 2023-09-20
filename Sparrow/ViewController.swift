//Created for Sparrow in 2023
// Using Swift 5.0

import UIKit
import CoreML
import AVFoundation
import Vision

class ViewController: UIViewController ,AVCaptureVideoDataOutputSampleBufferDelegate{

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    var previousShapeLayer: CAShapeLayer?
    var isPersonMoving = false
    var isDetected = false

    var viewModel: DetectionViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        /// Selects Yolov3FP16 Model
//        guard let model = try? VNCoreMLModel(for: YOLOv3FP16(configuration: MLModelConfiguration()).model)
//        else {
//            return
//        }
        
        /// Selects Yolov3TinyFP16 Model
        guard let model = try? VNCoreMLModel(for: YOLOv3TinyFP16(configuration: MLModelConfiguration()).model)
        else {
            return
        }

        self.viewModel = DetectionViewModel(detectionService: HumanDetectionService(model: model))

        // Set up the capture session
        let captureSession = setupCamera()
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
        }
    }

    ///Typical camera setup config
    func setupCamera() -> AVCaptureSession{
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else {
            fatalError("Failed to create AVCaptureSession")
        }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            fatalError("Failed to access the camera")
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession.addInput(input)
        } catch {
            fatalError("Failed to create AVCaptureDeviceInput: \(error)")
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)

        // Set up the preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        if let previewLayer = previewLayer {
            view.layer.insertSublayer(previewLayer, at: 0)
        }
        
        return captureSession
    }
    
    /**
            Delegate function to get output buffer of camera
    */
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        var rect : CGRect!
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.removePreviousShapeLayer()

            if !self.isDetected {
                print("Detecting...")
                if let detectedPerson = self.viewModel.detectPerson(in: sampleBuffer) {
                    print(detectedPerson.location)
                    print(detectedPerson.confidence)
                    
                    // Draw a rectangle around the detected person
                    rect = CGRect(x: detectedPerson.location.origin.x * self.view.frame.size.width,
                                      y: detectedPerson.location.origin.y * self.view.frame.size.height,
                                      width: detectedPerson.location.size.width * self.view.frame.size.width,
                                      height: detectedPerson.location.size.height * self.view.frame.size.height)
                    
                    // Check if the person is moving or stationary
                    let isMoving = self.isPersonMoving(with: rect)
                    
                    // Set the stroke color based on whether the person is moving or stationary
                    let strokeColor = isMoving ? UIColor.red.cgColor : UIColor.green.cgColor
                    // Draw the rectangle with the appropriate stroke color
                    self.drawRectangle(on: self.view, rect: rect, strokeColor: strokeColor)
                    
                    // Update the `isPersonMoving` flag
                    self.isPersonMoving = isMoving
                    self.isDetected = true
                }
            }else{
                if rect != nil {
                    print("Tracking...")
                    let trackedPerson = self.viewModel.trackPerson(bondigBox: rect, image: sampleBuffer)
                    let trackRect = CGRect(x: trackedPerson!.location.origin.x * self.view.frame.size.width,
                        y: trackedPerson!.location.origin.y * self.view.frame.size.height,
                        width: trackedPerson!.location.size.width * self.view.frame.size.width,
                        height: trackedPerson!.location.size.height * self.view.frame.size.height)
                    self.drawRectangle(on: self.view, rect: rect, strokeColor: UIColor.blue.cgColor)
                }else{
                    self.isDetected = false
                }
            }
        }
    }
    
    ///Checking for when to trigger the action
    func isPersonMoving(with rect: CGRect) -> Bool {

        let centerX = rect.origin.x + rect.size.width / 2
        let centerY = rect.origin.y + rect.size.height / 2
        let viewCenterX = view.frame.size.width / 2
        let viewCenterY = view.frame.size.height / 2
        
        let distanceThreshold: CGFloat = 50
        
        let distance = sqrt(pow(centerX - viewCenterX, 2) + pow(centerY - viewCenterY, 2))
        
        return distance > distanceThreshold
    }
    
    ///Draw Bondinbox function (needs accuracy)
    func drawRectangle(on view: UIView, rect: CGRect, strokeColor: CGColor) {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor
        shapeLayer.lineWidth = 4.0
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.frame = view.bounds
        
        let path = UIBezierPath(rect: rect)
        shapeLayer.path = path.cgPath
        
        view.layer.addSublayer(shapeLayer)
        
        previousShapeLayer = shapeLayer
    }
    
    ///Removing previously drawn bondingBox
    func removePreviousShapeLayer() {
        previousShapeLayer?.removeFromSuperlayer()
        previousShapeLayer = nil
    }
    
    ///Deiniting session, preventing memory leakage
    deinit {
        captureSession?.stopRunning()
    }

}

/*
## Overview

This ViewController sets up a camera and uses CoreML to detect humans in the camera frame. It displays a bounding box around detected humans and tracks them as they move around. The bounding box color indicates whether the human is stationary (green) or moving (red).

## Class Properties

- `captureSession`: The AVCaptureSession that manages the camera input and video output.

- `previewLayer`: The AVCaptureVideoPreviewLayer that displays the camera preview.

- `previousShapeLayer`: Reference to the last drawn CAShapeLayer so it can be removed before drawing a new one.

- `isPersonMoving`: Bool indicating if the last detected person is moving or stationary.

- `isDetected`: Bool indicating if a person has been detected yet.

- `viewModel`: The DetectionViewModel that handles the CoreML human detection and tracking.

## ViewController Lifecycle

- `viewDidLoad()`: Sets up the CoreML model, DetectionViewModel, and camera capture session. Starts the capture session on a background queue.

- `setupCamera()`: Configures the capture session with video input and output. Sets up the preview layer.

- `captureOutput()`: The delegate callback that runs CoreML human detection on each video frame. Draws the bounding box around any detected humans.

- `isPersonMoving()`: Checks if the center of the detected bounding box is beyond a threshold distance from the center of the view to determine if the person is moving.

- `drawRectangle()`: Draws the bounding box CAShapeLayer for a detected human.

- `removePreviousShapeLayer()`: Removes any previously drawn bounding box layers.

- `deinit`: Stops the capture session when ViewController is deallocated.

## DetectionViewModel

- `detectPerson()`: Runs human detection on a video frame and returns detection result.

- `trackPerson()`: Runs human tracking on subsequent frames to follow a detected person.

This handles the CoreML logic so the ViewController can focus on the camera setup and UI display.
*/
