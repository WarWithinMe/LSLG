//
//  LSLGRenderControl.swift
//  LSLG
//
//  Created by Morris on 4/9/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

class LSLGRenderControl:LSLGSegmentedControl, NSMenuDelegate {
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override init(x:CGFloat, y:CGFloat) {
        super.init(x: x, y: y)
        
        appendItems([
            LSLGRCItem(icon:LSLGIcon.Setting,  id:"Setting", desc:"Settings")
          , LSLGRCItem(icon:LSLGIcon.Log,      id:"Log", desc:"Log")
          , LSLGRCItem(icon:LSLGIcon.Suzanne,  id:"Model", desc:"Model")
          , LSLGRCItem(icon:LSLGIcon.Fragment, content:"Fragment", desc:"Fragment Shader")
          , LSLGRCItem(icon:LSLGIcon.Geometry, content:"Geometry", desc:"Geometry Shader")
          , LSLGRCItem(icon:LSLGIcon.Vertex,   content:"Vertex", desc:"Vertex Shader")
        ])
    }
    
    private var logView:LSLGLogView? = nil
    
    override func itemClicked(item: LSLGRCItem) {
        
        switch item.id {
            case "Log":
                if logView != nil {
                    logView!.removeFromSuperview()
                    logView = nil
                    item.selected = false
                } else {
                    logView = LSLGLogView( frame:frame )
                    (window as! LSLGWindow).setContent( logView!, fillWindow:false )
                    item.selected = true
                }
            
            case "Setting":
                (window?.windowController() as! LSLGWindowController).appendLog("TestLogfsaklfjsdjf log fsadtjekklj vewnfsai fdaskflsffsdfsdaf fsdakjfsdj fasfsa fdsf ", isError:Int(arc4random_uniform(3)) == 1, desc:"TestLog\( arc4random_uniform(1000000))")
            
            case "Fragment":
                showFragmentMenu()
            
            default :
                item.toggleSelected()
        }
    }
    
    private var currentShaderMenu:String = ""
    
    private func showFragmentMenu() {
        let rect = itemRect( "Fragment" )
        if rect == nil { return }
        
        var point = rect!.origin
        point.y += rect!.size.height
        
        var controller = window!.windowController() as! LSLGWindowController
        
        showMenu( "Fragment", items:controller.fragmentShaders(), location:point, selectedIndex:3 )
    }
    
    func showMenu( menuId:String, items:[String], location:NSPoint, selectedIndex:Int ) {
        currentShaderMenu = menuId
        
        var menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        
        for i in items {
            menu.addItemWithTitle(i, action: nil, keyEquivalent: "")
        }
        
        menu.popUpMenuPositioningItem( menu.itemArray[selectedIndex] as? NSMenuItem, atLocation: location, inView: self )
        
        currentShaderMenu = ""
    }
    
    func menuDidClose(menu: NSMenu) {
        println("\(menu.highlightedItem!.title)")
    }
}
