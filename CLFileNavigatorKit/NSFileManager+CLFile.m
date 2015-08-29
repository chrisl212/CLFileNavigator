//
//  NSFileManager+CLFile.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/19/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "NSFileManager+CLFile.h"

#define KB_SIZE 1024

@implementation NSFileManager (CLFile)

NSByteCountFormatter *byteCountFormatter;

- (NSArray *)filesFromDirectoryAtPath:(NSString *)path error:(NSError **)err
{
    BOOL isDir;
    if (![self fileExistsAtPath:path isDirectory:&isDir])
    {
        if (err)
            *err = [NSError errorWithDomain:[NSString stringWithFormat:@"No such file or directory %@", path] code:NSNotFound userInfo:nil];
        return nil;
    }
    if (!isDir)
    {
        if (err)
            *err = [NSError errorWithDomain:[NSString stringWithFormat:@"Item at path %@ is not a directory", path] code:-1 userInfo:nil];
        return nil;
    }
    
    NSMutableArray *files = [NSMutableArray array];
    
    NSArray *fileNames = [self contentsOfDirectoryAtPath:path error:err];
    
    for (NSString *name in fileNames)
    {
        CLFile *f = [CLFile fileWithPath:[path stringByAppendingPathComponent:name] error:nil];
        if (f)
            [files addObject:f];
    }
    
    return [NSArray arrayWithArray:files];
}

- (NSString *)formattedSizeStringForBytes:(CLFileSize)bytes
{
    if (!byteCountFormatter)
        byteCountFormatter = [[NSByteCountFormatter alloc] init];
    return [byteCountFormatter stringFromByteCount:bytes];
}

- (void)getFreeSpace:(CLFileSize *)freeSpace totalSpace:(CLFileSize *)totalSpace
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSDictionary *fileSystemAttributes = [self attributesOfFileSystemForPath:documentsDirectory error:nil];
    
    if (freeSpace)
        *freeSpace = [fileSystemAttributes[NSFileSystemFreeSize] unsignedLongLongValue];
    if (totalSpace)
        *totalSpace = [fileSystemAttributes[NSFileSystemSize] unsignedLongLongValue];
}

@end
