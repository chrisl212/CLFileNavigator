//
//  CLFileOpener.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/19/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CLFileDisplayViewController.h"

@class CLFile;

@interface CLFileOpener : NSObject <CLFileDisplayDelegate>

+ (id)fileOpener;
- (void)openFileAtPath:(NSString *)path type:(NSInteger)type sender:(UIViewController *)vc;
- (void)openFile:(CLFile *)file sender:(UIViewController *)vc;

@end
