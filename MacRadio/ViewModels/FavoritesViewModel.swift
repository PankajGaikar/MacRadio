//
//  FavoritesViewModel.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import Foundation
import SwiftData
import Combine
import RadioBrowserKit

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var favorites: [FavoriteStation] = []
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadFavorites()
    }
    
    func loadFavorites() {
        let descriptor = FetchDescriptor<FavoriteStation>(
            sortBy: [SortDescriptor(\.addedDate, order: .reverse)]
        )
        favorites = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func removeFavorite(_ favorite: FavoriteStation) {
        modelContext.delete(favorite)
        try? modelContext.save()
        loadFavorites()
    }
    
    func toStation(_ favorite: FavoriteStation) -> Station? {
        // Create a JSON representation and decode it as Station
        let json: [String: Any?] = [
            "stationuuid": favorite.stationUUID,
            "name": favorite.name,
            "url": favorite.url,
            "url_resolved": favorite.url,
            "homepage": favorite.homepage ?? "",
            "favicon": favorite.favicon ?? "",
            "tags": favorite.tags ?? "",
            "countrycode": favorite.countrycode ?? "",
            "state": nil,
            "language": favorite.language ?? "",
            "codec": favorite.codec ?? "",
            "bitrate": favorite.bitrate ?? 0,
            "hls": 0,
            "votes": 0,
            "lastcheckok": 1,
            "lastchecktime": Date().timeIntervalSince1970,
            "clickcount": 0,
            "clicktrend": 0,
            "geo_lat": nil,
            "geo_long": nil,
            "geo_distance": nil,
            "has_extended_info": false,
            "added": Date().timeIntervalSince1970,
            "lastchangetime": Date().timeIntervalSince1970
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json.compactMapValues { $0 }),
              let station = try? JSONDecoder().decode(Station.self, from: jsonData) else {
            return nil
        }
        return station
    }
}

