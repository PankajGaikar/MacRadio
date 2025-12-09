# MacRadio

A beautiful, open-source Mac app for streaming radio stations from around the world, built with SwiftUI and powered by [RadioBrowserKit](https://github.com/PankajGaikar/RadioBrowserKit).

## Features

### 🎵 Core Functionality
- **Browse & Search**: Discover thousands of radio stations from around the world
- **Country & Region Browsing**: Browse stations by country with regional subcategories (states)
- **Advanced Search Filters**: Filter by country, language, tag, codec, bitrate, and more
- **Favorites**: Save your favorite stations for quick access
- **Recently Played**: Automatically tracks the last 10 played stations
- **Icecast Metadata**: Displays real-time song titles and artist information from Icecast streams

### 🎛️ Playback Features
- **Play/Pause/Stop Controls**: Full playback control
- **Volume Control**: Adjustable volume slider
- **AirPlay Support**: Stream to AirPlay-enabled devices with visual indicators
- **Media Controls**: Integration with macOS Now Playing and Control Center
- **Remote Control**: Support for keyboard media keys and remote control devices

### 🎨 User Experience
- **Menu Bar Integration**: App stays running in the menu bar when window is closed
- **Always-On Player**: Persistent player controls at the bottom of the window
- **Lazy Loading**: Efficient pagination for large station lists
- **Current Country Highlighting**: Your country appears at the top of the countries list
- **Horizontal Category Grid**: Quick country selection with visual grid

## Architecture

MacRadio follows a clean **MVVM (Model-View-ViewModel)** architecture:

- **Models**: `FavoriteStation`, `RecentStation` (SwiftData)
- **ViewModels**: `StationListViewModel`, `FavoritesViewModel`, `RecentsViewModel`, `CountriesViewModel`, `SearchFilters`
- **Views**: SwiftUI views for each screen and component
- **Services**: `PlaybackService`, `RadioBrowserService`, `MediaControlsManager`, `MenuBarManager`, `IcecastMetadataParser`

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Installation

### Building from Source

1. Clone the repository:
```bash
git clone https://github.com/PankajGaikar/MacRadio.git
cd MacRadio
```

2. Open the project in Xcode:
```bash
open MacRadio.xcodeproj
```

3. Build and run the project (⌘R)

### Dependencies

- **RadioBrowserKit**: Local Swift Package dependency (included in the project)

## Usage

### Getting Started

1. Launch MacRadio
2. Browse stations by clicking "Browse" in the sidebar
3. Use the search bar to find specific stations
4. Click the play button next to any station to start streaming
5. Add stations to favorites by clicking the heart icon

### Browsing by Country

1. Click "Countries" in the sidebar
2. Select a country from the list (your current country appears at the top)
3. If the country has regions/states, select one to see stations
4. Stations will load automatically with lazy loading as you scroll

### Using Search Filters

1. Enter a search term in the search bar
2. Click the "Filters" button to open the filter panel
3. Set filters like:
   - Country Code (e.g., US, GB, IN)
   - Language
   - Tag (e.g., jazz, rock, news)
   - Codec (MP3, AAC, OGG, FLAC)
   - Bitrate range
   - HTTPS only
   - Sort order
4. Click "Search" to apply filters

### AirPlay

1. Start playing a station
2. Click the AirPlay button in the player controls
3. Select an AirPlay-enabled device
4. The AirPlay indicator will show when streaming to an external device

### Menu Bar Mode

- Close the window to keep the app running in the menu bar
- Click the menu bar icon to show the window again
- The icon changes to indicate playback state

## Project Structure

```
MacRadio/
├── MacRadio/
│   ├── Models/          # SwiftData models
│   ├── ViewModels/      # MVVM view models
│   ├── Views/           # SwiftUI views
│   ├── Services/        # Business logic services
│   └── MacRadioApp.swift
├── MacRadio.xcodeproj/
└── README.md
```

## Technologies

- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Local data persistence
- **AVFoundation**: Audio playback and AirPlay support
- **MediaPlayer**: Now Playing and remote control integration
- **Combine**: Reactive programming
- **RadioBrowserKit**: Radio Browser API client

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source. See LICENSE file for details.

## Acknowledgments

- [Radio Browser API](https://www.radio-browser.info/) for providing the radio station database
- [RadioBrowserKit](https://github.com/PankajGaikar/RadioBrowserKit) for the Swift API client

## Author

Pankaj Gaikar

---

Made with ❤️ for radio lovers

