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
#import <id3v2tag.h>
#import <mpegfile.h>
#import <attachedpictureframe.h>
#import "NSFileManager+CLFile.h"

class fraction
{
    long num;
    long den;
    
public:
    fraction():num(0), den(0)
    {}
    
    fraction(long n, long d):num(n), den(d)
    {}
    
    fraction reduce()
    {
        fraction retval(num, den);
        long u = num, v = den, temp;
        
        while (v != 0)
        {
            temp = u % v;
            u = v;
            v = temp;
        }
        retval.num /= u;
        retval.den /= u;
        return retval;
    }
    
    long numerator()
    { return num; }
    
    long denominator()
    { return den; }
};

@implementation CLFilePropertiesViewController
{
    NSDateFormatter *dateFormatter;
}

- (id)initWithFile:(CLFile *)file
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.file = file;
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd/yyyy hh:mm a"];
        
        [self updateTableViewItems];
    }
    return self;
}

- (id)initWithFilePath:(NSString *)path
{
    return [self initWithFile:[CLFile fileWithPath:path error:nil]];
}

- (void)updateTableViewItems
{
    NSString *creationDateString = [dateFormatter stringFromDate:self.file.creationDate];
    NSString *modifiedDateString = [dateFormatter stringFromDate:self.file.lastModifiedDate];
    
    self.tableViewItems =
    @[@{@"name" : @"File Name", @"value" : self.file.fileName, @"type" : @"field", @"selector" : @"renameFile:"},
      @{@"name" : @"Creation Date", @"value" : creationDateString, @"type" : @"label"},
      @{@"name" : @"Last Modified", @"value" : modifiedDateString, @"type" : @"label"},
      @{@"name" : @"File Size", @"value" : self.file.fileSizeString, @"type" : @"label"}
      ].mutableCopy;
    
    switch (self.file.fileType)
    {
        case CLFileTypeDirectory:
        {
            [self.tableViewItems removeLastObject];
            NSArray *directoryContents = self.file.directoryContents;
            NSString *numberOfItems = [NSString stringWithFormat:@"%ld", (unsigned long)directoryContents.count];
            NSDictionary *directoryItemsInfo = @{@"name" : @"Items", @"value" : numberOfItems, @"type" : @"label"};
            CLFileSize totalSize = 0;
            for (CLFile *f in directoryContents)
            {
                totalSize += f.fileSize;
            }
            NSDictionary *directorySizeInfo = @{@"name" : @"Total Size", @"value" : [[NSFileManager defaultManager] formattedSizeStringForBytes:totalSize], @"type" : @"label"};
            
            [self.tableViewItems addObject:directoryItemsInfo];
            [self.tableViewItems addObject:directorySizeInfo];
            break;
        }
        case CLFileTypeImage:
        {
            UIImage *image = [UIImage imageWithContentsOfFile:self.file.filePath];
            NSString *dimensionsString = [NSString stringWithFormat:@"%.0Fx%.0F", image.size.width, image.size.height];
            [self.tableViewItems addObject:@{@"name" : @"Image Dimensions", @"value" : dimensionsString, @"type" : @"label"}];
            
            fraction raw((long)image.size.width, (long)image.size.height);
            fraction aspect = raw.reduce();
            NSString *aspectRatio = [NSString stringWithFormat:@"%ld:%ld", aspect.numerator(), aspect.denominator()];
            [self.tableViewItems addObject:@{@"name" : @"Aspect Ratio", @"value" : aspectRatio, @"type" : @"label"}];
            
            break;
        }
            
        case CLFileTypeMusic:
        {
            CLAudioItem *audioItem = [[CLAudioItem alloc] initWithFile:self.file];
            NSDictionary *artistInfo = @{@"name" : @"Artist", @"value" : audioItem.artist, @"type" : @"field", @"selector" : @"changeArtist:"};
            NSDictionary *albumInfo = @{@"name" : @"Album", @"value" : audioItem.album, @"type" : @"field", @"selector" : @"changeAlbum:"};
            NSDictionary *songNameInfo = @{@"name" : @"Title", @"value" : audioItem.title, @"type" : @"field", @"selector" : @"changeName:"};
            //NSDictionary *yearInfo = @{@"name" : @"Year", @"value" : audioItem.year, @"type" : @"field", @"selector" : @"changeYear:"}; TODO: implement
            [self.tableViewItems addObjectsFromArray:@[artistInfo, albumInfo, songNameInfo]];
            if ([self.file.fileExtension isEqualToString:@"mp3"])
            {
                NSDictionary *artworkInfo = @{@"name" : @"Album Artwork", @"value" : audioItem.albumArtworkImage, @"type" : @"image", @"selector" : @"changeArtwork"};
                [self.tableViewItems addObject:artworkInfo];
            }
            //moves onto movies, as the two share the duration property
        }
            
        case CLFileTypeMovie:
        {
            AVURLAsset *asset = [AVURLAsset assetWithURL:self.file.fileURL];
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

- (void)changeArtwork
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    TagLib::MPEG::File file(self.file.filePath.UTF8String);
    TagLib::ID3v2::FrameList frameList = file.ID3v2Tag(true)->frameListMap()["APIC"];
    TagLib::ID3v2::AttachedPictureFrame *picFrame;

    if (frameList.isEmpty())
    {
        picFrame = new TagLib::ID3v2::AttachedPictureFrame;
        picFrame->setMimeType("image/png");
        NSData *imageData = UIImagePNGRepresentation(image);
        TagLib::ByteVector bytes((const char *)imageData.bytes, (unsigned int)imageData.length);
        picFrame->setPicture(bytes);
        file.ID3v2Tag()->addFrame(picFrame);
    }
    for(TagLib::ID3v2::FrameList::ConstIterator it = frameList.begin(); it != frameList.end(); ++it)
    {
        picFrame = (TagLib::ID3v2::AttachedPictureFrame *)(*it);
        if (picFrame->mimeType() == "image/png")
        {
            NSData *imageData = UIImagePNGRepresentation(image);
            TagLib::ByteVector bytes((const char *)imageData.bytes, (unsigned int)imageData.length);
            picFrame->setPicture(bytes);
        }
        else if (picFrame->mimeType() == "image/jpeg")
        {
            NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
            TagLib::ByteVector bytes((const char *)imageData.bytes, (unsigned int)imageData.length);
            picFrame->setPicture(bytes);
        }
    }
    file.save();
    [self dismissViewControllerAnimated:YES completion:nil];
    [self updateTableViewItems];
    [self.tableView reloadData];
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
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
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
        [textField addTarget:self action:selector forControlEvents:UIControlEventEditingDidEnd];
        [textField addTarget:textField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    }
    else if ([cellType isEqualToString:@"image"])
    {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:cellDictionary[@"value"]];
        imageView.frame = CGRectMake(0, 0, 40.0, 40.0);
        cell.accessoryView = imageView;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    else
    {
        cell.detailTextLabel.text = cellDictionary[@"value"];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *cellDictionary = self.tableViewItems[indexPath.row];

    if ([cellDictionary[@"type"] isEqualToString:@"image"])
    {
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:NSSelectorFromString(cellDictionary[@"selector"])];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
