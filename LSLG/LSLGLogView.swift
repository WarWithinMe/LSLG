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
        super.init(frame: frameRect)
        
        self.borderType            = .NoBorder
        self.hasHorizontalScroller = false
        self.hasVerticalScroller   = true
        self.autoresizingMask      = .ViewWidthSizable | .ViewHeightSizable
        self.drawsBackground       = false
        
        var tv = NSTextView(frame:NSMakeRect(0,0,self.contentSize.width,self.contentSize.height))
        self.textView = tv
        
        tv.autoresizingMask      = .ViewWidthSizable
        tv.editable              = false
        tv.drawsBackground       = false
        tv.horizontallyResizable = false
        tv.verticallyResizable   = true
        
        tv.textContainer?.containerSize = NSMakeSize( self.contentSize.width, CGFloat.max )
        tv.textContainer?.widthTracksTextView = true
        
        self.documentView = tv
        
        let font = NSFont(name: "Verdana", size: 12)!
        var param = NSMutableParagraphStyle()
        param.paragraphSpacing = 4.0
        param.lineSpacing      = 1.0
        
        self.normalTextAttr = [
            NSFontAttributeName : font
          , NSForegroundColorAttributeName : NSColor(white: 0.73, alpha: 1)
          , NSParagraphStyleAttributeName : param
        ]
        self.errorTextAttr = [
            NSFontAttributeName : font
          , NSForegroundColorAttributeName : NSColor(red:0.997, green:0.31, blue:0.231, alpha:1)
          , NSParagraphStyleAttributeName : param
        ]
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"updateContent:", name:LSLGWindowLogUpdate, object:nil)
    }
    
    private var textView:NSTextView!
    private var displayedLogCount:Int = 0
    private var normalTextAttr:[NSString:AnyObject]!
    private var errorTextAttr:[NSString:AnyObject]!

    override func viewDidMoveToWindow() {
        self.updateContent(nil)
        super.viewDidMoveToWindow()
    }
    
    func updateContent(notification:NSNotification?) {
        
        let wc:AnyObject? = self.window?.windowController()
        if wc == nil { return }
        
        if let o:AnyObject = notification?.object {
            if o !== wc {
                return
            }
        }
        
        let logs = (wc! as! LSLGWindowController).logs
        var formater = NSDateFormatter()
        formater.dateFormat = "[HH:mm:ss]"
            
        while displayedLogCount < logs.count {
            let item = logs[displayedLogCount]
            let ts   = self.textView.textStorage!
            
            if !item.log.isEmpty {
                ts.appendAttributedString( NSAttributedString(
                    string: "\(formater.stringFromDate(item.time)) \(item.log)"
                  , attributes: item.isError ? self.errorTextAttr : self.normalTextAttr
                ))
            }
            ts.appendAttributedString(NSAttributedString(string: "\n"))
            ++displayedLogCount
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}