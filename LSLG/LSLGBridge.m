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