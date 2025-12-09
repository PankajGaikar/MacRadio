//
//  WindowAccessor.swift
//  MacRadio
//
//  Created by Pankaj Gaikar on 09/12/25.
//

import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    let delegate: WindowDelegate
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.delegate = delegate
                window.isReleasedWhenClosed = false
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

