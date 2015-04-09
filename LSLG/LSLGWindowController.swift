//
//  LSLGWindowController.swift
//  LSLG
//
//  Created by Morris on 4/7/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

private var WindowControllerArray = [LSLGWindowController]()

let LSLGWindowLogUpdate = "LSLGWindowLogUpdate"

class LSLGWindowController: NSWindowController, NSWindowDelegate {
    
    typealias LogEntry = (time:NSDate, log:String, isError:Bool)
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    var logs:[LogEntry] = []
    var logSepTimer:NSTimer?
    
    override init() {
        super.init(window:nil)
        
        self.windowFrameAutosaveName = "LSLGWindow"
        
        var window = LSLGWindow()
        window.delegate = self
        self.window = window
        window.makeKeyAndOrderFront(nil)
        WindowControllerArray.append(self)
        
        
        self.appendLog("aaa")
    }
    
    
    /* Log Related Functions */
    func appendLog(aLog:String, isError:Bool = false) {
        self.logs.append( (time:NSDate(), log:aLog, isError:isError) )
        self.logUpdated()
        
        if self.logSepTimer == nil { self.setLogTimer(30) }
    }
    
    func logUpdated() { NSNotificationCenter.defaultCenter().postNotification( NSNotification(name:LSLGWindowLogUpdate, object:self) ) }
    func setLogTimer(sec:NSTimeInterval) { self.logSepTimer = NSTimer(timeInterval: sec, target: self, selector: "onTimer:", userInfo: nil, repeats: false) }
    
    func onTimer(aTimer:NSTimer) {
        if let lastLog = self.logs.last {
            let interval:NSTimeInterval = 30 - lastLog.0.timeIntervalSinceDate( NSDate() )
            if interval >= 0 {
                // Re-schedule the timer, because we just received new log after the timer is on.
                self.setLogTimer( interval )
                return
            }
        }
        
        // Add a blank line to indicate that previous message is old.
        self.appendLog("")
        self.logSepTimer = nil
    }
    
    
    /* Tear Down */
    func windowWillClose(notification: NSNotification) {
        if notification.object?.windowController() as LSLGWindowController == self {
            WindowControllerArray.removeAtIndex( find( WindowControllerArray, self)! )
            if let t = self.logSepTimer {
                t.invalidate()
            }
        }
    }
}
