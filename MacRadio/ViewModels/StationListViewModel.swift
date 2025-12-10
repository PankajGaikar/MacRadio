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
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var hasMore = true
    @Published var searchFilters = SearchFilters()
    
    private let modelContext: ModelContext
    private let pageSize = 50
    private var currentOffset = 0
    private var currentLoadType: LoadType = .topClick
    private var currentSearchQuery: StationSearchQuery?
    private var currentCountryCode: String?
    private var currentStateName: String?
    
    enum LoadType {
        case topClick
        case search
        case countryCode
        case state
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadTopStations() async {
        isLoading = true
        errorMessage = nil
        currentOffset = 0
        currentLoadType = .topClick
        hasMore = true
        
        do {
            stations = try await RadioBrowserService.shared.topClick(pageSize)
            currentOffset = stations.count
            hasMore = stations.count == pageSize
            isLoading = false
        } catch {
            errorMessage = "Failed to load stations: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func loadMoreStations() async {
        guard !isLoadingMore && hasMore else { return }
        
        isLoadingMore = true
        
        do {
            let newStations: [Station]
            
            switch currentLoadType {
            case .topClick:
                // For topClick, load more items (it doesn't support offset)
                // Load a larger batch and append new items
                let totalToLoad = currentOffset + pageSize
                newStations = try await RadioBrowserService.shared.topClick(totalToLoad)
                // Only append stations we haven't seen yet
                let newItems = Array(newStations.dropFirst(currentOffset))
                stations.append(contentsOf: newItems)
                hasMore = newStations.count == totalToLoad && newItems.count == pageSize
                
            case .search:
                guard var query = currentSearchQuery else { return }
                query.offset = currentOffset
                query.limit = pageSize
                // Preserve country code if we're searching within a country
                if let countryCode = currentCountryCode {
                    query.countrycode = countryCode
                }
                newStations = try await RadioBrowserService.shared.search(query)
                stations.append(contentsOf: newStations)
                hasMore = newStations.count == pageSize
                
            case .countryCode:
                guard let code = currentCountryCode else { return }
                newStations = try await RadioBrowserService.shared.stationsByCountryCode(code, limit: pageSize, offset: currentOffset)
                stations.append(contentsOf: newStations)
                hasMore = newStations.count == pageSize
                
            case .state:
                guard let state = currentStateName else { return }
                newStations = try await RadioBrowserService.shared.stationsByState(state, limit: pageSize, offset: currentOffset)
                stations.append(contentsOf: newStations)
                hasMore = newStations.count == pageSize
            }
            
            currentOffset = stations.count
            isLoadingMore = false
        } catch {
            errorMessage = "Failed to load more stations: \(error.localizedDescription)"
            isLoadingMore = false
        }
    }
    
    func searchStations() async {
        isLoading = true
        errorMessage = nil
        currentOffset = 0
        currentLoadType = .search
        hasMore = true
        
        // Build query with filters
        var query = searchFilters.toSearchQuery(name: searchText)
        query.limit = pageSize
        currentSearchQuery = query
        
        do {
            stations = try await RadioBrowserService.shared.search(query)
            currentOffset = stations.count
            hasMore = stations.count == pageSize
            isLoading = false
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func loadStationsForCountry(_ code: String) async {
        isLoading = true
        errorMessage = nil
        currentOffset = 0
        currentLoadType = .countryCode
        currentCountryCode = code
        hasMore = true
        
        do {
            let results = try await RadioBrowserService.shared.stationsByCountryCode(code, limit: pageSize, offset: 0)
            stations = results
            currentOffset = stations.count
            hasMore = stations.count == pageSize
            // Clear error if successful (even if empty)
            if stations.isEmpty {
                errorMessage = nil
            }
            isLoading = false
        } catch let error as RadioBrowserError {
            switch error {
            case .serverUnavailable:
                errorMessage = "Server temporarily unavailable. Please try again."
            case .notFound:
                errorMessage = nil // No stations found is not an error
            default:
                errorMessage = "Failed to load stations: \(error.localizedDescription)"
            }
            stations = []
            isLoading = false
        } catch {
            errorMessage = "Failed to load stations: \(error.localizedDescription)"
            stations = []
            isLoading = false
        }
    }
    
    func loadStationsForState(_ stateName: String) async {
        isLoading = true
        errorMessage = nil
        currentOffset = 0
        currentLoadType = .state
        currentStateName = stateName
        hasMore = true
        
        do {
            stations = try await RadioBrowserService.shared.stationsByState(stateName, limit: pageSize, offset: 0)
            currentOffset = stations.count
            hasMore = stations.count == pageSize
            isLoading = false
        } catch {
            errorMessage = "Failed to load stations: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func searchStationsInCountry(_ countryCode: String, searchText: String) async {
        isLoading = true
        errorMessage = nil
        currentOffset = 0
        currentLoadType = .search
        currentCountryCode = countryCode
        hasMore = true
        
        // Build search query with country filter
        var query = StationSearchQuery()
        query.name = searchText.isEmpty ? nil : searchText
        query.countrycode = countryCode
        query.limit = pageSize
        query.offset = 0
        query.hidebroken = true
        currentSearchQuery = query
        
        do {
            let results = try await RadioBrowserService.shared.search(query)
            stations = results
            currentOffset = stations.count
            hasMore = stations.count == pageSize
            
            // Clear error message if search was successful (even if empty)
            if stations.isEmpty {
                errorMessage = nil // Don't show error for empty results
            }
            isLoading = false
        } catch let error as RadioBrowserError {
            // Handle specific RadioBrowserKit errors
            switch error {
            case .serverUnavailable:
                errorMessage = "Server temporarily unavailable. Please try again."
            case .notFound:
                errorMessage = "No stations found matching your search."
            case .rateLimited:
                errorMessage = "Too many requests. Please wait a moment."
            case .invalidRequest(let message):
                errorMessage = "Invalid search: \(message)"
            default:
                errorMessage = "Search failed: \(error.localizedDescription)"
            }
            stations = [] // Clear stations on error
            isLoading = false
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            stations = [] // Clear stations on error
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

