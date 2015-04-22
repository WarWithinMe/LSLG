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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onPipelineChange:", name: LSLGWindowPipelineChange, object: nil)
    }
    
    private var logView:LSLGLogView? = nil
    
    private var modelIcons = [LSLGIcon.Cube, LSLGIcon.Sphere, LSLGIcon.Donut, LSLGIcon.Suzanne]
    
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
            case "Model"   : showModelMenu()
            
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
    
    private func showModelMenu() {
        let rect = itemRect( "Model" )
        if rect == nil { return }
        
        var location = rect!.origin
        location.y += rect!.size.height
        
        currentShaderMenu = "Model"
        var menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        
        var selectedIdx = 0
        var c = (window!.windowController() as! LSLGWindowController)
        var selectedModel = c.usingModel
        var modelNames = c.models()
        
        for var i = 0; i < modelNames.count; ++i {
            var m = modelNames[i]
            var item = menu.addItemWithTitle(m, action: nil, keyEquivalent: "")!
            item.image = modelIcons[i].image
            item.image?.setTemplate(true)
            if m == selectedModel { selectedIdx = i }
        }
        
        mouseExited(NSEvent())
        menu.popUpMenuPositioningItem( menu.itemArray[selectedIdx] as? NSMenuItem, atLocation: location, inView: self )
        currentShaderMenu = ""
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
            menu.addItemWithTitle(sh, action: nil, keyEquivalent: "")!
            if sh == selectedId { selectedIdx = i }
        }
        
        mouseExited(NSEvent())
        menu.popUpMenuPositioningItem( menu.itemArray[selectedIdx] as? NSMenuItem, atLocation: location, inView: self )
        currentShaderMenu = ""
    }
    
    private func updateControl(targetController:LSLGWindowController?) {
        var c = window?.windowController() as? LSLGWindowController
        if c == nil { return }
        if targetController != nil && targetController != c { return }
        
        var cc = c!
        
        var item = getItemById("Geometry")!
        item.visible = cc.geometryShs().count > 1
        item.content = cc.usingGeometrySh
        
        item = getItemById("Fragment")!
        item.visible = cc.fragmentShs().count > 1
        item.content = cc.usingFragmentSh
        
        item = getItemById("Vertex")!
        item.visible = cc.vertexShs().count > 1
        item.content = cc.usingVertexSh
        
        var models = cc.models()
        for var i = 0; i < models.count; ++i {
            if models[i] == cc.usingModel {
                getItemById("Model")!.icon = modelIcons[i]
                break
            }
        }
    }
    
    func onPipelineChange(n:NSNotification) {
        updateControl( n.object as? LSLGWindowController )
    }
    
    func menuDidClose(menu: NSMenu) {
        if menu.highlightedItem == nil { return }
        
        var c = (window!.windowController() as! LSLGWindowController)
        var t = menu.highlightedItem!.title
        switch currentShaderMenu {
            case "Geometry" : c.usingGeometrySh = t
            case "Fragment" : c.usingFragmentSh = t
            case "Vertex"   : c.usingVertexSh   = t
            case "Model"    : c.usingModel      = t
            default: return
        }
    }
    
    override func viewDidMoveToWindow() {
        updateControl(nil)
        super.viewDidMoveToWindow()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
