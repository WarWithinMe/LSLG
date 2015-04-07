//
//  AppDelegate.swift
//  LSLG
//
//  Created by Morris on 3/31/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var window:LSLGWindowController!
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool { return true }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Create default window
        LSLGWindowController()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

