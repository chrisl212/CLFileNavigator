//
//  CLSettingsViewController.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/28/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "CLSettingsViewController.h"
#import "ACAlertView.h"

@implementation CLSettingsViewController

- (instancetype)init
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *fileTypesPath = [cachesDirectory stringByAppendingPathComponent:@"FileTypes.json"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:fileTypesPath])
        {
            NSString *bundleFileTypesPath = [[NSBundle mainBundle] pathForResource:@"FileTypes" ofType:@"json"];
            [[NSFileManager defaultManager] copyItemAtPath:bundleFileTypesPath toPath:fileTypesPath error:nil];
        }
        
        self.fileTypesArray = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:fileTypesPath] options:NSJSONReadingMutableContainers error:nil];
        
        self.tableViewItems = @[].mutableCopy;
        for (NSDictionary *fileTypeDictionary in self.fileTypesArray)
        {
            NSDictionary *tableViewItemDictionary = @{@"name" : fileTypeDictionary[@"name"], @"items" : @[@{@"name" : @"UTIs", @"items" : fileTypeDictionary[@"uti"]}, @{@"name" : @"Extensions", @"items" : fileTypeDictionary[@"extension"]}, @{@"name" : @"MIME Types", @"items" : fileTypeDictionary[@"mime"]}]};
            [self.tableViewItems addObject:tableViewItemDictionary];
        }
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"File Types" image:[UIImage imageNamed:@"file-50.png"] selectedImage:[UIImage imageNamed:@"file_filled-50.png"]];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.title = @"File Types";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
}

- (void)dismiss
{
    for (NSMutableDictionary *fileTypeDictionary in self.fileTypesArray)
    {
        NSDictionary *newDictionary;
        for (NSDictionary *dict in self.tableViewItems)
            if ([dict[@"name"] isEqualToString:fileTypeDictionary[@"name"]])
                newDictionary = dict;
        NSMutableArray *newUTIs = newDictionary[@"items"][0][@"items"];
        NSMutableArray *newExts = newDictionary[@"items"][1][@"items"];
        NSMutableArray *newMIMEs = newDictionary[@"items"][2][@"items"];
        [fileTypeDictionary setObject:newUTIs forKey:@"uti"];
        [fileTypeDictionary setObject:newExts forKey:@"extension"];
        [fileTypeDictionary setObject:newMIMEs forKey:@"mime"];
    }
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileTypesPath = [cachesDirectory stringByAppendingPathComponent:@"FileTypes.json"];
    
    NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:fileTypesPath append:NO];
    [outputStream open];
    [NSJSONSerialization writeJSONObject:self.fileTypesArray toStream:outputStream options:kNilOptions error:nil];
    [outputStream close];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableViewItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    
    cell.textLabel.text = self.tableViewItems[indexPath.row][@"name"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *items = self.tableViewItems[indexPath.row][@"items"];
    CLTypesEditorController *editorController = [[CLTypesEditorController alloc] initWithItems:&items];
    [self.navigationController pushViewController:editorController animated:YES];
}

@end

@implementation CLTypesEditorController

- (id)initWithItems:(NSMutableArray *__autoreleasing *)items
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.tableViewItems = *items;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableViewItems.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableViewItems[section][@"items"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.tableViewItems[section][@"name"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
    
    cell.textLabel.text = self.tableViewItems[indexPath.section][@"items"][indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [self.tableViewItems[indexPath.section][@"items"] removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    if (editing)
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createType)];
    }
    else
    {
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
    }
}

- (void)createType
{
    ACAlertView *alertView = [ACAlertView alertWithTitle:@"New Type" style:ACAlertViewStyleTextFieldAndPickerView delegate:nil buttonTitles:@[@"Cancel", @"Create"]];
    
    NSMutableArray *names = @[].mutableCopy;
    for (NSDictionary *dict in self.tableViewItems)
    {
        [names addObject:dict[@"name"]];
    }
    alertView.pickerViewItems = names;
    [alertView showWithSelectionHandler:^(ACAlertView *alert, NSString *buttonTitle)
     {
         [alert dismiss];
         if ([buttonTitle isEqualToString:@"Cancel"])
             return;
         NSString *newType = alert.textField.text;
         NSString *category = alert.pickerViewButton.titleLabel.text;
         
         for (NSDictionary *dict in self.tableViewItems)
         {
             if ([dict[@"name"] isEqualToString:category])
                 [dict[@"items"] addObject:newType];
         }
         [self.tableView reloadData];
     }];
}

@end
