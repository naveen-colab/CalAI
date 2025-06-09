//
//  CameraViewModel.swift
//  CalAI
//
//  Created by Surya Teja Nammi on 6/8/25.
//

import Foundation
import AVFoundation
import SwiftUI
import Combine

class CameraViewModel: NSObject, ObservableObject {
    // Camera session properties
    @Published var session = AVCaptureSession()
    @Published var cameraPermissionGranted = false
    @Published var capturedImage: UIImage?
    @Published var isFlashOn = false
    @Published var isCameraUnavailable = false
    @Published var isProcessing = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    // Camera setup properties
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let photoOutput = AVCapturePhotoOutput()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        checkPermission()
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.cameraPermissionGranted = true
            self.setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.cameraPermissionGranted = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            self.cameraPermissionGranted = false
            self.showAlert = true
            self.alertMessage = "Camera access is required to use this feature. Please enable it in Settings."
        @unknown default:
            self.cameraPermissionGranted = false
            self.showAlert = true
            self.alertMessage = "Unknown camera permission status. Please try again."
        }
    }
    
    func capturePhoto() {
        print("Attempting to capture photo")
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let photoSettings = AVCapturePhotoSettings()
            print("Configured photo settings")
            
            // Configure flash
            if self.photoOutput.supportedFlashModes.contains(.on) && self.isFlashOn {
                photoSettings.flashMode = .on
            } else {
                photoSettings.flashMode = .off
            }
            
            // High quality photo - don't set dimensions here as it should match the output settings
            if #available(iOS 16.0, *) {
                // Use the same dimensions we set in setup
            } else {
                photoSettings.isHighResolutionPhotoEnabled = true
            }
            
            // Capture the photo
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    func retakePhoto() {
        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = nil
            self?.startSession()
        }
    }
    
    func toggleFlash() {
        isFlashOn.toggle()
    }
    
    func analyzeImage() {
        guard capturedImage != nil else { return }
        
        isProcessing = true
        
        // Here we would call the OpenAI service to analyze the image
        // For now, we'll just simulate a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.isProcessing = false
            
            // Navigate to the analysis view
            // This will be handled by the parent view
        }
    }
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    // Add this new method to properly configure the session
    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            
            // Remove existing inputs
            self.session.inputs.forEach { self.session.removeInput($0) }
            
            // Add video input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.session.canAddInput(videoInput) else {
                DispatchQueue.main.async {
                    self.isCameraUnavailable = true
                    self.showAlert = true
                    self.alertMessage = "Could not setup camera input."
                }
                self.session.commitConfiguration()
                return
            }
            
            self.session.addInput(videoInput)
            
            // Add photo output
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                self.photoOutput.isHighResolutionCaptureEnabled = true
                self.photoOutput.maxPhotoQualityPrioritization = .quality
            }
            
            self.session.commitConfiguration()
            
            DispatchQueue.main.async {
                self.startSession()
            }
        }
    }
    
    // Update setupCamera to use configureSession
    func setupCamera() {
        configureSession()
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.showAlert = true
                self?.alertMessage = "Error capturing photo: \(error.localizedDescription)"
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async { [weak self] in
                self?.showAlert = true
                self?.alertMessage = "Could not create image from captured data."
            }
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            print("Photo captured successfully")
            self?.capturedImage = image
            self?.stopSession()
        }
    }
}
