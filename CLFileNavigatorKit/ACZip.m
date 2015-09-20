//
//  ACZip.m
//  ACFileNavigator
//
//  Created by Chris on 1/20/14.
//  Copyright (c) 2014 A and C Studios. All rights reserved.
//

#define MAXFILENAME 1024
#define BLOCKSIZE 512

#import <sys/stat.h>
#import "CLFile.h"
#import "ACZip.h"
#import "zip.h"
#import "CLDirectoryViewController.h"

@implementation ACZip

+ (BOOL)compressFile:(NSString *)path compressionType:(ACZipCompressionType)type
{
    ACAlertView *alert = [ACAlertView alertWithTitle:@"Compressing..." style:ACAlertViewStyleProgressView delegate:nil buttonTitles:@[@"Hide"]];
    [alert show];
    dispatch_async(dispatch_queue_create("com.aczip", NULL), ^{
        switch (type)
        {
            case ACZipCompressionTypeGzip:
                compress_gz(path.UTF8String, [path stringByAppendingPathExtension:@"gz"].UTF8String);
                break;
                
            case ACZipCompressionTypeBzip2:
                compress_bz2(path.UTF8String, [path stringByAppendingPathExtension:@"bz2"].UTF8String);
                break;
                
            case ACZipCompressionTypeZip:
                [self zipFiles:@[path] toDir:[path.stringByDeletingPathExtension stringByAppendingPathExtension:@"zip"]];
                break;
                
            case ACZipCompressionTypeTar:
                // TODO: Everything for tar
                break;
                
            default:
                break;
        }
    });
    return YES;
}

+ (BOOL)compressFiles:(NSArray *)files destination:(NSString *)dest compressionType:(ACZipCompressionType)type
{
    return [self compressFiles:files destination:dest compressionType:type completion:nil];
}

+ (BOOL)compressFiles:(NSArray *)files destination:(NSString *)dest compressionType:(ACZipCompressionType)type completion:(ACZipCompletion)comp
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        ACAlertView *alert = [ACAlertView alertWithTitle:@"Compressing..." style:ACAlertViewStyleProgressView delegate:nil buttonTitles:@[@"Hide"]];
        [alert show];
    });
    dispatch_async(dispatch_queue_create("com.aczip", NULL), ^{
        switch (type)
        {
            case ACZipCompressionTypeZip:
                [self zipFiles:files toDir:dest];
                break;
                
            case ACZipCompressionTypeTar:
                //TODO: Everything for tar
                break;
                
            default:
                break;
        }
        if (comp)
            comp();
    });
    return YES;
}

bool compress_gz(const char *path, const char *dest)
{
    ACAlertView *alertView;
    for (ACAlertView *alert in [UIApplication sharedApplication].keyWindow.subviews)
    {
        if ([alert isKindOfClass:[ACAlertView class]])
        {
            if (alert.alertViewStyle == ACAlertViewStyleProgressView)
                alertView = alert;
        }
    }
    
    FILE *orig = fopen(path, "r");
    long double sz;
    fseek(orig, 0L, SEEK_END);
    sz = ftell(orig);
    fseek(orig, 0L, SEEK_SET);
    gzFile file = gzopen(dest, "wb");
    char buf[BLOCKSIZE + 1];
    long double final = 0;
    long read = 0;
    
    while ((read = fread(buf, 1, BLOCKSIZE, orig)) > 0)
    {
        final += read;
        gzwrite(file, buf, (unsigned int)read);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (alertView)
                alertView.progressView.progress = final/sz;
        });
    }
    fclose(orig);
    gzclose(file);
    dispatch_async(dispatch_get_main_queue(), ^{
        [alertView dismiss];
        [[NSNotificationCenter defaultCenter] postNotificationName:CLDirectoryViewControllerRefreshNotification object:nil];
    });
    if (final == sz)
        return YES;
    else
        return NO;
}

bool compress_bz2(const char *path, const char *dest)
{
    ACAlertView *alertView;
    for (ACAlertView *alert in [UIApplication sharedApplication].keyWindow.subviews)
    {
        if ([alert isKindOfClass:[ACAlertView class]])
        {
            if (alert.alertViewStyle == ACAlertViewStyleProgressView)
                alertView = alert;
        }
    }
    
    BZFILE *file = BZ2_bzopen(dest, "wb");
    FILE *orig = fopen(path, "rb");
    long double size;
    fseek(orig, 0L, SEEK_END);
    size = ftell(orig);
    fseek(orig, 0L, SEEK_SET);
    
    char buf[BLOCKSIZE];
    long double read;
    long double total = 0;
    while ((read = fread(buf, 1, BLOCKSIZE, orig)) > 0)
    {
        total += read;
        BZ2_bzwrite(file, buf, read);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (alertView)
                alertView.progressView.progress = total/size;
        });
    }
    
    fclose(orig);
    BZ2_bzclose(file);
    dispatch_async(dispatch_get_main_queue(), ^{
        [alertView dismiss];
        [[NSNotificationCenter defaultCenter] postNotificationName:CLDirectoryViewControllerRefreshNotification object:nil];
    });
    if (total == size)
        return YES;
    else
        return NO;
}

uLong filetime(const char *filename, tm_zip *tmzip, uLong *dostime)
{
    int ret = 0;
    struct stat s = {0};
    struct tm* filedate;
    time_t tm_t = 0;
    
    if (strcmp(filename,"-") != 0)
    {
        char name[MAXFILENAME+1];
        int len = (int)strlen(filename);
        if (len > MAXFILENAME)
            len = MAXFILENAME;
        
        strncpy(name, filename, MAXFILENAME - 1);
        name[MAXFILENAME] = 0;
        
        if (name[len - 1] == '/')
            name[len - 1] = 0;
        
        /* not all systems allow stat'ing a file with / appended */
        if (stat(name,&s) == 0)
        {
            tm_t = s.st_mtime;
            ret = 1;
        }
    }
    
    filedate = localtime(&tm_t);
    
    tmzip->tm_sec  = filedate->tm_sec;
    tmzip->tm_min  = filedate->tm_min;
    tmzip->tm_hour = filedate->tm_hour;
    tmzip->tm_mday = filedate->tm_mday;
    tmzip->tm_mon  = filedate->tm_mon ;
    tmzip->tm_year = filedate->tm_year;
    return ret;
}

+ (void)zip_add_dir:(zipFile)zip dir:(CLFile *)dir root:(BOOL)root total:(NSString *)tot compressed:(CGFloat *)comp totalCount:(CGFloat)totalCount alert:(ACAlertView *)al
{
    if (root)
    {
        tot = dir.fileName;
    }
    
    for (CLFile *__strong sub in dir.directoryContents)
    {
        if (sub.isDirectory)
        {
            sub = [[CLFile alloc] initWithFilePath:sub.filePath error:nil];
            NSString *nextRoot = [tot stringByAppendingPathComponent:sub.fileName];
            [self zip_add_dir:zip dir:sub root:NO total:nextRoot compressed:comp totalCount:totalCount alert:al];
        }
        else
        {
            zip_fileinfo inf;
            filetime(sub.filePath.UTF8String, &inf.tmz_date, &inf.dosDate);
            zipOpenNewFileInZip(zip, [[tot stringByAppendingPathComponent:sub.fileName] UTF8String], &inf, NULL, 0, NULL, 0, NULL, Z_DEFLATED, Z_DEFAULT_COMPRESSION);
            NSData *data = [NSData dataWithContentsOfFile:sub.filePath];
            zipWriteInFileInZip(zip, data.bytes, (unsigned int)data.length);
            zipCloseFileInZip(zip);
            (*comp)++;
            dispatch_async(dispatch_get_main_queue(), ^{
                al.progressView.progress = (*comp)/totalCount;
            });
        }
    }
}

+ (NSInteger)get_file_count:(CLFile *)dir root:(BOOL)root total:(NSString *)tot
{
    NSInteger retVal = 0;
    if (root)
    {
        tot = dir.fileName;
    }
    
    for (CLFile *__strong sub in dir.directoryContents)
    {
        if (sub.isDirectory)
        {
            sub = [CLFile fileWithPath:sub.filePath error:nil];
            NSString *nextRoot = [tot stringByAppendingPathComponent:sub.fileName];
            retVal += [self get_file_count:sub root:NO total:nextRoot];
        }
        else
        {
            retVal++;
        }
    }
    return retVal;
}

+ (void)zipFiles:(NSArray *)files toDir:(NSString *)dest
{
    ACAlertView *alertView;
    for (UIView *view in [UIApplication sharedApplication].keyWindow.subviews)
    {
        if ([view isKindOfClass:[ACAlertView class]] && [[(ACAlertView *)view titleLabel].text isEqualToString:@"Compressing..."])
            alertView = (ACAlertView *)view;
    }
    
    CGFloat totalCount = files.count;
    CGFloat compressed = 0.0;
    zipFile zip = zipOpen(dest.UTF8String, APPEND_STATUS_CREATE);
    for (NSString *path in files)
    {
        CLFile *f = [CLFile fileWithPath:path error:nil];
        if (f.isDirectory)
        {
            NSString *total;
            totalCount += [self get_file_count:f root:YES total:total];
            [self zip_add_dir:zip dir:f root:YES total:total compressed:&compressed totalCount:totalCount alert:alertView];
            dispatch_async(dispatch_get_main_queue(), ^{
                alertView.progressView.progress = compressed/totalCount;
            });
        }
        else
        {
            NSData *data = [NSData dataWithContentsOfFile:path];
            zip_fileinfo inf = {0};
            filetime(path.UTF8String, &inf.tmz_date, &inf.dosDate);
            int res = zipOpenNewFileInZip(zip, path.lastPathComponent.UTF8String, &inf, NULL, 0, NULL, 0, NULL, Z_DEFLATED, Z_DEFAULT_COMPRESSION);
            if (res != ZIP_OK)
                puts("ERROR");
            res = zipWriteInFileInZip(zip, data.bytes, (unsigned int)data.length);
            zipCloseFileInZip(zip);
            if (res != ZIP_OK)
                puts("ERROR");
            compressed++;
            dispatch_async(dispatch_get_main_queue(), ^{
                alertView.progressView.progress = compressed/totalCount;
            });
        }
    }
    zipClose(zip, NULL);
    dispatch_sync(dispatch_get_main_queue(), ^{
        [alertView dismiss];
        [[NSNotificationCenter defaultCenter] postNotificationName:CLDirectoryViewControllerRefreshNotification object:nil];
    });
}

@end
