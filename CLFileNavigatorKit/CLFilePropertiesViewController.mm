//
//  CLFilePropertiesViewController.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/28/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "CLFilePropertiesViewController.h"
#import "CLFile.h"
#import "CLAudioItem.h"
#import <AVFoundation/AVFoundation.h>
#import <fileref.h>

@implementation CLFilePropertiesViewController

- (id)initWithFile:(CLFile *)file
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.file = file;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd/yyyy hh:mm a"];
        
        NSString *creationDateString = [dateFormatter stringFromDate:file.creationDate];
        NSString *modifiedDateString = [dateFormatter stringFromDate:file.lastModifiedDate];
        
        self.tableViewItems =
    @[@{@"name" : @"File Name", @"value" : self.file.fileName, @"type" : @"field", @"selector" : @"renameFile:"},
    @{@"name" : @"Creation Date", @"value" : creationDateString, @"type" : @"label"},
    @{@"name" : @"Last Modified", @"value" : modifiedDateString, @"type" : @"label"},
    @{@"name" : @"File Size", @"value" : file.fileSizeString, @"type" : @"label"}
                                ].mutableCopy;
        
        switch (file.fileType)
        {
            case CLFileTypeImage:
            {
                UIImage *image = [UIImage imageWithContentsOfFile:file.filePath];
                NSString *dimensionsString = [NSString stringWithFormat:@"%.0Fx%.0F", image.size.width, image.size.height];
                [self.tableViewItems addObject:@{@"name" : @"Image Dimensions", @"value" : dimensionsString, @"type" : @"label"}];
                break;
            }
                
            case CLFileTypeMusic:
            {
                CLAudioItem *audioItem = [[CLAudioItem alloc] initWithFile:file];
                NSDictionary *artistInfo = @{@"name" : @"Artist", @"value" : audioItem.artist, @"type" : @"field", @"selector" : @"changeArtist:"};
                NSDictionary *albumInfo = @{@"name" : @"Album", @"value" : audioItem.album, @"type" : @"field", @"selector" : @"changeAlbum:"};
                NSDictionary *songNameInfo = @{@"name" : @"Title", @"value" : audioItem.title, @"type" : @"field", @"selector" : @"changeName:"};
                //NSDictionary *yearInfo = @{@"name" : @"Year", @"value" : audioItem.year, @"type" : @"field", @"selector" : @"changeYear:"}; TODO: implement
                [self.tableViewItems addObjectsFromArray:@[artistInfo, albumInfo, songNameInfo]];
                //moves onto movies, as the two share the duration property
            }
                
            case CLFileTypeMovie:
            {
                AVURLAsset *asset = [AVURLAsset assetWithURL:file.fileURL];
                CMTime durationTime = asset.duration;
                CGFloat seconds = CMTimeGetSeconds(durationTime);
                NSDateComponentsFormatter *formatter = [[NSDateComponentsFormatter alloc] init];
                formatter.allowedUnits =  NSCalendarUnitMinute | NSCalendarUnitSecond;
                formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
                formatter.unitsStyle = NSDateComponentsFormatterUnitsStylePositional;
                [self.tableViewItems addObject:@{@"name" : @"Duration", @"value" : [formatter stringFromTimeInterval:seconds], @"type" : @"label"}];
                break;
            }
                
            default:
                break;
        }

    }
    return self;
}

- (id)initWithFilePath:(NSString *)path
{
    return [self initWithFile:[CLFile fileWithPath:path error:nil]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
    self.navigationItem.title = @"Properties";
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)renameFile:(UITextField *)sender
{
    NSString *newFileName = sender.text;
    NSString *newFilePath = [self.file.filePath.stringByDeletingLastPathComponent stringByAppendingPathComponent:newFileName];
    [[NSFileManager defaultManager] moveItemAtPath:self.file.filePath toPath:newFilePath error:nil];
    self.file = [CLFile fileWithPath:newFilePath error:nil];
}

- (void)changeTag:(NSString *)type value:(NSString *)val
{


}

- (void)changeArtist:(UITextField *)sender
{
    TagLib::FileRef f(self.file.filePath.UTF8String);
    TagLib::String s((const char *)[sender.text cStringUsingEncoding:NSISOLatin1StringEncoding]);
    f.tag()->setArtist(s);
    f.save();
}

- (void)changeAlbum:(UITextField *)sender
{
    TagLib::FileRef f(self.file.filePath.UTF8String);
    TagLib::String s((const char *)[sender.text cStringUsingEncoding:NSISOLatin1StringEncoding]);
    f.tag()->setAlbum(s);
    f.save();
}

- (void)changeName:(UITextField *)sender
{
    TagLib::FileRef f(self.file.filePath.UTF8String);
    TagLib::String s((const char *)[sender.text cStringUsingEncoding:NSISOLatin1StringEncoding]);
    f.tag()->setTitle(s);
    f.save();
}

- (void)changeYear:(UITextField *)sender
{
    TagLib::FileRef f(self.file.filePath.UTF8String);
    f.tag()->setYear((uint)[sender.text intValue]);
    f.save();//nnot correctly implemented
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
    
    NSDictionary *cellDictionary = self.tableViewItems[indexPath.row];
    
    cell.textLabel.text = cellDictionary[@"name"];
    
    NSString *cellType = cellDictionary[@"type"];
    
    if ([cellType isEqualToString:@"field"])
    {
        cell.detailTextLabel.hidden = YES;
        [[cell viewWithTag:3] removeFromSuperview];
        UITextField *textField = [[UITextField alloc] init];
        textField.tag = 3;
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:textField];
        [cell addConstraint:[NSLayoutConstraint constraintWithItem:textField attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:cell.textLabel attribute:NSLayoutAttributeTrailing multiplier:1 constant:8]];
        [cell addConstraint:[NSLayoutConstraint constraintWithItem:textField attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeTop multiplier:1 constant:8]];
        [cell addConstraint:[NSLayoutConstraint constraintWithItem:textField attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:-8]];
        [cell addConstraint:[NSLayoutConstraint constraintWithItem:textField attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeTrailing multiplier:1 constant:-16]];
        textField.textAlignment = NSTextAlignmentRight;
        textField.text = cellDictionary[@"value"];
        
        SEL selector = NSSelectorFromString(cellDictionary[@"selector"]);
        [textField addTarget:self action:selector forControlEvents:UIControlEventEditingDidEndOnExit];
    }
    else
    {
        cell.detailTextLabel.text = cellDictionary[@"value"];
    }
    
    return cell;
}

@end
