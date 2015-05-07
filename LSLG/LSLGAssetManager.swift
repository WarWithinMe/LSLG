//
//  LSLGAssetManager.swift
//  LSLG
//
//  Created by Morris on 4/23/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

let LSLGWindowPipelineChange = "LSLGWindowPipelineChange"

class LSLGAssetManager: NSObject, LSLGFolderMonitorDelegate {
    
    var folderPath:String { return monitor != nil ? monitor!.folderPath : "" }
    
    private var monitor:LSLGFolderMonitor?
    
    override init() {
        super.init()
        
        // Add default assets
        for asset in LSLGAsset.DefaultAssets { assetMap[asset.assetKey] = asset }
        
        useAsset( "Suzanne", type: .Model )
        useAsset( "BuiltIn", type: .VertexShader )
        useAsset( "BuiltIn", type: .FragmentShader )
        useAsset( "BuiltIn", type: .GeometryShader )
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
        for path in added {
            if let a = LSLGAsset.assetWithPath(folderPath.stringByAppendingPathComponent(path)) {
                assetMap[ path ] = a
            }
        }
        
        for path in modified {
            assetMap[ path ]?.update()
        }
        
        for path in removed {
            assetMap[ path ] = nil
        }
        
        // This method is called by monitor after it has init read the folder
        if let info = initialAssetsInfo {
            initialAssetsInfo = nil
            
            useAsset(info["model"]!,    type: .Model)
            useAsset(info["vertex"]!,   type: .VertexShader)
            useAsset(info["fragment"]!, type: .FragmentShader)
            useAsset(info["geometry"]!, type: .GeometryShader)
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
    
    func getUsingAsset( type:LSLGAssetType )-> LSLGAsset? { return usingAssetMap[type] }
    
    func useAsset( name:String, type:LSLGAssetType ) {
        if let a = assetByName( name, type:type) { useAsset( a ) }
    }
    
    func useAsset( asset:LSLGAsset ) {
        if assetMap[asset.assetKey] != nil {
            usingAssetMap[asset.type] = asset
            
            NSNotificationCenter.defaultCenter().postNotification(
                NSNotification(name: LSLGWindowPipelineChange, object: self, userInfo:["newAsset":asset])
            )
            println("Using asset \(asset.name)")
        } else {
            println("Using invalid asset \(asset.name)")
        }
    }
    
    var glGeomShaders :[LSLGAsset] { return assetsByType( .GeometryShader ) }
    var glFragShaders :[LSLGAsset] { return assetsByType( .FragmentShader ) }
    var glVertShaders :[LSLGAsset] { return assetsByType( .VertexShader) }
    var glModels      :[LSLGAsset] { return assetsByType( .Model ) }
    
    var glCurrModel      :LSLGAsset { return getUsingAsset( .Model )! }
    var glCurrVertShader :LSLGAsset { return getUsingAsset( .VertexShader )! }
    var glCurrFragShader :LSLGAsset { return getUsingAsset( .FragmentShader )! }
    var glCurrGeomShader :LSLGAsset { return getUsingAsset( .GeometryShader )! }
    
    func glAssets(type:LSLGAssetType) -> [LSLGAsset]  { return assetsByType(  type )  }
    func glCurrAsset(type:LSLGAssetType) -> LSLGAsset { return getUsingAsset( type )! }
    
//    func onAssetUpdate(n:NSNotification) {
//        var sendNotify = false
//        if let asset = n.object as? LSLGAsset {
//            if asset == glCurrAsset( asset.type ) {
//                sendNotify = true
//            } else if let range = asset.path.rangeOfString( folderPath ) {
//                sendNotify = true
//            }
//        }
//        
//        if (!sendNotify) { return }
//        NSNotificationCenter.defaultCenter().postNotification(
//            NSNotification(name: LSLGWindowPipelineChange, object: self, userInfo:["asset":n.object!])
//        )
//    }
}
