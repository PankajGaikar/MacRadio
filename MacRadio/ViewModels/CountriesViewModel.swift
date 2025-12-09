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
    let id: String
    let name: String
    let code: String?
    let stationCount: Int
    let isCurrentCountry: Bool
}

@MainActor
final class CountriesViewModel: ObservableObject {
    @Published var countries: [CountryItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCountryCode: String? {
        didSet {
            // Auto-select current country if available
            if selectedCountryCode == nil, let currentCode = currentCountryCode {
                if countries.contains(where: { $0.code == currentCode }) {
                    selectedCountryCode = currentCode
                }
            }
        }
    }
    
    private var currentCountryCode: String? {
        Locale.current.region?.identifier
    }
    
    func loadCountries() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let namedCounts = try await RadioBrowserService.shared.countries()
            
            // Convert to CountryItem and sort
            var countryItems = namedCounts.map { namedCount in
                // Try to extract country code from name
                // The API returns country names, we need to map them to codes
                let code = countryCodeFromName(namedCount.name)
                let isCurrent = code == currentCountryCode
                
                return CountryItem(
                    id: namedCount.name,
                    name: namedCount.name,
                    code: code,
                    stationCount: namedCount.stationcount,
                    isCurrentCountry: isCurrent
                )
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
            
            // Auto-select current country if available
            if selectedCountryCode == nil, let currentCode = currentCountryCode {
                if countryItems.contains(where: { $0.code == currentCode }) {
                    selectedCountryCode = currentCode
                }
            }
            
            isLoading = false
        } catch {
            errorMessage = "Failed to load countries: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func countryCodeFromName(_ name: String) -> String? {
        // Use Locale to find country code from name
        let locale = Locale(identifier: "en_US_POSIX")
        for code in Locale.isoRegionCodes {
            if let countryName = locale.localizedString(forRegionCode: code),
               countryName.lowercased() == name.lowercased() {
                return code
            }
        }
        return nil
    }
}

