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
    override var mouseDownCanMoveWindow:Bool { return false }

    private var hovering:Bool  = false
    private var isClicked:Bool = false

    init(x:CGFloat, y:CGFloat) {
        super.init(frame: NSMakeRect(x, y-12, 12, 12))

        autoresizingMask = .ViewMinYMargin
        addTrackingRect( bounds, owner: self, userData: nil, assumeInside: false )
    }

    override func acceptsFirstMouse(theEvent: NSEvent) -> Bool { return true }

    func doAction() {}

    func drawCircle(context:NSGraphicsContext) {
        var alpha:CGFloat = hovering ? 0.8 : 0.3
        NSColor.whiteColor().setFill()

        CGContextSetAlpha(context.CGContext, alpha)
        NSBezierPath(ovalInRect: NSMakeRect(0, 0, 12, 12)).fill()

        CGContextSetAlpha(context.CGContext, 1)
        context.compositingOperation = .CompositeDestinationOut
        NSBezierPath(ovalInRect: NSMakeRect(1, 1, 10, 10)).fill()

        CGContextSetAlpha(context.CGContext, alpha)
        context.compositingOperation = .CompositeSourceOver
    }

    override func mouseDown(theEvent: NSEvent) {
        isClicked = true
        needsDisplay = true
    }

    override func mouseUp(theEvent: NSEvent) {
        isClicked = false
        if hovering { self.doAction() }
        needsDisplay = true
    }

    override func mouseEntered(theEvent: NSEvent) {
        hovering = true
        needsDisplay = true
    }

    override func mouseExited(theEvent: NSEvent) {
        hovering = false
        needsDisplay = true
    }
}



class LSLGWCCloseBtn: LSLGWCButton {
    override func doAction() { window!.close() }

    override func drawRect(dirtyRect: NSRect) {
        var context = NSGraphicsContext.currentContext()!

        if !hovering {
            drawCircle( context )
            return
        }

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

        context.compositingOperation = .CompositeDestinationOut
        CGContextSetAlpha(context.CGContext, 1)
        clip.fill()
        context.compositingOperation = .CompositeSourceOver
    }
}




class LSLGWCOnTopBtn: LSLGWCButton {

    static let CGFloatingWindowLevel:Int = Int( CGWindowLevelForKey( Int32(kCGFloatingWindowLevelKey) ) )
    static let CGNormalWindowLevel:Int   = Int( CGWindowLevelForKey( Int32(kCGNormalWindowLevelKey) ) )

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override init(x: CGFloat, y: CGFloat) {
        super.init(x: x, y: y)
        toolTip = "Always on-top"
    }


    override func doAction() {
        var w = self.window!
        if w.level == LSLGWCOnTopBtn.CGFloatingWindowLevel {
            w.level = LSLGWCOnTopBtn.CGNormalWindowLevel
        } else {
            w.level = LSLGWCOnTopBtn.CGFloatingWindowLevel
            w.makeKeyAndOrderFront(nil)
        }
    }

    override func drawRect(dirtyRect: NSRect) {
        drawCircle(NSGraphicsContext.currentContext()!)

        if window!.level == LSLGWCOnTopBtn.CGFloatingWindowLevel {
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
        toolTip = "Toggle opacity"
    }

    override func doAction() { window!.alphaValue = window!.alphaValue == 1.0 ? 0.5 : 1.0 }

    override func drawRect(dirtyRect: NSRect) {

        var context = NSGraphicsContext.currentContext()!

        if window!.alphaValue == 1.0 {
            drawCircle(context)
            return
        }

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

        context.compositingOperation = .CompositeSourceOut
        CGContextSetAlpha(context.CGContext, hovering ? 0.8 : 0.3)
        NSBezierPath(ovalInRect: NSMakeRect(0, 0, 12, 12)).fill()
    }
}

class LSLGTitle: NSView {

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var mouseDownCanMoveWindow:Bool { return true }

    override init(frame:NSRect) {
        super.init(frame:frame)
        autoresizingMask = .ViewWidthSizable | .ViewMinYMargin
    }

    override func drawRect(dirtyRect: NSRect) {
        var context  = NSGraphicsContext.currentContext()!.CGContext
        let rectPath = NSBezierPath(
            roundedRect: NSMakeRect(0, frame.height-12, frame.width, 12)
            , xRadius: 5
            , yRadius: 5
        )

        CGContextSaveGState(context)
        NSRectClip( NSMakeRect(0, frame.height-6, self.frame.width, 6) )
        CGContextSetAlpha(context, 0.13)
        CGContextBeginTransparencyLayer(context, nil)
        CGContextSetShadowWithColor(context, CGSizeMake(0, -1), 0, NSColor.whiteColor().CGColor)
        CGContextSetBlendMode(context, kCGBlendModeSourceOut)
        NSColor.whiteColor().setFill()
        rectPath.fill()
        CGContextEndTransparencyLayer(context)
        CGContextRestoreGState(context)
    }
}
