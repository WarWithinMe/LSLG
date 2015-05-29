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
    
    private var finishedLaunching:Bool = false
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        finishedLaunching = true
        
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
          , "MSAA" : false
        ])
        
        // Each CVDisplayLink will create a high priority background thread.
        // Tried to create a CVDisplayLilnk for each window, but the app
        // freeze after second window is created.
        var dlpointer:Unmanaged<CVDisplayLink>?
        CVDisplayLinkCreateWithActiveCGDisplays(&dlpointer)
        displayLink = dlpointer?.takeRetainedValue()
        
        CVDisplayLinkSetOutputCallback( displayLink!, lslgGetCVDisplayLinkCallback(), UnsafeMutablePointer<Void>(unsafeAddressOf(self)) )
        CVDisplayLinkStart( displayLink! )
    }
    
    
    private var displayLink:CVDisplayLink?
    func onCVDisplayCallback( outPutTime:UnsafePointer<CVTimeStamp> )-> CVReturn {
        // After some testing, it seems like when a method is call upon an object,
        // the ARC will wrap the call with retain/release(), thus, the object will
        // never get released before the method returns.
        
        // So if the opengl view will never get released before render fisnihed.
        
        // The only thing we need to do about CVDisplayLink is to stop it when app is terminating.
        LSLGWindowController.updateOpenGl()
        return kCVReturnSuccess.value
    }
    
    
    @IBAction func showPreference(sender: AnyObject) { (NSApplication.sharedApplication().keyWindow?.windowController() as? LSLGWindowController)?.toggleSettings() }
    @IBAction func newWindow(sender: AnyObject)   { LSLGWindowController(path:"") }
    @IBAction func closeWindow(sender: AnyObject) { NSApplication.sharedApplication().keyWindow?.close() }
    
    func applicationShouldTerminate(app:NSApplication)->NSApplicationTerminateReply {
        // Store the window infomation when cocoa call this method.
        // Because if we do it in applicationWillTerminate(), all the window has already closed.
        LSLGWindowController.persistWindowInfo()
        return .TerminateNow
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {}
    
    func openFolder( path:String ) { LSLGWindowController(path:path) }
    
    func application(sender: NSApplication, openFiles filenames: [AnyObject]) {
        for file in (filenames as! [String]) {
            openFolder(file)
        }
    }
    func application(sender: NSApplication, openFile: String) -> Bool {
        openFolder(openFile)
        return true
    }
    func applicationOpenUntitledFile(sender: NSApplication) -> Bool {
        if finishedLaunching { openFolder("") }
        return true
    }
}

