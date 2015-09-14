//
//  CLSettingsViewController.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/28/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLSettingsViewController : UITableViewController

@property (strong, nonatomic) NSMutableArray *tableViewItems;
@property (strong, nonatomic) NSMutableArray *fileTypesArray;

- (void)dismiss;

@end

@interface CLTypesEditorController : UITableViewController

@property (strong, nonatomic) NSMutableArray *tableViewItems;

- (id)initWithItems:(NSMutableArray **)items;

@end