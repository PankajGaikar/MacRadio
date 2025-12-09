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
                    // Station name
                    Text(station.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    // Icecast metadata (current song/artist)
                    if let title = playbackService.currentTitle {
                        Text(title)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else if let artist = playbackService.currentArtist {
                        Text(artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Station metadata
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
                        
                        // AirPlay indicator
                        if playbackService.isAirPlayActive {
                            HStack(spacing: 4) {
                                Image(systemName: "airplayaudio")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                if let deviceName = playbackService.airPlayDeviceName {
                                    Text(deviceName)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                } else {
                                    Text("AirPlay")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
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
            
            // AirPlay route picker button (macOS 11+)
            if #available(macOS 11.0, *) {
                AirPlayRoutePickerButton()
                    .frame(width: 24, height: 24)
            }
            
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

