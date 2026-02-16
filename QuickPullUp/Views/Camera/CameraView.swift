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
    @State private var showSettings = false
    
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
                        },
                        onDelete: {
                            deleteMedia(media)
                        }
                    )
                } else {
                    // Camera view
                    cameraInterface
                }
            } else {
                // Permission denied
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Kamera-Zugriff erforderlich")
                        .font(.title2)
                    Text("Bitte aktiviere den Kamera-Zugriff in den Einstellungen")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
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
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: settings)
        }
    }
    
    private var cameraInterface: some View {
        ZStack {
            // Camera preview
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()
            
            VStack {
                // Top bar
                HStack {
                    Spacer()
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                
                Spacer()
                
                // Photo/Video mode switcher
                HStack(spacing: 30) {
                    Button("FOTO") {
                        settings.captureMode = .photo
                    }
                    .foregroundColor(settings.captureMode == .photo ? .yellow : .white)
                    .font(.system(size: 16, weight: .semibold))
                    
                    Button("VIDEO") {
                        settings.captureMode = .video
                    }
                    .foregroundColor(settings.captureMode == .video ? .yellow : .white)
                    .font(.system(size: 16, weight: .semibold))
                }
                .padding(.bottom, 20)
                
                // Capture button
                Button(action: {
                    if settings.captureMode == .photo {
                        cameraManager.capturePhoto()
                    } else {
                        if isRecording {
                            cameraManager.stopRecording() 
                            isRecording = false
                        } else {
                            cameraManager.startRecording()
                            isRecording = true
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                        
                        if settings.captureMode == .video && isRecording {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red)
                                .frame(width: 30, height: 30)
                        } else {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 65, height: 65)
                        }
                    }
                }
                .padding(.bottom, 20)
                
                // Zoom control
                zoomControl
                    .padding(.bottom, 40)
            }
            
            // Discrete camera switcher (only in discrete mode)
            if settings.cameraMode == .discrete {
                VStack {
                    HStack(spacing: 20) {
                        Button("0.5×") {
                            cameraManager.switchDiscreteCamera(to: .ultraWide)
                        }
                        .foregroundColor(cameraManager.selectedDiscreteCamera == .ultraWide ? .yellow : .white)
                        .font(.system(size: 18, weight: .semibold))
                        
                        Button("1×") {
                            cameraManager.switchDiscreteCamera(to: .wide)
                        }
                        .foregroundColor(cameraManager.selectedDiscreteCamera == .wide ? .yellow : .white)
                        .font(.system(size: 18, weight: .semibold))
                    }
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
                // iOS Standard Zoom Wheel
                iosStandardZoomWheel
            } else {
                // Horizontal Slider
                horizontalZoomSlider
            }
        }
    }
    
    private var iosStandardZoomWheel: some View {
        HStack(spacing: 15) {
            ForEach([0.5, 1.0, 2.0, 3.0], id: \.self) { zoom in
                if zoom <= cameraManager.getMaxZoom() {
                    Button(action: {
                        cameraManager.setZoom(zoom)
                    }) {
                        Text(zoom == 0.5 ? ".5" : "\(Int(zoom))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(abs(cameraManager.currentZoomFactor - zoom) < 0.3 ? .yellow : .white)
                            .frame(width: 35, height: 35)
                            .background(
                                Circle()
                                    .fill(abs(cameraManager.currentZoomFactor - zoom) < 0.3 ? Color.white.opacity(0.2) : Color.clear)
                            )
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(25)
    }
    
    private var horizontalZoomSlider: some View {
        VStack(spacing: 5) {
            Text("\(String(format: "%.1f", cameraManager.currentZoomFactor))×")
                .foregroundColor(.white)
                .font(.caption)
            
            Slider(
                value: Binding(
                    get: { cameraManager.currentZoomFactor },
                    set: { cameraManager.setZoom($0) }
                ),
                in: 1...cameraManager.getMaxZoom()
            )
            .frame(width: 200)
            .accentColor(.yellow)
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(20)
    }
    
    private func saveMedia(_ media: CapturedMedia) {
        cameraManager.saveMediaToPhotos(url: media.url, isVideo: media.isVideo) { success in
            DispatchQueue.main.async {
                if success {
                    print("✅ Saved to Photos")
                } else {
                    print("❌ Failed to save")
                }
                cameraManager.capturedMedia = nil
            }
        }
    }
    
    private func deleteMedia(_ media: CapturedMedia) {
        try? FileManager.default.removeItem(at: media.url)
        cameraManager.capturedMedia = nil
    }
}
