//
//  LSLGFolderMonitor.swift
//  LSLG
//
//  Created by Morris on 5/7/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

protocol LSLGFolderMonitorDelegate: class {
    // These two function is called in the main queue.
    func onFileChanged( paths:[String] )
    func onFolderChanged( added:[String], _ modified:[String], _ removed:[String] )
}

/*
    Currently the LSLGFolderMonitor cannot handle the event of Folder Removal
*/
class LSLGFolderMonitor {
    
    static var eventQueue = dispatch_queue_create("wwm.LSLGFolderMonitor",  DISPATCH_QUEUE_SERIAL) 
    
    private(set) var folderPath:String = ""
    private var folderDSrc:dispatch_source_t!
    
    weak var delegate:LSLGFolderMonitorDelegate?
    
    convenience init?(path:String) {
        
        self.init()
        
        var dirFD = Darwin.open( path.fileSystemRepresentation(), O_EVTONLY )
        if dirFD < 0 { return nil }
        
        // Create a dispatch source to monitor the folder's WRITE ( including create/delete of the content. )
        var _src = dispatch_source_create(
            DISPATCH_SOURCE_TYPE_VNODE 
            , UInt(dirFD)
            , DISPATCH_VNODE_WRITE
            , LSLGFolderMonitor.eventQueue
        )
        if _src == nil {
            Darwin.close( dirFD )
            return nil
        }
        
        // Setup the dispatch source
        dispatch_source_set_cancel_handler(_src, { Darwin.close( dirFD ) })
        dispatch_source_set_event_handler (_src, { [weak self] in if let strongSelf = self {strongSelf.onFolderEvt()} })
        
        // Self init
        folderPath = path
        folderDSrc = _src
        self.scanFolder()
        
        dispatch_resume( _src )
    }
    
    private var sheduledCheck = false
    private func onFolderEvt() {
        // This function is call concurrently on a gloabl queue when the content of
        // the folder is added / renamed / removed. Perform a scan to know what's changed.
        if sheduledCheck {
            println("Already sheduled scanning.")
            return
        }
        
        // Shedule the check after 50ms. Since the folder might just changing a bunch of files.
        sheduledCheck = true
        dispatch_after( dispatch_time(DISPATCH_TIME_NOW, Int64(50 * NSEC_PER_MSEC)) , LSLGFolderMonitor.eventQueue, {
            [weak self] in
            
            if let strongSelf = self {
                strongSelf.scanFolder()
                strongSelf.sheduledCheck = false
            }
        } )
    }
    
    typealias ContentAttr = (modifyTime:NSDate, createTime:NSDate, dSrc:dispatch_source_t?)
    private var folderStatus = [String:ContentAttr]()
    
    private func scanFolder() {
        // When the folder's content change, find out new content that we have not yet monitored.
        // We need to create a dsrc for each of the file inside the folder. Since, WRITE-ing to
        // the file doesn't cause the folder's dsrc to trigger an event.
        // It's believed that FSEvent/KernelQueues is better when we need to watch large amount of file.
        // But in LSLG, I think we don't need to watch that much files.
        var manager = NSFileManager()
        var currentFiles = [String:ContentAttr]()
        
        var added    = [String]()
        var modified = [String]()
        var removed  = [String]()
        
        if let contents = manager.contentsOfDirectoryAtPath( folderPath, error:nil ) as? [String] {
            for file in contents
            {
                // Explicitly ignore .DS_Store
                if file == ".DS_Store" { continue }
                
                var filePath = folderPath.stringByAppendingPathComponent(file)
                var attributes = manager.attributesOfItemAtPath( filePath, error:nil )
                if attributes == nil { continue }
                
                var dSrc:dispatch_source_t? = nil
                var createTime   = attributes![ NSFileCreationDate ] as! NSDate
                var storedStatus = folderStatus[ file ]
                
                if storedStatus == nil {
                    added.append( file )
                    dSrc = watchFile( filePath )
                } else if storedStatus!.createTime != createTime || storedStatus!.dSrc == nil {
                    // The file is a newly created file, need to re-create a dsrc for the file.
                    dSrc = watchFile( filePath )
                } else {
                    // The file remains the old file, re-use the old dsrc
                    dSrc = storedStatus!.dSrc
                }
                
                currentFiles[ file ] = (
                    modifyTime:attributes![ NSFileModificationDate ] as! NSDate
                    , createTime:createTime
                    , dSrc : dSrc
                )
            }
        } 
        
        // Release removed file's descriptor.
        for (file,attr) in folderStatus {
            var currentAttr = currentFiles[ file ]
            if let ca = currentAttr {
                if let dSrc = attr.dSrc where dSrc != ca.dSrc {
                    // We have created a new dSrc for the file. So remove the old dSrc.
                    println("canceling for file (O): \(file)")
                    dispatch_source_cancel( dSrc )
                    
                    modified.append( file )
                } else if ca.modifyTime != attr.modifyTime {
                    modified.append( file )
                }
                
                
            } else {
                removed.append( file )
                if let src = attr.dSrc {
                    println("canceling for file (R): \(file)")
                    dispatch_source_cancel( src )
                }
            }
        }
        
        folderStatus = currentFiles
        
        dispatch_async( dispatch_get_main_queue(), { self.delegate?.onFolderChanged(added, modified, removed) } )
    }
    
    private var changedFiles = [String]()
    private var changedFilesLock = NSLock()
    private func watchFile( path:String )-> dispatch_source_t? {
        var dirFD = Darwin.open( path.fileSystemRepresentation(), O_EVTONLY )
        if dirFD < 0 { return nil }
        
        var _src = dispatch_source_create(
            DISPATCH_SOURCE_TYPE_VNODE 
            , UInt(dirFD)
            , DISPATCH_VNODE_WRITE | DISPATCH_VNODE_REVOKE | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_DELETE
            , LSLGFolderMonitor.eventQueue
        )
        if _src == nil {
            Darwin.close( dirFD )
            return nil
        }
        
        // Setup the dispatch source
        dispatch_source_set_cancel_handler( _src ) { Darwin.close( dirFD ) }
        dispatch_source_set_event_handler(  _src ) {
            [weak self] in
            if let strongSelf = self {
                if dispatch_source_get_data( _src ) != DISPATCH_VNODE_WRITE {
                    // if it's not DISPATCH_VNODE_WRITE, the dirFD is probabaly not usable anymore.
                    // Thus we do a scan on the folder to re-create a dirFD.
                    // Example: TextEdit will re-create the file the first time it tries to save, cause the dirFD not usable.
                    strongSelf.folderStatus[path.lastPathComponent]?.dSrc = nil
                    strongSelf.onFolderEvt()
                    println( "\(path) changed casuing a rescan." )
                    return
                }
                
                strongSelf.changedFilesLock.lock()
                strongSelf.changedFiles.append( path.lastPathComponent )
                strongSelf.changedFilesLock.unlock()
                
                dispatch_async( dispatch_get_main_queue(), {
                    if let strongSelf = self {
                        strongSelf.changedFilesLock.lock()
                        var fs = strongSelf.changedFiles
                        strongSelf.changedFiles = []
                        strongSelf.changedFilesLock.unlock()
                        
                        strongSelf.delegate?.onFileChanged(fs)
                    }
                } )
            }
        }
        
        dispatch_resume( _src ) 
        return _src
    }
    
    /* Cleanup */
    deinit {
        if let src = folderDSrc { dispatch_source_cancel( src ) }
        for (string,attr) in folderStatus { if let src = attr.dSrc { dispatch_source_cancel( src ) } }
    }
}
