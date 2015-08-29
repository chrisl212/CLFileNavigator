//
//  UIImage+CLFile.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/19/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLFile.h"

@interface UIImage (CLFile)

+ (UIImage *)iconForFileType:(CLFileType)fileType;

@end
