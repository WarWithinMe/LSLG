//
//  LSLGWindowController.swift
//  LSLG
//
//  Created by Morris on 4/7/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

private var WindowControllerArray = [LSLGWindowController]()
private let OldLogMarkerAddDelay:NSTimeInterval = 20

// Notification names
let LSLGWindowLogUpdate      = "LSLGWindowLogUpdate"
let LSLGWindowPipelineChange = "LSLGWindowPipelineChange"


class LSLGWindowController: NSWindowController, NSWindowDelegate {
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    typealias LogEntry = (time:NSDate, log:String, isError:Bool, desc:String)
    
    var logs:[LogEntry] = []
    private var logSepTimer:NSTimer?
    
    init() {
        super.init(window:nil)
        
        windowFrameAutosaveName = "LSLGWindow\(WindowControllerArray.count)"
        
        var w = LSLGWindow()
        w.delegate = self
        window = w
        
        w.createSubviews()
        w.makeKeyAndOrderFront(nil)
        WindowControllerArray.append(self)
    }
   
    /* Log Related Functions */
    func appendLog(aLog:String, isError:Bool = false, desc:String = "") {
        logs.append( (time:NSDate(), log:aLog, isError:isError, desc:desc) )
        
        NSNotificationCenter.defaultCenter().postNotification( NSNotification(name:LSLGWindowLogUpdate, object:self) )
        
        if !desc.isEmpty {
            (window as! LSLGWindow).quickLog( desc, isError )
        }
        
        if logSepTimer == nil { setLogTimer(OldLogMarkerAddDelay) }
    }
    
    func setLogTimer(sec:NSTimeInterval) {
        logSepTimer = NSTimer.scheduledTimerWithTimeInterval(sec, target: self, selector: "onTimer:", userInfo: nil, repeats: false)
    }
    
    func onTimer(aTimer:NSTimer) {
        if let lastLog = logs.last {
            let interval:NSTimeInterval = OldLogMarkerAddDelay - NSDate().timeIntervalSinceDate( lastLog.0 )
            if interval >= 0 {
                // Re-schedule the timer, because we just received new log after the timer is on.
                setLogTimer( interval )
                return
            }
        }
        
        // Add a blank line to indicate that previous message is old.
        appendLog("")
        logSepTimer = nil
    }
    
    
    /* Watch changes in folder */
    func monitorFolder(path:String) {
        
    }
    
    /* Shader */
    func geometryShs()-> [String] { return ["Geometry1", "Geometry2", "Default", "Geometry3"] }
    func fragmentShs()-> [String] { return ["Frag1", "Frag2", "Frag3", "Default", "Frag4"] }
    func vertexShs()-> [String] { return ["Vertex1", "Vertex2", "Vertex3", "Default", "Vertex4"] }
    func models()-> [String] { return ["Cube", "Sphere", "Donut", "Suzanne"] }
    
    var usingModel:String = "Suzanne" {
        didSet {
            println("using new model \(usingModel)")
            NSNotificationCenter.defaultCenter().postNotification( NSNotification(name: LSLGWindowPipelineChange, object: self, userInfo: ["component":"model"]) )
        }
    }
    
    var usingFragmentSh:String = "Default" {
        didSet {
            println("using new fragment shader \(usingFragmentSh)")
            NSNotificationCenter.defaultCenter().postNotification( NSNotification(name: LSLGWindowPipelineChange, object: self, userInfo: ["component":"fragment"]) )
        }
    }
    var usingGeometrySh:String = "Default" {
        didSet {
            println("using new Geometry shader \(usingGeometrySh)")
            NSNotificationCenter.defaultCenter().postNotification( NSNotification(name: LSLGWindowPipelineChange, object: self, userInfo: ["component":"geometry"]) )
        }
    }
    var usingVertexSh:String = "Default" {
        didSet {
            println("using new Vertex shader \(usingVertexSh)")
            NSNotificationCenter.defaultCenter().postNotification( NSNotification(name: LSLGWindowPipelineChange, object: self, userInfo: ["component":"vertex"]) )
        }
    }
    
    
    /* Tear Down */
    func windowWillClose(notification: NSNotification) {
        if notification.object?.windowController() as! LSLGWindowController == self {
            WindowControllerArray.removeAtIndex( find(WindowControllerArray, self)! )
            // Remove timer if it's still active.
            if let t = logSepTimer { t.invalidate() }
        }
    }
}
