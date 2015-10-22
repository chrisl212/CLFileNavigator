//
//  CLFileDisplayViewController.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 9/27/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 @brief Abstract superclass for all view controllers that display the contents of files.
 
 */

@class CLFileDisplayViewController;

@protocol CLFileDisplayDelegate <NSObject>

- (void)fileDisplayControllerWasCreated:(CLFileDisplayViewController *)controller;//for memory issues
- (void)fileDisplayControllerShouldHide:(CLFileDisplayViewController *)controller;
- (void)fileDisplayControllerShouldUnhide:(CLFileDisplayViewController *)controller;
- (void)fileDisplayControllerWasClosed:(CLFileDisplayViewController *)controller;//for memory issues

@end

@interface CLFileDisplayViewController : UIViewController

@property (weak, nonatomic) id<CLFileDisplayDelegate> fileDisplayDelegate;
@property (nonatomic, getter=isHiding) BOOL hiding;
@property (nonatomic) CGPoint hidingCenter;
@property (nonatomic) BOOL canHide;

- (void)dismiss;
- (UIImage *)hidingIcon;

@end

/**
 @brief Needed to properly hide/unhide @a CLFileDisplayViewController
 */
@interface CLFileDisplayView : UIView

@property (weak, nonatomic) CLFileDisplayViewController *controller;
@property (nonatomic) BOOL hiding;
@property (nonatomic) BOOL moving;

@end