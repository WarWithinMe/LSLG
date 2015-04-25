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
    
    private(set) var type:LSLGAssetType
    private(set) var name:String
    var assetKey:String { return isBuiltIn ? "/BuiltInAsset\(builtInId)/" : path.lastPathComponent }
    
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
    
    private var path:String
    
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
    
    private var builtInId:Int = -1
    var isBuiltIn:Bool { return builtInId >= 0 }
    private func markAsBuiltIn()->LSLGAsset {
        self.name      = "BuiltIn"
        self.builtInId = (++LSLGAsset.DefaultAssetId)
        return self
    }
    
    static let StripExtReg = NSRegularExpression(pattern: "\\.[^.]+$", options:.CaseInsensitive, error: nil)!
    static private var DefaultAssetId:Int = 0
    static let DefaultAssets = [
        LSLGAssetFragSh.defaultAsset()
      , LSLGAssetVertexSh.defaultAsset()
      , LSLGAssetGeoSh.defaultAsset()
      , LSLGAssetModel.suzanne()
      , LSLGAssetModel.donut()
      , LSLGAssetModel.sphere()
      , LSLGAssetModel.cube()
    ]
}

func < (l:LSLGAsset, r:LSLGAsset)->Bool {
    return l.builtInId != r.builtInId ? (l.builtInId > r.builtInId) : (l.name < r.name) }
func > (l:LSLGAsset, r:LSLGAsset)->Bool {
    return l.builtInId != r.builtInId ? (r.builtInId > l.builtInId) : (r.name < l.name) }

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
