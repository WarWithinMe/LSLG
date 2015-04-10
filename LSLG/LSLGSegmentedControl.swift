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
    
    class LSLGRCItem : NSObject {
        
        var id:String="";
        weak var parent:LSLGSegmentedControl?
        var icon:LSLGIcon? {
            didSet { self.tryUpdateParent() }
        }
        var width:CGFloat  { return self.visible ? self.__width : 0 }
        var content:String = "" {
            didSet { self.tryUpdateParent() }
        }
        var visible:Bool = true {
            didSet { self.tryUpdateParent() }
        }
        var selected:Bool = false {
            didSet { self.tryUpdateParent() }
        }
        
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
        
        var __trackingRect:NSTrackingRectTag = -1
        private var __width:CGFloat  = 24.0
        
        func toggleSelected() { self.selected = !self.selected }
        
        func tryUpdateParent() {
            if let p = self.parent {
                p.updateFrame()
            }
        }
        
        func calcWidth() {
            self.__width  = round(self.content.sizeWithAttributes( [NSFontAttributeName:NSFont(name: "Verdana", size:10.0 )!] ).width) + 8 // 4pt padding for both left and right
            self.parent?.updateFrame()
        }
        
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var mouseDownCanMoveWindow:Bool { return false }
    
    var items  = [LSLGRCItem]()
    
    var textLayer:CALayer!
    var hlLayer:CALayer!
    var hoveringIdx:Int = -1
    
    // The {x,y} is bottom-right coordinate
    init(x:CGFloat, y:CGFloat) {
        super.init(frame: NSMakeRect(x-80, y, 80, 20))
        self.autoresizingMask = .ViewMinXMargin
        self.wantsLayer = true
        
        // Background. Use a layer to draw the background, because it's just not possible
        // to draw a pixel-perfect line (which is 1-pixel wide) with core graphics.
        var bgLayer = CAGradientLayer()
        bgLayer.frame = self.bounds
        bgLayer.borderWidth  = 0.5
        bgLayer.borderColor  = NSColor(calibratedWhite: 0.4, alpha: 0.25).CGColor
        bgLayer.cornerRadius = self.frame.height / 2
        bgLayer.autoresizingMask = CAAutoresizingMask.LayerWidthSizable
        bgLayer.locations = [0,0.4,0.6,1]
        bgLayer.colors = [
            NSColor(calibratedWhite:0.174, alpha:0.56 ).CGColor
          , NSColor(calibratedWhite:0.039, alpha:0.52 ).CGColor
          , NSColor(calibratedWhite:0.039, alpha:0.52 ).CGColor
          , NSColor(calibratedWhite:0.174, alpha:0.56 ).CGColor
        ]
        self.layer!.addSublayer(bgLayer)
        
        var maskLayer = CALayer()
        maskLayer.frame = self.bounds
        maskLayer.cornerRadius = self.frame.height / 2
        maskLayer.backgroundColor = NSColor.blackColor().CGColor
        maskLayer.autoresizingMask = .LayerNotSizable
        
        // Add a highlight layer to indicate hover
        self.hlLayer = CALayer()
        self.hlLayer.backgroundColor = NSColor.whiteColor().CGColor
        self.hlLayer.frame = self.bounds
        self.hlLayer.hidden = true
        self.hlLayer.opacity = 0.06
        self.hlLayer.mask = maskLayer
        self.layer!.addSublayer(self.hlLayer)
        
        // Since we use layer to draw the background, we also need to use layer
        // to draw the content. Otherwise the content will be behind the background.
        self.textLayer = CALayer()
        self.textLayer.frame = self.bounds
        self.textLayer.autoresizingMask = .LayerWidthSizable
        self.textLayer.delegate = self
        self.layer!.addSublayer(self.textLayer)
    }
    
    func appendItems(items:[LSLGRCItem]) {
        for item in items {
            if let op = item.parent {
                op.removeItem(item)
            }
            
            self.items.append(item)
            item.parent = self
        }
        self.updateFrame()
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
            if aItem.__trackingRect != -1 {
                self.removeTrackingRect( aItem.__trackingRect )
                aItem.__trackingRect = -1
            }
            self.items.removeAtIndex(idx)
            self.updateFrame()
            aItem.parent = nil
        }
    }
    
    func updateFrame() {
        for item in self.items {
            if item.__trackingRect != -1 {
                self.removeTrackingRect( item.__trackingRect )
                item.__trackingRect = -1
            }
        }
        
        var rect  = self.bounds
        let range = self.visibleItemRange()
        
        for i in lazy( range.1 ... range.0 ).reverse() {
            var item = self.items[i]
            if !item.visible { continue }
            
            rect.size.width = item.width
            if i == range.0 || i == range.1 { rect.size.width += 4 }
            item.__trackingRect = self.addTrackingRect(rect, owner: self, userData: nil, assumeInside: false)
            rect.origin.x += rect.size.width
        }
        
        self.frame = NSMakeRect(
            self.frame.origin.x + self.frame.width - rect.origin.x
          , self.frame.origin.y
          , rect.origin.x
          , self.frame.height
        )
    
        self.needsDisplay = true
        self.textLayer.setNeedsDisplay()
    }
    
    private func visibleItemRange() -> (Int, Int) {
        // First Visible Item ( in reversed order )
        var firstVIndex = self.items.count - 1
        for ; firstVIndex >= 0; --firstVIndex { if self.items[firstVIndex].visible { break } }
        
        // Last Visible Item
        var lastVIndex = 0
        for ; lastVIndex <= firstVIndex; ++lastVIndex { if self.items[lastVIndex].visible { break } }
        return (firstVIndex, lastVIndex)
    }
    
    override func viewDidMoveToWindow() {
        if let screen = self.window?.screen {
            self.textLayer.contentsScale = screen.backingScaleFactor
        }
    }
    
    override func drawLayer(layer: CALayer!, inContext ctx: CGContext!) {
        
        if layer != self.textLayer { return }
        
        CGContextSetTextDrawingMode(ctx, kCGTextFill)
        CGContextSetFontSize(ctx, 16)
        
        var font  = NSFont(name: "Verdana", size:10.0 )!
        var normalColor   = NSColor(calibratedWhite: 0.407, alpha: 1).CGColor
        var selectedColor = NSColor(red:0.171, green:0.522, blue:1, alpha:1).CGColor
        var normalText:[NSObject:AnyObject]   = [ kCTFontAttributeName:font , kCTForegroundColorAttributeName:normalColor ]
        var selectedText:[NSObject:AnyObject] = [ kCTFontAttributeName:font , kCTForegroundColorAttributeName:selectedColor ]
        
        let iconY:CGFloat = (self.frame.height - 16)/2 + 16
        var x:CGFloat = 8
        let y:CGFloat = (self.bounds.height-NSLayoutManager().defaultLineHeightForFont(font))/2 + 2
        var sep = NSMakeRect(4, 4, 1, self.bounds.height-8)
        
        if let screen = self.window?.screen {
            sep.size.width /= screen.backingScaleFactor
        }
        
        var firstItem = true
        
        for var i = self.items.count - 1; i >= 0; --i {
            var item = self.items[i]
            if !item.visible {
                continue
            }
            
            if !firstItem {
                // Draw seperator
                sep.origin.x = x-4
                CGContextSetGrayFillColor(ctx, 0.329, 0.9)
                CGContextFillRect( ctx, sep )
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
   
    func itemClicked(item:LSLGRCItem) {}
    
    override func mouseUp(theEvent: NSEvent) {
        for item in self.items {
            item.visible = true
        }
        if self.hoveringIdx >= 0 && self.hoveringIdx < self.items.count {
            self.itemClicked(self.items[self.hoveringIdx])
        }
    }
    
    override func mouseEntered(theEvent: NSEvent) {
        
        let visibleRange = self.visibleItemRange()
        
        var x:CGFloat = 4
        var margin:CGFloat = 0
        
        for var i = visibleRange.0; i >= visibleRange.1; --i {
            var item = self.items[i]
            if item.__trackingRect != theEvent.trackingNumber {
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
            CATransaction.setValue(kCFBooleanTrue, forKeyPath: kCATransactionDisableActions)
            
            self.hlLayer.frame = NSMakeRect(x, 0, item.width+margin, self.frame.height)
            self.hlLayer.hidden = false
            // Mask's frame must set after its content
            self.hlLayer.mask.frame = NSMakeRect(-x, 0, self.frame.width, self.frame.height)
            
            CATransaction.commit()
            self.hoveringIdx = i
            break
        }
    }
    
    override func mouseExited(theEvent: NSEvent) {
        self.hlLayer.hidden = true
        self.hoveringIdx = -1
    }
    
}
