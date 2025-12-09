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
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private let radioBrowser = RadioBrowser()
    private var playbackSuccessCallback: ((Station) -> Void)?
    
    override init() {
        super.init()
        setupAudioSession()
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
        
        // Create player
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.volume = volume
        
        // Observe status
        playerItem?.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        
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
        
        // Record click
        Task {
            do {
                _ = try await radioBrowser.click(stationUUID: station.stationuuid)
            } catch {
                // Silently fail
            }
        }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func resume() {
        player?.play()
        isPlaying = true
    }
    
    func stop() {
        player?.pause()
        playerItem?.removeObserver(self, forKeyPath: "status")
        NotificationCenter.default.removeObserver(self)
        player = nil
        playerItem = nil
        currentStation = nil
        isPlaying = false
        isLoading = false
        playbackSuccessCallback = nil
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

