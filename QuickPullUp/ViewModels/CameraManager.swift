//
//  CameraManager.swift
//  QuickPullUp
//
//  Created by Danny Wright on 16.02.26.
//

import AVFoundation
import SwiftUI
import Photos
import Combine

class CameraManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var capturedMedia: CapturedMedia?
    @Published var currentZoomFactor: CGFloat = 1.0
    
    let session = AVCaptureSession()
    private var videoOutput = AVCaptureMovieFileOutput()
    private var photoOutput = AVCapturePhotoOutput()
    private var currentCamera: AVCaptureDevice?
    
    var settings: CameraSettings
    
    // Camera types for discrete mode
    enum DiscreteCamera {
        case ultraWide
        case wide
    }
    
    @Published var selectedDiscreteCamera: DiscreteCamera = .wide
    
    init(settings: CameraSettings) {
        self.settings = settings
        super.init()
    }
    
    func checkAuthorization() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            await MainActor.run {
                isAuthorized = true
            }
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                isAuthorized = granted
            }
        default:
            await MainActor.run {
                isAuthorized = false
            }
        }
    }
    
    func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .high
        
        // Setup camera based on mode
        setupCamera()
        
        // Add outputs
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        session.commitConfiguration()
    }
    
    private func setupCamera() {
        // Remove existing inputs
        session.inputs.forEach { session.removeInput($0) }
        
        let camera: AVCaptureDevice?
        
        if settings.cameraMode == .discrete {
            // Discrete mode: specific camera selection
            camera = selectedDiscreteCamera == .ultraWide ?
                AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) :
                AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        } else {
            // Standard mode: dual camera for smooth zoom
            camera = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) ??
                     AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }
        
        guard let camera = camera,
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
            currentCamera = camera
        }
    }
    
    func startSession() {
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }
    }
    
    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
            }
        }
    }
    
    // MARK: - Zoom Control
        
        func setZoom(_ factor: CGFloat) {
            guard let device = currentCamera else { return }
            
            do {
                try device.lockForConfiguration()
                
                // Clamp zoom factor to device limits
                let maxZoom: CGFloat
                if settings.cameraMode == .discrete {
                    // In discrete mode with ultra wide, no zoom
                    if selectedDiscreteCamera == .ultraWide {
                        maxZoom = 1.0
                    } else {
                        // Wide camera can zoom
                        maxZoom = min(device.activeFormat.videoMaxZoomFactor, 3.0)
                    }
                } else {
                    // Standard mode allows full zoom range
                    maxZoom = min(device.activeFormat.videoMaxZoomFactor, 10.0)
                }
                
                let clampedZoom = max(1.0, min(factor, maxZoom))
                device.videoZoomFactor = clampedZoom
                
                device.unlockForConfiguration()
                
                DispatchQueue.main.async {
                    self.currentZoomFactor = clampedZoom
                }
            } catch {
                print("Error setting zoom: \(error)")
            }
        }
        
        func switchDiscreteCamera(to camera: DiscreteCamera) {
            guard settings.cameraMode == .discrete else { return }
            
            selectedDiscreteCamera = camera
            
            // Reconfigure session with new camera
            session.beginConfiguration()
            setupCamera()
            session.commitConfiguration()
            
            // Reset zoom
            currentZoomFactor = 1.0
        }
        
        func getMaxZoom() -> CGFloat {
            guard let device = currentCamera else { return 1.0 }
            
            if settings.cameraMode == .discrete {
                if selectedDiscreteCamera == .ultraWide {
                    return 1.0 // No zoom for ultra wide
                } else {
                    return min(device.activeFormat.videoMaxZoomFactor, 3.0)
                }
            } else {
                return min(device.activeFormat.videoMaxZoomFactor, 10.0)
            }
        }
    
    // MARK: - Capture Photo & Video
        
        func capturePhoto() {
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
        
        private var videoOutputURL: URL?
        
        func startRecording() {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            
            videoOutputURL = tempURL
            videoOutput.startRecording(to: tempURL, recordingDelegate: self)
        }
        
        func stopRecording() {
            videoOutput.stopRecording()
        }
        
        var isRecording: Bool {
            videoOutput.isRecording
        }
        
        // MARK: - Save to Photos
        
        private func saveToPhotos(url: URL, isVideo: Bool) {
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else { return }
                
                PHPhotoLibrary.shared().performChanges {
                    if isVideo {
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                    } else {
                        PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                    }
                } completionHandler: { success, error in
                    if success {
                        print("Saved to Photos")
                    } else if let error = error {
                        print("Error saving: \(error)")
                    }
                }
            }
        }
    }

    // MARK: - AVCapturePhotoCaptureDelegate

    extension CameraManager: AVCapturePhotoCaptureDelegate {
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let data = photo.fileDataRepresentation(),
                  let image = UIImage(data: data) else { return }
            
            // Save to temp file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpg")
            
            if let jpegData = image.jpegData(compressionQuality: 0.9) {
                try? jpegData.write(to: tempURL)
                
                DispatchQueue.main.async {
                    self.capturedMedia = CapturedMedia(url: tempURL, isVideo: false)
                }
            }
        }
    }

    // MARK: - AVCaptureFileOutputRecordingDelegate

    extension CameraManager: AVCaptureFileOutputRecordingDelegate {
        func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
            if let error = error {
                print("Error recording: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                self.capturedMedia = CapturedMedia(url: outputFileURL, isVideo: true)
            }
        }
    }

// Model for captured media
struct CapturedMedia: Identifiable {
    let id = UUID()
    let url: URL
    let isVideo: Bool
}
