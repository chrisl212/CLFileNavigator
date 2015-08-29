//
//  UIImage+CLFile.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/19/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "UIImage+CLFile.h"

@implementation UIImage (CLFile)

+ (UIImage *)iconForFileType:(CLFileType)fileType
{
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
    NSString *iconFilePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"ico"]; //TODO: customizable icons
    return [UIImage imageWithContentsOfFile:iconFilePath];
}

@end
