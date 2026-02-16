//
//  SettingsView.swift
//  QuickPullUp
//
//  Created by Danny Wright on 16.02.26.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: CameraSettings
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Zoom-Steuerung")) {
                    Picker("Stil", selection: $settings.zoomControlStyle) {
                        ForEach(ZoomControlStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    switch settings.zoomControlStyle {
                    case .wheel:
                        Text("Modernes Zoom-Rad wie bei iOS Standard")
                            .font(.caption)
                            .foregroundColor(.gray)
                    case .slider:
                        Text("Klassische Zoom-Leiste")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Kamera-Modus")) {
                    Picker("Modus", selection: $settings.cameraMode) {
                        ForEach(CameraMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    switch settings.cameraMode {
                    case .discrete:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Wechsel zwischen Weitwinkel (0.5×) und Normal (1×)")
                            Text("• Weitwinkel: kein Zoom")
                            Text("• Normal: Zoom möglich")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                        
                    case .standard:
                        Text("Sanftes Zoomen von 0.5× bis 10× wie bei iOS Standard. Automatischer Kamerawechsel.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Über")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}
