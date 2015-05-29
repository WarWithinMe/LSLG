//
//  LSLGBridge.h
//  LSLG
//
//  Created by Morris on 5/28/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NSString* __nullable  lslgGetFdPath(int fd);

CVDisplayLinkOutputCallback __nonnull  lslgGetCVDisplayLinkCallback();
