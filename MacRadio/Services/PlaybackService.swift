//
//  PlaybackService.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import Foundation
import AVFoundation
import Combine
import RadioBrowserKit

@MainActor
final class PlaybackService: NSObject, ObservableObject {
    @Published var currentStation: Station?
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var volume: Float = 1.0 {
        didSet {
            player?.volume = volume
        }
    }
    
    // Icecast metadata
    @Published var currentTitle: String?
    @Published var currentArtist: String?
    
    // AirPlay status
    @Published var isAirPlayActive: Bool = false
    @Published var airPlayDeviceName: String?
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var playbackSuccessCallback: ((Station) -> Void)?
    private var metadataObserver: NSKeyValueObservation?
    private var mediaControlsManager: MediaControlsManager?
    private var airPlayObserver: NSKeyValueObservation?
    
    override init() {
        super.init()
        setupAudioSession()
        setupMediaControls()
    }
    
    private func setupMediaControls() {
        mediaControlsManager = MediaControlsManager()
        mediaControlsManager?.setupMediaControls(playbackService: self)
    }
    
    private func setupAudioSession() {
        do {
            #if os(macOS)
            // macOS doesn't use AVAudioSession, but we can still configure the player
            #else
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func play(_ station: Station, onSuccess: @escaping (Station) -> Void) {
        guard let urlString = station.url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: urlString) else {
            errorMessage = "Invalid station URL"
            return
        }
        
        // Stop current playback
        stop()
        
        isLoading = true
        errorMessage = nil
        currentStation = station
        playbackSuccessCallback = onSuccess
        
        // Create player with Icecast metadata support
        let asset = AVURLAsset(url: url)
        
        // Enable timed metadata for Icecast streams using modern API
        if #available(macOS 13.0, *) {
            Task {
                do {
                    _ = try await asset.load(.availableMetadataFormats)
                } catch {
                    // Silently fail - metadata is optional
                }
            }
        } else {
            asset.loadValuesAsynchronously(forKeys: ["availableMetadataFormats"]) {
                // Metadata will be available through timedMetadata property
            }
        }
        
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        player?.volume = volume
        
        // Enable AirPlay (macOS automatically supports AirPlay through AVPlayer)
        player?.allowsExternalPlayback = true
        
        // Observe AirPlay status
        observeAirPlayStatus()
        
        // Observe status
        playerItem?.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        
        // Observe timed metadata for Icecast streams
        observeTimedMetadata()
        
        // Observe playback end
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        // Play
        player?.play()
        isPlaying = true
        
        // Update media controls
        updateMediaControls()
        
        // Record click
        Task {
            do {
                _ = try await RadioBrowserService.shared.click(stationUUID: station.stationuuid)
            } catch {
                // Silently fail - don't interrupt playback
                print("Failed to record click: \(error.localizedDescription)")
            }
        }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        updateMediaControls()
    }
    
    func resume() {
        player?.play()
        isPlaying = true
        updateMediaControls()
    }
    
    func stop() {
        player?.pause()
        playerItem?.removeObserver(self, forKeyPath: "status")
        NotificationCenter.default.removeObserver(self)
        metadataObserver?.invalidate()
        metadataObserver = nil
        airPlayObserver?.invalidate()
        airPlayObserver = nil
        player = nil
        playerItem = nil
        currentStation = nil
        currentTitle = nil
        currentArtist = nil
        isAirPlayActive = false
        airPlayDeviceName = nil
        isPlaying = false
        isLoading = false
        playbackSuccessCallback = nil
        updateMediaControls()
    }
    
    private func observeAirPlayStatus() {
        // Observe external playback status (AirPlay)
        airPlayObserver = player?.observe(\.isExternalPlaybackActive, options: [.new]) { [weak self] player, _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isAirPlayActive = player.isExternalPlaybackActive
                // Note: Device name is not directly available, but we can indicate AirPlay is active
            }
        }
    }
    
    private func updateMediaControls() {
        mediaControlsManager?.updateNowPlaying(
            station: currentStation,
            title: currentTitle,
            artist: currentArtist,
            isPlaying: isPlaying
        )
    }
    
    private func observeTimedMetadata() {
        // Use AVPlayerItemMetadataOutput for modern metadata observation
        let metadataOutput = AVPlayerItemMetadataOutput(identifiers: nil)
        metadataOutput.setDelegate(self, queue: DispatchQueue.main)
        
        if let playerItem = playerItem {
            // Remove existing outputs
            playerItem.outputs.forEach { playerItem.remove($0) }
            playerItem.add(metadataOutput)
        }
        
        // Also observe timedMetadata for older API compatibility
        if #available(macOS 10.15, *) {
            // Use metadata output delegate instead
        } else {
            metadataObserver = playerItem?.observe(\.timedMetadata, options: [.new]) { [weak self] item, _ in
                guard let self = self, let metadata = item.timedMetadata else { return }
                
                Task { @MainActor in
                    let parsed = IcecastMetadataParser.parseTimedMetadata(metadata)
                    if let title = parsed.title {
                        self.currentTitle = title
                    }
                    if let artist = parsed.artist {
                        self.currentArtist = artist
                    }
                }
            }
        }
    }
    
    @objc private func playerDidFinishPlaying() {
        // This indicates successful playback started
        if let station = currentStation {
            playbackSuccessCallback?(station)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let item = playerItem {
                switch item.status {
                case .failed:
                    errorMessage = item.error?.localizedDescription ?? "Playback failed"
                    isPlaying = false
                    isLoading = false
                    playbackSuccessCallback = nil
                case .readyToPlay:
                    isLoading = false
                    // If we're playing and ready, consider it successful
                    if isPlaying {
                        // Give it a moment to actually start playing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                            if let self = self, self.isPlaying, let station = self.currentStation {
                                self.playbackSuccessCallback?(station)
                                self.playbackSuccessCallback = nil
                            }
                        }
                    }
                default:
                    break
                }
            }
        }
    }
    
    deinit {
        player?.pause()
        playerItem?.removeObserver(self, forKeyPath: "status")
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - AVPlayerItemMetadataOutputPushDelegate
extension PlaybackService: @preconcurrency AVPlayerItemMetadataOutputPushDelegate {
    nonisolated func metadataOutput(_ output: AVPlayerItemMetadataOutput, didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup], from track: AVPlayerItemTrack?) {
                Task { @MainActor in
                    for group in groups {
                        let parsed = IcecastMetadataParser.parseTimedMetadata(group.items)
                        if let title = parsed.title {
                            self.currentTitle = title
                        }
                        if let artist = parsed.artist {
                            self.currentArtist = artist
                        }
                    }
                    // Update media controls when metadata changes
                    self.updateMediaControls()
                }
    }
}

