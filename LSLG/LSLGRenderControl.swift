//
//  LSLGRenderControl.swift
//  LSLG
//
//  Created by Morris on 4/2/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

class LSLGIcon: NSObject {}

class LSLGRenderControl: NSView {
    
    class LSLGRCItem : NSObject {
        var parent:LSLGRenderControl?
        var icon:LSLGIcon? {
            didSet { self.tryUpdateParent() }
        }
        var width:Int { return self.__width }
        var content:String = "" {
            didSet { self.tryUpdateParent() }
        }
        var visible:Bool = true {
            didSet {
                if self.visible != oldValue { self.tryUpdateParent() }
            }
        }
        
        init(content:String) {
            super.init()
            self.content = content
            self.calcWidth()
        }
        
        init(icon:LSLGIcon) {
            super.init()
            self.icon = icon
            self.calcWidth()
        }
        
        private var __width:Int = 16
        
        func tryUpdateParent() {
            if let p = self.parent {
                p.updateFrame()
                p.needsDisplay = true
            }
        }
        
        func calcWidth() {}
        func render(inRect:NSRect) {}
    }
    
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var mouseDownCanMoveWindow:Bool { return false }
    
    var trackingRectTag:NSTrackingRectTag?
    var items = [LSLGRCItem]()
    
    // The {x,y} is bottom-right coordinate
    init(x:CGFloat, y:CGFloat) {
        super.init(frame: NSMakeRect(x-80, y, 80, 20))
        self.autoresizingMask = NSAutoresizingMaskOptions.ViewMinXMargin
        self.wantsLayer = true
        
        // Background. Use a layer to draw the background, because it's just not possible
        // to draw a pixel-perfect line (which is 1-pixel wide) with core graphics.
        var bgLayer = CAGradientLayer()
        bgLayer.frame = self.bounds
        bgLayer.borderWidth  = 0.5
        bgLayer.borderColor  = NSColor(calibratedWhite: 0.4, alpha: 0.38).CGColor
        bgLayer.cornerRadius = self.frame.height / 2
        bgLayer.autoresizingMask = CAAutoresizingMask.LayerWidthSizable
        bgLayer.colors = [
            NSColor(calibratedWhite:0.174, alpha:0.85 ).CGColor
          , NSColor(calibratedWhite:0.039, alpha:0.80 ).CGColor
          , NSColor(calibratedWhite:0.174, alpha:0.85 ).CGColor
        ]
        self.layer!.addSublayer(bgLayer)
        
    }
    
    func addDefaultItems() {
        self.items.append( LSLGRCItem(content:"Settings") )
        self.items.append( LSLGRCItem(content:"Log") )
        self.items.append( LSLGRCItem(content:"Model") )
        self.items.append( LSLGRCItem(content:"Fragment") )
        self.items.append( LSLGRCItem(content:"Geometry") )
        self.items.append( LSLGRCItem(content:"Vertex") )
    }
    
    func addItem(aItem:LSLGRCItem, atItex idx:Int = -1 ) {
        if let op = aItem.parent {
            op.removeItem(aItem)
        }
        
        if idx < 0 {
            self.items.append( aItem )
        } else {
            self.items.insert( aItem, atIndex: idx )
        }
        aItem.parent = self
        self.updateFrame()
    }
    
    func removeItem(aItem:LSLGRCItem) {
        if let idx = find(self.items, aItem) {
            self.items.removeAtIndex(idx)
            self.updateFrame()
            aItem.parent = nil
        }
    }
    
    func updateFrame() {
        if let tag = self.trackingRectTag {
            self.removeTrackingRect( tag )
        }
        self.trackingRectTag = self.addTrackingRect(self.bounds, owner: self, userData: nil, assumeInside: false)
    }
    
    override func drawRect(dirtyRect: NSRect) {
        
//        var ctx   = NSGraphicsContext.currentContext()!
//        var cgctx = ctx.CGContext
//        
//        var backingScaleFactor:CGFloat = 1.0
//        if let screen = self.window!.screen {
//            backingScaleFactor = screen.backingScaleFactor
//        }
//        
//        var frame = self.bounds
//        frame.size.width  -= 1
//        frame.size.height -= 1
//        //frame.origin.x    += 1
//        //frame.origin.y    += 1
//        
//        CGContextSaveGState(cgctx)
//        
//        NSColor.redColor().setFill()
//        var bg = NSBezierPath(roundedRect: frame, xRadius: frame.height/2, yRadius: frame.height/2)
//        bg.lineWidth = 0
//        
//        NSColor(calibratedWhite: 0.4, alpha: 0.45).setStroke()
//        NSColor(calibratedWhite: 1, alpha: 1).setStroke()
//        
//        
//        var cfm = CGAffineTransformMakeTranslation(5, 0.3)
//        CGContextSetLineWidth(cgctx, 0.5)
//        
//        withUnsafePointer(&cfm) { (p) in
//            CGContextAddPath( cgctx, CGPathCreateWithRoundedRect(
//                CGRectMake(frame.origin.x, frame.origin.y, frame.width, frame.height),
//                frame.height/2,
//                frame.height/2,
//                p
//            ))
//        }
//        
//        //CGContextStrokePath(cgctx)
//        CGContextRestoreGState(cgctx)
    }
    
    override func mouseDown(theEvent: NSEvent) {
        self.needsDisplay = true
    }
    
    override func mouseUp(theEvent: NSEvent) {
        self.needsDisplay = true
    }
    
    override func mouseEntered(theEvent: NSEvent) {
        self.needsDisplay = true
    }
    
    override func mouseExited(theEvent: NSEvent) {
        self.needsDisplay = true
    }
    
}
