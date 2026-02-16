//
//  CameraSettings.swift
//  QuickPullUp
//
//  Created by Danny Wright on 16.02.26.
//

import Foundation
import Combine

enum ZoomControlStyle: String, Codable, CaseIterable {
    case wheel = "Zoom Rad"
    case slider = "Zoom Leiste"
}

enum CameraMode: String, Codable, CaseIterable {
    case discrete = "Diskrete Auswahl"
    case standard = "Standard iOS"
}

enum CaptureMode: String, Codable, CaseIterable {
    case photo = "Foto"
    case video = "Video"
}

class CameraSettings: ObservableObject {
    @Published var zoomControlStyle: ZoomControlStyle {
        didSet {
            UserDefaults.standard.set(zoomControlStyle.rawValue, forKey: "zoomControlStyle")
        }
    }
    
    @Published var cameraMode: CameraMode {
        didSet {
            UserDefaults.standard.set(cameraMode.rawValue, forKey: "cameraMode")
        }
    }
    
    @Published var captureMode: CaptureMode {
        didSet {
            UserDefaults.standard.set(captureMode.rawValue, forKey: "captureMode")
        }
    }
    
    init() {
        // Load saved settings or use defaults
        if let savedZoomStyle = UserDefaults.standard.string(forKey: "zoomControlStyle"),
           let zoomStyle = ZoomControlStyle(rawValue: savedZoomStyle) {
            self.zoomControlStyle = zoomStyle
        } else {
            self.zoomControlStyle = .wheel
        }
        
        if let savedCameraMode = UserDefaults.standard.string(forKey: "cameraMode"),
           let mode = CameraMode(rawValue: savedCameraMode) {
            self.cameraMode = mode
        } else {
            self.cameraMode = .standard
        }
        if let savedCaptureMode = UserDefaults.standard.string(forKey: "captureMode"),
           let mode = CaptureMode(rawValue: savedCaptureMode) {
            self.captureMode = mode
        } else {
            self.captureMode = .photo
        }
    }
}
