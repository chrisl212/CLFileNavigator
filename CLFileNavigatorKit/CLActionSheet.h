//
//  CLActionSheet.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 10/16/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^CLActionSheetCompletionHandler)(NSString *buttonTitle);

@interface CLActionSheet : UIActionSheet <UIActionSheetDelegate>

@property (strong, nonatomic) CLActionSheetCompletionHandler completionHandler;

@end
