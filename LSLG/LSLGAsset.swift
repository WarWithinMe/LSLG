//
//  LSLGAsset.swift
//  LSLG
//
//  Created by Morris on 4/24/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

enum LSLGAssetType:Int {
    case FragmentShader
    case VertexShader
    case GeometryShader
    case Image
    case Model
}

class LSLGAsset: NSObject {
    
    private var path:String
    private(set) var type:LSLGAssetType
    private(set) var name:String
    
    static var StripExtReg = NSRegularExpression(pattern: "\\.[^.]+$", options:.CaseInsensitive, error: nil)!
    
    init( path:String, type:LSLGAssetType ) {
        self.path = path
        self.type = type
        
        var n = path.lastPathComponent
        self.name = LSLGAsset.StripExtReg.stringByReplacingMatchesInString(
            n
          , options: NSMatchingOptions.allZeros
          , range: NSMakeRange(0, count(n))
          , withTemplate: ""
        )
        super.init()
    }
    
    // When the content in the file system changes, this method is called.
    func update(){}
    
    class func assetWithPath( path:String )-> LSLGAsset? {
        var delegate = NSApplication.sharedApplication().delegate as! LSLGAppDelegate
        var p = path.lastPathComponent
        let r = NSMakeRange(0, count(p))
        let o = NSMatchingOptions.WithoutAnchoringBounds
        if delegate.REG_FRAG.numberOfMatchesInString(p, options: o, range: r) > 0 {
            return LSLGAssetFragSh( path )
        } else if delegate.REG_VERT.numberOfMatchesInString(p, options: o, range: r) > 0 {
            return LSLGAssetVertexSh( path )
        } else if delegate.REG_GEOM.numberOfMatchesInString(p, options: o, range: r) > 0 {
            return LSLGAssetGeoSh( path )
        } else if delegate.REG_IMGE.numberOfMatchesInString(p, options: o, range: r) > 0 {
            return LSLGAssetImage( path )
        } else if delegate.REG_MODL.numberOfMatchesInString(p, options: o, range: r) > 0 {
            return LSLGAssetModel( path )
        }
        return nil
    }
    
    private(set) var isBuiltIn = false
    private func markAsBuiltIn()->LSLGAsset { self.isBuiltIn = true; self.name = "BuiltIn"; return self }
    
    static let DefaultAssets = [
        LSLGAssetFragSh.defaultAsset()
      , LSLGAssetVertexSh.defaultAsset()
      , LSLGAssetGeoSh.defaultAsset()
      , LSLGAssetModel.cube()
      , LSLGAssetModel.sphere()
      , LSLGAssetModel.donut()
      , LSLGAssetModel.suzanne()
    ]
}

func < (left:LSLGAsset, right:LSLGAsset)->Bool {
    if left.isBuiltIn != right.isBuiltIn { return left.isBuiltIn }
    return left.name < right.name
}
func > (left:LSLGAsset, right:LSLGAsset)->Bool {
    if left.isBuiltIn != right.isBuiltIn { return right.isBuiltIn }
    return left.name > right.name
}

class LSLGAssetFragSh : LSLGAsset {
    init( _ path:String ) { super.init(path:path, type:.FragmentShader) }
    
    class func defaultAsset()-> LSLGAsset { return LSLGAssetFragSh("").markAsBuiltIn() }
}
class LSLGAssetVertexSh : LSLGAsset {
    init( _ path:String ) { super.init(path:path, type:.VertexShader) }
    
    class func defaultAsset()-> LSLGAsset { return LSLGAssetVertexSh("").markAsBuiltIn() }
}
class LSLGAssetGeoSh : LSLGAsset {
    init( _ path:String ) { super.init(path:path, type:.GeometryShader) }
    
    class func defaultAsset()-> LSLGAsset { return LSLGAssetGeoSh("").markAsBuiltIn() }
}
class LSLGAssetImage : LSLGAsset {
    init( _ path:String ) { super.init(path:path, type:.Image) }
}
class LSLGAssetModel : LSLGAsset {
    init( _ path:String ) { super.init(path:path, type:.Model) }
    
    private init( n:String ) { super.init(path:"", type:.Model); markAsBuiltIn(); name = n }
    class func cube()->    LSLGAsset { return LSLGAssetModel(n:"Cube")    }
    class func sphere()->  LSLGAsset { return LSLGAssetModel(n:"Sphere")  }
    class func donut()->   LSLGAsset { return LSLGAssetModel(n:"Donut")   }
    class func suzanne()-> LSLGAsset { return LSLGAssetModel(n:"Suzanne") }
}
