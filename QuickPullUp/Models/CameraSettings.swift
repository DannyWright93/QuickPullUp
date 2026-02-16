//
//  CameraSettings.swift
//  QuickPullUp
//
//  Created by Danny Wright on 16.02.26.
//

import Foundation

enum ZoomControlStyle: String, Codable, CaseIterable {
    case wheel = "Zoom Rad"
    case slider = "Zoom Leiste"
}

enum CameraMode: String, Codable, CaseIterable {
    case discrete = "Diskrete Auswahl"
    case standard = "Standard iOS"
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
    }
}
