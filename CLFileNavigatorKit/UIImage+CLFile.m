//
//  UIImage+CLFile.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/19/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "UIImage+CLFile.h"
#import "ACUnzip.h"

@implementation UIImage (CLFile)

+ (UIImage *)iconForFileType:(CLFileType)fileType
{
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];

    NSString *iconsDirectoryPath = [cachesDirectory stringByAppendingPathComponent:[[NSUserDefaults standardUserDefaults] objectForKey:@"IconsPath"]];
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"IconsPath"] || ![[NSFileManager defaultManager] fileExistsAtPath:iconsDirectoryPath])
    {
        iconsDirectoryPath = [cachesDirectory stringByAppendingPathComponent:@"Icons/Default Icons"];
        [[NSFileManager defaultManager] createDirectoryAtPath:iconsDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *defaultIconsPath = [[NSBundle mainBundle] pathForResource:@"DefaultIcons" ofType:@"zip"];
        [ACUnzip decompressFiles:defaultIconsPath toDirectory:[cachesDirectory stringByAppendingPathComponent:@"Icons"] fileType:ACUnzipFileTypeZip];
        [[NSUserDefaults standardUserDefaults] setObject:@"Icons/Default Icons" forKey:@"IconsPath"];
    }
    
    NSString *fileName;
    
    switch (fileType)
    {
        case CLFileTypeDirectory:
            fileName = @"dir";
            break;
            
        case CLFileTypeUnknown:
            fileName = @"unk";
            break;
            
        case CLFileTypeImage:
            fileName = @"pic";
            break;
            
        case CLFileTypeMovie:
            fileName = @"mov";
            break;
        
        case CLFileTypeMusic:
            fileName = @"mp3";
            break;
            
        case CLFileTypePDF:
            fileName = @"pdf";
            break;
            
        case CLFileTypeRichText:
            fileName = @"rtf";
            break;
            
        case CLFileTypeText:
            fileName = @"txt";
            break;
            
        case CLFileTypeWeb:
            fileName = @"htm";
            break;
            
        case CLFileTypeZip:
            fileName = @"zip";
            break;
            
        default:
            fileName = @"unk";
            break;
    }
    NSString *iconFilePath = [iconsDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", fileName, ([[NSFileManager defaultManager] fileExistsAtPath:[iconsDirectoryPath stringByAppendingPathComponent:@"dir.ico"]]) ? @"ico" : @"png"]];
    return [UIImage imageWithContentsOfFile:iconFilePath];
}

@end
