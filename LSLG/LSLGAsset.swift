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

 func glErrorString( error:Int32 )-> String {
    switch error {
        case GL_INVALID_ENUM: return "GL_INVALID_ENUM"
        case GL_INVALID_VALUE: return "GL_INVALID_VALUE"
        case GL_INVALID_OPERATION: return "GL_INVALID_OPERATION"
        case GL_OUT_OF_MEMORY: return "GL_OUT_OF_MEMORY"
        case GL_INVALID_FRAMEBUFFER_OPERATION: return "GL_INVALID_FRAMEBUFFER_OPERATION"
        default: return "GL_NO_ERROR"
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
    
    class func assetWithPath( path:String, type:LSLGAssetType )-> LSLGAsset? {
        switch type {
            case .FragmentShader: return LSLGAssetFragSh( path: path ) 
            case .GeometryShader: return LSLGAssetGeoSh( path: path ) 
            case .VertexShader:   return LSLGAssetVertexSh( path: path ) 
            case .Model:          return LSLGAssetModel( path: path ) 
            case .Image:          return LSLGAssetImage( path: path ) 
            default : return nil
        }
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
      , LSLGAssetImage.defaultAsset()
    ]
    
    // When the content in the file system changes, this method is called.
    // Typically called by AssetManager
    func update(){
        initError = ""
        if glAssetInited {
            delGLAsset()
            glAsset = nil
        }
    }
    
    func getGLAsset() -> GLuint {
        if !glAssetInited { initGLAsset() }
        return glAsset == nil ? 0 : glAsset!
    }
    
    var glAssetInited:Bool { return glAsset != nil  }
    private var glAsset:GLuint?
    private(set) var initError:String = ""
    private func initGLAsset() -> Bool { return false }
    private func delGLAsset() {}
    deinit {
        if glAssetInited { delGLAsset() }
    }
}




/* Helper */
func < (l:LSLGAsset, r:LSLGAsset)->Bool {
    return l.builtInId != r.builtInId ? (l.builtInId > r.builtInId) : (l.name < r.name) }
func > (l:LSLGAsset, r:LSLGAsset)->Bool {
    return l.builtInId != r.builtInId ? (r.builtInId > l.builtInId) : (r.name < l.name) }




/* Subclass */
class LSLGAssetImage : LSLGAsset {
    override var type:LSLGAssetType { return .Image }
    
    class func defaultAsset()->LSLGAsset {
        var a = LSLGAssetImage(path:"")
        a.markAsBuiltIn()
        a.name = "None"
        return a
    }
    
    private func getImageRep()->NSBitmapImageRep? {
        if (isBuiltIn) {
            var rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1, pixelsHigh: 1, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSCalibratedRGBColorSpace, bytesPerRow: 0, bitsPerPixel: 0)
            var transparent = 0
            rep?.setPixel(&transparent, atX: 0, y: 0)
            return rep
        } else {
            var img = NSImage( contentsOfFile: path )
            return img?.representations[0] as? NSBitmapImageRep
        }
    }
    
    private override func delGLAsset() { glDeleteTextures(1, &glAsset!) }
    private override func initGLAsset() -> Bool {
        
        var error = ""
        
        if let imageRep = getImageRep() {
            
            var textureName:GLuint = 0
            let GLT2D:GLenum = GLenum( GL_TEXTURE_2D )
            
            glGenTextures(1, &textureName)
            glBindTexture(GLT2D, textureName)
            glAsset = textureName
            
            glTexParameteri(GLT2D, GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
            glTexParameteri(GLT2D, GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
            glTexParameteri(GLT2D, GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
            glTexParameteri(GLT2D, GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR_MIPMAP_LINEAR)
            
            // Allocate and load image data into texture
            glTexImage2D(
                GLT2D, 0, GL_RGBA
              , GLsizei(imageRep.pixelsWide)
              , GLsizei(imageRep.pixelsHigh)
              , 0 , GLenum( GL_RGBA ) , GLenum( GL_UNSIGNED_INT_8_8_8_8_REV )
              , imageRep.bitmapData
            )
            
            // Create mipmaps for this texture for better image quality
            glGenerateMipmap(GLT2D)
            
            var glErr = Int32(glGetError())
            if (glErr != GL_NO_ERROR) {
                error = "Error occured when binding texture:\(glErrorString(glErr))"
            }
            
        } else {
            error = "Cannot load image at \(path)"
        }
        
        if ( !error.isEmpty ) {
            NSNotificationCenter.defaultCenter().postNotificationName(
                LSLGAssetInitFailure , object:self , userInfo:["info":error]
            )
            return false
        }
        
        return true
    }
}


class LSLGAssetModel : LSLGAsset {
    override var type:LSLGAssetType { return .Model }
    
    private convenience init( name:String ) { self.init(path:""); markAsBuiltIn(); self.name = name; }
    
    class func cube()->    LSLGAsset { return LSLGAssetModel(name:"Cube")    }
    class func sphere()->  LSLGAsset { return LSLGAssetModel(name:"Sphere")  }
    class func donut()->   LSLGAsset { return LSLGAssetModel(name:"Donut")   }
    class func suzanne()-> LSLGAsset { return LSLGAssetModel(name:"Suzanne") }
    
    var vertexData = [GLfloat]()
    private(set) var vertexCount:Int = 0
    
    private func getObjString()->String {
        if isBuiltIn {
            switch name {
                case "Cube"    : return LSLGModelObjCube
                case "Sphere"  : return LSLGModelObjSphere
                case "Donut"   : return LSLGModelObjDonut
                case "Suzanne" : return LSLGModelObjSuzanne
                default : return ""
            }
        }
        
        var error:NSError? = nil
        var model = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: &error)
        if error != nil {
            initError = "Cannot read model `\(name)` : \(path)"
            return ""
        }
        return model! as String
    }
    
    private func readFromObjData() {
        let src = getObjString()
        
        var lineScanner  = NSScanner(string: src)
        var csNewline    = NSCharacterSet.newlineCharacterSet()
        var csWhitespace = NSCharacterSet.whitespaceCharacterSet()
        var line:NSString? = nil
        var type:NSString? = nil
        
        typealias vec3 = (x:Float,y:Float,z:Float)
        typealias vec2 = (u:Float,v:Float)
        
        var vertexArray  = [vec3]()
        var normalArray  = [vec3]()
        var textureArray = [vec2]()
        
        while !lineScanner.atEnd {
            lineScanner.scanUpToCharactersFromSet(csNewline, intoString: &line)
            if line == nil { break }
            
            var scanner = NSScanner(string: line! as String)
            scanner.scanUpToCharactersFromSet(csWhitespace, intoString: &type)
            
            if type == "v" {
                var vertex:vec3 = (0,0,0)
                scanner.scanFloat(&vertex.x)
                scanner.scanFloat(&vertex.y)
                scanner.scanFloat(&vertex.z)
                vertexArray.append(vertex)
            } else if type == "vt" {
                var texture:vec2 = (0,0)
                scanner.scanFloat(&texture.u)
                scanner.scanFloat(&texture.v)
                textureArray.append(texture)
            } else if type == "vn" {
                var normal:vec3 = (0,0,0)
                scanner.scanFloat(&normal.x)
                scanner.scanFloat(&normal.y)
                scanner.scanFloat(&normal.z)
                normalArray.append(normal)
            } else if type == "f" {
                var component:NSString? = ""
                var face = [NSString]()
                while !scanner.atEnd {
                    scanner.scanUpToCharactersFromSet(csWhitespace, intoString: &component)
                    if component != nil {
                        face.append( component! )
                    }
                }
                var count = 3
                if face.count > 3 {
                    face.insert( face[0], atIndex: 3 )
                    face.insert( face[2], atIndex: 4 )
                    count = 6
                }
                for var i = 0; i < count; ++i {
                    var parts = face[i].componentsSeparatedByString("/")
                    var vec3  = vertexArray[ parts[0].integerValue! - 1 ]
                    vertexData.append( vec3.x )
                    vertexData.append( vec3.y )
                    vertexData.append( vec3.z )
                    
                    vec3 = (0,0,0)
                    if parts.count > 2 {
                        var idx = parts[1].integerValue
                        if idx > 0 {
                            vec3 = vertexArray[ idx - 1 ]
                        }
                    }
                    vertexData.append( vec3.x )
                    vertexData.append( vec3.y )
                    vertexData.append( vec3.z )
                    
                    vec3 = (0,0,0)
                    if parts.count > 2 {
                        var idx = parts[1].integerValue
                        if idx > 0 {
                            var vec2 = textureArray[ idx - 1 ]
                            vec3.x = vec2.u
                            vec3.y = vec2.v
                        }
                    }
                    vertexData.append( vec3.x )
                    vertexData.append( vec3.y )
                }
            }
        }
        
        vertexCount = vertexData.count / 8
    }
    
    
    private override func delGLAsset() { glDeleteVertexArrays(1, &glAsset!) }
    private override func initGLAsset() -> Bool {
        
        readFromObjData()
        
        let vertices = vertexData
        
        var vao:GLuint = 0
        glGenVertexArrays(1, &vao)
        glBindVertexArray(vao)
        
        var vbo:GLuint = 0
        glGenBuffers(1, &vbo)
        glBindBuffer( GLenum(GL_ARRAY_BUFFER), vbo )
        glBufferData( GLenum(GL_ARRAY_BUFFER), vertices.count * sizeof(GLfloat), vertices, GLenum(GL_STATIC_DRAW) )
        
        
        glEnableVertexAttribArray(0)
        glEnableVertexAttribArray(1)
        glEnableVertexAttribArray(2)
        
        let size = GLsizei(8*sizeof(GLfloat)) 
        // position
        glVertexAttribPointer(0, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), size, UnsafePointer<Void>(bitPattern:0) )
        // normal
        glVertexAttribPointer(1, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), size, UnsafePointer<Void>(bitPattern:3*sizeof(GLfloat)) )
        // texcord
        glVertexAttribPointer(2, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), size, UnsafePointer<Void>(bitPattern:6*sizeof(GLfloat)) )
        
        
        glBindVertexArray(0)
        glAsset = vao
        return true
    }
}


class LSLGAssetShader : LSLGAsset {
    
    // The variable is used to store default content of a shader.
    private var shaderContent:NSString?
    private convenience init( dc:String ) {
        self.init(path:"")
        self.shaderContent = dc
        self.markAsBuiltIn()
    }
    
    private override func delGLAsset() { glDeleteShader(glAsset!) }
    
    private override func initGLAsset()-> Bool {
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
            
            var logLength = GLint()
            glGetShaderiv(shaderHandle, GLenum(GL_INFO_LOG_LENGTH), &logLength)
            
            if (logLength > 0) {
                var log = [GLchar](count:Int(logLength), repeatedValue: 0)
                glGetShaderInfoLog(shaderHandle, logLength, &logLength, &log)
                
                initError = "\n" + (NSString(bytes: &log, length:Int(logLength), encoding: NSUTF8StringEncoding)! as String)
            } else {
                initError = "Cannot compile shader `\(name)`"
            }
            
            return false
        }
        
        glAsset = shaderHandle
        return true
    }
}

class LSLGAssetFragSh : LSLGAssetShader {
    override var type:LSLGAssetType { return .FragmentShader }
    class func defaultAsset()-> LSLGAsset { return LSLGAssetFragSh(dc:LSLGShaderSrcFragment) }
}
class LSLGAssetVertexSh : LSLGAssetShader {
    override var type:LSLGAssetType { return .VertexShader }
    class func defaultAsset()-> LSLGAsset { return LSLGAssetVertexSh(dc:LSLGShaderSrcVertex) }
}
class LSLGAssetGeoSh : LSLGAssetShader {
    override var type:LSLGAssetType { return .GeometryShader }
    class func defaultAsset()-> LSLGAsset { return LSLGAssetGeoSh(dc:"") }
}
