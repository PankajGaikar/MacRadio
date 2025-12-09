//
//  CountryCategoryGrid.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import SwiftUI

struct CountryCategoryGrid: View {
    var countries: [CountryItem]
    @Binding var selectedCountryCode: String?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" option
                CategoryButton(
                    title: "All",
                    isSelected: selectedCountryCode == nil,
                    action: {
                        selectedCountryCode = nil
                    }
                )
                
                // Countries
                ForEach(countries.filter { $0.code != nil }) { country in
                    CategoryButton(
                        title: country.name,
                        isSelected: selectedCountryCode == country.code,
                        showLocationIcon: country.isCurrentCountry,
                        action: {
                            selectedCountryCode = country.code
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    var showLocationIcon: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if showLocationIcon {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                Text(title)
                    .font(isSelected ? .headline : .subheadline)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

