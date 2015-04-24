//
//  LSLGAssetManager.swift
//  LSLG
//
//  Created by Morris on 4/23/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

class LSLGAssetManager: NSObject {
    
    private(set) var folderPath:NSString!
    private var folderDSrc:dispatch_source_t!
    
    init?(path:String) {
        
        checkQueue = dispatch_queue_create("wwm.LSLGAssetManager",  DISPATCH_QUEUE_SERIAL)
        
        super.init()
        
        dirBrief = folderBrief( path )
        
        var p = path as NSString
        
        var dirFD = Darwin.open( p.fileSystemRepresentation, O_EVTONLY )
        if dirFD < 0 { return nil }
        
        // Create a dispatch source to monitor the directory for writes
        var _src = dispatch_source_create(
            DISPATCH_SOURCE_TYPE_VNODE  // Watch for certain events on the VNODE spec'd by the second (handle) argument
            , UInt(dirFD)               // The handle to watch (the directory FD)
            , DISPATCH_VNODE_WRITE      // The events to watch for on the VNODE spec'd by handle (writes)
            , dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0) // The queue to which the handler block will ultimately be dispatched
        )
        if _src == nil {
            Darwin.close( dirFD )
            return nil
        }
        
        dispatch_source_set_cancel_handler(_src) { Darwin.close( dirFD ) }
        dispatch_source_set_event_handler(_src) {
            [unowned self] in
            self.onFileChanged()
        }
        
        dispatch_resume( _src )
        
        folderPath = p
        folderDSrc = _src
    }
    
    private func folderBrief( path:String )->[String:NSDate] {
        var manager = NSFileManager()
        var brief   = [String:NSDate]()
        
        if let contents = manager.contentsOfDirectoryAtPath( path, error:nil ) as? [String] {
            for file in contents
            {
                if let attr = manager.attributesOfItemAtPath( path.stringByAppendingPathComponent(file), error:nil ) {
                    brief[ file ] = (attr[ NSFileModificationDate ] as! NSDate)
                }
            }
        }
        
        return brief
    }
    
    // This property is inited when the Manager is inited, and then only accessed outside the main queue.
    private var dirBrief:[String:NSDate]!
    private func diffFolderBrief() {
        // This function is called in a background thread.
        var newBrief = folderBrief( folderPath as String )
        
        var removed  = [String]()
        var modified = [String]()
        var added    = [String]()
        
        for (key, value) in dirBrief {
            if let newData = newBrief[key] {
                if value != newData {
                    modified.append( key )
                }
            } else {
                removed.append( key )
            }
        }
        
        for (key, value) in newBrief {
            if dirBrief[key] == nil {
                added.append( key )
            }
        }
        
        dirBrief = newBrief
        if added.count + removed.count + modified.count > 0 {
            dispatch_async( dispatch_get_main_queue() ) {
                self.reloadAsset( added, modified, removed )
            }
        }
    }
    
    private var checking = false
    private var nextCheck:dispatch_source_t?
    private var checkQueue:dispatch_queue_t
    private var oneMoreCheck = false
    private func onFileChanged() {
        println("[Debug] Received event from GCD \(DISPATCH_TIME_NOW)")
        // If the event happens before scheduled checking, we would like to do
        // one more check after that checking. Since this probably means that
        // there are several files edited at the same time.
        if checking {
            oneMoreCheck = true
        } else {
            checking  = true
            nextCheck = dispatch_source_create( DISPATCH_SOURCE_TYPE_TIMER, 0, 0, checkQueue )
            dispatch_source_set_timer(
                nextCheck!
              , dispatch_time( DISPATCH_TIME_NOW, Int64(50 * NSEC_PER_MSEC) )
              , 150 * NSEC_PER_MSEC
              , 0
            )
            dispatch_source_set_event_handler( nextCheck! ) {
                [weak self] in
                if let strongSelf = self {
                    strongSelf.diffFolderBrief()
                    
                    if strongSelf.oneMoreCheck {
                        strongSelf.oneMoreCheck = false
                    } else {
                        dispatch_source_cancel( strongSelf.nextCheck! )
                        strongSelf.nextCheck = nil
                        strongSelf.checking = false
                    }
                }
            }
            dispatch_resume( nextCheck! )
        }
    }
    
    
    private func reloadAsset( added:[String], _ modified:[String], _ removed:[String] ) {
        println("Add: \(added)")
        println("Modify: \(modified)")
        println("Remove: \(removed)")
    }
    
    deinit {
        dispatch_source_cancel( folderDSrc! )
        if nextCheck != nil { dispatch_source_cancel( nextCheck! ) }
    }
}
