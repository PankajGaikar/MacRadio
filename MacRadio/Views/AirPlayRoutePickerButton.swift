//
//  AirPlayRoutePickerButton.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import SwiftUI
import AVKit

@available(macOS 11.0, *)
struct AirPlayRoutePickerButton: NSViewRepresentable {
    func makeNSView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.isRoutePickerButtonBordered = false
        return routePickerView
    }
    
    func updateNSView(_ nsView: AVRoutePickerView, context: Context) {
        // No updates needed
    }
}

