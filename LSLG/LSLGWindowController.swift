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
let LSLGWindowSubviewToggle  = "LSLGWindowSubviewToggle"


class LSLGWindowController: NSWindowController, NSWindowDelegate {
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    typealias LogEntry = (time:NSDate, log:String, isError:Bool, desc:String)
    
    var logs:[LogEntry] = []
    private var logSepTimer:NSTimer?
    
    override init(window: NSWindow?) { super.init(window: window) }
    
    convenience init?( path:String ) {
        if path.isEmpty {
            // Always open blank window if the user request.
            self.init(savedInfo:["path":path])
            return
        }
        
        var nonWorking:LSLGWindowController? = nil
        for c in WindowControllerArray {
            if c.folderPath == path {
                self.init(window:nil)
                return nil
            } else if c.folderPath.isEmpty {
                nonWorking = c
            }
        }
        if let c = nonWorking {
            // If there's a blank window, use that window instead of create a new one.
            c.monitorFolder(path)
            c.window?.makeMainWindow()
            self.init(window:nil)
            return nil
        } else {
            self.init(savedInfo:["path":path])
        }
    }
    
    convenience init(savedInfo:[String:String]?) {
        
        self.init(window:nil)
        
        assetManager = LSLGAssetManager()
        
        // Window data
        if let info = savedInfo {
            // This will create a new AssetManager
            monitorFolder( info["path"]! )
            assetManager.initialAssetsInfo = info
        }
        
        // Window view related
        windowFrameAutosaveName = "LSLGWindow\(WindowControllerArray.count)"
        
        var w = LSLGWindow()
        w.delegate = self
        window = w
        w.createSubviews()
        w.makeKeyAndOrderFront(nil)
        WindowControllerArray.append(self)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "pipelineUpdated:", name: LSLGWindowPipelineChange, object: nil
        )
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector : "onAssetAvaible:", name: LSLGWindowAssetsAvailable, object: nil
        )
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "onWorkingFolderChanged:", name: LSLGWindowFolderChange, object: assetManager
        )
        
        NSTimer.scheduledTimerWithTimeInterval(0, target: self, selector: "updateOGL:", userInfo: nil, repeats: true)
    }
    
    func updateOGL( t:NSTimer ) {
        (window as! LSLGWindow).oglView.needsDisplay = true
    }
    
   
    /* Log Related Functions */
    func appendLog(aLog:String, isError:Bool = false, desc:String = "") {
        logs.append( (time:NSDate(), log:aLog, isError:isError, desc:desc) )
        
        NSNotificationCenter.defaultCenter().postNotification( NSNotification(name:LSLGWindowLogUpdate, object:self) )
        
        if !desc.isEmpty {
            (window as? LSLGWindow)?.quickLog( desc, isError )
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
    
    
    /* Asset Management */
    var folderPath:String { return assetManager.folderPath }
    private(set) var assetManager:LSLGAssetManager! 
    func monitorFolder(path:String) {
        if path.isEmpty || path == folderPath { return }
        
        for c in WindowControllerArray {
            if c.folderPath == path { return }
        }
        
        if assetManager.watchFolder( path ) {
            (window as? LSLGWindow)?.titleView.updateTitle()
            appendLog("Watching folder: \(path)", isError:false, desc:"Watching '\(path.lastPathComponent)'" )
        } else {
            appendLog("Failed to watch folder: \(path)", isError:true, desc:"Failed to watch '\(path.lastPathComponent)'" )
        }
    }
    
    func onWorkingFolderChanged( n:NSNotification ) {
        (window as! LSLGWindow).titleView.updateTitle()
        
        if let am = n.object as? LSLGAssetManager where (am == assetManager && am.folderPath.isEmpty) {
            appendLog("Working folder has been deleted.", isError:false, desc:"Working folder has been deleted" )
        }
    }
    
    func onAssetAvaible( aNotify:NSNotification ) {
        if assetManager != (aNotify.object as? LSLGAssetManager) { return }
        var oglView = (window as! LSLGWindow).oglView
        var changedTypes = (aNotify.userInfo as! [String:AnyObject])["changedTypes"] as! [Int]
        
        if ( find(changedTypes, LSLGAssetType.Image.rawValue) != nil ) { oglView.updateTexture() }
    }
    
    func pipelineUpdated( aNotify:NSNotification ) {
        if assetManager != (aNotify.object as? LSLGAssetManager) { return }
        var oglView = (window as! LSLGWindow).oglView
        var changedTypes = (aNotify.userInfo as! [String:AnyObject])["changedTypes"] as! [Int]
        
        if ( find(changedTypes, LSLGAssetType.Model.rawValue) != nil ) { oglView.updateModel() }
        if ( find(changedTypes, LSLGAssetType.Image.rawValue) != nil ) { oglView.updateTexture() }
        if ( find(changedTypes, LSLGAssetType.VertexShader.rawValue) != nil
          || find(changedTypes, LSLGAssetType.GeometryShader.rawValue) != nil
          || find(changedTypes, LSLGAssetType.FragmentShader.rawValue) != nil
        ) {
            oglView.updateProgram()
        }
    }
    
    private var settings:LSLGSettings? = nil
    func toggleSettings() {
        var w = window as! LSLGWindow
        if let p = settings {
            w.removeContent(p.view)
            settings = nil
        } else {
            
            if logView != nil { toggleLogView() /* Hide logview */ }
            
            settings = LSLGSettings()
            w.setContent(settings!.view, fillWindow: true)
        }
        
        NSNotificationCenter.defaultCenter().postNotification(
            NSNotification(name: LSLGWindowSubviewToggle, object: self, userInfo:[
                "subview" : "settings"
              , "visible" : settings != nil
            ])
        )
    }
    
    private var logView:LSLGLogView? = nil
    func toggleLogView() {
        var w = window as! LSLGWindow
        if let l = logView {
            w.removeContent( l )
            logView = nil
        } else {
            
            if settings != nil { toggleSettings() /* Hide settings */ }
            
            logView = LSLGLogView( frame:NSZeroRect )
            w.setContent( logView!, fillWindow:false )
        } 
        
        
        NSNotificationCenter.defaultCenter().postNotification(
            NSNotification(name: LSLGWindowSubviewToggle, object: self, userInfo:[
                "subview" : "logs"
              , "visible" : logView != nil
            ])
        )
    }
    
    func setYRotate( rotate:Bool ) {
        (window as! LSLGWindow).oglView.autoRotate = rotate
    }
    
    
    /* Tear Down */
    func windowWillClose(notification: NSNotification) {
        if notification.object?.windowController() as! LSLGWindowController == self {
            
            if WindowControllerArray.count == 1 {
                // Store last window's info
                LSLGWindowController.persistWindowInfo()
            }
            
            WindowControllerArray.removeAtIndex( find(WindowControllerArray, self)! )
            // Remove timer if it's still active.
            if let t = logSepTimer { t.invalidate() }
        }
    }
    
    /* Window Info */
    class func persistWindowInfo() {
        // At least persist one window info.
        if WindowControllerArray.count == 0 { return }
        
        var infos:[[String:String]] = []
        
        for c in WindowControllerArray {
            infos.append( [
                "path"     : c.folderPath
              , "model"    : c.assetManager.glCurrModel.name
              , "vertex"   : c.assetManager.glCurrVertShader.name
              , "fragment" : c.assetManager.glCurrFragShader.name
              , "geometry" : c.assetManager.glCurrGeomShader.name
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
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        // Once the window is removed, call persistWindowInfo() to remove info
        // about the closed window.
        LSLGWindowController.persistWindowInfo()
    }
}