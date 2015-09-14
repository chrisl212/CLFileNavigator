//
//  CLMoviePlayerViewController.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 9/13/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CLFile;

@interface CLMoviePlayerViewController : UIViewController

- (id)initWithFilePath:(NSString *)path;
- (id)initWithFile:(CLFile *)file;

@end
