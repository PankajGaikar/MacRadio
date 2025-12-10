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
                // Always load stations for the country when selected
                // If states are available, we'll still show country stations until a state is selected
                Task {
                    // Wait a bit for states to load first
                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                    // Load stations for the country regardless of whether it has states
                    await loadStationsForCountry(code)
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
                // State selected - load stations for that state
                Task {
                    await loadStationsForState(stateName)
                }
            } else if oldValue != nil && newValue == nil {
                // State deselected - reload country stations
                if let countryCode = viewModel.selectedCountryCode, !countryCode.isEmpty {
                    Task {
                        await loadStationsForCountry(countryCode)
                    }
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
                    
                    // Countries - only show those with valid codes
                    ForEach(viewModel.countries.filter { $0.code != nil && $0.code!.count == 2 }) { country in
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
                        .tag(country.code! as String?) // Force unwrap is safe here since we filtered
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
                    } else if let error = stationListViewModel.errorMessage {
                        VStack(spacing: 8) {
                            Text("Error")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text(error)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task {
                                    if !countrySearchText.isEmpty {
                                        await searchStationsInCountry(countryCode)
                                    } else {
                                        await loadStationsForCountry(countryCode)
                                    }
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if stationListViewModel.stations.isEmpty {
                        VStack(spacing: 8) {
                            Text("No stations found")
                                .foregroundColor(.secondary)
                            if let selectedCountry = viewModel.countries.first(where: { $0.code == countryCode }) {
                                Text("\(selectedCountry.name) - \(selectedCountry.stationCount) stations available")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if !viewModel.states.isEmpty && viewModel.selectedStateName == nil {
                                    Text("Or select a region to filter")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
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
        // Normalize country code - extract just the 2-letter code if in "Name-CODE" format
        var normalizedCode = countryCode
        if countryCode.count > 2 {
            // Try to extract code from "Name-CODE" format
            if let lastPart = countryCode.split(separator: "-").last, lastPart.count == 2 {
                normalizedCode = String(lastPart).uppercased()
            } else {
                // Try to find the code from the countries list
                if let country = viewModel.countries.first(where: { $0.id == countryCode || $0.name == countryCode }) {
                    normalizedCode = country.code ?? countryCode
                }
            }
        } else {
            normalizedCode = countryCode.uppercased()
        }
        
        // Only proceed if we have a valid 2-letter code
        guard normalizedCode.count == 2 else {
            return
        }
        
        isLoadingStations = true
        stationListViewModel.errorMessage = nil // Clear any previous errors
        await stationListViewModel.loadStationsForCountry(normalizedCode)
        isLoadingStations = false
    }
    
    private func loadStationsForState(_ stateName: String) async {
        isLoadingStations = true
        stationListViewModel.errorMessage = nil // Clear any previous errors
        await stationListViewModel.loadStationsForState(stateName)
        isLoadingStations = false
    }
    
    private func searchStationsInCountry(_ countryCode: String) async {
        // Normalize country code - extract just the 2-letter code if in "Name-CODE" format
        var normalizedCode = countryCode
        if countryCode.count > 2 {
            // Try to extract code from "Name-CODE" format
            if let lastPart = countryCode.split(separator: "-").last, lastPart.count == 2 {
                normalizedCode = String(lastPart).uppercased()
            } else {
                // Try to find the code from the countries list
                if let country = viewModel.countries.first(where: { $0.id == countryCode || $0.name == countryCode }) {
                    normalizedCode = country.code ?? countryCode
                }
            }
        } else {
            normalizedCode = countryCode.uppercased()
        }
        
        // Only proceed if we have a valid 2-letter code
        guard normalizedCode.count == 2 else {
            return
        }
        
        isLoadingStations = true
        stationListViewModel.errorMessage = nil // Clear any previous errors
        await stationListViewModel.searchStationsInCountry(normalizedCode, searchText: countrySearchText)
        isLoadingStations = false
    }
}

