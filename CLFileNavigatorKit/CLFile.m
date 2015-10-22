//
//  CLFile.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/18/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "CLFile.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "NSFileManager+CLFile.h"
#import "ACAlertView.h"

#define KB_SIZE 1024

@implementation CLFile
{
    CLFileType fileType;
}

- (CLFileType)fileTypeForExtension:(NSString *)ext
{
    CLFileType retval = CLFileTypeUnknown;
    
    if (ext.length > 0)
    {
        NSString *UTI = (__bridge NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)ext, NULL);
        NSString *MIME = (__bridge NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
        
        NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *fileTypesPath = [cachesDirectory stringByAppendingPathComponent:@"FileTypes.json"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:fileTypesPath])
        {
            NSString *bundleFileTypesPath = [[NSBundle mainBundle] pathForResource:@"FileTypes" ofType:@"json"];
            [[NSFileManager defaultManager] copyItemAtPath:bundleFileTypesPath toPath:fileTypesPath error:nil];
        }
        
        NSError *error;
        NSArray *fileTypes = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:fileTypesPath] options:kNilOptions error:&error];
        if (error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                ACAlertView *errorAlert = [ACAlertView alertWithTitle:@"Error" style:ACAlertViewStyleTextView delegate:nil buttonTitles:@[@"Close"]];
                errorAlert.textView.text = error.localizedDescription;
                [errorAlert show];
            });
            
            return CLFileTypeUnknown;
        }
        
        for (NSDictionary *type in fileTypes)
        {
            NSArray *fileTypeExtensions = type[@"extension"];
            NSArray *fileTypeUTIs = type[@"uti"];
            NSArray *fileTypeMIMEs = type[@"mime"];
            CLFileType fType = [type[@"type"] intValue];
            
            for (NSString *extension in fileTypeExtensions)
                if ([extension caseInsensitiveCompare:ext] == NSOrderedSame)
                {
                    retval = fType;
                    return retval;
                }
            
            for (NSString *uti in fileTypeUTIs)
                if (UTTypeConformsTo((__bridge CFStringRef)UTI, (__bridge CFStringRef)uti))
                {
                    retval = fType;
                    return retval;
                }
            
            for (NSString *mimeType in fileTypeMIMEs)
                if ([mimeType isEqualToString:MIME])
                {
                    retval = fType;
                    return retval;
                }
        }
    }
    
    return retval;
}

+ (id)fileWithPath:(NSString *)path error:(NSError *__autoreleasing *)err
{
    return [[self alloc] initWithFilePath:path error:err];
}

- (id)initWithFilePath:(NSString *)path error:(NSError **)err
{
    if (self = [super init])
    {
        BOOL fileExists = NO, isDir = NO;
        
        fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
        
        if (!fileExists)
        {
            if (err)
                *err = [NSError errorWithDomain:[NSString stringWithFormat:@"File does not exist at path %@", path] code:NSNotFound userInfo:nil];
            return nil;
        }
        
        self.directory = isDir;
        self.filePath = path;
        self.fileExtension = [path pathExtension];
        self.fileName = [path lastPathComponent];
        
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:err];
        if (!fileAttributes)
            return nil;
        
        self.fileSize = [fileAttributes[NSFileSize] unsignedLongLongValue];
        self.creationDate = fileAttributes[NSFileCreationDate];
        self.lastModifiedDate = fileAttributes[NSFileModificationDate];
        
        if (self.isDirectory)
            fileType = CLFileTypeDirectory;
        else
            fileType = [self fileTypeForExtension:self.fileExtension];
    }
    return self;
}

- (NSString *)fileSizeString
{
    if (self.isDirectory)
        return @"";
    return [[NSFileManager defaultManager] formattedSizeStringForBytes:self.fileSize];
}

- (CLFileType)fileType
{
    return fileType;
}

- (void)setDirectory:(BOOL)directory
{
    _directory = directory;
    if (directory)
        fileType = CLFileTypeDirectory;
    else
        fileType = [self fileTypeForExtension:self.fileExtension];
}

- (void)setFileExtension:(NSString *)fileExtension
{
    _fileExtension = fileExtension;
    fileType = [self fileTypeForExtension:fileExtension];
}

- (NSArray *)directoryContents
{
    if (!self.isDirectory)
        return nil;
    
    NSMutableArray *dirContents = [NSMutableArray array];
    
    NSError *error;
    NSArray *contents = [[NSFileManager defaultManager] filesFromDirectoryAtPath:self.filePath error:&error];
    if (error)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            ACAlertView *errorAlert = [ACAlertView alertWithTitle:@"Error" style:ACAlertViewStyleTextView delegate:nil buttonTitles:@[@"Close"]];
            errorAlert.textView.text = error.localizedDescription;
            [errorAlert show];
        });
        
        return nil;
    }
    
    for (CLFile *file in contents)
    {
        if (!file.isDirectory)
        {
            [dirContents addObject:file];
            continue;
        }
        [dirContents addObjectsFromArray:file.directoryContents];
        [dirContents addObject:file];
    }
    
    return dirContents;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]])
        return [self.filePath isEqualToString:[(CLFile *)object filePath]];
    return [super isEqual:object];
}

- (NSURL *)fileURL
{
    return [NSURL fileURLWithPath:self.filePath];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"File Name: %@\\nFull Path: %@\\nFile Size: %@\\nIs Directory: %@\\n", self.fileName, self.filePath, self.fileSizeString, (self.isDirectory) ? @"Yes" : @"No"];
}

@end
