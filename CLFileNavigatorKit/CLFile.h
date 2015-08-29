//
//  CLFile.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/18/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef unsigned long long CLFileSize;

typedef NS_ENUM(NSInteger, CLFileType)
{
    CLFileTypeText = 0,
    CLFileTypeImage,
    CLFileTypeWeb,
    CLFileTypePDF,
    CLFileTypeZip,
    CLFileTypeDirectory,
    CLFileTypeMovie,
    CLFileTypeUnknown,
    CLFileTypeMusic,
    CLFileTypeRichText
};

@interface CLFile : NSObject

@property (strong, nonatomic) NSString *fileName;
@property (strong, nonatomic) NSString *filePath;
@property (strong, nonatomic) NSString *fileExtension;
@property (strong, nonatomic) NSDate *creationDate;
@property (strong, nonatomic) NSDate *lastModifiedDate;
@property (nonatomic) CLFileSize fileSize;
@property (nonatomic, getter=isDirectory) BOOL directory;

+ (id)fileWithPath:(NSString *)path error:(NSError **)err;
- (id)initWithFilePath:(NSString *)path error:(NSError **)err;
- (NSString *)fileSizeString;
- (CLFileType)fileType;
- (NSArray *)directoryContents;
- (NSURL *)fileURL;

@end
