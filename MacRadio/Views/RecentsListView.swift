//
//  RecentsListView.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import SwiftUI
import RadioBrowserKit

struct RecentsListView: View {
    @ObservedObject var viewModel: RecentsViewModel
    @ObservedObject var playbackService: PlaybackService
    @ObservedObject var favoritesViewModel: FavoritesViewModel
    
    var body: some View {
        if viewModel.recents.isEmpty {
            VStack {
                Text("No recent stations")
                    .foregroundColor(.secondary)
                Text("Play stations to see them here")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(viewModel.recents) { recent in
                if let station = viewModel.toStation(recent) {
                    StationRowView(
                        station: station,
                        isFavorite: favoritesViewModel.isFavorite(station.stationuuid),
                        isPlaying: playbackService.currentStation?.stationuuid == station.stationuuid && playbackService.isPlaying,
                        onPlay: {
                            playbackService.play(station) { playedStation in
                                viewModel.addRecent(playedStation)
                            }
                        },
                        onToggleFavorite: {
                            favoritesViewModel.toggleFavorite(from: station)
                        }
                    )
                }
            }
        }
    }
}

