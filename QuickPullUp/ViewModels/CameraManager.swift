//
//  CameraManager.swift
//  QuickPullUp
//
//  Created by Danny Wright on 16.02.26.
//

import AVFoundation
import SwiftUI
import Photos

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
}

// Model for captured media
struct CapturedMedia: Identifiable {
    let id = UUID()
    let url: URL
    let isVideo: Bool
}
