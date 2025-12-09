//
//  PlayerView.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import SwiftUI
import RadioBrowserKit

struct PlayerView: View {
    @ObservedObject var playbackService: PlaybackService
    
    var body: some View {
        HStack(spacing: 16) {
            // Station info
            if let station = playbackService.currentStation {
                VStack(alignment: .leading, spacing: 2) {
                    Text(station.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        if let country = station.countrycode {
                            Text(country.uppercased())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let codec = station.codec {
                            Text(codec)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                Text("No station playing")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Loading indicator
            if playbackService.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
            
            // Error message
            if let error = playbackService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .lineLimit(1)
            }
            
            // Play/Pause button
            Button(action: {
                if playbackService.isPlaying {
                    playbackService.pause()
                } else if playbackService.currentStation != nil {
                    playbackService.resume()
                }
            }) {
                Image(systemName: playbackService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .disabled(playbackService.currentStation == nil)
            
            // Stop button
            Button(action: {
                playbackService.stop()
            }) {
                Image(systemName: "stop.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(playbackService.currentStation == nil)
            
            // Volume control
            HStack(spacing: 4) {
                Image(systemName: "speaker.wave.2")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(value: $playbackService.volume, in: 0...1)
                    .frame(width: 100)
                
                Image(systemName: "speaker.wave.3")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

