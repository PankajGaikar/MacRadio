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
    @State private var countrySearchText = ""
    
    var body: some View {
        HSplitView {
            // Countries column
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
        .onAppear {
            // Load countries when view appears
            if viewModel.countries.isEmpty {
                Task {
                    await viewModel.loadCountries()
                }
            }
        }
        .onChange(of: viewModel.selectedCountryCode) { oldValue, newValue in
            // Reset state selection and search when country changes
            viewModel.selectedStateName = nil
            countrySearchText = ""
            
            if let code = newValue, !code.isEmpty {
                // Load stations if no states available
                Task {
                    // Wait a bit for states to load
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    if viewModel.states.isEmpty {
                        await loadStationsForCountry(code)
                    } else {
                        // Clear stations until state is selected
                        stationListViewModel.stations = []
                    }
                }
            } else {
                // "All" selected - load top stations
                Task {
                    await stationListViewModel.loadTopStations()
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
            } else if viewModel.countries.isEmpty {
                VStack {
                    Text("No countries available")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $viewModel.selectedCountryCode) {
                    // "All" option
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("All")
                                .font(.headline)
                            Text("All stations")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .tag(nil as String?)
                    
                    // Countries
                    ForEach(viewModel.countries) { country in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    if country.isCurrentCountry {
                                        Image(systemName: "location.fill")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                    Text(country.name)
                                        .font(.headline)
                                }
                                Text("\(country.stationCount) stations")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .tag(country.code as String?)
                    }
                }
                .frame(minWidth: 180, idealWidth: 220)
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
            if viewModel.selectedCountryCode == nil {
                // Show top stations when "All" is selected
                if stationListViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if stationListViewModel.stations.isEmpty {
                    VStack {
                        Text("No stations found")
                            .foregroundColor(.secondary)
                        Button("Load Top Stations") {
                            Task {
                                await stationListViewModel.loadTopStations()
                            }
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
            } else if let countryCode = viewModel.selectedCountryCode, !countryCode.isEmpty {
                VStack(spacing: 0) {
                    // Search bar for country-specific stations
                    HStack {
                        TextField("Search stations in \(viewModel.countries.first(where: { $0.code == countryCode })?.name ?? "country")...", text: $countrySearchText)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                if !countrySearchText.isEmpty {
                                    Task {
                                        await searchStationsInCountry(countryCode)
                                    }
                                } else {
                                    // Clear search and reload all stations for country
                                    Task {
                                        await loadStationsForCountry(countryCode)
                                    }
                                }
                            }
                        
                        Button("Search") {
                            Task {
                                if !countrySearchText.isEmpty {
                                    await searchStationsInCountry(countryCode)
                                } else {
                                    await loadStationsForCountry(countryCode)
                                }
                            }
                        }
                        .disabled(countrySearchText.isEmpty && stationListViewModel.stations.isEmpty)
                        
                        if !countrySearchText.isEmpty {
                            Button {
                                countrySearchText = ""
                                Task {
                                    await loadStationsForCountry(countryCode)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    
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
    
    private func searchStationsInCountry(_ countryCode: String) async {
        isLoadingStations = true
        await stationListViewModel.searchStationsInCountry(countryCode, searchText: countrySearchText)
        isLoadingStations = false
    }
}

