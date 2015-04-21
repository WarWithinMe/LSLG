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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onShaderUpdate:", name: LSLGWindowShaderUpdate, object: nil)
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
            
            case "Geometry": showGeometryMenu()
            case "Fragment": showFragmentMenu()
            case "Vertex"  : showVertexMenu()
            
            default :
                item.toggleSelected()
        }
    }
    
    private var currentShaderMenu:String = ""
    
    private func showGeometryMenu() {
        var c = (window!.windowController() as! LSLGWindowController)
        showShaderMenu("Geometry", shaders: c.geometryShs(), selectedId: c.usingGeometrySh )
    }
    private func showFragmentMenu() {
        var c = (window!.windowController() as! LSLGWindowController)
        showShaderMenu("Fragment", shaders: c.fragmentShs(), selectedId: c.usingFragmentSh )
    }
    private func showVertexMenu() {
        var c = (window!.windowController() as! LSLGWindowController)
        showShaderMenu("Vertex", shaders: c.vertexShs(), selectedId: c.usingVertexSh )
    }
    
    private func showShaderMenu( shader:String, shaders:[String], selectedId:String ) {
        let rect = itemRect( shader )
        if rect == nil { return }
        
        var location = rect!.origin
        location.y += rect!.size.height
        
        currentShaderMenu = shader
        
        var menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        
        var selectedIdx = 0
        
        for var i = 0; i < shaders.count; ++i {
            var sh = shaders[i]
            menu.addItemWithTitle(sh, action: nil, keyEquivalent: "")
            if sh == selectedId { selectedIdx = i }
        }
        
        mouseExited(NSEvent())
        menu.popUpMenuPositioningItem( menu.itemArray[selectedIdx] as? NSMenuItem, atLocation: location, inView: self )
        currentShaderMenu = ""
    }
    
    func onShaderUpdate(n:NSNotification) {
        var c = (window!.windowController() as! LSLGWindowController)
        
        if (n.object as! LSLGWindowController) != c { return }
        
        getItemById("Geometry")!.content = c.usingGeometrySh
        getItemById("Fragment")!.content = c.usingFragmentSh
        getItemById("Vertex")!.content   = c.usingVertexSh
    }
    
    func menuDidClose(menu: NSMenu) {
        var c = (window!.windowController() as! LSLGWindowController)
        var t = menu.highlightedItem!.title
        switch currentShaderMenu {
            case "Geometry" : c.usingGeometrySh = t
            case "Fragment" : c.usingFragmentSh = t
            case "Vertex"   : c.usingVertexSh   = t
            default: return
        }
    }
    
    override func viewDidMoveToWindow() {
        if let w = window {
            var c = (w.windowController() as! LSLGWindowController)
            getItemById("Geometry")!.content = c.usingGeometrySh
            getItemById("Fragment")!.content = c.usingFragmentSh
            getItemById("Vertex")!.content   = c.usingVertexSh
        }
        
        super.viewDidMoveToWindow()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
