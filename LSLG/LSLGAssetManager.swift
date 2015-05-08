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
    
    override init() {
        super.init()
        
        // Add default assets
        for asset in LSLGAsset.DefaultAssets { assetMap[asset.assetKey] = asset }
        
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
        for path in paths {
            assetMap[ path ]?.update()
        } 
    }
    
    func onFolderChanged(added: [String], _ modified: [String], _ removed: [String]) {
        
        var pipelineUpdated = false
        
        for path in added {
            if let a = LSLGAsset.assetWithPath(folderPath.stringByAppendingPathComponent(path)) {
                assetMap[ path ] = a
            }
        }
        
        for path in modified {
            var a = assetMap[ path ]
            a?.update()
            if a != nil && isAssetUsing( a! ) {
                pipelineUpdated = true
            }
        }
        
        for path in removed {
            if let a = assetMap[path] {
                if isAssetUsing( a ) {
                    pipelineUpdated = true
                    useDefaultAsset(a.type)
                }
                assetMap[ path ] = nil
            }
        }
        
        // This method is called by monitor after it has init read the folder
        if let info = initialAssetsInfo {
            initialAssetsInfo = nil
            
            useAsset(info["model"]!,    type: .Model)
            useAsset(info["vertex"]!,   type: .VertexShader)
            useAsset(info["fragment"]!, type: .FragmentShader)
            useAsset(info["geometry"]!, type: .GeometryShader)
        } else if pipelineUpdated {
            NSNotificationCenter.defaultCenter().postNotification(
                NSNotification(name: LSLGWindowPipelineChange, object: self, userInfo:nil)
            )
        }
        
        if !(added.isEmpty && removed.isEmpty) {
            NSNotificationCenter.defaultCenter().postNotification(
                NSNotification(name: LSLGWindowAssetsAvailable, object: self, userInfo:nil)
            )
        }
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
    
    func useAsset( name:String, type:LSLGAssetType ) {
        if let a = assetByName( name, type:type) { useAsset( a ) }
    }
    
    func useAsset( asset:LSLGAsset ) {
        if assetMap[asset.assetKey] != nil {
            if usingAssetMap[ asset.type ] == asset { return }
            
            usingAssetMap[asset.type] = asset
            
            NSNotificationCenter.defaultCenter().postNotification(
                NSNotification(name: LSLGWindowPipelineChange, object: self, userInfo:nil)
            )
            println("Using asset \(asset.name)")
        } else {
            println("Using invalid asset \(asset.name)")
        }
    }
    
    func useDefaultAsset( assetType:LSLGAssetType ) {
        var name = ""
        switch assetType {
            case .Model: name = "Suzanne"
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
    
    var glCurrModel      :LSLGAsset { return glCurrAsset( .Model ) }
    var glCurrVertShader :LSLGAsset { return glCurrAsset( .VertexShader ) }
    var glCurrFragShader :LSLGAsset { return glCurrAsset( .FragmentShader ) }
    var glCurrGeomShader :LSLGAsset { return glCurrAsset( .GeometryShader ) }
    
    func glAssets(type:LSLGAssetType) -> [LSLGAsset]  { return assetsByType(  type )  }
    func glCurrAsset(type:LSLGAssetType) -> LSLGAsset { return usingAssetMap[type]! }
}
