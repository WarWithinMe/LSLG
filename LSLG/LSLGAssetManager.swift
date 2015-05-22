//
//  LSLGAssetManager.swift
//  LSLG
//
//  Created by Morris on 4/23/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

let LSLGWindowPipelineChange  = "LSLGWindowPipelineChange"
let LSLGWindowAssetsAvailable = "LSLGWindowAssetsAvailable"

class LSLGAssetManager: NSObject, LSLGFolderMonitorDelegate {
    
    var folderPath:String { return monitor != nil ? monitor!.folderPath : "" }
    
    private var monitor:LSLGFolderMonitor?
    
    private var REG_FRAG:NSRegularExpression 
    private var REG_GEOM:NSRegularExpression
    private var REG_VERT:NSRegularExpression
    private var REG_MODL:NSRegularExpression
    private var REG_IMGE:NSRegularExpression
    
    override init() {
        var defaults = NSUserDefaults.standardUserDefaults()
        typealias REGEX = NSRegularExpression 
        REG_FRAG = REGEX(pattern: defaults.stringForKey("RegexFragment")!, options: .CaseInsensitive, error: nil)!
        REG_GEOM = REGEX(pattern: defaults.stringForKey("RegexGeometry")!, options: .CaseInsensitive, error: nil)!
        REG_VERT = REGEX(pattern: defaults.stringForKey("RegexVertex")!, options: .CaseInsensitive, error: nil)!
        REG_MODL = REGEX(pattern: defaults.stringForKey("RegexModel")!, options: .CaseInsensitive, error: nil)!
        REG_IMGE = REGEX(pattern: defaults.stringForKey("RegexImage")!,  options: .CaseInsensitive, error: nil)!
        
        super.init()
        
        // Add default assets
        for asset in LSLGAsset.DefaultAssets { assetMap[asset.assetKey] = asset }
        
        useDefaultAsset( .Image )
        useDefaultAsset( .Model )
        useDefaultAsset( .VertexShader )
        useDefaultAsset( .FragmentShader )
        useDefaultAsset( .GeometryShader )
    }
    
    func watchFolder( path:String )-> Bool {
        if path == folderPath { return true }
        if path.isEmpty { return false }
        
        // Create monitor
        monitor = LSLGFolderMonitor(path: path)
        monitor?.delegate = self
        return monitor != nil
    }
    
    var initialAssetsInfo:[String:String]?
    
    /* Asset management */
    private var assetMap = [String:LSLGAsset]()
    private var usingAssetMap = [LSLGAssetType:LSLGAsset]()
    
    func onFileChanged(paths: [String]) {
        var pipelineUpdated = [Int]()
        for path in paths {
            if let a = assetMap[path] {
                a.update()
                if isAssetUsing(a) {
                    pipelineUpdated.append(a.type.rawValue)
                }
            }
        } 
        if !pipelineUpdated.isEmpty {
            NSNotificationCenter.defaultCenter().postNotification(
                NSNotification(name: LSLGWindowPipelineChange, object: self, userInfo:["changedTypes":pipelineUpdated])
            ) 
        }
    }
    
    func onFolderChanged(added: [String], _ modified: [String], _ removed: [String]) {
        
        var pipelineUpdated = [Int]()
        var assetChanges    = [Int]()
        
        for path in added {
            if let a = assetWithPath(folderPath.stringByAppendingPathComponent(path)) {
                assetMap[ path ] = a
                assetChanges.append( a.type.rawValue )
            }
        }
        
        for path in modified {
            if let a = assetMap[ path ] {
                a.update()
                if isAssetUsing(a) {
                    pipelineUpdated.append( a.type.rawValue )
                }
                assetChanges.append( a.type.rawValue )
            }
        }
        
        for path in removed {
            if let a = assetMap[path] {
                if isAssetUsing( a ) {
                    useDefaultAsset(a.type)
                    pipelineUpdated.append( a.type.rawValue )
                }
                assetMap[ path ] = nil
                assetChanges.append( a.type.rawValue )
            }
        }
        
        // This method is called by monitor after it has init read the folder
        if let info = initialAssetsInfo {
            initialAssetsInfo = nil
            
            useAsset(info["model"],    type: .Model)
            useAsset(info["vertex"],   type: .VertexShader)
            useAsset(info["fragment"], type: .FragmentShader)
            useAsset(info["geometry"], type: .GeometryShader)
        } else if !pipelineUpdated.isEmpty {
            NSNotificationCenter.defaultCenter().postNotification(
                NSNotification(name: LSLGWindowPipelineChange, object: self, userInfo:["changedTypes":pipelineUpdated])
            )
        }
        
        if !(added.isEmpty && removed.isEmpty) {
            NSNotificationCenter.defaultCenter().postNotification(
                NSNotification(name: LSLGWindowAssetsAvailable, object: self, userInfo:["changedTypes":assetChanges])
            )
        }
    }
    
    private func assetWithPath( path:String )-> LSLGAsset? {
        var p = path.lastPathComponent
        let r = NSMakeRange(0, count(p))
        let o = NSMatchingOptions.WithoutAnchoringBounds
        
        var type:LSLGAssetType = .Generic
        
        if REG_FRAG.numberOfMatchesInString(p, options: o, range: r) > 0 {
            type = .FragmentShader
        } else if REG_VERT.numberOfMatchesInString(p, options: o, range: r) > 0 {
            type = .VertexShader
        } else if REG_GEOM.numberOfMatchesInString(p, options: o, range: r) > 0 {
            type = .GeometryShader
        } else if REG_IMGE.numberOfMatchesInString(p, options: o, range: r) > 0 {
            type = .Image
        } else if REG_MODL.numberOfMatchesInString(p, options: o, range: r) > 0 {
            type = .Model
        }
        return LSLGAsset.assetWithPath( path, type:type )
    }
    
    func assetsByType(type:LSLGAssetType)->[LSLGAsset] {
        var r = [LSLGAsset]()
        for (p, asset) in assetMap {
            if asset.type == type {
                r.append(asset)
            }
        }
        return r
    }
    
    func assetByName(name:String, type:LSLGAssetType)-> LSLGAsset? {
        for (p, asset) in assetMap {
            if asset.type == type && asset.name == name {
                return asset
            }
        }
        return nil
    }
    
    func isAssetUsing( asset:LSLGAsset )-> Bool { return glCurrAsset( asset.type ) == asset }
    
    func useAsset( name:String?, type:LSLGAssetType ) {
        if name != nil {
            if let a = assetByName( name!, type:type) { useAsset( a ) }
        }
    }
    
    func useAsset( asset:LSLGAsset ) {
        if assetMap[asset.assetKey] != nil {
            if usingAssetMap[ asset.type ] == asset { return }
            
            usingAssetMap[asset.type] = asset
            
            NSNotificationCenter.defaultCenter().postNotification( NSNotification(
               name: LSLGWindowPipelineChange
              , object: self
              , userInfo: ["changedTypes":[asset.type.rawValue]]
            ))
            println("Using asset \(asset.name)")
        } else {
            println("Using invalid asset \(asset.name)")
        }
    }
    
    func useDefaultAsset( assetType:LSLGAssetType ) {
        var name = ""
        switch assetType {
            case .Model: name = "Suzanne"
            case .Image: name = "None"
            default:     name = "BuiltIn"
        }
        if !name.isEmpty {
            usingAssetMap[assetType] = assetByName( name, type:assetType )!
        }
    }
    
    var glGeomShaders :[LSLGAsset] { return assetsByType( .GeometryShader ) }
    var glFragShaders :[LSLGAsset] { return assetsByType( .FragmentShader ) }
    var glVertShaders :[LSLGAsset] { return assetsByType( .VertexShader) }
    var glModels      :[LSLGAsset] { return assetsByType( .Model ) }
    var glTextures    :[LSLGAsset] { return assetsByType( .Image ) }
    
    var glCurrModel      :LSLGAsset { return glCurrAsset( .Model ) }
    var glCurrVertShader :LSLGAsset { return glCurrAsset( .VertexShader ) }
    var glCurrFragShader :LSLGAsset { return glCurrAsset( .FragmentShader ) }
    var glCurrGeomShader :LSLGAsset { return glCurrAsset( .GeometryShader ) }
    
    var glCurrTexture    :LSLGAsset { return glCurrAsset( .Image ) }
    
    func glAssets(type:LSLGAssetType) -> [LSLGAsset]  { return assetsByType( type )  }
    func glCurrAsset(type:LSLGAssetType) -> LSLGAsset { return usingAssetMap[type]! }
}
