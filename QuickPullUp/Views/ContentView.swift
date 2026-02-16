//
//  ContentView.swift
//  QuickPullUp
//
//  Created by Danny Wright on 16.02.26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var settings = CameraSettings()
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            CameraView(settings: settings)
            
            // Settings button overlay
            VStack {
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
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: settings)
        }
    }
}

#Preview {
    ContentView()
}
