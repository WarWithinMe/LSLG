//
//  AppDelegate.swift
//  LSLG
//
//  Created by Morris on 3/31/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

@NSApplicationMain
class LSLGAppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("QuitWhenLastWindowClosed")
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Create default window
        LSLGWindowController.createWindowOnAppLaunch()
        
        var defaults = NSUserDefaults.standardUserDefaults()
        defaults.registerDefaults([
            "RegexFragment" : "\\.frag$"
          , "RegexGeometry" : "\\.geom$"
          , "RegexVertex"   : "\\.vert$"
          , "RegexModel"    : "\\.obj$"
          , "RegexImage"    : "\\.(png|jpg|bmp)$"
            
          , "QuitWhenLastWindowClosed" : true
          , "AutoYaxisRotation" : true
          , "FXAA" : false
        ])
    }
    
    @IBAction func showPreference(sender: AnyObject) { (NSApplication.sharedApplication().keyWindow?.windowController() as? LSLGWindowController)?.toggleSettings() }
    @IBAction func newWindow(sender: AnyObject)   { LSLGWindowController() }
    @IBAction func closeWindow(sender: AnyObject) { NSApplication.sharedApplication().keyWindow?.close() }
    
    func applicationShouldTerminate(app:NSApplication)->NSApplicationTerminateReply {
        // Store the window infomation when cocoa call this method.
        // Because if we do it in applicationWillTerminate(), all the window has already closed.
        LSLGWindowController.persistWindowInfo()
        return .TerminateNow
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {}
}

