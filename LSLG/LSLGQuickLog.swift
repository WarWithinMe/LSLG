//
//  LSLGQuickLog.swift
//  LSLG
//
//  Created by Morris on 4/10/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

class LSLGQuickLog: NSView {
    
    
    private class CATextLayerAA:CATextLayer {
        
        override var string:AnyObject! {
            didSet {
                // Re-calc label size.
                let size = string.sizeWithAttributes( [NSFontAttributeName:font] )
                frame.size = NSMakeSize( round(size.width) + 8, round(size.height) + 3 )
                
                println("CATextLayerAA didSet: \(string) \(frame.size)")
            }
        }
        
        func prepare() {
            foregroundColor = NSColor.whiteColor().CGColor
            font            = NSFont(name: "Verdana", size: 10)
            fontSize        = 10.0
            doubleSided     = false
            alignmentMode   = kCAAlignmentCenter
        }
        
        private override func drawInContext(ctx: CGContext!) {
            CGContextSetFillColorWithColor( ctx, NSColor.redColor().CGColor )
            CGContextFillRect( ctx, bounds )
            CGContextSetShouldSmoothFonts( ctx, true )
            CGContextTranslateCTM( ctx, 0, -2 )
            super.drawInContext( ctx )
        }
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private var textLayer1:CATextLayerAA
    private var textLayer2:CATextLayerAA
    private var logQueue:[(String,Bool)] = []
    private var animating:Bool = false
    
    private weak var frontLayer:CATextLayer?
    private weak var backLayer:CATextLayer?
    
    private var textLayer3:CALayer!
    
    override init(frame:NSRect) {
        textLayer1 = CATextLayerAA()
        textLayer2 = CATextLayerAA()
        
        textLayer1.prepare()
        textLayer2.prepare()
        
        super.init(frame:frame)
        
        autoresizingMask = .ViewWidthSizable
        layer = CALayer()
        wantsLayer = true
        
        textLayer1.delegate = self
        textLayer2.delegate = self
        layer?.addSublayer( textLayer1 )
        layer?.addSublayer( textLayer2 )
    }
    
    override func actionForLayer(layer: CALayer!, forKey event: String!) -> CAAction! {
        return nil
    }
    
    override func layer(layer: CALayer, shouldInheritContentsScale s: CGFloat, fromWindow w: NSWindow) -> Bool {
        println("changed contentsscale")
        return true
    }
    
    override func viewDidMoveToWindow() {
        if let w = window {
            textLayer1.contentsScale = w.backingScaleFactor
            textLayer2.contentsScale = w.backingScaleFactor
        }
    }
    
    func scheduleLog(log:String, _ isError:Bool) {
        logQueue.insert( (log,isError), atIndex: 0 )
        startAnimation()
    }
    
    func startAnimation() {
        if animating { return }
        //animating = true
        
        let item = logQueue.removeLast()
        textLayer1.string = item.0
    }
}
