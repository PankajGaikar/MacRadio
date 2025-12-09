//
//  CountriesListView.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import SwiftUI
import RadioBrowserKit

struct CountriesListView: View {
    @ObservedObject var viewModel: CountriesViewModel
    @ObservedObject var playbackService: PlaybackService
    @ObservedObject var recentsViewModel: RecentsViewModel
    @ObservedObject var stationListViewModel: StationListViewModel
    
    @State private var isLoadingStations = false
    
    var body: some View {
        HSplitView {
            // Countries list
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                VStack {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task {
                            await viewModel.loadCountries()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.countries.isEmpty {
                VStack {
                    Text("No countries found")
                        .foregroundColor(.secondary)
                    Button("Load Countries") {
                        Task {
                            await viewModel.loadCountries()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.countries, selection: $viewModel.selectedCountryCode) { country in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(country.name)
                                    .font(.headline)
                                if country.isCurrentCountry {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                }
                            }
                            Text("\(country.stationCount) stations")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .tag(country.code)
                }
                .frame(minWidth: 200, idealWidth: 250)
            }
            
            // Stations for selected country
            if let countryCode = viewModel.selectedCountryCode {
                if isLoadingStations {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if stationListViewModel.stations.isEmpty {
                    VStack {
                        Text("No stations found")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(stationListViewModel.stations) { station in
                        StationRowView(
                            station: station,
                            isFavorite: stationListViewModel.isFavorite(station.stationuuid),
                            isPlaying: playbackService.currentStation?.stationuuid == station.stationuuid && playbackService.isPlaying,
                            onPlay: {
                                playbackService.play(station) { playedStation in
                                    recentsViewModel.addRecent(playedStation)
                                }
                            },
                            onToggleFavorite: {
                                stationListViewModel.toggleFavorite(station)
                            }
                        )
                    }
                }
            } else {
                VStack {
                    Text("Select a country")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            if viewModel.countries.isEmpty {
                await viewModel.loadCountries()
            }
        }
        .onChange(of: viewModel.selectedCountryCode) { oldValue, newValue in
            if let code = newValue {
                loadStationsForCountry(code)
            }
        }
    }
    
    private func loadStationsForCountry(_ countryCode: String) {
        isLoadingStations = true
        stationListViewModel.stations = []
        
        Task {
            do {
                stationListViewModel.stations = try await RadioBrowserService.shared.stationsByCountryCode(countryCode, limit: 100)
                isLoadingStations = false
            } catch {
                stationListViewModel.errorMessage = "Failed to load stations: \(error.localizedDescription)"
                isLoadingStations = false
            }
        }
    }
}

