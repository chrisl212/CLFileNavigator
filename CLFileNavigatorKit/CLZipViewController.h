//
//  CLZipViewController.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 10/16/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <CLFileNavigatorKit/CLFileNavigatorKit.h>

@interface CLZipViewController : CLFileDisplayViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *tableViewItems;
@property (strong, nonatomic) NSArray *directories;

- (id)initWithFile:(NSString *)file;

@end
