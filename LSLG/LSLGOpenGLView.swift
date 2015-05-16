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
    
    private var initError:String = ""
    
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
          , 0
        ] 
        var pf = NSOpenGLPixelFormat(attributes: pfAttr)
        if pf == nil {
            initError = "Failed to create OGL pixel format"
            return
        }
        
        var ctx = NSOpenGLContext(format: pf, shareContext: nil)
        if ctx == nil {
            initError = "Failed to create OGL context"
            return
        }
        
        pixelFormat = pf
        openGLContext = ctx
        
        wantsBestResolutionOpenGLSurface = true
    }
    
    override func viewDidMoveToWindow() {
        if let w = window where !initError.isEmpty {
            (w.windowController() as! LSLGWindowController).appendLog( initError, isError: true, desc:"" )
            initError = ""
        }
    }
    
    override func prepareOpenGL() {
        super.prepareOpenGL()
        
        // VSync
        var v:GLint = 1
        openGLContext.setValues(&v, forParameter:NSOpenGLContextParameter.GLCPSwapInterval)
        v = 0
        openGLContext.setValues(&v, forParameter:NSOpenGLContextParameter.GLCPSurfaceOpacity)
    }
    
    override func reshape() {
        super.reshape()
        
        var b = convertRectToBacking( bounds )
        glViewport( 0, 0, Int32(b.width), Int32(b.height) )
    }
    
    override func drawRect(dirtyRect: NSRect) {
        openGLContext.makeCurrentContext()
        var assetManager = (window?.windowController() as! LSLGWindowController).assetManager
        
        if ( __updateModel || true ) {
            glBindVertexArray( assetManager.glCurrModel.getGLAsset() )
            __updateModel = false
        }
        
        if ( __updateProgram ) {
            var program = glCreateProgram()
            
            glAttachShader( program, assetManager.glCurrVertShader.getGLAsset() )
            glAttachShader( program, assetManager.glCurrFragShader.getGLAsset() )
            var geo = assetManager.glCurrGeomShader
            if (!geo.isBuiltIn) { glAttachShader( program, geo.getGLAsset() ) }
            
            glProgram = program
            
            glLinkProgram(program)
            glUseProgram(program)
            
            var success:GLint = 0
            glGetProgramiv(program, GLenum(GL_LINK_STATUS), &success)
            if (success == GL_FALSE) {
                var infoLog = [GLchar](count:512,repeatedValue:0)
                glGetProgramInfoLog(program, 512, nil, &infoLog)
                println("\(NSString(CString: &infoLog, encoding: NSASCIIStringEncoding))")
            }
            
            __updateProgram = false
        }
        
        if ( __updateTexture && false ) {
            glBindTexture( GLenum(GL_TEXTURE_2D), assetManager.glCurrTexture.getGLAsset() )
            __updateTexture = false
        }
        
        // Render 3D Content
        // Set up the modelview and projection matricies
        var modelView  = [GLfloat](count:16, repeatedValue:0)
        var projection = [GLfloat](count:16, repeatedValue:0)
        var mvp        = [GLfloat](count:16, repeatedValue:0)
        
        glClear( GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT) )
        
//        // Calculate the projection matrix
//        mtxLoadPerspective(projection, 90, (float)m_viewWidth / (float)m_viewHeight,5.0,10000);
//        // Calculate the modelview matrix to render our character at the proper position and rotation
//        mtxLoadTranslate(modelView, 0, 150, -1050);
//        mtxRotateXApply(modelView, -90.0f);	
//        mtxRotateApply(modelView, m_characterAngle, 0.7, 0.3, 1);
//        // Multiply the modelview and projection matrix and set it in the shader
//        mtxMultiply(mvp, projection, modelView);
        
        // Have our shader use the modelview projection matrix 
        // that we calculated above
        // glGetUniformLocation( glProgram, "projection" )
        // glUniformMatrix4fv(m_characterMvpUniformIdx, 1, GL_FALSE, [1,0,0,0 ,0,1,0,0 ,0,0,0,1]);
        
        // Cull back faces now that we no longer render with an inverted matrix
        // glCullFace( GLenum(GL_BACK) )
        
        println("render\(glGetError())")
        //glDrawArrays( GLenum(GL_TRIANGLES), 0, 6 )
        glDrawElements( GLenum(GL_TRIANGLES), 6, GLenum(GL_UNSIGNED_INT), UnsafePointer<Void>(bitPattern:0))
        println("render\(glGetError())")
        openGLContext.flushBuffer()
    }
    
    private var __updateModel:Bool   = true
    private var __updateProgram:Bool = true
    private var __updateTexture:Bool = true
    
    private var glProgram:GLuint = 0
    
    func updateModel()   { needsDisplay = true; __updateModel   = true }
    func updateProgram() { needsDisplay = true; __updateProgram = true }
    func updateTexture() { needsDisplay = true; __updateTexture = true }
}
