//
//  ContentView.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var playbackService = PlaybackService()
    @StateObject private var stationListViewModel: StationListViewModel
    @StateObject private var favoritesViewModel: FavoritesViewModel
    @StateObject private var recentsViewModel: RecentsViewModel
    @StateObject private var countriesViewModel = CountriesViewModel()
    
    @State private var selectedSection: Section = .browse
    
    enum Section: String, CaseIterable {
        case browse = "Browse"
        case countries = "Countries"
        case favorites = "Favorites"
        case recents = "Recents"
    }
    
    init(modelContext: ModelContext) {
        let stationListVM = StationListViewModel(modelContext: modelContext)
        let favoritesVM = FavoritesViewModel(modelContext: modelContext)
        let recentsVM = RecentsViewModel(modelContext: modelContext)
        
        _stationListViewModel = StateObject(wrappedValue: stationListVM)
        _favoritesViewModel = StateObject(wrappedValue: favoritesVM)
        _recentsViewModel = StateObject(wrappedValue: recentsVM)
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedSection) {
                ForEach(Section.allCases, id: \.self) { section in
                    NavigationLink(value: section) {
                        Label(section.rawValue, systemImage: iconForSection(section))
                    }
                }
            }
            .navigationTitle("MacRadio")
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            // Main content
            VStack(spacing: 0) {
                Group {
                    switch selectedSection {
                    case .browse:
                        StationListView(
                            viewModel: stationListViewModel,
                            playbackService: playbackService,
                            recentsViewModel: recentsViewModel
                        )
                    case .countries:
                        CountriesListView(
                            viewModel: countriesViewModel,
                            playbackService: playbackService,
                            recentsViewModel: recentsViewModel,
                            stationListViewModel: stationListViewModel
                        )
                    case .favorites:
                        FavoritesListView(
                            viewModel: favoritesViewModel,
                            playbackService: playbackService,
                            recentsViewModel: recentsViewModel
                        )
                    case .recents:
                        RecentsListView(
                            viewModel: recentsViewModel,
                            playbackService: playbackService,
                            favoritesViewModel: favoritesViewModel
                        )
                    }
                }
                
                // Always-visible player
                Divider()
                PlayerView(playbackService: playbackService)
            }
        }
    }
    
    private func iconForSection(_ section: Section) -> String {
        switch section {
        case .browse:
            return "radio"
        case .countries:
            return "globe"
        case .favorites:
            return "heart.fill"
        case .recents:
            return "clock.fill"
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: FavoriteStation.self, RecentStation.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return ContentView(modelContext: container.mainContext)
}
