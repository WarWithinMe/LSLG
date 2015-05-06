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
          , UInt32(NSOpenGLPFAOpenGLProfile), UInt32(NSOpenGLProfileVersion3_2Core)
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
        
        // Turn this on for OpenGL newbie
        CGLEnable(ctx!.CGLContextObj, kCGLCECrashOnRemovedFunctions);
        
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
    }
}
