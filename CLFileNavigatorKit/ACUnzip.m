//
//  ACUnzip.m
//  ACFileNavigator
//
//  Created by Chris on 1/18/14.
//  Copyright (c) 2014 A and C Studios. All rights reserved.
//

#define BLOCKSIZE 32

#import "ACUnzip.h"
#import "unzip.h"
#import "CLDirectoryViewController.h"

@implementation ACUnzip

+ (BOOL)decompressFile:(NSString *)file fileType:(ACUnzipFileType)fileType
{
    BOOL prog = NO;
    if (fileType == ACUnzipFileTypeGZip || fileType == ACUnzipFileTypeZip)
        prog = YES;
    ACAlertView *alertView = [ACAlertView alertWithTitle:@"Extracting..." style:(prog) ? ACAlertViewStyleProgressView : ACAlertViewStyleSpinner delegate:nil buttonTitles:@[@"Hide"]];
    [alertView show];
    dispatch_async(dispatch_queue_create("com.acunzip", NULL), ^{
        switch (fileType)
        {
            case ACUnzipFileTypeGZip:
                g_unzip(file.UTF8String, (char *)[file stringByDeletingPathExtension].UTF8String);
                break;
                
            case ACUnzipFileTypeBZip2:
                bzip2_unzip(file.UTF8String, (char *)file.stringByDeletingPathExtension.UTF8String);
                break;
                
            case ACUnzipFileTypeTar:
                [self untar:file];
                break;
                
            case ACUnzipFileTypeLZMA:
                lzma_unzip(file.UTF8String, (char *)file.stringByDeletingPathExtension.UTF8String);
                break;
                
            default:
                break;
        }
    });
    return YES;
}

bool lzma_unzip(const char *in_file, char *out_file)
{
    ACAlertView *presentedAlertView;
    NSArray *windowSubviews = [UIApplication sharedApplication].keyWindow.subviews;
    for (ACAlertView *alertView in windowSubviews)
    {
        if ([alertView isKindOfClass:[ACAlertView class]])
        {
            presentedAlertView = alertView;
        }
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:out_file]])
        out_file = (char *)[[NSString stringWithUTF8String:out_file] stringByAppendingString:@".1"].UTF8String;
    
    //lzma
    
    return YES;
}

bool g_unzip(const char *in_file, char *out_file)
{
    ACAlertView *presentedAlertView;
    NSArray *windowSubviews = [UIApplication sharedApplication].keyWindow.subviews;
    for (ACAlertView *alertView in windowSubviews)
    {
        if ([alertView isKindOfClass:[ACAlertView class]])
        {
            presentedAlertView = alertView;
        }
    }
    FILE *fp = fopen(in_file, "rb");
    fseek(fp, 0L, SEEK_END);
    long sz = ftell(fp);
    fseek(fp, 0L, SEEK_SET);
    fseek(fp, sz - 4, SEEK_SET);
    UInt32 *buf = malloc(sizeof(UInt32) * 4);
    fread(buf, 4, 1, fp);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:out_file]])
        out_file = (char *)[[NSString stringWithUTF8String:out_file] stringByAppendingString:@".1"].UTF8String;
    gzFile inFile = gzopen(in_file, "rb");
    FILE *outFile = fopen(out_file, "wb");
    if (!inFile || !outFile)
        return NO;
    char buffer[BLOCKSIZE];
    int num_read = 0;
    long double progress = 0.0;
    while ((num_read = gzread(inFile, buffer, BLOCKSIZE)) > 0)
    {
        progress += BLOCKSIZE;
        dispatch_async(dispatch_get_main_queue(), ^{
            presentedAlertView.progressView.progress = progress/(*buf);
        });
        fwrite(buffer, 1, num_read, outFile);
    }
    gzclose(inFile);
    fclose(outFile);
    free(buf);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [presentedAlertView dismiss];
        [[NSNotificationCenter defaultCenter] postNotificationName:CLDirectoryViewControllerRefreshNotification object:nil];
    });
    return YES;
}

bool bzip2_unzip(const char *in_file, char *out_file_name)
{
    ACAlertView *presentedAlertView;
    NSArray *windowSubviews = [UIApplication sharedApplication].keyWindow.subviews;
    for (ACAlertView *alertView in windowSubviews)
    {
        if ([alertView isKindOfClass:[ACAlertView class]])
        {
            presentedAlertView = alertView;
        }
    }
    
    int error;
    char buffer[BLOCKSIZE];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:out_file_name]])
        out_file_name = (char *)[[NSString stringWithUTF8String:out_file_name] stringByAppendingString:@".1"].UTF8String;
    FILE *f = fopen(in_file, "rb");
    FILE *out_file = fopen(out_file_name, "wb");
    BZFILE *b = BZ2_bzReadOpen(&error, f, 0, 0, NULL, 0);
    do
    {
        NSInteger read = BZ2_bzRead(&error, b, buffer, BLOCKSIZE);
        fwrite(buffer, read, 1, out_file);
    } while(error != BZ_STREAM_END);
    BZ2_bzReadClose(&error, b);
    /*
    if ( (!buffer))
    {
        NSLog(@"%s", BZ2_bzerror(b, &error));
        return NO;
    }*/
    fclose(out_file);
    fclose(f);
    dispatch_sync(dispatch_get_main_queue(), ^{
        [presentedAlertView dismiss];
        [[NSNotificationCenter defaultCenter] postNotificationName:CLDirectoryViewControllerRefreshNotification object:nil];
    });
    return YES;
}

+ (BOOL)decompressFiles:(NSString *)file toDirectory:(NSString *)path fileType:(ACUnzipFileType)fileType
{
    return [self decompressFiles:file toDirectory:path fileType:fileType completion:nil];
}

+ (BOOL)decompressFiles:(NSString *)file toDirectory:(NSString *)path fileType:(ACUnzipFileType)fileType completion:(ACUnzipCompletion)comp
{
    ACAlertView *alertView = [ACAlertView alertWithTitle:@"Extracting..." style:ACAlertViewStyleProgressView delegate:nil buttonTitles:@[@"Hide"]];
    [alertView show];
    dispatch_async(dispatch_queue_create("com.acunzip", NULL), ^{
        BOOL success;
        if (fileType == ACUnzipFileTypeZip)
            success = [self unzip:file toPath:path];
        else
            success = [self untar:file];
        if (!success)
        {
            [alertView performSelectorOnMainThread:@selector(dismiss) withObject:nil waitUntilDone:NO];
            dispatch_async(dispatch_get_main_queue(), ^{
                ACAlertView *alert = [ACAlertView alertWithTitle:@"Failure" style:ACAlertViewStyleTextView delegate:nil buttonTitles:@[@"Close"]];
                alert.textView.text = @"The file is not a valid zip archive.";
                [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
            });
        }
        if (comp)
            comp();
    });
    return YES;
}

+ (BOOL)unzip:(NSString *)file toPath:(NSString *)path
{
    ACAlertView *presentedAlertView;
    NSArray *windowSubviews = [UIApplication sharedApplication].keyWindow.subviews;
    for (ACAlertView *alertView in windowSubviews)
    {
        if ([alertView isKindOfClass:[ACAlertView class]])
        {
            presentedAlertView = alertView;
        }
    }
    
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    unzFile zip = unzOpen(file.UTF8String);
    if (!zip)
        return NO;
    if (unzGoToFirstFile(zip) != UNZ_OK)
    {
        unzCloseCurrentFile(zip);
        unzClose(zip);
        return NO;
    }
    do
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            presentedAlertView.progressView.progress = 0.0;
        });
        unzOpenCurrentFile(zip);
        unz_file_info inf;
        char fileName[512];
        unzGetCurrentFileInfo(zip, &inf, fileName, 512, NULL, 0, NULL, 0);
        char buf[BLOCKSIZE];
        int read;
        NSString *filePath = [NSString stringWithUTF8String:fileName];
        NSMutableData *data = [NSMutableData data];
        if ([filePath rangeOfString:@"/"].location != NSNotFound)
        {
            NSString *directories = filePath;
            NSArray *comps = [filePath componentsSeparatedByString:@"/"];
            if (![[comps lastObject] isEqualToString:@""])
                directories = [filePath stringByDeletingLastPathComponent];
            if (![[NSFileManager defaultManager] fileExistsAtPath:directories])
                [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByAppendingPathComponent:directories] withIntermediateDirectories:YES attributes:nil error:nil];
        }
        while ((read = (unzReadCurrentFile(zip, buf, BLOCKSIZE))) > 0)
        {
            [data appendBytes:buf length:read];
            dispatch_async(dispatch_get_main_queue(), ^{
                presentedAlertView.progressView.progress = data.length/inf.uncompressed_size;
            });
        }
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [[NSDateComponents alloc] init];
        [components setDay:inf.tmu_date.tm_mday];
        [components setYear:inf.tmu_date.tm_year];
        [components setMonth:inf.tmu_date.tm_mon];
        [components setSecond:inf.tmu_date.tm_sec];
        [components setHour:inf.tmu_date.tm_hour];
        [components setMinute:inf.tmu_date.tm_min];
        NSDate *date = [calendar dateFromComponents:components];
        
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:filePath]])
            filePath = [filePath stringByAppendingString:@".1"];
        [[NSFileManager defaultManager] createFileAtPath:[path stringByAppendingPathComponent:filePath] contents:data attributes:@{NSFileModificationDate: date}];
        unzCloseCurrentFile(zip);
    } while (unzGoToNextFile(zip) != UNZ_END_OF_LIST_OF_FILE);
    unzClose(zip);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [presentedAlertView dismiss];
        [[NSNotificationCenter defaultCenter] postNotificationName:CLDirectoryViewControllerRefreshNotification object:nil];
    });
    
    return YES;
}

+ (BOOL)untar:(NSString *)path
{
    ACAlertView *presentedAlertView;
    NSArray *windowSubviews = [UIApplication sharedApplication].keyWindow.subviews;
    for (ACAlertView *alertView in windowSubviews)
    {
        if ([alertView isKindOfClass:[ACAlertView class]])
        {
            presentedAlertView = alertView;
        }
    }
    
    [[NSFileManager defaultManager] createFilesAndDirectoriesAtPath:path.stringByDeletingPathExtension withTarPath:path error:nil];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [presentedAlertView dismiss];
        [[NSNotificationCenter defaultCenter] postNotificationName:CLDirectoryViewControllerRefreshNotification object:nil];
    });
    return YES;
}

@end
