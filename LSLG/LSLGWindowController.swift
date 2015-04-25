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
let LSLGWindowFolderChange   = "LSLGWindowFolderChange"


class LSLGWindowController: NSWindowController, NSWindowDelegate {
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    typealias LogEntry = (time:NSDate, log:String, isError:Bool, desc:String)
    
    var logs:[LogEntry] = []
    private var logSepTimer:NSTimer?
    
    convenience init() { self.init(savedInfo:nil) }
    
    init(savedInfo:[String:String]?) {
        
        super.init(window:nil)
        
        // Window data
        if let info = savedInfo {
            monitorFolder( info["path"]! )
            
            useAsset(info["model"]!, type: .Model)
            useAsset(info["vertex"]!, type: .VertexShader)
            useAsset(info["fragment"]!, type: .FragmentShader)
            useAsset(info["geometry"]!, type: .GeometryShader)
        } else {
            useAsset("Suzanne", type: .Model)
            useAsset("BuiltIn", type: .VertexShader)
            useAsset("BuiltIn", type: .FragmentShader)
            useAsset("BuiltIn", type: .GeometryShader)
        }
        
        // Window view related
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
    
    
    /* Watch changes in folder */
    var folderPath:String { return assetManager.folderPath as! String }
    private var assetManager = LSLGAssetManager()
    func monitorFolder(path:String) {
        if path.isEmpty { return }
        if let asset = LSLGAssetManager( path:path ) {
            assetManager = asset
            NSNotificationCenter.defaultCenter().postNotification( NSNotification(name: LSLGWindowFolderChange, object: self, userInfo:nil) )
            appendLog("Watching folder: \(path)", isError:false, desc:"Watching '\(path.lastPathComponent)'" )
        } else {
            appendLog("Failed to watch folder: \(path)", isError:true, desc:"Failed to watch '\(path.lastPathComponent)'" )
        }
    }
    

    /* Shader & Model */
    var glGeomShaders :[LSLGAsset] { return assetManager.assetsByType( .GeometryShader ) }
    var glFragShaders :[LSLGAsset] { return assetManager.assetsByType( .FragmentShader ) }
    var glVertShaders :[LSLGAsset] { return assetManager.assetsByType( .VertexShader) }
    var glModels      :[LSLGAsset] { return assetManager.assetsByType( .Model ) }
    
    var glCurrModel      :LSLGAsset { return assetManager.getUsingAsset( .Model )! }
    var glCurrVertShader :LSLGAsset { return assetManager.getUsingAsset( .VertexShader )! }
    var glCurrFragShader :LSLGAsset { return assetManager.getUsingAsset( .FragmentShader )! }
    var glCurrGeomShader :LSLGAsset { return assetManager.getUsingAsset( .FragmentShader )! }
    
    func glAssets(type:LSLGAssetType) -> [LSLGAsset]  { return assetManager.assetsByType(  type )  }
    func glCurrAsset(type:LSLGAssetType) -> LSLGAsset { return assetManager.getUsingAsset( type )! }
    
    func useAsset( name:String, type:LSLGAssetType ) {
        if let a = assetManager.assetByName( name, type:type) {
            useAsset( a )
        } else {
            println("Using invalid asset \(name)")
        }
    }
    func useAsset( asset:LSLGAsset ) {
        if assetManager.useAsset( asset ) {
            NSNotificationCenter.defaultCenter().postNotification(
                NSNotification(name: LSLGWindowPipelineChange, object: self, userInfo:["assetType":asset.type.rawValue])
            )
        } else {
            println("Using invalid asset \(asset)")
        }
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
              , "model"    : c.glCurrModel.name
              , "vertex"   : c.glCurrVertShader.name
              , "fragment" : c.glCurrFragShader.name
              , "geometry" : c.glCurrFragShader.name
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
