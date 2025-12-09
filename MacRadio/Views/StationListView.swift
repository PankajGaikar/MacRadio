//
//  StationListView.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import SwiftUI
import RadioBrowserKit

struct StationListView: View {
    @ObservedObject var viewModel: StationListViewModel
    @ObservedObject var playbackService: PlaybackService
    @ObservedObject var recentsViewModel: RecentsViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                TextField("Search stations...", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task {
                            await viewModel.searchStations()
                        }
                    }
                
                Button("Search") {
                    Task {
                        await viewModel.searchStations()
                    }
                }
                .disabled(viewModel.searchText.isEmpty)
            }
            .padding()
            
            // Station list
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                VStack {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task {
                            await viewModel.loadTopStations()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.stations.isEmpty {
                VStack {
                    Text("No stations found")
                        .foregroundColor(.secondary)
                    Button("Load Top Stations") {
                        Task {
                            await viewModel.loadTopStations()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.stations) { station in
                    StationRowView(
                        station: station,
                        isFavorite: viewModel.isFavorite(station.stationuuid),
                        isPlaying: playbackService.currentStation?.stationuuid == station.stationuuid && playbackService.isPlaying,
                        onPlay: {
                            playbackService.play(station) { playedStation in
                                recentsViewModel.addRecent(playedStation)
                            }
                        },
                        onToggleFavorite: {
                            viewModel.toggleFavorite(station)
                        }
                    )
                }
            }
        }
        .task {
            if viewModel.stations.isEmpty {
                await viewModel.loadTopStations()
            }
        }
    }
}

