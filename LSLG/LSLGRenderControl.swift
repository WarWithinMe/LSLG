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
          , LSLGRCItem(icon:LSLGIcon.Log,      id:"Log",     desc:"Log")
          , LSLGRCItem(icon:LSLGIcon.Suzanne,  id:"Model",   desc:"Model")
          , LSLGRCItem(icon:LSLGIcon.Fragment, content:"Fragment", desc:"Fragment Shader")
          , LSLGRCItem(icon:LSLGIcon.Geometry, content:"Geometry", desc:"Geometry Shader")
          , LSLGRCItem(icon:LSLGIcon.Vertex,   content:"Vertex",   desc:"Vertex Shader")
          , LSLGRCItem(icon:LSLGIcon.Texture,  content:"Texture",  desc:"Texture")
        ])
        
        NSNotificationCenter.defaultCenter().addObserver(
            self
          , selector : "onPipelineChange:"
          , name     : LSLGWindowPipelineChange
          , object   : nil
        )
        
        NSNotificationCenter.defaultCenter().addObserver(
            self
          , selector : "onWinSubviewToggle:"
          , name     : LSLGWindowSubviewToggle
          , object   : nil
        )
        
        NSNotificationCenter.defaultCenter().addObserver(
            self
          , selector : "onPipelineChange:"
          , name     : LSLGWindowAssetsAvailable
          , object   : nil
        )
    }
    
    
    static private var DefaultModelIcon = LSLGIcon.Model
    static private var ModelIcons = [
        "Cube"    : LSLGIcon.Cube
      , "Sphere"  : LSLGIcon.Sphere
      , "Donut"   : LSLGIcon.Donut
      , "Suzanne" : LSLGIcon.Suzanne
    ]
    
    override func itemClicked(item: LSLGRCItem) {
        
        var controller = (window?.windowController() as? LSLGWindowController)
        
        switch item.id {
            case "Log"     : controller?.toggleLogView()
            case "Setting" : controller?.toggleSettings()
            case "Geometry": showAssetMenu("Geometry", type: .GeometryShader)
            case "Fragment": showAssetMenu("Fragment", type: .FragmentShader)
            case "Vertex"  : showAssetMenu("Vertex",   type: .VertexShader)
            case "Texture" : showAssetMenu("Texture",  type: .Image)
            case "Model"   :
                showAssetMenu("Model", type: .Model) {
                    (menuItem, asset) in
                    if let img = LSLGRenderControl.ModelIcons[asset.name]?.image {
                        menuItem.image = img
                        img.setTemplate(true)
                    } 
                }
            
            default :
                item.toggleSelected()
        }
    }
    
    private var currentMenu:String = ""
    private func showAssetMenu( menuName:String, type:LSLGAssetType, setupItem:((NSMenuItem,LSLGAsset)->())? = nil ) {
        let rect = itemRect( menuName )
        if rect == nil { return }
        
        var location = rect!.origin
        location.y += rect!.size.height
        
        var menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        
        var c = (window!.windowController() as! LSLGWindowController).assetManager
        var selected = c.glCurrAsset( type )
        var selectedItem:NSMenuItem? = nil
        
        // The statement after "in" ( a.k.a c.glAssets(type) )
        // will store in a unnamed local variable(without retain/release), according to the assembly
        for sh in sorted( c.glAssets(type), < ) {
            var m = menu.addItemWithTitle(sh.name, action: nil, keyEquivalent: "")!
            setupItem?( m, sh )
            if selectedItem == nil || sh == selected { selectedItem = m }
        }
        
        mouseExited(NSEvent())
        currentMenu = menuName
        menu.popUpMenuPositioningItem( selectedItem!, atLocation:location, inView:self )
        currentMenu = ""
    }
    
    private func updateControl( assetManager:LSLGAssetManager? ) {
        var c = window?.windowController() as? LSLGWindowController
        if c == nil { return }
        
        var cc = c!.assetManager
        
        if assetManager != nil && assetManager != cc { return }
        
        
        var item = getItemById("Geometry")!
        item.visible = cc.glGeomShaders.count > 1
        item.content = cc.glCurrGeomShader.name
        
        item = getItemById("Fragment")!
        item.visible = cc.glFragShaders.count > 1
        item.content = cc.glCurrFragShader.name
        
        item = getItemById("Vertex")!
        item.visible = cc.glVertShaders.count > 1
        item.content = cc.glCurrVertShader.name
        
        item = getItemById("Texture")!
        item.visible = cc.glTextures.count > 1
        item.content = cc.glCurrTexture.name
        
        if let icon = LSLGRenderControl.ModelIcons[cc.glCurrModel.name] {
            getItemById("Model")!.icon = icon
        } else {
            getItemById("Model")!.icon = LSLGRenderControl.DefaultModelIcon
        }
    }
    
    func onPipelineChange(n:NSNotification) { updateControl( n.object as? LSLGAssetManager ) }
    func onWinSubviewToggle(n:NSNotification)  {
        if let c:AnyObject = window?.windowController(), userInfo = n.userInfo where c === n.object {
            var item:LSLGRCItem!
            if userInfo["subview"]! as! String == "logs" {
                item = getItemById("Log")!
            } else {
                item = getItemById("Setting")!
            }
            item.selected = userInfo["visible"]! as! Bool
        }
    }
    
    func menuDidClose(menu: NSMenu) {
        if menu.highlightedItem == nil { return }
        
        var type:LSLGAssetType
        switch currentMenu {
            case "Geometry" : type = .GeometryShader
            case "Fragment" : type = .FragmentShader
            case "Vertex"   : type = .VertexShader
            case "Texture"  : type = .Image
            case "Model"    : type = .Model
            default: return
        }
        (window!.windowController() as! LSLGWindowController).assetManager.useAsset(menu.highlightedItem!.title, type:type)
    }
    
    override func viewDidMoveToWindow() {
        updateControl(nil)
        super.viewDidMoveToWindow()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
