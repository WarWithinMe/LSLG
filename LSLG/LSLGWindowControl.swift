//
//  LSLGWindowControl.swift
//  LSLG
//
//  Created by Morris on 4/1/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

class LSLGWCButton: NSView {
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    var hovering:Bool  = false
    var isClicked:Bool = false
    
    init(x:CGFloat, y:CGFloat) {
        super.init(frame: NSMakeRect(x, y-12, 12, 12))
        self.autoresizingMask = NSAutoresizingMaskOptions.ViewMinYMargin
        self.addTrackingArea(
            NSTrackingArea(
                rect     : self.bounds
              , options  : NSTrackingAreaOptions.MouseEnteredAndExited | NSTrackingAreaOptions.ActiveInActiveApp
              , owner    : self
              , userInfo : nil
            )
        )
    }
    
    override func acceptsFirstMouse(theEvent: NSEvent) -> Bool { return true }
    
    func doAction() {}
    
    func drawCircle(context:NSGraphicsContext) {
        var alpha:CGFloat = self.hovering ? 0.8 : 0.3
        NSColor.whiteColor().setFill()
        
        CGContextSetAlpha(context.CGContext, alpha)
        NSBezierPath(ovalInRect: NSMakeRect(0, 0, 12, 12)).fill()
        
        CGContextSetAlpha(context.CGContext, 1)
        context.compositingOperation = NSCompositingOperation.CompositeDestinationOut
        NSBezierPath(ovalInRect: NSMakeRect(1, 1, 10, 10)).fill()
        
        CGContextSetAlpha(context.CGContext, alpha)
        context.compositingOperation = NSCompositingOperation.CompositeSourceOver
    }
    
    override func mouseDown(theEvent: NSEvent) {
        self.isClicked = true
        self.needsDisplay = true
    }
    
    override func mouseUp(theEvent: NSEvent) {
        self.isClicked = false
        self.doAction()
        self.needsDisplay = true
    }
    
    override func mouseEntered(theEvent: NSEvent) {
        self.hovering = true
        self.needsDisplay = true
    }
    
    override func mouseExited(theEvent: NSEvent) {
        self.hovering = false
        self.needsDisplay = true
    }
}



class LSLGWCCloseBtn: LSLGWCButton {
    override func doAction() {
        self.window!.close()
    }
    
    override func drawRect(dirtyRect: NSRect) {
        var context = NSGraphicsContext.currentContext()!
        
        if self.hovering {
            NSColor.whiteColor().setFill()
            CGContextSetAlpha(context.CGContext, 0.8)
            NSBezierPath(ovalInRect: NSMakeRect(0, 0, 12, 12)).fill()
            
            var clip = NSBezierPath(rect: NSMakeRect(2, 5, 8, 2))
            clip.appendBezierPathWithRect(NSMakeRect(5, 2, 2, 8))
            var transform = NSAffineTransform()
            transform.translateXBy(6,yBy:6)
            transform.rotateByDegrees(45)
            transform.translateXBy(-6,yBy:-6)
            clip.transformUsingAffineTransform(transform)
            
            context.compositingOperation = NSCompositingOperation.CompositeDestinationOut
            CGContextSetAlpha(context.CGContext, 1)
            clip.fill()
            context.compositingOperation = NSCompositingOperation.CompositeSourceOver
            
        } else {
            self.drawCircle( context )
        }
    }
}




class LSLGWCOnTopBtn: LSLGWCButton {
    
    let CGFloatingWindowLevel:Int = Int( CGWindowLevelForKey( Int32(kCGFloatingWindowLevelKey) ) )
    let CGNormalWindowLevel:Int   = Int( CGWindowLevelForKey( Int32(kCGNormalWindowLevelKey) ) )
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override init(x: CGFloat, y: CGFloat) {
        super.init(x: x, y: y)
        self.toolTip = "Always on-top"
    }

    
    override func doAction() {
        var window = self.window!
        if window.level == self.CGFloatingWindowLevel {
            window.level = self.CGNormalWindowLevel
        } else {
            window.level = self.CGFloatingWindowLevel
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    override func drawRect(dirtyRect: NSRect) {
        self.drawCircle(NSGraphicsContext.currentContext()!)
        
        if self.window!.level == self.CGFloatingWindowLevel {
            NSBezierPath(ovalInRect: NSMakeRect(4, 4, 4, 4)).fill()
        }
    }
}




class LSLGWCOpacityBtn: LSLGWCButton {
    
    let CGFloatingWindowLevel:Int = Int( CGWindowLevelForKey( Int32(kCGFloatingWindowLevelKey) ) )
    let CGNormalWindowLevel:Int   = Int( CGWindowLevelForKey( Int32(kCGNormalWindowLevelKey) ) )
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override init(x: CGFloat, y: CGFloat) {
        super.init(x: x, y: y)
        self.toolTip = "Toggle opacity"
    }
    
    override func doAction() {
        var w = self.window!
        if w.alphaValue == 1.0 {
            w.alphaValue = 0.5
        } else {
            w.alphaValue = 1.0
        }
    }
    
    override func drawRect(dirtyRect: NSRect) {
        
        var context = NSGraphicsContext.currentContext()!
        
        if self.window!.alphaValue != 1.0 {
            NSColor.whiteColor().setFill()
            
            context.saveGraphicsState()
            var clip = NSBezierPath()
            clip.moveToPoint(NSMakePoint(0,  0))
            clip.lineToPoint(NSMakePoint(12, 12))
            clip.lineToPoint(NSMakePoint(0,  12))
            clip.closePath()
            clip.addClip()
            
            NSBezierPath(ovalInRect: NSMakeRect(1, 1, 10, 10)).fill()
            context.restoreGraphicsState()
            
            context.compositingOperation = NSCompositingOperation.CompositeSourceOut
            CGContextSetAlpha(context.CGContext, 0.8)
            NSBezierPath(ovalInRect: NSMakeRect(0, 0, 12, 12)).fill()
            
        } else {
            self.drawCircle(context)
        }
    }
}
