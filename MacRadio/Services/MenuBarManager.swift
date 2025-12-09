//
//  MenuBarManager.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import AppKit
import SwiftUI
import Combine

@MainActor
final class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    @Published var isWindowVisible = true
    
    init() {
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Use SF Symbol for menu bar icon
            if let image = NSImage(systemSymbolName: "radio", accessibilityDescription: "MacRadio") {
                image.isTemplate = true
                image.size = NSSize(width: 18, height: 18)
                button.image = image
            }
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create menu
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Show Window", action: #selector(showWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit MacRadio", action: #selector(quitApp), keyEquivalent: "q"))
        
        // Set menu items target
        menu.items.forEach { $0.target = self }
        
        statusItem?.menu = menu
    }
    
    @objc private func togglePopover() {
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                if let button = statusItem?.button {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                }
            }
        }
    }
    
    @objc private func showWindow() {
        // Show all windows
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Show all windows
        for window in NSApp.windows {
            window.makeKeyAndOrderFront(nil)
        }
        
        isWindowVisible = true
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    func updateMenuBarIcon(isPlaying: Bool) {
        if let button = statusItem?.button {
            let iconName = isPlaying ? "radio.fill" : "radio"
            if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: "MacRadio") {
                image.isTemplate = true
                image.size = NSSize(width: 18, height: 18)
                button.image = image
            }
        }
    }
}

