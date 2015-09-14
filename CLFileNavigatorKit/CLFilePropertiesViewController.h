//
//  CLFilePropertiesViewController.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/28/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CLFile;

@interface CLFilePropertiesViewController : UITableViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (strong, nonatomic) NSMutableArray *tableViewItems;
@property (strong, nonatomic) CLFile *file;

- (id)initWithFile:(CLFile *)file;
- (id)initWithFilePath:(NSString *)path;

@end
