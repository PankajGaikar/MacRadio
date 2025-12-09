//
//  MediaControlsManager.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import Foundation
import MediaPlayer
import AVFoundation
import AppKit
import RadioBrowserKit

@MainActor
final class MediaControlsManager {
    private var nowPlayingInfo: [String: Any] = [:]
    private var commandCenter: MPRemoteCommandCenter?
    
    func setupMediaControls(playbackService: PlaybackService) {
        // Setup Now Playing info
        setupNowPlaying()
        
        // Setup remote command center for media controls
        setupRemoteCommandCenter(playbackService: playbackService)
        
        // Observe playback service changes
        observePlaybackService(playbackService: playbackService)
    }
    
    private func setupNowPlaying() {
        // Enable Now Playing info updates
        MPNowPlayingInfoCenter.default().playbackState = .unknown
    }
    
    private func setupRemoteCommandCenter(playbackService: PlaybackService) {
        commandCenter = MPRemoteCommandCenter.shared()
        
        // Play command
        commandCenter?.playCommand.addTarget { [weak playbackService] _ in
            guard let service = playbackService else { return .commandFailed }
            if service.currentStation != nil {
                service.resume()
                return .success
            }
            return .commandFailed
        }
        
        // Pause command
        commandCenter?.pauseCommand.addTarget { [weak playbackService] _ in
            guard let service = playbackService else { return .commandFailed }
            service.pause()
            return .success
        }
        
        // Toggle play/pause
        commandCenter?.togglePlayPauseCommand.addTarget { [weak playbackService] _ in
            guard let service = playbackService else { return .commandFailed }
            if service.isPlaying {
                service.pause()
            } else if service.currentStation != nil {
                service.resume()
            }
            return .success
        }
        
        // Stop command
        commandCenter?.stopCommand.addTarget { [weak playbackService] _ in
            guard let service = playbackService else { return .commandFailed }
            service.stop()
            return .success
        }
        
        // Change playback position (for seeking, though radio streams typically don't support this)
        commandCenter?.changePlaybackPositionCommand.isEnabled = false
        
        // Next/Previous tracks (disabled for radio)
        commandCenter?.nextTrackCommand.isEnabled = false
        commandCenter?.previousTrackCommand.isEnabled = false
    }
    
    private func observePlaybackService(playbackService: PlaybackService) {
        // Update Now Playing info when station changes
        // This will be called from PlaybackService when needed
    }
    
    func updateNowPlaying(
        station: Station?,
        title: String?,
        artist: String?,
        isPlaying: Bool
    ) {
        var info: [String: Any] = [:]
        
        if let station = station {
            // Station name
            info[MPMediaItemPropertyTitle] = station.name
            
            // Artist/Station info
            if let artist = artist {
                info[MPMediaItemPropertyArtist] = artist
            } else if let country = station.countrycode {
                info[MPMediaItemPropertyArtist] = Locale.current.localizedString(forRegionCode: country) ?? country
            }
            
            // Album/Station description
            if let tags = station.tags {
                info[MPMediaItemPropertyAlbumTitle] = tags
            }
            
            // Artwork (favicon)
            if let faviconURL = station.favicon, let url = URL(string: faviconURL) {
                Task {
                    if let image = await loadImage(from: url) {
                        let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                        info[MPMediaItemPropertyArtwork] = artwork
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
                    }
                }
            }
        }
        
        // Playback state
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
        
        // Update Now Playing info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info.isEmpty ? nil : info
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
    }
    
    private func loadImage(from url: URL) async -> NSImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return NSImage(data: data)
        } catch {
            return nil
        }
    }
}

