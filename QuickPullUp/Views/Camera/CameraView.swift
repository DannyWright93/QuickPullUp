//
//  CameraView.swift
//  QuickPullUp
//
//  Created by Danny Wright on 16.02.26.
//

import SwiftUI

struct CameraView: View {
    @StateObject private var cameraManager: CameraManager
    @ObservedObject var settings: CameraSettings
    
    @State private var isRecording = false
    
    init(settings: CameraSettings) {
        self.settings = settings
        _cameraManager = StateObject(wrappedValue: CameraManager(settings: settings))
    }
    
    var body: some View {
        ZStack {
            if cameraManager.isAuthorized {
                if let media = cameraManager.capturedMedia {
                    // Show preview after capture
                    MediaPreviewView(
                        media: media,
                        onSave: {
                            saveMedia(media)
                            cameraManager.capturedMedia = nil
                        },
                        onDelete: {
                            deleteMedia(media)
                            cameraManager.capturedMedia = nil
                        }
                    )
                } else {
                    // Camera view
                    cameraInterface
                }
            } else {
                // Permission denied
                VStack {
                    Text("Camera access required")
                        .font(.title)
                    Text("Please enable camera access in Settings")
                        .foregroundColor(.gray)
                }
            }
        }
        .task {
            await cameraManager.checkAuthorization()
            if cameraManager.isAuthorized {
                cameraManager.setupSession()
                cameraManager.startSession()
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    private var cameraInterface: some View {
        ZStack {
            // Camera preview
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Controls at bottom
                HStack(spacing: 40) {
                    // Settings button
                    Button(action: {
                        // TODO: Show settings
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    
                    // Capture button
                    Button(action: {
                        if isRecording {
                            cameraManager.stopRecording()
                            isRecording = false
                        } else {
                            cameraManager.capturePhoto()
                        }
                    }) {
                        Circle()
                            .fill(isRecording ? Color.red : Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .frame(width: 80, height: 80)
                            )
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.3)
                            .onEnded { _ in
                                cameraManager.startRecording()
                                isRecording = true
                            }
                    )
                    
                    // Flip camera (placeholder for now)
                    Button(action: {
                        // TODO: Flip camera
                    }) {
                        Image(systemName: "camera.rotate")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 40)
                
                // Zoom control
                zoomControl
                    .padding(.bottom, 20)
            }
            
            // Discrete camera switcher (only in discrete mode)
            if settings.cameraMode == .discrete {
                VStack {
                    HStack(spacing: 20) {
                        Button("0.5×") {
                            cameraManager.switchDiscreteCamera(to: .ultraWide)
                        }
                        .foregroundColor(cameraManager.selectedDiscreteCamera == .ultraWide ? .yellow : .white)
                        
                        Button("1×") {
                            cameraManager.switchDiscreteCamera(to: .wide)
                        }
                        .foregroundColor(cameraManager.selectedDiscreteCamera == .wide ? .yellow : .white)
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(20)
                    .padding(.top, 60)
                    
                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder
    private var zoomControl: some View {
        let maxZoom = cameraManager.getMaxZoom()
        
        if maxZoom > 1.0 {
            if settings.zoomControlStyle == .wheel {
                // Zoom wheel (circular)
                HStack {
                    Text("\(String(format: "%.1f", cameraManager.currentZoomFactor))×")
                        .foregroundColor(.white)
                        .font(.caption)
                    
                    Slider(
                        value: Binding(
                            get: { cameraManager.currentZoomFactor },
                            set: { cameraManager.setZoom($0) }
                        ),
                        in: 1...maxZoom
                    )
                    .frame(width: 150)
                    .accentColor(.yellow)
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(20)
            } else {
                // Zoom slider (vertical)
                VStack {
                    Text("\(String(format: "%.1f", cameraManager.currentZoomFactor))×")
                        .foregroundColor(.white)
                        .font(.caption)
                    
                    Slider(
                        value: Binding(
                            get: { cameraManager.currentZoomFactor },
                            set: { cameraManager.setZoom($0) }
                        ),
                        in: 1...maxZoom
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 100, height: 200)
                    .accentColor(.yellow)
                }
            }
        }
    }
    
    private func saveMedia(_ media: CapturedMedia) {
        // Save to Photos library
        print("Saving media: \(media.url)")
        // TODO: Implement save to Photos
    }
    
    private func deleteMedia(_ media: CapturedMedia) {
        // Delete temp file
        try? FileManager.default.removeItem(at: media.url)
        print("Deleted media")
    }
}
