//
//  LSLGQuickLog.swift
//  LSLG
//
//  Created by Morris on 4/10/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

class LSLGQuickLog: NSView {
    
    private class NoopAction:CAAction {
        @objc private func runActionForKey(event: String!, object anObject: AnyObject!, arguments dict: [NSObject : AnyObject]!) {}
    }
    
    private class CATextLayerAA:CATextLayer {
        
        override var string:AnyObject! {
            didSet {
                // Re-calc label size.
                let size = string.sizeWithAttributes( [NSFontAttributeName:font] )
                frame.size = NSMakeSize( round(size.width) + 8, round(size.height) + 2 )
            }
        }
        
        var error:Bool {
            get { return false }
            set {
                if newValue {
                    foregroundColor = NSColor(red:1, green:0.304, blue:0.194, alpha:1).CGColor
                } else {
                    foregroundColor = NSColor(white:0.67,alpha:1).CGColor
                }
            }
        }
        
        func prepare() {
            font          = NSFont(name: "Verdana", size: 10)
            fontSize      = 10.0
            doubleSided   = false
            alignmentMode = kCAAlignmentCenter
        }
        
        private override func drawInContext(ctx: CGContext!) {
            CGContextSetFillColorWithColor( ctx, NSColor(white: 0.287, alpha: 0.7).CGColor )
            CGContextFillRect( ctx, bounds )
            CGContextSetShouldSmoothFonts( ctx, true )
            CGContextTranslateCTM( ctx, 0, 2 )
            super.drawInContext( ctx )
        }
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private var textLayer1:CATextLayerAA
    private var textLayer2:CATextLayerAA
    private var logQueue:[(String,Bool)] = []
    
    private weak var frontLayer:CATextLayer?
    private weak var backLayer:CATextLayer?
    
    private var disappearTimer:NSTimer?
    private var noopAction:NoopAction = NoopAction()
    
    override var flipped:Bool { return true }
    
    override init(frame:NSRect) {
        textLayer1 = CATextLayerAA()
        textLayer2 = CATextLayerAA()
        
        textLayer1.prepare()
        textLayer2.prepare()
        
        super.init(frame:frame)
        
        layer = CALayer()
        wantsLayer = true
        autoresizingMask = .ViewWidthSizable
        
        textLayer1.delegate = self
        textLayer2.delegate = self
        
        var l = layer!
        l.addSublayer( textLayer1 )
        l.addSublayer( textLayer2 )
        
        l.sublayerTransform = CATransform3DMakeTranslation(0, bounds.height, 0)
    }
    
    override func actionForLayer(layer: CALayer!, forKey event: String!) -> CAAction! {
        if event == "contents" || event == "foregroundColor" {
            return noopAction
        }
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
    
    func onDisappearTimer(timer:NSTimer) {
        disappearTimer = nil
        if logQueue.isEmpty {
            layer?.sublayerTransform = CATransform3DMakeTranslation(0, bounds.height, 0)
            return
        }
        
        let item = logQueue.removeLast()
        textLayer1.string = item.0
        textLayer1.error  = item.1
        
        scheduleDisappear()
    }
    
    func scheduleDisappear() {
        disappearTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "onDisappearTimer:", userInfo: nil, repeats: false)
    }
    
    func startAnimation() {
        if disappearTimer != nil { return }
        scheduleDisappear()
        
        let item = logQueue.removeLast()
        textLayer1.string = item.0
        textLayer1.error  = item.1
        layer?.sublayerTransform = CATransform3DMakeTranslation(0, 0, 0)
    }
}
