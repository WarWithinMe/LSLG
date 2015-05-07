//
//  LSLGAsset.swift
//  LSLG
//
//  Created by Morris on 4/24/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa
import GLKit

enum LSLGAssetType:Int {
    case FragmentShader = 0
    case VertexShader
    case GeometryShader
    case Image
    case Model
    case Generic
    
    func glType() -> GLenum {
        switch self {
            case .FragmentShader: return GLenum(GL_FRAGMENT_SHADER)
            case .VertexShader:   return GLenum(GL_VERTEX_SHADER)
            case .GeometryShader: return GLenum(GL_GEOMETRY_SHADER)
            default: return 0
        } 
    }
}

let LSLGAssetInitFailure = "LSLGAssetInitFailure"

class LSLGAsset: NSObject {
    
    var type:LSLGAssetType { return .Generic }
    
    private(set) var name:String
    var assetKey:String { return isBuiltIn ? "/BuiltInAsset\(builtInId)/" : path.lastPathComponent }
    
    init( path:String ) {
        self.path = path
        
        var n = path.lastPathComponent
        self.name = LSLGAsset.StripExtReg.stringByReplacingMatchesInString(
            n
          , options: NSMatchingOptions.allZeros
          , range: NSMakeRange(0, count(n))
          , withTemplate: ""
        )
        super.init()
    }
    
    private(set) var path:String
    
    class func assetWithPath( path:String )-> LSLGAsset? {
        var delegate = NSApplication.sharedApplication().delegate as! LSLGAppDelegate
        var p = path.lastPathComponent
        let r = NSMakeRange(0, count(p))
        let o = NSMatchingOptions.WithoutAnchoringBounds
        if delegate.REG_FRAG.numberOfMatchesInString(p, options: o, range: r) > 0 {
            return LSLGAssetFragSh( path: path )
        } else if delegate.REG_VERT.numberOfMatchesInString(p, options: o, range: r) > 0 {
            return LSLGAssetVertexSh( path: path )
        } else if delegate.REG_GEOM.numberOfMatchesInString(p, options: o, range: r) > 0 {
            return LSLGAssetGeoSh( path: path )
        } else if delegate.REG_IMGE.numberOfMatchesInString(p, options: o, range: r) > 0 {
            return LSLGAssetImage( path: path )
        } else if delegate.REG_MODL.numberOfMatchesInString(p, options: o, range: r) > 0 {
            return LSLGAssetModel( path: path )
        }
        return nil
    }
    
    // Built-In assets
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
    
    // When the content in the file system changes, this method is called.
    // Typically called by AssetManager
    func update(){
        glAssetInited = false
        initError = ""
    }
    
    func retrieveGLAsset() -> GLuint? {
        if glAssetInited == false {
            glAssetInited = initGLAsset()
        }
        return glAssetInited ? getGLAsset() : nil
    }
    
    private var glAssetInited = false
    private(set) var initError:String = ""
    private func initGLAsset() -> Bool { return false }
    private func getGLAsset() -> GLuint? { return nil }
}




/* Helper */
func < (l:LSLGAsset, r:LSLGAsset)->Bool {
    return l.builtInId != r.builtInId ? (l.builtInId > r.builtInId) : (l.name < r.name) }
func > (l:LSLGAsset, r:LSLGAsset)->Bool {
    return l.builtInId != r.builtInId ? (r.builtInId > l.builtInId) : (r.name < l.name) }




/* Subclass */
class LSLGAssetImage : LSLGAsset {
    override var type:LSLGAssetType { return .Image }
}


class LSLGAssetModel : LSLGAsset {
    override var type:LSLGAssetType { return .Model }
    
    private convenience init( name:String ) { self.init(path:""); markAsBuiltIn(); self.name = name }
    class func cube()->    LSLGAsset { return LSLGAssetModel(name:"Cube")    }
    class func sphere()->  LSLGAsset { return LSLGAssetModel(name:"Sphere")  }
    class func donut()->   LSLGAsset { return LSLGAssetModel(name:"Donut")   }
    class func suzanne()-> LSLGAsset { return LSLGAssetModel(name:"Suzanne") }
}


class LSLGAssetShader : LSLGAsset {
    
    // The variable is used to store default content of a shader.
    private var shaderContent:NSString?
    private convenience init( dc:String ) {
        self.init(path:"")
        self.shaderContent = dc
        self.markAsBuiltIn()
    }
    
    private var shaderHandle  : GLuint = 0
    
    override func getGLAsset() -> GLuint? { return shaderHandle }
    override func initGLAsset()-> Bool {
        // Get shader source
        var shaderContent:NSString? = self.shaderContent
        if shaderContent == nil {
            var error: NSError? = nil
            shaderContent = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: &error)
            if error != nil {
                initError = "Cannot read shader `\(name)` : \(path)"
                return false
            }
        }
        
        // Create shader handle
        var shaderHandle:GLuint = glCreateShader( type.glType() )
        
        // Supply source
        var shaderStringUTF8   = shaderContent!.UTF8String
        var shaderStringLength = GLint(shaderContent!.length)
        glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength)
        
        // Compile shader
        glCompileShader(shaderHandle)
        
        // Get errors
        var compileSuccess = GLint()
        glGetShaderiv(shaderHandle, GLenum(GL_COMPILE_STATUS), &compileSuccess)
        if (compileSuccess == GL_FALSE) {
            initError = "Cannot compile shader `\(name)`"
            
            var logLength = GLint()
            glGetShaderiv(shaderHandle, GLenum(GL_INFO_LOG_LENGTH), &logLength)
            
            if (logLength > 0) {
                var log = [GLchar](count:Int(logLength), repeatedValue: 0)
                glGetShaderInfoLog(shaderHandle, logLength, &logLength, &log)
                
                NSNotificationCenter.defaultCenter().postNotificationName(
                    LSLGAssetInitFailure
                  , object:self
                  , userInfo:["info":NSString(bytes: &log, length:Int(logLength), encoding: NSASCIIStringEncoding)!]
                )
            }
            
            return false
        }
        
        self.shaderHandle = shaderHandle
        return true
    }
}

class LSLGAssetFragSh : LSLGAssetShader {
    override var type:LSLGAssetType { return .FragmentShader }
    class func defaultAsset()-> LSLGAsset { return LSLGAssetFragSh(dc:"") }
}
class LSLGAssetVertexSh : LSLGAssetShader {
    override var type:LSLGAssetType { return .VertexShader }
    class func defaultAsset()-> LSLGAsset { return LSLGAssetVertexSh(dc:"") }
}
class LSLGAssetGeoSh : LSLGAssetShader {
    override var type:LSLGAssetType { return .GeometryShader }
    class func defaultAsset()-> LSLGAsset { return LSLGAssetGeoSh(dc:"") }
}
