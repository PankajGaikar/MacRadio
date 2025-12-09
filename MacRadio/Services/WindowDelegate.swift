//
//  WindowDelegate.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import AppKit

class WindowDelegate: NSObject, NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Hide window instead of closing
        sender.orderOut(nil)
        return false
    }
}

