//
//  LSLGSettings.swift
//  LSLG
//
//  Created by Morris on 5/18/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa


class LSLGSettings : NSViewController {
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    @IBOutlet var settingsView: LSLGSettingsView!
    
    init?( nibName:String = "Settings" ) {
        super.init(nibName:nibName, bundle:nil)
    }
    
    override func viewDidLoad() {
        var scrollView = (view as! NSScrollView)
        scrollView.documentView = settingsView
        
        var dict = [
            "settings" : settingsView,
            "super"    : scrollView.contentView
        ]
        scrollView.contentView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("|-0-[settings]-0-|", options: .allZeros, metrics: nil, views:dict)
        )
        scrollView.contentView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("V:[settings(>=super)]", options: .allZeros, metrics: nil, views:dict)
        )
    }
    
    override func viewDidAppear() {
        var scrollView = (view as! NSScrollView)
        scrollView.verticalScroller?.floatValue = 0
        scrollView.contentView.scrollToPoint(
            NSMakePoint(0, settingsView.frame.height - scrollView.documentVisibleRect.height )
        ) 
    }

}

class LSLGSettingsView: NSView {
    
    @IBOutlet weak var regexNotice: NSTextField!
    
    override func awakeFromNib() {
        wantsLayer = true
        self.layer!.backgroundColor = NSColor(calibratedWhite: 1, alpha: 0.03).CGColor
        
        let cbAttr = [
            NSFontAttributeName : NSFont(name: "Verdana", size: 10)!
          , NSForegroundColorAttributeName : NSColor(white: 0.713, alpha: 1)
        ]
        
        for view in subviews {
            if (view.tag() == 100) {
                var cell = (view as! NSButton).cell() as! NSButtonCell
                cell.highlightsBy    = NSCellStyleMask.NoCellMask
                cell.attributedTitle = NSAttributedString(string: cell.title , attributes: cbAttr)
            }
        }
    }
    
    override func layout() {
        regexNotice.preferredMaxLayoutWidth = frame.width - 50
        super.layout()
    }
}


// Setting Controls
class LSLGSettingsLine: NSView {
    override func drawRect(dirtyRect: NSRect) {
        NSColor(white: 0.28, alpha: 1).setFill()
        var height:CGFloat = 1.0
        if let w = window {
            height /= w.backingScaleFactor
        }
        NSRectFill(NSMakeRect(0, 0, self.bounds.width, height))
        super.drawRect(dirtyRect)
    }
}

class LSLGSettingsTextField: NSTextField {
    
    override func becomeFirstResponder() -> Bool {
        if super.becomeFirstResponder() {
            var text = currentEditor() as? NSTextView
            text?.insertionPointColor = NSColor(white: 0.713, alpha: 1)
            return true
        }
        return false
    }
    
    override func drawRect(dirtyRect: NSRect) {
        
        var rect = self.bounds
        
        // Background
        NSColor(white: 0.074, alpha: 1).setFill()
        NSRectFill(rect)
        
        // Border
        if let ce = currentEditor() where ce == window?.firstResponder {
            NSColor(calibratedRed:0.114, green:0.546, blue:0.895, alpha:1).setStroke()
            if window!.backingScaleFactor == 1.0 {
                NSBezierPath(rect:NSMakeRect(
                    rect.origin.x + 0.5
                  , rect.origin.y + 0.5
                  , rect.width  - 1
                  , rect.height - 1
                )).stroke()
            } else {
                NSBezierPath(rect:rect).stroke()
            }
        } else {
            NSColor(white: 0.266, alpha: 1).setStroke()
            var path = NSBezierPath()
            if window!.backingScaleFactor == 1.0 {
                
            } else {
                path.moveToPoint( NSMakePoint( 0, rect.height ) )
                path.lineToPoint( NSMakePoint( rect.width, rect.height ) )
                path.closePath()
            }
            path.stroke()
        }
        
        super.drawRect(dirtyRect)
    }
    
}
