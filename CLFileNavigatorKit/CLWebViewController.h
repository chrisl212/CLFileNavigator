//
//  CLWebViewController.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/19/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CLFile;

@interface CLWebViewController : UIViewController

- (id)initWithFileAtPath:(NSString *)path;
- (id)initWithFile:(CLFile *)file;

@end
