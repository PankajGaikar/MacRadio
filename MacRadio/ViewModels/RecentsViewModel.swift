//
//  RecentsViewModel.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import Foundation
import SwiftData
import Combine
import RadioBrowserKit

@MainActor
final class RecentsViewModel: ObservableObject {
    @Published var recents: [RecentStation] = []
    
    private let modelContext: ModelContext
    private let maxRecents = 10
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadRecents()
    }
    
    func loadRecents() {
        let descriptor = FetchDescriptor<RecentStation>(
            sortBy: [SortDescriptor(\.playedDate, order: .reverse)]
        )
        recents = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func addRecent(_ station: Station) {
        // Remove existing if present
        let descriptor = FetchDescriptor<RecentStation>(
            predicate: #Predicate { $0.stationUUID == station.stationuuid }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
        }
        
        // Add new recent
        let recent = RecentStation(from: station)
        modelContext.insert(recent)
        try? modelContext.save()
        
        // Keep only last 10
        let allRecents = FetchDescriptor<RecentStation>(
            sortBy: [SortDescriptor(\.playedDate, order: .reverse)]
        )
        if let all = try? modelContext.fetch(allRecents), all.count > maxRecents {
            for item in all.dropFirst(maxRecents) {
                modelContext.delete(item)
            }
            try? modelContext.save()
        }
        
        loadRecents()
    }
    
    func toStation(_ recent: RecentStation) -> Station? {
        // Create a JSON representation and decode it as Station
        let json: [String: Any?] = [
            "stationuuid": recent.stationUUID,
            "name": recent.name,
            "url": recent.url,
            "url_resolved": recent.url,
            "homepage": recent.homepage ?? "",
            "favicon": recent.favicon ?? "",
            "tags": recent.tags ?? "",
            "countrycode": recent.countrycode ?? "",
            "state": nil,
            "language": recent.language ?? "",
            "codec": recent.codec ?? "",
            "bitrate": recent.bitrate ?? 0,
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

