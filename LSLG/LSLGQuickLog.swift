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
            string        = " " // This sets the initial frame to the layer.
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
    
    private var animating:Bool = false
    
    private var nextLogTimer:NSTimer?
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
        
        // l.sublayerTransform = CATransform3DMakeTranslation(0, bounds.height, 0)
        translateSublayer( bounds.height )
    }
    
    private func translateSublayer( y:CGFloat ) {
        var i = CATransform3DIdentity
        i.m34 = -1 / 400
        layer!.sublayerTransform = CATransform3DTranslate(i, 0, y, 0)
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
        } else if let t = nextLogTimer {
            // Fire the timer when the view is moved out of the window
            t.fire()
        }
    }
    
    func scheduleLog(log:String, _ isError:Bool) {
        logQueue.insert( (log,isError), atIndex: 0 )
        showLog()
    }
    
    private func flipAnimation( flipToVisible:Bool )-> CAAnimation {
        
        let duration = 0.3
        var ani1 = CABasicAnimation(keyPath: "transform.rotation.x")
        ani1.fromValue = NSNumber(double: flipToVisible ? M_PI : 0)
        ani1.toValue   = NSNumber(double: flipToVisible ? 0 : -M_PI)
        
        var ani2 = CABasicAnimation(keyPath: "transform.scale")
        ani2.fromValue = NSNumber(double:1)
        ani2.toValue   = NSNumber(double:0.95)
        ani2.duration  = duration / 2
        ani2.autoreverses = true
        
        var flip = CAAnimationGroup()
        flip.duration = duration
        flip.animations = [ani1,ani2]
        flip.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        flip.fillMode = kCAFillModeBoth
        flip.removedOnCompletion = false
        return flip
    }
    
    private func showLog() {
        
        // Show next log or disappear after 2 sec.
        // The timer is used to indicate if we are showing a log
        // If the timer is non-nil, it means there's a log showing.
        if nextLogTimer != nil { return }
        
        nextLogTimer = NSTimer.scheduledTimerWithTimeInterval(2.5, target: self, selector: "nextLog:", userInfo: nil, repeats: false)
        
        // Grab an item
        let item = logQueue.removeLast()
        
        // If frontLayer is being use, we flip to backLayer.
        if !animating {
            animating = true
            
            textLayer1.string = item.0
            textLayer1.error  = item.1
            
            CATransaction.begin()
                CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                textLayer1.transform = CATransform3DMakeRotation( 0, 1, 1, 0 )
                textLayer2.transform = CATransform3DMakeRotation( CGFloat(M_PI), 1, 0, 0 )
            CATransaction.commit()
            
        } else {
            
            textLayer1.addAnimation( flipAnimation(false), forKey: "FLIP" )
            textLayer2.addAnimation( flipAnimation(true),  forKey: "FLIP" )
            
            var tmp = textLayer2
            textLayer2 = textLayer1
            textLayer1 = tmp
            
            textLayer1.string  = item.0
            textLayer1.error   = item.1
        }
        
        // Show the layers
        //layer?.sublayerTransform = CATransform3DMakeTranslation(0, 0, 0)
        translateSublayer( 0 )
    }
    
    // If a functions is mean to be call by selector.
    // It must be public
    func nextLog(timer:NSTimer) {
        nextLogTimer = nil
        if logQueue.isEmpty {
            //layer!.sublayerTransform = CATransform3DMakeTranslation(0, bounds.height, 0)
            CATransaction.begin()
            translateSublayer( bounds.height )
            CATransaction.setCompletionBlock(){ self.animating = false }
            CATransaction.commit()
        } else {
            self.showLog()
        }
    }
    
    deinit {
        println("quicklog deinit")
    }
}
