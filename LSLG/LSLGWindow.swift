//
//  LSLGWindow.swift
//  LSLG
//
//  Created by Morris on 3/31/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

class LSLGWindow: NSWindow, NSDraggingDestination {
    
    private class UndraggableView : NSView {
        override var mouseDownCanMoveWindow:Bool { return false }
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var canBecomeKeyWindow:Bool { return true; }
    
    private var realContentView:NSView!
    private var renderControl:LSLGRenderControl!
    private var quickLogView:LSLGQuickLog!
    var titleView:LSLGTitle!
    var oglView:LSLGOpenGLView!
    
    init() {
        let sf = NSScreen.mainScreen()!.frame
        super.init(
            contentRect : NSMakeRect( sf.width/2-200, sf.height/2-200, 400, 400 )
          , styleMask   : NSResizableWindowMask
          , backing     : .Buffered
          , defer       : false
        )
        
        movableByWindowBackground = true
        
        minSize = NSMakeSize(390, 340)
        backgroundColor = NSColor.clearColor()
        opaque = false
    }
    
    func createSubviews() {
        
        var contentView = self.contentView as! NSView
        contentView.wantsLayer = true
        
        // Background & Border
        var layer = contentView.layer!
        layer.backgroundColor = NSColor(calibratedWhite:0.076, alpha:1.0).CGColor
        layer.borderColor     = NSColor(calibratedWhite:0.05, alpha:1.0).CGColor
        layer.cornerRadius    = 5.0
        layer.borderWidth     = 1.0 / backingScaleFactor
        
        // Gradient BG
        var gradientLayer = CAGradientLayer()
        gradientLayer.autoresizingMask = .LayerWidthSizable | .LayerMinYMargin
        gradientLayer.backgroundColor  = NSColor.greenColor().CGColor
        gradientLayer.frame            = CGRectMake( 0, layer.frame.height-100, layer.frame.width, 100 )
        gradientLayer.colors           = [
            NSColor( calibratedWhite:0.076, alpha:1.0 ).CGColor
          , NSColor( calibratedWhite:0.103, alpha:1.0 ).CGColor
        ]
        layer.addSublayer( gradientLayer )
        
        
        // A view to prevent dragging the window, making the titlebar the only
        // element which can drag the window
        var maskView = UndraggableView( frame:contentView.bounds )
        maskView.frame.size.height = maskView.frame.height - 25.0
        maskView.autoresizingMask = .ViewMinYMargin | .ViewWidthSizable
        contentView.addSubview( maskView )
        
        
        // Real content view, this is the content view wrapper
        realContentView = NSView( frame:contentView.bounds )
        realContentView.autoresizingMask = .ViewHeightSizable | .ViewWidthSizable
        contentView.addSubview( realContentView )
        
        // OpenGL View
        oglView = LSLGOpenGLView( frame: contentView.bounds )
        setContent( oglView )
        
        // Title, which makes the window draggable
        titleView = LSLGTitle(frame: NSMakeRect(0, contentView.frame.height-25, contentView.frame.width, 25))
        contentView.addSubview( titleView )
        
        
        // Title controls
        contentView.addSubview( LSLGWCCloseBtn  (x:8,  y:frame.height-6) )
        contentView.addSubview( LSLGWCOnTopBtn  (x:26, y:frame.height-6) )
        contentView.addSubview( LSLGWCOpacityBtn(x:44, y:frame.height-6) )
        
        
        // Quick Log
        quickLogView = LSLGQuickLog( frame:NSMakeRect(10,0,contentView.bounds.width-10,30) )
        contentView.addSubview( quickLogView )
        
        
        // Render controls
        renderControl = LSLGRenderControl( x:frame.width - 10, y:10 )
        contentView.addSubview( renderControl )
        
        
        // Register DnD
        registerForDraggedTypes([NSFilenamesPboardType])
    }
    
    override var canBecomeMainWindow:Bool { return true }
    
    func removeContent(view:NSView) {
        if let rcv:AnyObject = realContentView.subviews.first {
            if rcv === view {
                view.removeFromSuperview()
                setContent( oglView )
                oglView.hidden = false
            }
        }
    }
    
    func setContent(view:NSView, fillWindow:Bool = true, keepOgl:Bool = false) {
        if let rcv:AnyObject = realContentView.subviews.first {
            if rcv === view {
                return
            } else {
                rcv.removeFromSuperview()
            }
        }
        
        view.autoresizingMask = .ViewHeightSizable | .ViewWidthSizable
        var frame = contentView.bounds
        if !fillWindow {
            frame.origin.y     = 35
            frame.origin.x     = 10
            frame.size.width  -= 20
            frame.size.height -= 60
        }
        view.frame = frame
        realContentView.addSubview(view)
        makeFirstResponder( view )
        
        if keepOgl {
            // Dirty, Allow oglView to be inside the window even when log is displayed.
            realContentView.addSubview( oglView )
            oglView.hidden = true
        }
    }
    
    func quickLog(desc:String, _ isError:Bool) { quickLogView.scheduleLog( desc, isError ) }
    
    private var dndHighlight:CALayer?
    private var draggingIn:Bool = false {
        didSet {
            var layer = contentView.layer!!
            if draggingIn {
                if dndHighlight == nil {
                    var dh = CALayer()
                    dh.frame = contentView.bounds
                    dh.backgroundColor = NSColor(red:0.144, green:0.507, blue:1, alpha:0.1).CGColor
                    dndHighlight = dh
                    layer.addSublayer( dh )
                    layer.borderColor = NSColor(red:0.144, green:0.507, blue:1, alpha:1).CGColor
                    layer.borderWidth = 2
                }
            } else {
                layer.borderColor = NSColor(calibratedWhite:0.05, alpha:1.0).CGColor
                layer.borderWidth = 1.0 / backingScaleFactor
                dndHighlight?.removeFromSuperlayer()
                dndHighlight = nil
            }
        }
    }
    
    func draggingEnded(sender: NSDraggingInfo?) { self.draggingIn = false }
    func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        var pb = sender.draggingPasteboard()
        if let pl:Array = pb.propertyListForType( NSFilenamesPboardType ) as? [AnyObject] {
            var fm = NSFileManager.defaultManager()
            for path in pl {
                var exist = ObjCBool(false)
                fm.fileExistsAtPath(path as! String, isDirectory: &exist)
                if exist.boolValue {
                    draggingIn = true
                    return .Link
                }
            }
        }
        return .None
    }
    
    func performDragOperation(sender: NSDraggingInfo) -> Bool {
        var pb = sender.draggingPasteboard()
        if let pl:Array = pb.propertyListForType( NSFilenamesPboardType ) as? [AnyObject] {
            var fm = NSFileManager.defaultManager()
            for path in pl {
                var exist = ObjCBool(false)
                fm.fileExistsAtPath(path as! String, isDirectory: &exist)
                if exist.boolValue {
                    onDropFolder( path as! String )
                    return true
                }
            }
        }
        return false
    }
    
    func onDropFolder(path:String) { (windowController() as! LSLGWindowController).monitorFolder(path) }
}
