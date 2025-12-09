//
//  SearchFiltersView.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import SwiftUI
import RadioBrowserKit

struct SearchFiltersView: View {
    @ObservedObject var filters: SearchFilters
    @State private var showFilters = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter toggle button
            HStack {
                Button(action: {
                    showFilters.toggle()
                }) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("Filters")
                        if filters.hasActiveFilters {
                            Image(systemName: "circle.fill")
                                .font(.caption2)
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .buttonStyle(.bordered)
                
                if filters.hasActiveFilters {
                    Button("Clear") {
                        filters.reset()
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Filters panel
            if showFilters {
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Country filter
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Country Code")
                                .font(.headline)
                            TextField("e.g., US, GB, IN (ISO 3166-1 alpha-2)", text: Binding(
                                get: { filters.countryCode ?? "" },
                                set: { filters.countryCode = $0.isEmpty ? nil : $0.uppercased() }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .help("Enter a 2-letter country code (e.g., US, GB, IN)")
                        }
                        
                        // Language filter
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Language")
                                .font(.headline)
                            TextField("e.g., English, Spanish", text: Binding(
                                get: { filters.language ?? "" },
                                set: { filters.language = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                        
                        // Tag filter
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tag")
                                .font(.headline)
                            TextField("e.g., jazz, rock, news", text: Binding(
                                get: { filters.tag ?? "" },
                                set: { filters.tag = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                        
                        // Codec filter
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Codec")
                                .font(.headline)
                            Picker("Codec", selection: $filters.codec) {
                                Text("Any").tag(String?.none)
                                Text("MP3").tag("MP3" as String?)
                                Text("AAC").tag("AAC" as String?)
                                Text("OGG").tag("OGG" as String?)
                                Text("FLAC").tag("FLAC" as String?)
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Bitrate range
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Bitrate (kbps)")
                                .font(.headline)
                            HStack {
                                TextField("Min", value: $filters.bitrateMin, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                                Text("to")
                                    .foregroundColor(.secondary)
                                TextField("Max", value: $filters.bitrateMax, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                            }
                        }
                        
                        // HTTPS only
                        Toggle("HTTPS Only", isOn: Binding(
                            get: { filters.isHTTPS ?? false },
                            set: { filters.isHTTPS = $0 ? true : nil }
                        ))
                        
                        // Hide broken stations
                        Toggle("Hide Broken Stations", isOn: $filters.hideBroken)
                        
                        // Sort order
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sort By")
                                .font(.headline)
                            Picker("Sort", selection: $filters.orderString) {
                                Text("Name").tag("name")
                                Text("Votes").tag("votes")
                                Text("Click Count").tag("clickcount")
                                Text("Bitrate").tag("bitrate")
                                Text("Country").tag("country")
                                Text("Language").tag("language")
                                Text("State").tag("state")
                                Text("Tags").tag("tags")
                            }
                            .pickerStyle(.menu)
                            
                            Toggle("Reverse Order", isOn: $filters.reverse)
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 400)
                Divider()
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

