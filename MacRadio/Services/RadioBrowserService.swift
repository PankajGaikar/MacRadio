//
//  RadioBrowserService.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import Foundation
import RadioBrowserKit

/// Shared RadioBrowser service for the app
@MainActor
final class RadioBrowserService {
    static let shared = RadioBrowserService()
    
    private let radioBrowser: RadioBrowser
    
    private init() {
        // Create a single shared instance
        // RadioBrowser will automatically discover and use the best mirror
        self.radioBrowser = RadioBrowser()
    }
    
    // MARK: - Station Methods
    
    func topClick(_ count: Int) async throws -> [Station] {
        try await radioBrowser.topClick(count)
    }
    
    func topVote(_ count: Int) async throws -> [Station] {
        try await radioBrowser.topVote(count)
    }
    
    func search(_ query: StationSearchQuery) async throws -> [Station] {
        try await radioBrowser.search(query)
    }
    
    func stationsByCountryCode(_ code: String, limit: Int?) async throws -> [Station] {
        try await radioBrowser.stationsByCountryCode(code, limit: limit)
    }
    
    func stationsByCountry(_ name: String, limit: Int?) async throws -> [Station] {
        try await radioBrowser.stationsByCountry(name, exact: true, limit: limit)
    }
    
    // MARK: - List Methods
    
    func countries() async throws -> [NamedCount] {
        try await radioBrowser.countries()
    }
    
    // MARK: - Interaction Methods
    
    func click(stationUUID: String) async throws -> ClickResponse {
        try await radioBrowser.click(stationUUID: stationUUID)
    }
    
    func vote(stationUUID: String) async throws -> VoteResponse {
        try await radioBrowser.vote(stationUUID: stationUUID)
    }
}

