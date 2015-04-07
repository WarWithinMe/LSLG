//
//  LSLGWindow.swift
//  LSLG
//
//  Created by Morris on 3/31/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

class LSLGWindow: NSWindow {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func canBecomeKeyWindow()->Bool { return true; }
    
    var realContentView:NSView!
    var renderControl:LSLGRenderControl!
    
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
        
        var contentView = self.contentView as NSView
        contentView.wantsLayer = true
        
        // Background & Border
        var layer = contentView.layer!
        layer.cornerRadius = 5.0
        layer.backgroundColor = NSColor(calibratedWhite:0.076, alpha:1.0).CGColor
        layer.borderColor = NSColor(calibratedWhite:0.05, alpha:1.0).CGColor
        layer.borderWidth = 1.0
        if let screen = self.screen {
            layer.borderWidth = 1.0 / screen.backingScaleFactor
        }
        
        // Gradient BG
        var gradientLayer = CAGradientLayer()
        gradientLayer.colors = [ NSColor(calibratedWhite:0.076, alpha:1.0).CGColor, NSColor(calibratedWhite:0.103, alpha:1.0).CGColor ]
        gradientLayer.frame  = CGRectMake(0, layer.frame.height-100, layer.frame.width, 100)
        gradientLayer.autoresizingMask = CAAutoresizingMask.LayerWidthSizable | CAAutoresizingMask.LayerMinYMargin
        gradientLayer.backgroundColor  = NSColor.greenColor().CGColor
        layer.addSublayer( gradientLayer )
        
        // Title, which makes the window draggable
        self.contentView.addSubview(
            LSLGTitle(frame: NSMakeRect(0, self.contentView.frame.height-25, self.contentView.frame.width, 25))
        )
        
        // Title controls
        self.contentView.addSubview( LSLGWCCloseBtn  (x:6,  y:self.frame.height-6) )
        self.contentView.addSubview( LSLGWCOnTopBtn  (x:22, y:self.frame.height-6) )
        self.contentView.addSubview( LSLGWCOpacityBtn(x:38, y:self.frame.height-6) )
        
        // Render controls
        self.renderControl = LSLGRenderControl( x:self.frame.width - 12, y:12 )
        self.contentView.addSubview( self.renderControl )
    }
    
    func setContent(aview:NSView) {
        if (aview.isEqualTo(self.realContentView)) { return; }
        
        if let rcv = self.realContentView {
            self.contentView.removeView(rcv)
        }
        
        self.realContentView = aview
        aview.autoresizingMask = NSAutoresizingMaskOptions.ViewHeightSizable | NSAutoresizingMaskOptions.ViewWidthSizable
        aview.frame = self.contentView.bounds
        self.contentView.addSubview(aview, positioned: NSWindowOrderingMode.Below, relativeTo: nil)
    }
}

class LSLGTitle: NSView {
    
    override var mouseDownCanMoveWindow:Bool { return true }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override init(frame:NSRect) {
        super.init(frame:frame)
        self.autoresizingMask = NSAutoresizingMaskOptions.ViewWidthSizable | NSAutoresizingMaskOptions.ViewMinYMargin
    }
    
    override func drawRect(dirtyRect: NSRect) {
        NSLog("Drawing Titlebar")
        var context = NSGraphicsContext.currentContext()!.CGContext
        
        let rectanglePath = NSBezierPath(roundedRect: NSMakeRect(0, self.frame.height-12, self.frame.width, 12), xRadius: 5, yRadius: 5)
        
        CGContextSaveGState(context)
        NSRectClip( NSMakeRect(0, self.frame.height-6, self.frame.width, 6) )
        CGContextSetAlpha(context, 0.13)
        CGContextBeginTransparencyLayer(context, nil)
            CGContextSetShadowWithColor(context, CGSizeMake(0, -1), 0, NSColor.whiteColor().CGColor)
            CGContextSetBlendMode(context, kCGBlendModeSourceOut)
            NSColor.whiteColor().setFill()
            rectanglePath.fill()
        CGContextEndTransparencyLayer(context)
        CGContextRestoreGState(context)
    }
}
