//
//  LSLGRenderControl.swift
//  LSLG
//
//  Created by Morris on 4/9/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

class LSLGRenderControl:LSLGSegmentedControl {
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override init(x:CGFloat, y:CGFloat) {
        super.init(x: x, y: y)
        
        appendItems([
            LSLGRCItem(icon:LSLGIcon(type: .Setting), id:"Setting")
          , LSLGRCItem(icon:LSLGIcon(type: .Log),     id:"Log")
          , LSLGRCItem(icon:LSLGIcon(type: .Suzanne), id:"Model")
          , LSLGRCItem(content:"Fragment", id:"Fragment")
          , LSLGRCItem(content:"Geometry", id:"Geometry")
          , LSLGRCItem(content:"Vertex",   id:"Vertex")
        ])
    }
    
    private var logView:LSLGLogView? = nil
    
    override func itemClicked(item: LSLGRCItem) {
        
        if item.id == "Log" {
            if logView != nil {
                logView!.removeFromSuperview()
                logView = nil
                item.selected = false
            } else {
                logView = LSLGLogView( frame:frame )
                (window as! LSLGWindow).setContent( logView!, fillWindow:false )
                item.selected = true
            }
        } else {
            item.toggleSelected()
        }
    }
}
