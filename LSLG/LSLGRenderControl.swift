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
        var parent:LSLGSegmentedControl?
        var icon:LSLGIcon? {
            didSet { self.tryUpdateParent() }
        }
        var width:CGFloat  { return self.visible ? self.__width : 0 }
        var content:NSString = "" {
            didSet { self.tryUpdateParent() }
        }
        var visible:Bool = true {
            didSet { self.tryUpdateParent() }
        }
        
        init(content:String, id:String="") {
            super.init()
            self.id = id
            self.content = content as NSString
            self.calcWidth()
        }
        
        init(icon:LSLGIcon, id:String="") {
            super.init()
            self.id = id
            self.icon = icon
        }
        
        private var __width:CGFloat  = 24.0
        
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
    var trTags = [NSTrackingRectTag]()
    
    var textLayer:CALayer!
    var hlLayer:CALayer!
    var hoveringIdx:Int = -1
    
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
        maskLayer.autoresizingMask = CAAutoresizingMask.LayerNotSizable
        
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
        self.textLayer.autoresizingMask = CAAutoresizingMask.LayerWidthSizable
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
            self.items.removeAtIndex(idx)
            self.updateFrame()
            aItem.parent = nil
        }
    }
    
    func updateFrame() {
        
        var w:CGFloat = 8
        for item in self.items {
            w += item.width
        }
        
        self.frame = NSMakeRect(
            self.frame.origin.x + self.frame.width - w
          , self.frame.origin.y
          , w
          , self.frame.height
        )
        
        for tag in self.trTags { self.removeTrackingRect(tag) }
        
        var rect = self.bounds
        self.trTags.removeAll(keepCapacity: true)
        for var i = self.items.count - 1; i >= 0; --i {
            var item = self.items[i]
            if !item.visible {
                self.trTags.insert(LSLSInvisibleTrackingRectTag, atIndex: 0)
                continue
            }
            
            rect.size.width = item.width
            self.trTags.insert(self.addTrackingRect(rect, owner: self, userData: nil, assumeInside: false), atIndex: 0)
            rect.origin.x += item.width
        }
        
        self.needsDisplay = true
        self.textLayer.setNeedsDisplay()
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
        
        var font = NSFont(name: "Verdana", size:10.0 )!
        var dict:[NSObject:AnyObject] = [
            kCTFontAttributeName:font
          , kCTForegroundColorAttributeName:NSColor(calibratedWhite: 0.407, alpha: 1).CGColor
        ]
        
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
                CGContextSetGrayFillColor(ctx, 0.407, 1)
                CGContextEOFillPath( ctx )
                CGContextBeginPath( ctx )
                CGContextTranslateCTM( ctx, -x, -iconY )
            } else {
                CGContextSetTextPosition(ctx, x, y)
                CTLineDraw(CTLineCreateWithAttributedString( NSAttributedString(string:item.content, attributes:dict) ) , ctx)
            }
            
            x += item.width
            firstItem = false
        }
    }
    
    override func mouseUp(theEvent: NSEvent) {
        for item in self.items {
            item.visible = true
        }
        if self.hoveringIdx >= 0 && self.hoveringIdx < self.items.count {
            self.items[self.hoveringIdx].visible = false
        }
    }
    
    override func mouseEntered(theEvent: NSEvent) {
        var x:CGFloat = 4
        var r = self.bounds
        
        var hasVisibleSiblings = 0
        
        for var i = self.items.count - 1; i >= 0; --i {
            var item = self.items[i]
            if item.visible { ++hasVisibleSiblings }
            
            if self.trTags[i] != theEvent.trackingNumber {
                x += item.width
                continue
            }
            
            // Check if the item is the first visible item
            r.size.width = item.width
            if i == self.items.count - 1 || hasVisibleSiblings == 1 {
                x -= 4
                r.size.width += 4
            }
    
            // Check if this item is the last visible item
            hasVisibleSiblings = 0
            for var j = i-1; j >= 0; --j { if self.items[j].visible { ++hasVisibleSiblings } }
            if hasVisibleSiblings == 0 { r.size.width += 4 }
            
            r.origin.x = x
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKeyPath: kCATransactionDisableActions)
            self.hlLayer.frame = r
            self.hlLayer.hidden = false
            r.size.width = self.frame.width
            r.origin.x   = -x
            self.hlLayer.mask.frame = r
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


class LSLGRenderControl:LSLGSegmentedControl {
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override init(x:CGFloat, y:CGFloat) {
        super.init(x: x, y: y)
        
        self.appendItems([
            LSLGRCItem(icon:LSLGIcon(type: LSLGIconType.Setting), id:"Setting")
          , LSLGRCItem(icon:LSLGIcon(type: LSLGIconType.Log),     id:"Log")
          , LSLGRCItem(icon:LSLGIcon(type: LSLGIconType.Suzanne), id:"Model")
          , LSLGRCItem(content:"Fragment", id:"Fragment")
          , LSLGRCItem(content:"Geometry", id:"Geometry")
          , LSLGRCItem(content:"Vertex",   id:"Vertex")
        ])
    }
}
