//
//  LSLGWindowController.swift
//  LSLG
//
//  Created by Morris on 4/7/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Darwin
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
    
    convenience init() { self.init(savedInfo:nil) }
    
    init(savedInfo:[String:String]?) {
        
        if let info = savedInfo {
            usingModel      = info["model"]!
            usingVertexSh   = info["vertex"]!
            usingFragmentSh = info["fragment"]!
            usingGeometrySh = info["geometry"]!
        }
        
        super.init(window:nil)
        
        windowFrameAutosaveName = "LSLGWindow\(WindowControllerArray.count)"
        
        var w = LSLGWindow()
        w.delegate = self
        window = w
        
        w.createSubviews()
        w.makeKeyAndOrderFront(nil)
        WindowControllerArray.append(self)
        
        if let info = savedInfo {
            monitorFolder( info["path"]! )
        }
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
    private var folderPath:String = ""
    private var folderDSrc:dispatch_source_t?
    func monitorFolder(path:String) {
        
        let p = path as NSString
        
        var dirFD = Darwin.open( p.fileSystemRepresentation, O_EVTONLY )
        if dirFD < 0 {
            // TODO: Failed to watch folder, post log
            postWatchFolderLog( path, success: false )
            return
        }
        
        // Create a dispatch source to monitor the directory for writes
        var _src = dispatch_source_create(
            DISPATCH_SOURCE_TYPE_VNODE  // Watch for certain events on the VNODE spec'd by the second (handle) argument
          , UInt(dirFD)                 // The handle to watch (the directory FD)
          , DISPATCH_VNODE_WRITE        // The events to watch for on the VNODE spec'd by handle (writes)
          , dispatch_get_main_queue()   // The queue to which the handler block will ultimately be dispatched
        )
        if _src == nil {
            Darwin.close( dirFD )
            postWatchFolderLog( path, success: false )
            return
        }
        
        // Set the block to be submitted in response to an event
        dispatch_source_set_event_handler(_src) {
            [unowned self] in
            self.reloadFolder()
        }
        
        // Set the block to be submitted in response to source cancellation
        dispatch_source_set_cancel_handler(_src) { Darwin.close( dirFD ) }
        
        // Unsuspend the source s.t. it will begin submitting blocks
        dispatch_resume( _src )
        
        if folderDSrc != nil {
            println("un-watch folder: \(folderPath)")
            dispatch_source_cancel( folderDSrc! )
        }
        
        folderPath = path
        folderDSrc = _src
        
        postWatchFolderLog( path, success: true )
    }

    private func postWatchFolderLog( path:String, success:Bool ) {
        if success {
            appendLog("Watching folder: \(path)", isError:false, desc:"Watching '\((path as NSString).lastPathComponent)'" )
        } else {
            appendLog("Failed to watch folder: \(path)", isError:true, desc:"Failed to watch '\((path as NSString).lastPathComponent)'" )
        }
    }
    
    func reloadFolder() {
        println("folderChanged")
    }
    
    /* Shader */
    func geometryShs()-> [String] { return ["Geometry1", "Geometry2", "Default", "Geometry3"] }
    func fragmentShs()-> [String] { return ["Default"] }
    func vertexShs  ()-> [String] { return ["Vertex1", "Vertex2", "Vertex3", "Default", "Vertex4"] }
    func models     ()-> [String] { return ["Cube", "Sphere", "Donut", "Suzanne"] }
    
    var usingModel:String = "Suzanne" {
        didSet {
            if let idx = find( models(), usingModel ) {
                NSNotificationCenter.defaultCenter().postNotification( NSNotification(name: LSLGWindowPipelineChange, object: self, userInfo: ["component":"model"]) )
            } else {
                usingModel = oldValue
            }
            
        }
    }
    
    var usingFragmentSh:String = "Default" {
        didSet {
            if let idx = find( fragmentShs(), usingFragmentSh ) {
                NSNotificationCenter.defaultCenter().postNotification( NSNotification(name: LSLGWindowPipelineChange, object: self, userInfo: ["component":"fragment"]) )
            } else {
                usingFragmentSh = oldValue
            }
        }
    }
    var usingGeometrySh:String = "Default" {
        didSet {
            if let idx = find( geometryShs(), usingGeometrySh ) {
                NSNotificationCenter.defaultCenter().postNotification( NSNotification(name: LSLGWindowPipelineChange, object: self, userInfo: ["component":"geometry"]) )
            } else {
                usingGeometrySh = oldValue
            }
        }
    }
    var usingVertexSh:String = "Default" {
        didSet {
            if let idx = find( vertexShs(), usingVertexSh ) {
                NSNotificationCenter.defaultCenter().postNotification( NSNotification(name: LSLGWindowPipelineChange, object: self, userInfo: ["component":"vertex"]) )
            } else {
                usingVertexSh = oldValue
            }
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
    
    /* Window Info */
    class func persistWindowInfo() {
        var infos:[[String:String]] = []
        
        for c in WindowControllerArray {
            infos.append( [
                "path"     : c.folderPath
              , "model"    : c.usingModel
              , "vertex"   : c.usingVertexSh
              , "fragment" : c.usingFragmentSh
              , "geometry" : c.usingGeometrySh
            ] )
        }
        
        var def = NSUserDefaults.standardUserDefaults()
        def.setObject( infos, forKey: "WindowsInfo" )
        def.synchronize()
    }
    
    class func createWindowOnAppLaunch() {
        var def = NSUserDefaults.standardUserDefaults()
        if let infos = def.objectForKey("WindowsInfo") as? [[String:String]] where infos.count > 0 {
            // Restore windows.
            for info in infos {
                LSLGWindowController(savedInfo:info)
            }
            
        } else {
            LSLGWindowController()
        }
    }
}
