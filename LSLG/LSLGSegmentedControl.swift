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
        
        private var __desc:String
        private var __id:String
        private var __width:CGFloat = 0.0
        
        weak var parent:LSLGSegmentedControl?
        
        var trackingRect:NSTrackingRectTag = -1
        var tooltipRect:NSToolTipTag       = -1
        
        var icon:LSLGIcon? { didSet { calcWidth() } }
        var content:String { didSet { calcWidth() } }
        var desc:String    { return __desc  }
        var width:CGFloat  { return __width }
        var id:String      { return __id    }
        var visible:Bool  = true  { didSet { tryUpdateParent() } }
        var selected:Bool = false { didSet { tryUpdateParent() } }
        
        convenience init(icon:LSLGIcon, content:String, desc:String="") {
            self.init(icon:icon, content:content, id:content, desc:desc)
        }
        convenience init(icon:LSLGIcon, id:String, desc:String="") {
            self.init(icon:icon, content:"", id:id, desc:desc)
        }
        
        init(content:String, id:String="") {
            
            self.__id    = id.isEmpty ? content : id
            self.__desc  = ""
            self.content = content
            
            super.init()
            
            self.calcWidth()
        }
        
        init(icon:LSLGIcon, content:String, id:String, desc:String) {
            self.__id    = id
            self.__desc  = desc
            self.icon    = icon
            self.content = content
            
            super.init()
            self.calcWidth()
        }
        
        
        func toggleSelected()  { selected = !selected }
        func tryUpdateParent() { parent?.updateFrame() }
        
        func calcWidth() {
            if icon != nil {
                __width = icon!.width
                if !content.isEmpty {
                    __width += 2.0
                }
            } else {
                __width = 0
            }
            
            if !content.isEmpty {
                __width += round(content.sizeWithAttributes( [NSFontAttributeName:NSFont(name:"Verdana",size:10.0)!] ).width)
            }
            parent?.updateFrame()
        }
        
        override var description:String { return __desc }
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
        
        // Background. Use a layer to draw the background, because it's just not possible
        // to draw a pixel-perfect line (which is 1-pixel wide) with core graphics.
        var bgLayer = CAGradientLayer()
        bgLayer.frame = bounds
        bgLayer.borderWidth  = 0.5
        bgLayer.borderColor  = NSColor(calibratedWhite: 0.4, alpha: 0.25).CGColor
        bgLayer.cornerRadius = frame.height / 2
        bgLayer.autoresizingMask = CAAutoresizingMask.LayerWidthSizable
        bgLayer.locations = [0,0.5,1]
        bgLayer.colors = [
            NSColor(calibratedWhite:0.134, alpha:0.85 ).CGColor
          , NSColor(calibratedWhite:0.030, alpha:0.85 ).CGColor
          , NSColor(calibratedWhite:0.134, alpha:0.85 ).CGColor
        ]
        layer      = bgLayer
        wantsLayer = true
        
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
    
    func getItemById(id:String)->LSLGRCItem? {
        for item in items {
            if item.id == id { return item }
        }
        return nil
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
    
    func itemRect(itemId:String) -> NSRect? {
        var b = bounds
        
        let range = visibleItemRange()
        
        for i in lazy( range.1 ... range.0 ).reverse() {
            var item = items[i]
            if !item.visible { continue }
            
            b.size.width = item.width + 8
            if i == range.0 || i == range.1 { b.size.width += 2 }
            
            if item.id == itemId {
                return b
            }
            
            b.origin.x += item.width + 8
        }
        return nil
    }
    
    func updateFrame() {
        for item in items {
            if item.trackingRect != -1 {
                removeTrackingRect( item.trackingRect )
                item.trackingRect = -1
            }
            if item.tooltipRect != -1 {
                removeToolTip( item.tooltipRect )
                item.tooltipRect = -1
            }
        }
        
        var rect  = bounds
        let range = visibleItemRange()
        
        for i in lazy( range.1 ... range.0 ).reverse() {
            var item = items[i]
            if !item.visible { continue }
            
            rect.size.width = item.width + 8
            if i == range.0 || i == range.1 { rect.size.width += 2 }
            
            item.trackingRect = addTrackingRect( rect, owner: self, userData: nil, assumeInside: false )
            item.tooltipRect  = addToolTipRect( rect, owner: item, userData: nil )
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
        
        var x:CGFloat     = 2.0
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
                sepRect.origin.x = x
                CGContextSetGrayFillColor( ctx, 0.329, 0.9 )
                CGContextFillRect( ctx, sepRect )
            }
            
            x += 4.0 // Padding Left
            
            if let icon = item.icon {
                CGContextTranslateCTM( ctx, x, iconY )
                CGContextAddPath( ctx, icon.path )
                CGContextSetFillColorWithColor( ctx, item.selected ? selectedColor : normalColor )
                CGContextEOFillPath( ctx )
                CGContextBeginPath( ctx )
                CGContextTranslateCTM( ctx, -x, -iconY )
            }
            
            if !item.content.isEmpty {
                CGContextSetTextPosition(ctx, item.icon != nil ? x + 2.0 + item.icon!.width : x, y)
                CTLineDraw(CTLineCreateWithAttributedString( NSAttributedString(
                    string     : item.content
                  , attributes : item.selected ? selectedText : normalText
                )) , ctx)
            }
            
            x += item.width + 4.0 // Padding right
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
        
        var x:CGFloat      = 2
        var margin:CGFloat = 8
        
        for var i = visibleRange.0; i >= visibleRange.1; --i {
            var item = items[i]
            if item.trackingRect != theEvent.trackingNumber {
                x += item.width + 8
                continue
            }
            
            // The first visible item has 4px left margin
            if i == visibleRange.0 {
                x -= 2
                margin += 2
            }
            
            // The last visible item has 4px right margin
            if i == visibleRange.1 { margin += 6 }
        
            CATransaction.begin()
            CATransaction.setValue( kCFBooleanTrue, forKeyPath: kCATransactionDisableActions )
            
            hlLayer.frame = NSMakeRect( x, 0, item.width+margin, frame.height )
            hlLayer.hidden = false
            // Mask's frame must set after its content
            hlLayer.mask.frame = NSMakeRect( -x, 0, frame.width, frame.height )
            
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
