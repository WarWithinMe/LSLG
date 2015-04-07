//
//  LSLGWindowController.swift
//  LSLG
//
//  Created by Morris on 4/7/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

private var WindowControllerArray = [LSLGWindowController]()

class LSLGWindowController: NSWindowController, NSWindowDelegate {
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    var logs = [(NSDate,String)]()
    var logSepTimer:NSTimer?
    
    override init() {
        super.init(window:nil)
        
        self.windowFrameAutosaveName = "LSLGWindow"
        
        var window = LSLGWindow()
        window.delegate = self
        self.window = window
        window.makeKeyAndOrderFront(nil)
        
        self.appendLog("aaa")
        
        WindowControllerArray.append(self)
    }
    
    func appendLog(aLog:String) {
        self.logs.append((NSDate(), aLog))
        self.logUpdated()
        
        if self.logSepTimer == nil { self.setLogTimer(30) }
    }
    
    func logUpdated() { NSNotificationCenter.defaultCenter().postNotification( NSNotification(name:"LSLGLogUpdate", object:self) ) }
    func setLogTimer(sec:NSTimeInterval) { self.logSepTimer = NSTimer(timeInterval: sec, target: self, selector: "onTimer:", userInfo: nil, repeats: false) }
    
    func onTimer(aTimer:NSTimer) {
        if let lastLog = self.logs.last {
            let interval:NSTimeInterval = 30 - lastLog.0.timeIntervalSinceDate( NSDate() )
            if interval >= 0 {
                // Re-schedule the timer, because we just received new log when the timer is on.
                self.setLogTimer( interval )
                return
            }
        }
        
        self.logSepTimer = nil
        // Add a blank line to indicate that previous message is old.
        self.logs.append((NSDate(),""))
        self.logUpdated()
    }
    
    func windowWillClose(notification: NSNotification) {
        if notification.object?.windowController() as LSLGWindowController == self {
            WindowControllerArray.removeAtIndex( find( WindowControllerArray, self)! )
            if let t = self.logSepTimer {
                t.invalidate()
            }
        }
    }
}
