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
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool { return true }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Create default window
        LSLGWindowController()
    }
    
    @IBAction func showPreference(sender: AnyObject) { (NSApplication.sharedApplication().keyWindow as? LSLGWindow)?.showPreference() }
    @IBAction func newWindow(sender: AnyObject)   { LSLGWindowController() }
    @IBAction func closeWindow(sender: AnyObject) { NSApplication.sharedApplication().keyWindow?.close() }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}

