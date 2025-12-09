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
            countriesColumn
            
            // States/Regions list (shown when country selected and has states)
            if let countryCode = viewModel.selectedCountryCode, !countryCode.isEmpty, !viewModel.states.isEmpty {
                statesColumn
            }
            
            // Stations list
            stationsColumn
        }
        .task {
            if viewModel.countries.isEmpty {
                await viewModel.loadCountries()
            }
        }
        .onChange(of: viewModel.selectedCountryCode) { oldValue, newValue in
            if let code = newValue, !code.isEmpty {
                // Reset state selection when country changes
                viewModel.selectedStateName = nil
                // Load stations if no states available
                if viewModel.states.isEmpty {
                    Task {
                        await loadStationsForCountry(code)
                    }
                } else {
                    // Clear stations until state is selected
                    stationListViewModel.stations = []
                }
            }
        }
        .onChange(of: viewModel.selectedStateName) { oldValue, newValue in
            if let stateName = newValue, !stateName.isEmpty {
                Task {
                    await loadStationsForState(stateName)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var countriesColumn: some View {
        Group {
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
        }
    }
    
    private var statesColumn: some View {
        Group {
            if viewModel.isLoadingStates {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.states.isEmpty {
                VStack {
                    Text("No regions available")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.states, selection: $viewModel.selectedStateName) { state in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(state.name)
                                .font(.headline)
                            Text("\(state.stationcount) stations")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .tag(state.name)
                }
                .frame(minWidth: 180, idealWidth: 220)
            }
        }
    }
    
    private var stationsColumn: some View {
        Group {
            if let countryCode = viewModel.selectedCountryCode, !countryCode.isEmpty {
                if isLoadingStations {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if stationListViewModel.stations.isEmpty {
                    VStack {
                        if viewModel.states.isEmpty {
                            Text("No stations found")
                                .foregroundColor(.secondary)
                            if let selectedCountry = viewModel.countries.first(where: { $0.code == countryCode }) {
                                Text("\(selectedCountry.name) - \(selectedCountry.stationCount) stations available")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("Select a region")
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(stationListViewModel.stations) { station in
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
                        
                        // Loading indicator at bottom
                        if stationListViewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }
                        
                        // Load more trigger
                        if stationListViewModel.hasMore && !stationListViewModel.isLoadingMore {
                            Color.clear
                                .frame(height: 1)
                                .onAppear {
                                    Task {
                                        await stationListViewModel.loadMoreStations()
                                    }
                                }
                        }
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
    }
    
    // MARK: - Loading Functions
    
    private func loadStationsForCountry(_ countryCode: String) async {
        isLoadingStations = true
        await stationListViewModel.loadStationsForCountry(countryCode)
        isLoadingStations = false
    }
    
    private func loadStationsForState(_ stateName: String) async {
        isLoadingStations = true
        await stationListViewModel.loadStationsForState(stateName)
        isLoadingStations = false
    }
}

