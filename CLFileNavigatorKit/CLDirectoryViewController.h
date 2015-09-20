//
//  CLDirectoryViewController.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/18/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACAlertView.h"

@class CLFile;

extern NSString *const CLDirectoryViewControllerRefreshNotification;

extern NSString *const CLDirectoryViewControllerDisplayThumbnailsOption;
extern NSString *const CLDirectoryViewControllerDateDisplayOption;

@interface CLDirectoryViewController : UITableViewController <UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate, ACAlertViewDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) NSDictionary *options;
@property (strong, nonatomic) CLFile *directory;
@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSArray *files;

- (id)initWithDirectory:(CLFile *)dir;
- (id)initWithDirectoryPath:(NSString *)path;
- (void)refreshFiles;
- (UIView *)tableFooter;

@end
