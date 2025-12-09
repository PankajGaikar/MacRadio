//
//  SearchFilters.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import Foundation
import Combine
import RadioBrowserKit

@MainActor
final class SearchFilters: ObservableObject {
    @Published var countryCode: String?
    @Published var language: String?
    @Published var tag: String?
    @Published var codec: String?
    @Published var bitrateMin: Int?
    @Published var bitrateMax: Int?
    @Published var isHTTPS: Bool?
    @Published var orderString: String = "name"
    @Published var reverse: Bool = false
    @Published var hideBroken: Bool = true
    
    var hasActiveFilters: Bool {
        countryCode != nil ||
        language != nil ||
        tag != nil ||
        codec != nil ||
        bitrateMin != nil ||
        bitrateMax != nil ||
        isHTTPS != nil ||
        orderString != "name" ||
        reverse ||
        !hideBroken
    }
    
    func toSearchQuery(name: String) -> StationSearchQuery {
        var query = StationSearchQuery()
        query.name = name.isEmpty ? nil : name
        query.countrycode = countryCode
        query.language = language
        query.tag = tag
        query.codec = codec
        query.bitrateMin = bitrateMin
        query.bitrateMax = bitrateMax
        query.isHTTPS = isHTTPS
        // Convert string to SortOrder
        if let sortOrder = SortOrder(rawValue: orderString) {
            query.order = sortOrder
        }
        query.reverse = reverse
        query.hidebroken = hideBroken
        return query
    }
    
    func reset() {
        countryCode = nil
        language = nil
        tag = nil
        codec = nil
        bitrateMin = nil
        bitrateMax = nil
        isHTTPS = nil
        orderString = "name"
        reverse = false
        hideBroken = true
    }
}

