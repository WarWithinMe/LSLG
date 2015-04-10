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
        private override func drawInContext(ctx: CGContext!) {
            CGContextSetFillColorWithColor( ctx, backgroundColor )
            CGContextFillRect( ctx, bounds )
            CGContextSetShouldSmoothFonts( ctx, true )
            super.drawInContext( ctx )
        }
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private var textLayer1:CATextLayerAA
    private var textLayer2:CATextLayerAA
    private var logQueue:[(String,Bool)] = []
    private var animating:Bool = false
    
    override init(frame:NSRect) {
        textLayer1 = CATextLayerAA()
        textLayer2 = CATextLayerAA()
        
        textLayer1.backgroundColor = NSColor.blackColor().CGColor
        textLayer2.backgroundColor = NSColor.blackColor().CGColor
        
        super.init(frame:frame)
        
        autoresizingMask = .ViewWidthSizable
        wantsLayer = true
        
        layer?.addSublayer( textLayer1 )
        layer?.addSublayer( textLayer2 )
    }
    
    func scheduleLog(log:String, _ isError:Bool) {
        logQueue.append( (log,isError) )
        startAnimation()
    }
    
    func startAnimation() {
        if animating { return }
        animating = true
    }
}
