//
//  StationRowView.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import SwiftUI
import RadioBrowserKit

struct StationRowView: View {
    let station: Station
    let isFavorite: Bool
    let isPlaying: Bool
    let onPlay: () -> Void
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack {
            // Station info
            VStack(alignment: .leading, spacing: 4) {
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
                    
                    if let bitrate = station.bitrate {
                        Text("\(bitrate) kbps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let tags = station.tags, !tags.isEmpty {
                    Text(tags)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Play button
            Button(action: onPlay) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            
            // Favorite button
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(isFavorite ? .red : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

