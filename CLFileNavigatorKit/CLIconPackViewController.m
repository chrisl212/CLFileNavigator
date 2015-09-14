//
//  ACIconPackViewController.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/31/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "ACUnzip.h"
#import "CLIconPackViewController.h"
#import "CLSettingsViewController.h"

@implementation CLIconPackViewController

- (instancetype)init
{
    if (self = [super initWithStyle:UITableViewStylePlain])
    {
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Icons" image:[UIImage imageNamed:@"medium_icons-50.png"] selectedImage:[UIImage imageNamed:@"medium_icons_filled-50.png"]];

        NSString *requestURLString = @"http://a-cstudios.com/CLFileNavigator/icons/icons.json";
        NSData *requestData = [NSData dataWithContentsOfURL:[NSURL URLWithString:requestURLString]];
        
        NSString *cachedFilePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"Icons.json"];
        if (!requestData)
        {
            requestData = [NSData dataWithContentsOfFile:cachedFilePath];
            if (!requestData)
                return self;
        }
        else
        {
            [requestData writeToFile:cachedFilePath atomically:YES];
        }
        
        self.tableViewItems = [NSJSONSerialization JSONObjectWithData:requestData options:kNilOptions error:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:(CLSettingsViewController *)[self.tabBarController.viewControllers[0] viewControllers][0] action:@selector(dismiss)];
    self.navigationItem.title = @"Icons";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *directoryPath = [[cachesDirectory stringByAppendingPathComponent:@"Icons"] stringByAppendingPathComponent:self.tableViewItems[indexPath.row][@"decompressedName"]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath])
        cell.accessoryView = nil, cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"installing_updates-50.png"]];
    
    NSString *iconsPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"IconsPath"];
    if ([directoryPath.lastPathComponent isEqualToString:iconsPath.lastPathComponent])
        cell.backgroundColor = [UIColor colorWithRed:0.8 green:1.0 blue:0.8 alpha:1.0];
    else
        cell.backgroundColor = [UIColor whiteColor];
    
    cell.textLabel.text = self.tableViewItems[indexPath.row][@"name"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *cellDictionary = self.tableViewItems[indexPath.row];
    
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *directoryPath = [[cachesDirectory stringByAppendingPathComponent:@"Icons"] stringByAppendingPathComponent:cellDictionary[@"decompressedName"]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath])
    {
        [[NSUserDefaults standardUserDefaults] setObject:[@"Icons" stringByAppendingPathComponent:cellDictionary[@"decompressedName"]] forKey:@"IconsPath"];
        [tableView reloadData];
    }
    else
    {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [(UIActivityIndicatorView *)cell.accessoryView startAnimating];
        
        dispatch_async(dispatch_queue_create("com.ac", NULL), ^{
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:cellDictionary[@"url"]]];
            NSString *tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"zip"]];
            [data writeToFile:tempFilePath atomically:YES];
            
            [ACUnzip decompressFiles:tempFilePath toDirectory:[cachesDirectory stringByAppendingPathComponent:@"Icons"] fileType:ACUnzipFileTypeZip completion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
            }];
        });
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
