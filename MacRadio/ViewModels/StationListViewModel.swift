//
//  StationListViewModel.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import Foundation
import SwiftData
import Combine
import RadioBrowserKit

@MainActor
final class StationListViewModel: ObservableObject {
    @Published var stations: [Station] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    
    private let radioBrowser = RadioBrowser()
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadTopStations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            stations = try await radioBrowser.topClick(50)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func searchStations() async {
        guard !searchText.isEmpty else {
            await loadTopStations()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            var query = StationSearchQuery()
            query.name = searchText
            query.limit = 50
            stations = try await radioBrowser.search(query)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func isFavorite(_ stationUUID: String) -> Bool {
        let descriptor = FetchDescriptor<FavoriteStation>(
            predicate: #Predicate { $0.stationUUID == stationUUID }
        )
        return (try? modelContext.fetch(descriptor).first) != nil
    }
    
    func toggleFavorite(_ station: Station) {
        if isFavorite(station.stationuuid) {
            removeFavorite(station.stationuuid)
        } else {
            addFavorite(station)
        }
    }
    
    private func addFavorite(_ station: Station) {
        let favorite = FavoriteStation(from: station)
        modelContext.insert(favorite)
        try? modelContext.save()
    }
    
    private func removeFavorite(_ stationUUID: String) {
        let descriptor = FetchDescriptor<FavoriteStation>(
            predicate: #Predicate { $0.stationUUID == stationUUID }
        )
        if let favorite = try? modelContext.fetch(descriptor).first {
            modelContext.delete(favorite)
            try? modelContext.save()
        }
    }
}

