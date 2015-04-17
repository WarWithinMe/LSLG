//
//  LSLGLogView.swift
//  LSLG
//
//  Created by Morris on 4/7/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

class LSLGLogView: NSScrollView {
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override init(frame frameRect: NSRect) {
        let font  = NSFont(name: "Verdana", size: 12)!
        var param = NSMutableParagraphStyle()
        param.paragraphSpacing = 2.0
        param.lineSpacing      = 1.0
        
        normalTextAttr = [
            NSFontAttributeName : font
            , NSForegroundColorAttributeName : NSColor(white: 0.73, alpha: 1)
            , NSParagraphStyleAttributeName : param
        ]
        errorTextAttr = [
            NSFontAttributeName : font
            , NSForegroundColorAttributeName : NSColor(red:0.997, green:0.31, blue:0.231, alpha:1)
            , NSParagraphStyleAttributeName : param
        ]
        
        super.init(frame: frameRect)
        
        borderType            = .NoBorder
        hasHorizontalScroller = false
        hasVerticalScroller   = true
        autoresizingMask      = .ViewWidthSizable | .ViewHeightSizable
        drawsBackground       = false
        verticalScrollElasticity = .None
        
        textView = NSTextView( frame:NSMakeRect(0, 0, contentSize.width, contentSize.height) )
        
        textView.autoresizingMask      = .ViewWidthSizable
        textView.editable              = false
        textView.drawsBackground       = false
        textView.horizontallyResizable = false
        textView.verticallyResizable   = true
        
        textView.textContainer?.containerSize = NSMakeSize( contentSize.width, .max )
        textView.textContainer?.widthTracksTextView = true
        
        textView.selectedTextAttributes = [
            NSBackgroundColorAttributeName : NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        ]
        
        documentView = textView
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"updateContent:", name:LSLGWindowLogUpdate, object:nil)
    }
    
    private var textView:NSTextView!
    private var displayedLogCount:Int = 0
    private var normalTextAttr:[NSString:AnyObject]
    private var errorTextAttr:[NSString:AnyObject]

    override func viewDidMoveToWindow() {
        updateContent(nil)
        super.viewDidMoveToWindow()
    }
    
    func updateContent(notification:NSNotification?) {
        
        let wc:AnyObject? = window?.windowController()
        if wc == nil { return }
        
        if let o:AnyObject = notification?.object {
            if o !== wc {
                return
            }
        }
        
        // See if we need to autoscroll the textView
        let toBottomPx = CGFloat(1-verticalScroller!.floatValue) * (textView.frame.height - documentVisibleRect.height)
        
        let logs = (wc! as! LSLGWindowController).logs
        var formater = NSDateFormatter()
        formater.dateFormat = "[HH:mm:ss]"
            
        while displayedLogCount < logs.count {
            let item = logs[displayedLogCount]
            let ts   = textView.textStorage!
            
            if displayedLogCount > 0 {
                ts.appendAttributedString(NSAttributedString(string: "\n"))
            }
            
            if !item.log.isEmpty {
                ts.appendAttributedString( NSAttributedString(
                    string: "\(formater.stringFromDate(item.time)) \(item.log)"
                  , attributes: item.isError ? errorTextAttr : normalTextAttr
                ))
            }
            ++displayedLogCount
        }
        
        if toBottomPx < 18 {
            textView.scrollToEndOfDocument(nil)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}