//
//  FavoritesListView.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import SwiftUI
import RadioBrowserKit

struct FavoritesListView: View {
    @ObservedObject var viewModel: FavoritesViewModel
    @ObservedObject var playbackService: PlaybackService
    @ObservedObject var recentsViewModel: RecentsViewModel
    
    var body: some View {
        if viewModel.favorites.isEmpty {
            VStack {
                Text("No favorites yet")
                    .foregroundColor(.secondary)
                Text("Add stations to favorites from Browse")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(viewModel.favorites) { favorite in
                if let station = viewModel.toStation(favorite) {
                    StationRowView(
                        station: station,
                        isFavorite: true,
                        isPlaying: playbackService.currentStation?.stationuuid == station.stationuuid && playbackService.isPlaying,
                        onPlay: {
                            playbackService.play(station) { playedStation in
                                recentsViewModel.addRecent(playedStation)
                            }
                        },
                        onToggleFavorite: {
                            viewModel.removeFavorite(favorite)
                        }
                    )
                }
            }
        }
    }
}

