//
//  IcecastMetadataParser.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import Foundation
import AVFoundation

/// Parses Icecast metadata from radio streams
final class IcecastMetadataParser {
    
    /// Parse metadata from AVPlayerItem's timed metadata
    static func parseTimedMetadata(_ metadata: [AVMetadataItem]) -> (title: String?, artist: String?) {
        var title: String?
        var artist: String?
        
        for item in metadata {
            guard let key = item.commonKey?.rawValue ?? item.key as? String else { continue }
            
            // Get string value (use deprecated API for compatibility, or load async if needed)
            let stringValue: String?
            if #available(macOS 13.0, *) {
                // For now, use the deprecated API to avoid async complexity
                // In production, you might want to make this function async
                stringValue = item.stringValue
            } else {
                stringValue = item.stringValue
            }
            
            switch key {
            case AVMetadataKey.commonKeyTitle.rawValue, "icy-title", "StreamTitle":
                title = stringValue
            case AVMetadataKey.commonKeyArtist.rawValue, "icy-artist", "StreamArtist":
                artist = stringValue
            default:
                // Try to parse from value if it contains metadata
                if let value = stringValue {
                    let parsed = parseMetadataString(value)
                    if title == nil { title = parsed.title }
                    if artist == nil { artist = parsed.artist }
                }
            }
        }
        
        return (title, artist)
    }
    
    /// Parse metadata from HTTP headers (ICY protocol)
    static func parseHTTPHeaders(_ headers: [String: String]) -> (title: String?, artist: String?) {
        var title: String?
        var artist: String?
        
        // Check for Icecast metadata headers
        if let icyTitle = headers["icy-name"] ?? headers["icy-name"] {
            title = icyTitle
        }
        
        if let streamTitle = headers["icy-description"] {
            // Sometimes description contains "Artist - Title" format
            let parsed = parseMetadataString(streamTitle)
            if title == nil { title = parsed.title }
            if artist == nil { artist = parsed.artist }
        }
        
        return (title, artist)
    }
    
    /// Parse metadata string that might contain "Artist - Title" format
    private static func parseMetadataString(_ string: String) -> (title: String?, artist: String?) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to split by common separators
        let separators = [" - ", " – ", " — ", " | ", " / "]
        
        for separator in separators {
            if trimmed.contains(separator) {
                let parts = trimmed.components(separatedBy: separator)
                if parts.count >= 2 {
                    let artistPart = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let titlePart = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Only return if both parts are non-empty
                    if !artistPart.isEmpty && !titlePart.isEmpty {
                        return (titlePart, artistPart)
                    }
                }
            }
        }
        
        // If no separator found, treat entire string as title
        return (trimmed.isEmpty ? nil : trimmed, nil)
    }
    
    /// Extract metadata from ICY metadata string (format: StreamTitle='Artist - Title';)
    static func parseICYMetadata(_ metadata: String) -> (title: String?, artist: String?) {
        // ICY metadata format: StreamTitle='Artist - Title';
        let pattern = "StreamTitle='([^']+)'"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = metadata as NSString
        let results = regex?.matches(in: metadata, options: [], range: NSRange(location: 0, length: nsString.length))
        
        if let match = results?.first, match.numberOfRanges > 1 {
            let range = match.range(at: 1)
            if range.location != NSNotFound {
                let streamTitle = nsString.substring(with: range)
                return parseMetadataString(streamTitle)
            }
        }
        
        return (nil, nil)
    }
}

