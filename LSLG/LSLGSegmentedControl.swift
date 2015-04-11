//
//  LSLGRenderControl.swift
//  LSLG
//
//  Created by Morris on 4/2/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa
import CoreText

private let LSLSInvisibleTrackingRectTag:NSTrackingRectTag = -1

class LSLGSegmentedControl: NSView {
    
    class LSLGRCItem:NSObject {
        
        weak var parent:LSLGSegmentedControl?
        
        var trackingRect:NSTrackingRectTag = -1
        
        var id:String="";
        var width:CGFloat  = 24.0
        
        
        var icon:LSLGIcon?         { didSet { tryUpdateParent() } }
        var content:String = ""    { didSet { tryUpdateParent() } }
        var visible:Bool   = true  { didSet { tryUpdateParent() } }
        var selected:Bool  = false { didSet { tryUpdateParent() } }
        
        init(content:String, id:String="") {
            super.init()
            
            self.id = id
            self.content = content
            self.calcWidth()
        }
        
        init(icon:LSLGIcon, id:String="") {
            super.init()
            
            self.id = id
            self.icon = icon
        }
        
        
        func toggleSelected()  { selected = !selected }
        func tryUpdateParent() { if let p = parent { p.updateFrame() } }
        
        func calcWidth() {
            // 4pt padding for both left and right
            width = round(self.content.sizeWithAttributes( [NSFontAttributeName:NSFont(name: "Verdana", size:10.0 )!] ).width) + 8
            parent?.updateFrame()
        }
        
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var mouseDownCanMoveWindow:Bool { return false }
    
    
    private var items = [LSLGRCItem]()
    private var hoveringIdx:Int = -1
    private var textLayer:CALayer
    private var hlLayer:CALayer
    
    
    // Subclass should override this method
    func itemClicked(item:LSLGRCItem) {}
    
    
    // The {x,y} is bottom-right coordinate
    init(x:CGFloat, y:CGFloat) {
        hlLayer   = CALayer()
        textLayer = CALayer()
        
        super.init( frame:NSMakeRect(x-80, y, 80, 20) )
        
        autoresizingMask = .ViewMinXMargin
        wantsLayer = true
        
        // Background. Use a layer to draw the background, because it's just not possible
        // to draw a pixel-perfect line (which is 1-pixel wide) with core graphics.
        var bgLayer = CAGradientLayer()
        bgLayer.frame = bounds
        bgLayer.borderWidth  = 0.5
        bgLayer.borderColor  = NSColor(calibratedWhite: 0.4, alpha: 0.25).CGColor
        bgLayer.cornerRadius = frame.height / 2
        bgLayer.autoresizingMask = CAAutoresizingMask.LayerWidthSizable
        bgLayer.locations = [0,0.4,0.6,1]
        bgLayer.colors = [
            NSColor(calibratedWhite:0.174, alpha:0.56 ).CGColor
          , NSColor(calibratedWhite:0.039, alpha:0.52 ).CGColor
          , NSColor(calibratedWhite:0.039, alpha:0.52 ).CGColor
          , NSColor(calibratedWhite:0.174, alpha:0.56 ).CGColor
        ]
        layer!.addSublayer( bgLayer )
        
        var maskLayer = CALayer()
        maskLayer.frame = bounds
        maskLayer.cornerRadius = frame.height / 2
        maskLayer.backgroundColor = NSColor.blackColor().CGColor
        maskLayer.autoresizingMask = .LayerNotSizable
        
        // Add a highlight layer to indicate hover
        hlLayer.backgroundColor = NSColor.whiteColor().CGColor
        hlLayer.frame  = bounds
        hlLayer.hidden = true
        hlLayer.opacity = 0.06
        hlLayer.mask = maskLayer
        layer!.addSublayer( hlLayer )
        
        // Since we use layer to draw the background, we also need to use layer
        // to draw the content. Otherwise the content will be behind the background.
        textLayer.frame = bounds
        textLayer.autoresizingMask = .LayerWidthSizable
        textLayer.delegate = self
        layer!.addSublayer( self.textLayer )
    }
    
    func appendItems(newItems:[LSLGRCItem]) {
        for item in newItems {
            if let op = item.parent {
                op.removeItem(item)
            }
            
            item.parent = self
        }
        
        items += newItems
        updateFrame()
    }
    
    func addItem(aItem:LSLGRCItem, atItex idx:Int = -1 ) {
        if let op = aItem.parent {
            op.removeItem(aItem)
        }
        
        if idx < 0 {
            items.append( aItem )
        } else {
            items.insert( aItem, atIndex: idx )
        }
        aItem.parent = self
        updateFrame()
    }
    
    func removeItem(aItem:LSLGRCItem) {
        if let idx = find(self.items, aItem) {
            if aItem.trackingRect != -1 {
                removeTrackingRect( aItem.trackingRect )
                aItem.trackingRect = -1
            }
            
            items.removeAtIndex(idx)
            updateFrame()
            aItem.parent = nil
            
        }
    }
    
    func updateFrame() {
        for item in items {
            if item.trackingRect != -1 {
                removeTrackingRect( item.trackingRect )
                item.trackingRect = -1
            }
        }
        
        var rect  = bounds
        let range = visibleItemRange()
        
        for i in lazy( range.1 ... range.0 ).reverse() {
            var item = items[i]
            if !item.visible { continue }
            
            rect.size.width = item.width
            if i == range.0 || i == range.1 { rect.size.width += 4 }
            
            item.trackingRect = addTrackingRect( rect, owner: self, userData: nil, assumeInside: false )
            rect.origin.x += rect.size.width
        }
        
        frame = NSMakeRect(
            frame.origin.x + frame.width - rect.origin.x
          , frame.origin.y
          , rect.origin.x
          , frame.height
        )
    
        needsDisplay = true
        textLayer.setNeedsDisplay()
    }
    
    private func visibleItemRange() -> (Int, Int) {
        // First Visible Item ( in reversed order )
        var firstVIndex = items.count - 1
        for ; firstVIndex >= 0; --firstVIndex { if items[firstVIndex].visible { break } }
        
        // Last Visible Item
        var lastVIndex = 0
        for ; lastVIndex <= firstVIndex; ++lastVIndex { if items[lastVIndex].visible { break } }
        return (firstVIndex, lastVIndex)
    }
    
    override func viewDidMoveToWindow() {
        // The self.window might be nil
        if let w = window {
            textLayer.contentsScale = w.backingScaleFactor
        }
    }
    
    override func drawLayer(layer: CALayer!, inContext ctx: CGContext!) {
        
        if layer != textLayer { return }
        
        CGContextSetTextDrawingMode(ctx, kCGTextFill)
        CGContextSetFontSize(ctx, 16)
        
        var font          = NSFont(name: "Verdana", size:10.0 )!
        var normalColor   = NSColor(calibratedWhite: 0.407, alpha: 1).CGColor
        var selectedColor = NSColor(red:0.171, green:0.522, blue:1, alpha:1).CGColor
        
        var normalText:[NSObject:AnyObject]   = [ kCTFontAttributeName:font , kCTForegroundColorAttributeName:normalColor ]
        var selectedText:[NSObject:AnyObject] = [ kCTFontAttributeName:font , kCTForegroundColorAttributeName:selectedColor ]
        
        var x:CGFloat     = 8
        let y:CGFloat     = (bounds.height-NSLayoutManager().defaultLineHeightForFont(font))/2 + 2
        let iconY:CGFloat = (bounds.height - 16)/2 + 16
        
        var sepRect = NSMakeRect(4, 4, 1, bounds.height-8)
        
        if let screen = window?.screen {
            sepRect.size.width /= screen.backingScaleFactor
        }
        
        var firstItem = true
        
        for var i = items.count - 1; i >= 0; --i {
            var item = items[i]
            if !item.visible {
                continue
            }
            
            if !firstItem {
                // Draw seperator
                sepRect.origin.x = x-4
                CGContextSetGrayFillColor(ctx, 0.329, 0.9)
                CGContextFillRect( ctx, sepRect )
            }
            
            if let icon = item.icon {
                CGContextTranslateCTM( ctx, x, iconY )
                CGContextAddPath( ctx, icon.path )
                CGContextSetFillColorWithColor( ctx, item.selected ? selectedColor : normalColor )
                CGContextEOFillPath( ctx )
                CGContextBeginPath( ctx )
                CGContextTranslateCTM( ctx, -x, -iconY )
            } else {
                CGContextSetTextPosition(ctx, x, y)
                CTLineDraw(CTLineCreateWithAttributedString( NSAttributedString(
                    string     : item.content
                  , attributes : item.selected ? selectedText : normalText
                )) , ctx)
            }
            
            x += item.width
            firstItem = false
        }
    }
    
    override func mouseUp(theEvent: NSEvent) {
        if hoveringIdx >= 0 && hoveringIdx < items.count {
            itemClicked( items[hoveringIdx] )
        }
    }
    
    override func mouseEntered(theEvent: NSEvent) {
        
        let visibleRange = visibleItemRange()
        
        var x:CGFloat      = 4
        var margin:CGFloat = 0
        
        for var i = visibleRange.0; i >= visibleRange.1; --i {
            var item = items[i]
            if item.trackingRect != theEvent.trackingNumber {
                x += item.width
                continue
            }
            
            // The first visible item has 4px left margin
            if i == visibleRange.0 {
                x -= 4
                margin += 4
            }
            
            // The last visible item has 4px right margin
            if i == visibleRange.1 { margin += 4 }
        
            CATransaction.begin()
            CATransaction.setValue( kCFBooleanTrue, forKeyPath: kCATransactionDisableActions )
            
            hlLayer.frame = NSMakeRect( x, 0, item.width+margin, frame.height )
            hlLayer.hidden = false
            // Mask's frame must set after its content
            hlLayer.mask.frame = NSMakeRect(-x, 0, frame.width, frame.height)
            
            CATransaction.commit()
            hoveringIdx = i
            break
        }
    }
    
    override func mouseExited(theEvent: NSEvent) {
        hlLayer.hidden = true
        hoveringIdx = -1
    }
    
}
