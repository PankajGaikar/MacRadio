//
//  CountriesViewModel.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import Foundation
import Combine
import RadioBrowserKit

/// Represents a country with its code and name
struct CountryItem: Identifiable {
    let id: String // Use name+code combination to avoid duplicates
    let name: String
    let code: String?
    let stationCount: Int
    let isCurrentCountry: Bool
}

@MainActor
final class CountriesViewModel: ObservableObject {
    @Published var countries: [CountryItem] = []
    @Published var states: [StateCount] = []
    @Published var isLoading = false
    @Published var isLoadingStates = false
    @Published var errorMessage: String?
    @Published var selectedCountryCode: String? {
        didSet {
            // Validate and normalize country code (must be 2 letters)
            if let code = selectedCountryCode {
                // Extract just the country code if it's in "Name-CODE" format
                let normalizedCode: String?
                if code.count > 2, let lastTwo = code.split(separator: "-").last, lastTwo.count == 2 {
                    normalizedCode = String(lastTwo).uppercased()
                } else if code.count == 2 {
                    normalizedCode = code.uppercased()
                } else {
                    // Invalid format, try to find the code from countries list
                    normalizedCode = countries.first(where: { $0.id == code || $0.name == code })?.code
                }
                
                // Only proceed if we have a valid 2-letter code
                if let validCode = normalizedCode, validCode.count == 2 {
                    // Update to normalized code if different
                    if validCode != code {
                        selectedCountryCode = validCode
                        return // Will trigger didSet again with correct value
                    }
                    Task { @MainActor in
                        await loadStates(for: validCode)
                    }
                } else {
                    // Invalid code, clear selection
                    selectedCountryCode = nil
                }
            } else {
                states = []
            }
        }
    }
    @Published var selectedStateName: String?
    
    private var currentCountryCode: String? {
        Locale.current.region?.identifier
    }
    
    func loadCountries() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let namedCounts = try await RadioBrowserService.shared.countries()
            
            // Convert to CountryItem and sort
            // Use a Set to track seen names and avoid duplicates
            var seenNames = Set<String>()
            var countryItems: [CountryItem] = []
            
            for namedCount in namedCounts {
                // Skip duplicates
                if seenNames.contains(namedCount.name) {
                    continue
                }
                seenNames.insert(namedCount.name)
                
                // Try to extract country code from name
                // The API returns country names, we need to map them to codes
                let code = countryCodeFromName(namedCount.name)
                
                // Only include countries with valid codes (required for API calls)
                guard let code = code, !code.isEmpty else {
                    continue
                }
                
                let isCurrent = code == currentCountryCode
                
                // Use name + code for unique ID
                let uniqueId = "\(namedCount.name)-\(code)"
                
                countryItems.append(CountryItem(
                    id: uniqueId,
                    name: namedCount.name,
                    code: code,
                    stationCount: namedCount.stationcount,
                    isCurrentCountry: isCurrent
                ))
            }
            
            // Sort: current country first, then alphabetically
            countryItems.sort { first, second in
                if first.isCurrentCountry && !second.isCurrentCountry {
                    return true
                }
                if !first.isCurrentCountry && second.isCurrentCountry {
                    return false
                }
                return first.name < second.name
            }
            
            countries = countryItems
            
            // Auto-select current country if available (only if it has a valid code)
            // Do this in a Task to avoid publishing during view updates
            if selectedCountryCode == nil, let currentCode = currentCountryCode {
                if let currentCountry = countryItems.first(where: { $0.code == currentCode && $0.code != nil }) {
                    Task { @MainActor in
                        selectedCountryCode = currentCountry.code
                    }
                }
            }
            
            isLoading = false
        } catch {
            errorMessage = "Failed to load countries: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func loadStates(for countryCode: String?) async {
        guard var code = countryCode, !code.isEmpty else {
            states = []
            return
        }
        
        // Normalize country code - extract just the 2-letter code if in "Name-CODE" format
        if code.count > 2 {
            // Try to extract code from "Name-CODE" format
            if let lastPart = code.split(separator: "-").last, lastPart.count == 2 {
                code = String(lastPart).uppercased()
            } else {
                // Try to find the code from the countries list
                if let country = countries.first(where: { $0.id == code || $0.name == code }) {
                    code = country.code ?? code
                }
            }
        } else {
            code = code.uppercased()
        }
        
        // Only proceed if we have a valid 2-letter code
        guard code.count == 2 else {
            states = []
            return
        }
        
        isLoadingStates = true
        
        do {
            let allStates = try await RadioBrowserService.shared.states(country: code)
            // Filter states to ensure they match the selected country code
            // The API might return states from other countries, so we filter by the country field
            states = allStates.filter { $0.country.uppercased() == code.uppercased() }
            isLoadingStates = false
        } catch {
            // If states fail to load, just set empty array (not all countries have states)
            states = []
            isLoadingStates = false
        }
    }
    
    private func countryCodeFromName(_ name: String) -> String? {
        // Try multiple locale identifiers for better matching
        let locales = ["en_US", "en_GB", "en"]
        
        for localeId in locales {
            let locale = Locale(identifier: localeId)
            for code in Locale.isoRegionCodes {
                if let countryName = locale.localizedString(forRegionCode: code) {
                    // Try exact match first
                    if countryName.lowercased() == name.lowercased() {
                        return code
                    }
                    // Try without diacritics
                    if countryName.folding(options: .diacriticInsensitive, locale: locale).lowercased() == 
                       name.folding(options: .diacriticInsensitive, locale: locale).lowercased() {
                        return code
                    }
                }
            }
        }
        
        // Fallback: try common name mappings
        let commonMappings: [String: String] = [
            "United States": "US",
            "United Kingdom": "GB",
            "The Netherlands": "NL",
            "South Korea": "KR",
            "North Korea": "KP",
            "Russia": "RU",
            "Czech Republic": "CZ",
            "Vietnam": "VN",
            "India": "IN",
            "Afghanistan": "AF"
        ]
        
        return commonMappings[name]
    }
}

