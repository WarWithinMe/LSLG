//
//  LSLGAssetManager.swift
//  LSLG
//
//  Created by Morris on 4/23/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

class LSLGAssetManager: NSObject, LSLGFolderMonitorDelegate {
    
    var folderPath:String { return monitor != nil ? monitor!.folderPath : "" }
    
    private var monitor:LSLGFolderMonitor?
    
    init(path:String) {
        super.init()
        
        // Add default assets
        for asset in LSLGAsset.DefaultAssets { assetMap[asset.assetKey] = asset }
        
        useAsset( assetByName("Suzanne", type: .Model)! )
        useAsset( assetByName("BuiltIn", type: .VertexShader)! )
        useAsset( assetByName("BuiltIn", type: .FragmentShader)! )
        useAsset( assetByName("BuiltIn", type: .GeometryShader)! )
        
        // Create monitor
        if !path.isEmpty {
            monitor = LSLGFolderMonitor(path: path)
            monitor?.delegate = self
        }
    }
    
    
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
    func useAsset( asset:LSLGAsset )->Bool {
        if assetMap[asset.assetKey] != nil {
            usingAssetMap[asset.type] = asset
            return true
        }
        return false
    }
}
