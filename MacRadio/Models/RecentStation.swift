//
//  RecentStation.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import Foundation
import SwiftData
import RadioBrowserKit

@Model
final class RecentStation {
    var stationUUID: String
    var name: String
    var url: String
    var homepage: String?
    var favicon: String?
    var countrycode: String?
    var language: String?
    var tags: String?
    var codec: String?
    var bitrate: Int?
    var playedDate: Date
    
    init(from station: Station) {
        self.stationUUID = station.stationuuid
        self.name = station.name
        self.url = station.url
        self.homepage = station.homepage
        self.favicon = station.favicon
        self.countrycode = station.countrycode
        self.language = station.language
        self.tags = station.tags
        self.codec = station.codec
        self.bitrate = station.bitrate
        self.playedDate = Date()
    }
}

