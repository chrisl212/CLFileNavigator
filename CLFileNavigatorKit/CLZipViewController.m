//
//  CLZipViewController.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 10/16/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "CLZipViewController.h"

@implementation CLZipViewController
{
    NSDateFormatter *dateFormatter;
}

- (id)initWithFile:(NSString *)file
{
    if (self = [super init])
    {
        NSArray *files = [ACUnzip filesInArchive:file fileType:ACUnzipFileTypeZip error:nil];
        self.tableViewItems = files;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"CLFileCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    [self.view addSubview:self.tableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View Delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLFileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    CLFile *file = self.tableViewItems[indexPath.row];
    
    cell.fileNameLabel.text = file.fileName;
    cell.fileSizeLabel.text = [file fileSizeString];
    
    if (!dateFormatter)
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    }
    
    cell.fileIconImageView.image = [UIImage iconForFileType:file.fileType];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewItems.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLFile *f = self.tableViewItems[indexPath.row];
    NSLog(@"%@", f.filePath);
}

@end
