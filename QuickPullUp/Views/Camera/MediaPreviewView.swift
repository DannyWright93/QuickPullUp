//
//  MediaPreviewView.swift
//  QuickPullUp
//
//  Created by Danny Wright on 16.02.26.
//

import SwiftUI
import AVKit

struct MediaPreviewView: View {
    let media: CapturedMedia
    let onSave: () -> Void
    let onDelete: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if media.isVideo {
                VideoPlayer(player: AVPlayer(url: media.url))
                    .onAppear {
                        let player = AVPlayer(url: media.url)
                        player.play()
                        // Loop video
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: player.currentItem,
                            queue: .main
                        ) { _ in
                            player.seek(to: .zero)
                            player.play()
                        }
                    }
            } else {
                if let image = UIImage(contentsOfFile: media.url.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
            }
            
            // Gesture indicators
            VStack {
                Image(systemName: "arrow.up")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.top, 50)
                
                Spacer()
                
                HStack {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Spacer()
                }
                .padding(.leading, 50)
                .padding(.bottom, 100)
            }
        }
        .offset(dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    if value.translation.height < -100 {
                        // Swipe up - Save
                        onSave()
                    } else if value.translation.width < -100 {
                        // Swipe left - Delete
                        onDelete()
                    } else {
                        // Reset
                        withAnimation {
                            dragOffset = .zero
                        }
                    }
                }
        )
    }
}
