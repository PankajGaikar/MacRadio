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
            // Auto-select current country if available
            if selectedCountryCode == nil, let currentCode = currentCountryCode {
                if countries.contains(where: { $0.code == currentCode }) {
                    selectedCountryCode = currentCode
                }
            }
            // Load states when country changes
            if selectedCountryCode != nil {
                Task {
                    await loadStates(for: selectedCountryCode)
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
                let isCurrent = code == currentCountryCode
                
                // Use name + code (or name if code is nil) for unique ID
                let uniqueId = code != nil ? "\(namedCount.name)-\(code!)" : namedCount.name
                
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
            if selectedCountryCode == nil, let currentCode = currentCountryCode {
                if let currentCountry = countryItems.first(where: { $0.code == currentCode && $0.code != nil }) {
                    selectedCountryCode = currentCountry.code
                }
            }
            
            isLoading = false
        } catch {
            errorMessage = "Failed to load countries: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func loadStates(for countryCode: String?) async {
        guard let code = countryCode, !code.isEmpty else {
            states = []
            return
        }
        
        isLoadingStates = true
        
        do {
            states = try await RadioBrowserService.shared.states(country: code)
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
            "Vietnam": "VN"
        ]
        
        return commonMappings[name]
    }
}

