//
//  LSLGBridge.m
//  LSLG
//
//  Created by Morris on 5/28/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

#import <sys/fcntl.h>
#import "LSLGBridge.h"

NSString* __nullable  lslgGetFdPath(int fd) {
    char filePath[PATH_MAX];
    if (fcntl(fd, F_GETPATH, filePath) != -1)
    {
        return [NSString stringWithCString:filePath encoding:NSUTF8StringEncoding];
    }
    return nil;
}

// Remove these stuff when swift support C Function Pointers
#import "LSLG-Swift.h"
CVReturn CVDLCallbackFunction( CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext )
{
    return [(__bridge LSLGAppDelegate*)displayLinkContext onCVDisplayCallback:inOutputTime];
}

CVDisplayLinkOutputCallback __nonnull lslgGetCVDisplayLinkCallback() { return CVDLCallbackFunction; }