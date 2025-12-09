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
                List(viewModel.countries.filter { $0.code != nil }, selection: $viewModel.selectedCountryCode) { country in
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
                    .tag(country.code ?? "")
                }
                .frame(minWidth: 200, idealWidth: 250)
            }
            
            // Stations for selected country
            if let countryCode = viewModel.selectedCountryCode, !countryCode.isEmpty {
                if isLoadingStations {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if stationListViewModel.stations.isEmpty {
                    VStack {
                        Text("No stations found")
                            .foregroundColor(.secondary)
                        if let selectedCountry = viewModel.countries.first(where: { $0.code == countryCode }) {
                            Text("\(selectedCountry.name) - \(selectedCountry.stationCount) stations available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
            if let code = newValue, !code.isEmpty {
                Task {
                    await loadStationsForCountry(code)
                }
            }
        }
    }
    
    private func loadStationsForCountry(_ countryCode: String) async {
        await MainActor.run {
            isLoadingStations = true
            stationListViewModel.stations = []
        }
        
        // Find the country to get its name
        guard let country = viewModel.countries.first(where: { $0.code == countryCode }) else {
            await MainActor.run {
                isLoadingStations = false
                stationListViewModel.errorMessage = "Country not found"
            }
            return
        }
        
        do {
            // Try using country code first, fallback to country name
            let stations: [Station]
            if !countryCode.isEmpty {
                stations = try await RadioBrowserService.shared.stationsByCountryCode(countryCode, limit: 100)
            } else {
                stations = try await RadioBrowserService.shared.stationsByCountry(country.name, limit: 100)
            }
            
            await MainActor.run {
                stationListViewModel.stations = stations
                isLoadingStations = false
            }
        } catch {
            await MainActor.run {
                stationListViewModel.errorMessage = "Failed to load stations: \(error.localizedDescription)"
                isLoadingStations = false
            }
        }
    }
}

