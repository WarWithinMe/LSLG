//
//  LSLGOpenGLView.swift
//  LSLG
//
//  Created by Morris on 4/28/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa
import OpenGL
import GLKit

class LSLGOpenGLView: NSOpenGLView {
    
    override var mouseDownCanMoveWindow:Bool { return true }
    
    private var glInitError:String = ""
    private var msaa:Bool = false
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override init?(frame frameRect: NSRect, pixelFormat format: NSOpenGLPixelFormat!) {
        super.init(frame:frameRect, pixelFormat:format)
    }
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        var pfAttr:[NSOpenGLPixelFormatAttribute] = [
            UInt32(NSOpenGLPFADoubleBuffer)
          , UInt32(NSOpenGLPFADepthSize), 24
          , UInt32(NSOpenGLPFAOpenGLProfile), UInt32(NSOpenGLProfileVersion4_1Core)
        ] 
        
        msaa = NSUserDefaults.standardUserDefaults().boolForKey("MSAA")
        if msaa {
            pfAttr += [
                UInt32(NSOpenGLPFASampleBuffers), 1
              , UInt32(NSOpenGLPFASamples), 4
              , UInt32(NSOpenGLPFANoRecovery), 1
            ]
        }
        
        pfAttr.append(0)
        var pf = NSOpenGLPixelFormat(attributes: pfAttr)
        if pf == nil {
            glInitError = "Failed to create OGL pixel format"
            return
        }
        
        var ctx = NSOpenGLContext(format: pf, shareContext: nil)
        if ctx == nil {
            glInitError = "Failed to create OGL context"
            return
        }
        
        pixelFormat = pf
        openGLContext = ctx
        
        wantsBestResolutionOpenGLSurface = true
        
        addGestureRecognizer( NSPanGestureRecognizer(target: self, action: "onPanGesture:") )
    }
    
    override func viewDidMoveToWindow() {
        if let w = window where !glInitError.isEmpty {
            (w.windowController() as! LSLGWindowController).appendLog( glInitError, isError: true, desc:"" )
            glInitError = ""
        }
    }
    
    func updateOpenGL() {
        // This method is called on CVDisplayLink's thread.
        
        // Do nothing if the view is not added to window.
        if window == nil { return }
        
        lock.lock()
        var update = __updateResource != ENUM_UR.none.rawValue
        lock.unlock()
        
        if update {
            // Ask main thread to update the resource for us
            dispatch_sync( dispatch_get_main_queue(), { self.updateResource() })
        }
        
        render()
        ++glFrame
        
        var error = Int32( glGetError() ) // Always fetch the error
        
        if update {
            // If something updated, check if we have successfully rendered.
            var error1:String = "Render Successfully"
            var error2:String = ""
            if error != GL_NO_ERROR {
                error1 = "Render failed, because: \(glErrorString(error))" 
                error2 = "Failed to render"
            }
            if error != GL_NO_ERROR || lastGlRenderError != GL_NO_ERROR {
                lastGlRenderError = error
                dispatch_sync( dispatch_get_main_queue(), {
                    if let w = self.window {
                        (w.windowController() as! LSLGWindowController).appendLog(error1, isError:error != GL_NO_ERROR, desc:error2)
                        
                    }
                }) 
            }
        }
    }
    
    private var lastGlRenderError:Int32 = GL_NO_ERROR
    
    override func prepareOpenGL() {
        super.prepareOpenGL()
        
        // VSync
        openGLContext.setValues([1], forParameter:NSOpenGLContextParameter.GLCPSwapInterval)
        openGLContext.setValues([0], forParameter:NSOpenGLContextParameter.GLCPSurfaceOpacity)
        
        glEnable( GLenum(GL_DEPTH_TEST) )
        glEnable( GLenum(GL_CULL_FACE) ) 
        
        if msaa {
            glEnable( GLenum(GL_MULTISAMPLE) )
        } else {
            glDisable( GLenum(GL_MULTISAMPLE) )
        }
        
        // Create normal shaders
        var controller   = window?.windowController() as! LSLGWindowController
        var assetManager = controller.assetManager
        normalProgram = glCreateProgram()
        glAttachShader( normalProgram, assetManager.assetByName("normal", type: .VertexShader)!.getGLAsset() )
        glAttachShader( normalProgram, assetManager.assetByName("normal", type: .FragmentShader)!.getGLAsset() )
        glAttachShader( normalProgram, assetManager.assetByName("normal", type: .GeometryShader)!.getGLAsset() )
        glLinkProgram( normalProgram )
    }
    
    override func reshape() {
        super.reshape()
        
        var b = convertRectToBacking( bounds )
        glViewport( 0, 0, Int32(b.width), Int32(b.height) )
    }
    
    override func drawRect(dirtyRect: NSRect) {}
    
    func updateResource() {
        openGLContext.makeCurrentContext()
        
        var controller   = window?.windowController() as! LSLGWindowController
        var assetManager = controller.assetManager
        var asset:GLuint = 0
        
        if shouldUpdateRes( .model ) {
            asset = assetManager.glCurrModel.getGLAsset()
            if asset == 0 {
                controller.appendLog(
                    "Failed to load model '\(assetManager.glCurrModel.name)': \(assetManager.glCurrModel.assetInitError)"
                    , isError: true, desc: "Failed to load model"
                )
            } else {
                glBindVertexArray( asset )
            } 
        }
        
        if shouldUpdateRes( .program ) {
            if glProgram != 0 { glDeleteProgram( glProgram ) }
            
            glProgram = glCreateProgram()
            
            var shader = assetManager.glCurrVertShader 
            asset = shader.getGLAsset()
            if asset == 0 {
                controller.appendLog(
                    "Failed to compile vertex shader '\(shader.name)': \(shader.assetInitError)"
                    , isError: true, desc: "Failed to compile vertex shader"
                )
            } else {
                glAttachShader( glProgram, asset )
            }
            
            shader = assetManager.glCurrFragShader 
            asset  = shader.getGLAsset()
            if asset == 0 {
                controller.appendLog(
                    "Failed to compile fragment shader '\(shader.name)': \(shader.assetInitError)"
                    , isError: true, desc: "Failed to compile fragment shader"
                )
            } else {
                glAttachShader( glProgram, asset )
            }
            
            shader = assetManager.glCurrGeomShader
            if (!shader.isBuiltIn) {
                asset = shader.getGLAsset()
                if asset == 0 {
                    controller.appendLog(
                        "Failed to compile geometry shader '\(shader.name)': \(shader.assetInitError)"
                        , isError: true, desc: "Failed to compile geometry shader"
                    )
                } else {
                    glAttachShader( glProgram, asset )
                }
            }
            
            glLinkProgram(glProgram)
            glUseProgram(glProgram)
            
            var success:GLint = 0
            glGetProgramiv(glProgram, GLenum(GL_LINK_STATUS), &success)
            if (success == GL_FALSE) {
                var infoLog = [GLchar](count:512,repeatedValue:0)
                glGetProgramInfoLog(glProgram, 512, nil, &infoLog)
                controller.appendLog(
                    NSString(CString: &infoLog, encoding: NSASCIIStringEncoding)! as String
                    , isError: true, desc: "Failed to link program"
                )
            }
        }
        
        if shouldUpdateRes( .texture ) {
            var textures = assetManager.assetsByType( .Image )
            sort( &textures, {
                (a:LSLGAsset, b:LSLGAsset)->Bool in
                return a.path > b.path
            } )
            
            for i in 0..<textures.count {
                glActiveTexture( GLenum(GL_TEXTURE0 + i) )
                glBindTexture( GLenum(GL_TEXTURE_2D), textures[i].getGLAsset() )
                glUniform1i( glGetUniformLocation( glProgram, "texture\(i + 1)"), GLint(i) ) 
            }
        }
        
        __updateResource = ENUM_UR.none.rawValue
    }
    
    func render() {
        openGLContext.makeCurrentContext()
        
        var controller   = window?.windowController() as! LSLGWindowController
        var assetManager = controller.assetManager
        
        var rPerDegree:Float = Float(M_PI) / 180.0
        
        if !panning && autoRotate {
            rotateY = (rotateY+0.1) % 360 
        }
        
        glUniformMatrix4fv(
            glGetUniformLocation( glProgram, "model" )
          , 1, GLboolean(GL_FALSE)
          , getRawMatrix4( GLKMatrix4MakeXRotation( rotateX * rPerDegree ) * GLKMatrix4MakeYRotation( rotateY * rPerDegree ) )
        )
    
        glUniformMatrix4fv(
            glGetUniformLocation( glProgram, "view" )
          , 1, GLboolean(GL_FALSE)
          , getRawMatrix4( GLKMatrix4MakeLookAt( -camX, -camY, 3, -camX, -camY, -1, 0, 1, 0 ) )
        )
    
        glUniformMatrix4fv(
            glGetUniformLocation( glProgram, "projection" )
          , 1, GLboolean(GL_FALSE)
          , getRawMatrix4( GLKMatrix4MakePerspective( Float(zoom) * rPerDegree, Float(frame.width/frame.height), 0.1, 100 ) )
        )
    
        glUniform1f( glGetUniformLocation( glProgram, "frame" ), glFrame )
        
        glCullFace( GLenum(GL_BACK) )
        glClear( GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT) )
        
        glDrawArrays( GLenum(GL_TRIANGLES), 0, GLsizei((assetManager.glCurrModel as! LSLGAssetModel).vertexCount) )
        
        if showNormal {
            glUseProgram( normalProgram )
            
            glUniformMatrix4fv(
                glGetUniformLocation( normalProgram, "model" )
              , 1, GLboolean(GL_FALSE)
              , getRawMatrix4( GLKMatrix4MakeXRotation( rotateX * rPerDegree ) * GLKMatrix4MakeYRotation( rotateY * rPerDegree ) )
            )
            
            glUniformMatrix4fv(
                glGetUniformLocation( normalProgram, "view" )
              , 1, GLboolean(GL_FALSE)
              , getRawMatrix4( GLKMatrix4MakeLookAt( -camX, -camY, 3, -camX, -camY, -1, 0, 1, 0 ) )
            )
            
            glUniformMatrix4fv(
                glGetUniformLocation( normalProgram, "projection" )
              , 1, GLboolean(GL_FALSE)
              , getRawMatrix4( GLKMatrix4MakePerspective( Float(zoom) * rPerDegree, Float(frame.width/frame.height), 0.1, 100 ) )
            )
            
            glDrawArrays( GLenum(GL_TRIANGLES), 0, GLsizei((assetManager.glCurrModel as! LSLGAssetModel).vertexCount) )
            glCullFace( GLenum(GL_BACK) )
            glUseProgram( glProgram )
        }
        
        openGLContext.flushBuffer()
    }
    
    private func getRawMatrix4( mp:GLKMatrix4 ) -> [GLfloat] {
        return [ mp.m00, mp.m01, mp.m02, mp.m03
            , mp.m10, mp.m11, mp.m12, mp.m13
            , mp.m20, mp.m21, mp.m22, mp.m23
            , mp.m30, mp.m31, mp.m32, mp.m33 ]
    }
    
    private var glProgram:GLuint = 0
    private var normalProgram:GLuint = 0
    
    private var lock = NSLock()
    private enum ENUM_UR:Int {
        case none    = 0
        case model   = 1
        case texture = 2
        case program = 6
    }
    private var __updateResource:Int = ENUM_UR.model.rawValue | ENUM_UR.texture.rawValue | ENUM_UR.program.rawValue
    
    private func shouldUpdateRes( flag:ENUM_UR )->Bool { return __updateResource & flag.rawValue > 0 }
    
    func updateModel()   { lock.lock(); __updateResource |= ENUM_UR.model.rawValue;   lock.unlock() }
    func updateProgram() { lock.lock(); __updateResource |= ENUM_UR.program.rawValue; lock.unlock() }
    func updateTexture() { lock.lock(); __updateResource |= ENUM_UR.texture.rawValue; lock.unlock() }
    
    deinit {
        if glProgram != 0 {
            glDeleteProgram( glProgram )
        }
        if normalProgram != 0 {
            glDeleteProgram( normalProgram )
        }
    }
    
    
    private var zoom:Float = 30
    private var rotateX:Float = 0
    private var rotateY:Float = 0
    private var lastPanX:CGFloat = 0
    private var lastPanY:CGFloat = 0
    private var panning:Bool = false
    private var camX:Float = 0
    private var camY:Float = 0
    private var showNormal:Bool = false
    private var glFrame:Float = 0
    
    var autoRotate:Bool = NSUserDefaults.standardUserDefaults().boolForKey("AutoYaxisRotation")
    
    func onPanGesture( gesture:NSPanGestureRecognizer ) {
        if gesture.state == .Began {
            lastPanX = 0
            lastPanY = 0
            panning = true
        } else if ( gesture.state == .Ended ) {
            panning = false
        } else if ( gesture.state == .Changed ) {
            var t = gesture.translationInView(self)
            var s = self.bounds.size
            t.x *= 180.0 / s.width
            t.y *= -180.0 / s.height
            rotateX = min( max( rotateX + Float(t.y - lastPanY) , -90 ), 90 )
            rotateY = (rotateY + Float( t.x - lastPanX )) % 360
            lastPanX = t.x
            lastPanY = t.y
        }
    }
    
    override func magnifyWithEvent(event: NSEvent) {
        var r = zoom - Float(event.magnification * 10)
        if r > 100 { r = 100 }
        if r < 30 { r = 30 }
        zoom = r
    }
    override func scrollWheel(theEvent: NSEvent) {
        var r = zoom - Float(theEvent.deltaY * 0.3)
        if r > 100 { r = 100 }
        if r < 30 { r = 30 }
        zoom = r
    }
    
    override func keyDown(theEvent: NSEvent) {
        switch theEvent.charactersIgnoringModifiers! {
            case "s": camY = max( camY - 0.01, -0.5 )
            case "w": camY = min( camY + 0.01, 0.5 )
            case "a": camX = max( camX - 0.01, -0.5 )
            case "d": camX = min( camX + 0.01, 0.5 )
            case "r": resetTransform()
            case "n": showNormal = !showNormal
            case " ": panning = true
            
            default:
                if theEvent.keyCode == 123 {
                    camX = max( camX - 0.01, -0.5 )
                } else if theEvent.keyCode == 124 {
                    camX = min( camX + 0.01, 0.5 )
                } else if theEvent.keyCode == 125 {
                    camY = max( camY - 0.01, -0.5 )
                } else if theEvent.keyCode == 126 {
                    camY = min( camY + 0.01, 0.5 )
                }
        }
    }
    override func keyUp(theEvent: NSEvent) {
        if theEvent.charactersIgnoringModifiers == " " {
            panning = false
        }
    }
    
    override func acceptsFirstMouse(theEvent: NSEvent) -> Bool { return true }
    
    override func rightMouseDragged(theEvent: NSEvent) {
        camX = max( min( camX + Float(theEvent.deltaX * 0.01), 0.5 ), -0.5 )
        camY = max( min( camY - Float(theEvent.deltaY * 0.01), 0.5 ), -0.5 )
    }
    
    func resetTransform() {
        camX = 0
        camY = 0
        rotateX = 0
        rotateY = 0
        zoom = 30
        showNormal = false
        glFrame = 0
    }
}

func * ( left:GLKMatrix4, right:GLKMatrix4 ) -> GLKMatrix4 { return GLKMatrix4Multiply( left, right ) }
