//
//  LSLGWindow.swift
//  LSLG
//
//  Created by Morris on 3/31/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

class LSLGWindow: NSWindow {
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var canBecomeKeyWindow:Bool { return true; }
    
    private var realContentView:NSView!
    private var renderControl:LSLGRenderControl!
    private var quickLogView:LSLGQuickLog!
    
    init() {
        let frame = NSScreen.mainScreen()!.frame
        super.init(
            contentRect : NSMakeRect( frame.width/2-150, frame.height/2-150, 300, 300)
          , styleMask   : NSResizableWindowMask
          , backing     : .Buffered
          , defer       : false
        )
        
        self.movableByWindowBackground = true
        
        self.minSize = NSMakeSize(200, 200)
        self.backgroundColor = NSColor.clearColor()
        self.opaque = false
        
        var contentView = self.contentView as! NSView
        contentView.wantsLayer = true
        
        // Background & Border
        var layer = contentView.layer!
        layer.cornerRadius = 5.0
        layer.backgroundColor = NSColor(calibratedWhite:0.076, alpha:1.0).CGColor
        layer.borderColor     = NSColor(calibratedWhite:0.05, alpha:1.0).CGColor
        layer.borderWidth     = 1.0
        if let screen = self.screen {
            layer.borderWidth = 1.0 / screen.backingScaleFactor
        }
        
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
        
        // Real content view, this is the content view wrapper
        self.realContentView = NSView(frame:self.contentView.frame)
        self.realContentView.autoresizingMask = .ViewHeightSizable | .ViewWidthSizable
        self.contentView.addSubview( self.realContentView )
        
        // Title, which makes the window draggable
        self.contentView.addSubview(
            LSLGTitle(frame: NSMakeRect(0, self.contentView.frame.height-25, self.contentView.frame.width, 25))
        )
        
        // Title controls
        self.contentView.addSubview( LSLGWCCloseBtn  (x:6,  y:self.frame.height-6) )
        self.contentView.addSubview( LSLGWCOnTopBtn  (x:22, y:self.frame.height-6) )
        self.contentView.addSubview( LSLGWCOpacityBtn(x:38, y:self.frame.height-6) )
        
        // Render controls
        self.renderControl = LSLGRenderControl( x:self.frame.width - 10, y:10 )
        self.contentView.addSubview( self.renderControl )
    }
    
    func setContent(view:NSView, fillWindow:Bool = true) {
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
    }
    
    func quickLog(desc:String, _ isError:Bool) { quickLogView.scheduleLog( desc, isError ) }
}
