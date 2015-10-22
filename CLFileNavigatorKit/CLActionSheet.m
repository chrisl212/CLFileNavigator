//
//  CLActionSheet.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 10/16/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "CLActionSheet.h"

@implementation CLActionSheet

- (id<UIActionSheetDelegate>)delegate
{
    return self;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (self.completionHandler)
        self.completionHandler([self buttonTitleAtIndex:buttonIndex]);
}

@end
