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
        
        self.appendItems([
            LSLGRCItem(icon:LSLGIcon(type: LSLGIconType.Setting), id:"Setting")
          , LSLGRCItem(icon:LSLGIcon(type: LSLGIconType.Log),     id:"Log")
          , LSLGRCItem(icon:LSLGIcon(type: LSLGIconType.Suzanne), id:"Model")
          , LSLGRCItem(content:"Fragment", id:"Fragment")
          , LSLGRCItem(content:"Geometry", id:"Geometry")
          , LSLGRCItem(content:"Vertex",   id:"Vertex")
        ])
    }
    
    private var logView:LSLGLogView? = nil
    
    override func itemClicked(item: LSLGRCItem) {
        
        if item.id == "Log" {
            if self.logView != nil {
                self.logView!.removeFromSuperview()
                self.logView = nil
                item.selected = false
            } else {
                self.logView = LSLGLogView( frame:self.window!.frame )
                (self.window as! LSLGWindow).setContent( self.logView! )
                item.selected = true
            }
        } else {
            item.toggleSelected()
        }
    }
    
    deinit {
        println("rendercontrol deinit")
    }
}
