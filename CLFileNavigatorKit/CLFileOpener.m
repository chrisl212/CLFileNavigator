//
//  CLFileOpener.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/19/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "CLFileOpener.h"
#import "CLFile.h"
#import "CLDirectoryViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "CLImageViewController.h"
#import "CLWebViewController.h"
#import "CLAudioPlayerViewController.h"
#import "NSFileManager+CLFile.h"
#import "CLAudioItem.h"
#import "ACUnzip.h"
#import "CLTextEditorViewController.h"

@implementation CLFileOpener

+ (void)errorAlert:(NSError *)error
{
    ACAlertView *alertView = [ACAlertView alertWithTitle:@"Error" style:ACAlertViewStyleTextView delegate:nil buttonTitles:@[@"Close"]];
    alertView.textView.text = error.localizedDescription;
    [alertView show];
}

+ (void)openFileAtPath:(NSString *)path type:(NSInteger)type sender:(UIViewController *)vc
{
    id viewController;
    switch (type)
    {
        case CLFileTypeDirectory:
        {
            CLDirectoryViewController *directoryViewController = [[CLDirectoryViewController alloc] initWithDirectoryPath:path];
            [vc.navigationController pushViewController:directoryViewController animated:YES];
            return;
        }
            
        case CLFileTypeImage:
        {
            NSString *directoryPath = path.stringByDeletingLastPathComponent;
            
            NSError *error;
            NSArray *directoryFiles = [[NSFileManager defaultManager] filesFromDirectoryAtPath:directoryPath error:&error];
            if (error)
            {
                [self errorAlert:error];
                break;
            }
            
            BOOL pathInArray = NO;
            
            NSMutableArray *imageObjects = [NSMutableArray array];
            for (CLFile *file in directoryFiles)
            {
                if (file.fileType == CLFileTypeImage)
                {
                    NSDictionary *dict = @{CLImageFileNameKey: file.fileName, CLImageImageKey: [UIImage imageWithContentsOfFile:file.filePath]};
                    [imageObjects addObject:dict];
                    if ([file.filePath isEqualToString:path])
                        pathInArray = YES;
                }
            }
            
            UIImage *image = [UIImage imageWithContentsOfFile:path];
            if (!image)
                image = [[UIImage alloc] init];
            NSDictionary *dict = @{CLImageFileNameKey: path.lastPathComponent, CLImageImageKey: image};
            if (!pathInArray)
                [imageObjects addObject:dict];
            
            NSInteger idx = [imageObjects indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop)
                             {
                                 *stop = NO;
                                 NSString *fname = obj[CLImageFileNameKey];
                                 if (![fname isEqualToString:path.lastPathComponent])
                                     return NO;
                                 *stop = YES;
                                 return YES;
                             }];
            viewController = [[CLImageViewController alloc] initWithImages:imageObjects firstIndex:idx];
            break;
        }
            
        case CLFileTypeMovie:
        {
            MPMoviePlayerViewController *moviePlayerController = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:path]];
            [vc presentViewController:moviePlayerController animated:YES completion:nil];
            return;
        }
            
        case CLFileTypeMusic:
        {
            NSString *directoryPath = path.stringByDeletingLastPathComponent;
            
            NSError *error;
            NSArray *directoryFiles = [[NSFileManager defaultManager] filesFromDirectoryAtPath:directoryPath error:&error];
            if (error)
            {
                [self errorAlert:error];
                break;
            }
            
            NSMutableArray *musicObjects = [NSMutableArray array];
            
            for (CLFile *file in directoryFiles)
                if (file.fileType == CLFileTypeMusic)
                    [musicObjects addObject:[[CLAudioItem alloc] initWithFile:file]];
            
            CLAudioItem *audioItem = [[CLAudioItem alloc] initWithFilePath:path];
            if (![musicObjects containsObject:audioItem])
                [musicObjects addObject:audioItem];
            NSInteger firstIndex = [musicObjects indexOfObject:audioItem];
            viewController = [[CLAudioPlayerViewController alloc] initWithItems:musicObjects firstIndex:firstIndex];
            break;
        }
            
        case CLFileTypePDF:
        {
            viewController = [[CLWebViewController alloc] initWithFileAtPath:path];
            break;
        }
            
        case CLFileTypeRichText:
        {
            viewController = [[CLWebViewController alloc] initWithFileAtPath:path];
            break;
        }
            
        case CLFileTypeText:
        {
            NSString *directoryPath = path.stringByDeletingLastPathComponent;
            
            NSError *error;
            NSArray *directoryFiles = [[NSFileManager defaultManager] filesFromDirectoryAtPath:directoryPath error:&error];
            if (error)
            {
                [self errorAlert:error];
                break;
            }
            
            NSMutableArray *textFiles = [NSMutableArray array];
            for (CLFile *f in directoryFiles)
                if (f.fileType == CLFileTypeText)
                    [textFiles addObject:f];
            CLFile *file = [CLFile fileWithPath:path error:nil];
            if (![textFiles containsObject:file])
                [textFiles addObject:file];
            
            viewController = [[CLTextEditorViewController alloc] initWithFiles:textFiles firstIndex:[textFiles indexOfObject:file]];
            break;
        }
            
        case CLFileTypeUnknown:
        {
            ACAlertView *alertView = [ACAlertView alertWithTitle:@"Open as..." style:ACAlertViewStylePickerView delegate:nil buttonTitles:@[@"Cancel", @"Open"]];
            NSArray *pickerViewItems = @[@"Text File", @"Image File", @"Music File", @"Video File", @"PDF File", @"Web File", @"Compressed File", @"Rich Text File"];
            alertView.pickerViewItems = pickerViewItems;
            
            [alertView showWithSelectionHandler:^(ACAlertView *alertView, NSString *buttonTitle)
             {
                 if ([buttonTitle isEqualToString:@"Cancel"])
                     return;
                 
                 NSInteger index = [pickerViewItems indexOfObject:alertView.pickerViewButton.titleLabel.text];
                 NSArray *fileTypes = @[@(CLFileTypeText), @(CLFileTypeImage), @(CLFileTypeMusic), @(CLFileTypeMovie), @(CLFileTypePDF), @(CLFileTypeWeb), @(CLFileTypeZip), @(CLFileTypeRichText)];
                 CLFileType fileType = [fileTypes[index] integerValue];
                 
                 [self openFileAtPath:path type:fileType sender:vc];
                 [alertView dismiss];
             }];
            break;
        }
            
        case CLFileTypeWeb:
        {
            viewController = [[CLWebViewController alloc] initWithFileAtPath:path];
            break;
        }
            
        case CLFileTypeZip:
        {
            ACUnzipFileType fileType;
            
            NSString *fileExtension = path.pathExtension;
            
            if ([fileExtension caseInsensitiveCompare:@"zip"] == NSOrderedSame)
                fileType = ACUnzipFileTypeZip;
            else if ([fileExtension caseInsensitiveCompare:@"gz"] == NSOrderedSame)
                fileType = ACUnzipFileTypeGZip;
            else if ([fileExtension caseInsensitiveCompare:@"bz2"] == NSOrderedSame)
                fileType = ACUnzipFileTypeBZip2;
            else if ([fileExtension caseInsensitiveCompare:@"tar"] == NSOrderedSame)
                fileType = ACUnzipFileTypeTar;
            
            if (fileType == ACUnzipFileTypeGZip || fileType == ACUnzipFileTypeBZip2)
                [ACUnzip decompressFile:path fileType:fileType];
            else
            {
                NSString *newDirectoryPath = [path stringByDeletingPathExtension];
                [ACUnzip decompressFiles:path toDirectory:newDirectoryPath fileType:fileType];
            }
                
            break;
        }
            
        default:
            break;
    }
    
    if (!viewController)
        return;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    [vc presentViewController:navController animated:YES completion:nil];
}

+ (void)openFile:(CLFile *)file sender:(UIViewController *)vc
{
    [self openFileAtPath:file.filePath type:file.fileType sender:vc];
}

@end
