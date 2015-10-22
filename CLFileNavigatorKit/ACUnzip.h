//
//  ACUnzip.h
//  ACFileNavigator
//
//  Created by Chris on 1/18/14.
//  Copyright (c) 2014 A and C Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <zlib.h>
#import "bzlib.h"
#import "NSFileManager+Tar.h"
#import "ACAlertView.h"

typedef void(^ACUnzipCompletion)();

typedef NS_ENUM(NSInteger, ACUnzipFileType)
{
    ACUnzipFileTypeGZip, //Decompress a gz file
    ACUnzipFileTypeBZip2, //Decompress a bz2 file
    ACUnzipFileTypeTar, //Decompress a tar file
    ACUnzipFileTypeLZMA, /* TODO: I'll get to this eventually... */
    ACUnzipFileTypeZip
};

@interface ACUnzip : NSObject

+ (BOOL)decompressFile:(NSString *)file fileType:(ACUnzipFileType)fileType; //Decompresses the file of type "fileType" at "file". Creates the new file by removing the gz or bz2 extension, unless it is a tar file. In that case, a new directory is created and the files are placed there.
+ (BOOL)decompressFiles:(NSString *)file toDirectory:(NSString *)path fileType:(ACUnzipFileType)fileType;
+ (BOOL)decompressFiles:(NSString *)file toDirectory:(NSString *)path fileType:(ACUnzipFileType)fileType completion:(ACUnzipCompletion)comp;
+ (NSArray *)filesInArchive:(NSString *)file fileType:(ACUnzipFileType)fileType error:(NSError **)err;

@end
