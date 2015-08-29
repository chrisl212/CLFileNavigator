//
//  ACZip.h
//  ACFileNavigator
//
//  Created by Chris on 1/20/14.
//  Copyright (c) 2014 A and C Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <zlib.h>
#import "bzlib.h"
#import "ACAlertView.h"
#import "NSFileManager+Tar.h"

typedef void(^ACZipCompletion)();

typedef NS_ENUM(NSInteger, ACZipCompressionType)
{
    ACZipCompressionTypeBzip2, //Compresses a file to a bz2 file
    ACZipCompressionTypeGzip, //Compresses a file to a gz file
    ACZipCompressionTypeZip, //Compresses files to a zip file
    ACZipCompressionTypeLZMA, //TODO: find a way to port this to iOS
    ACZipCompressionTypeTar //TODO: not yet supported
};

@interface ACZip : NSObject

+ (BOOL)compressFile:(NSString *)path compressionType:(ACZipCompressionType)type; //Compresses the file at "path" into a "type" file
+ (BOOL)compressFiles:(NSArray *)files destination:(NSString *)dest compressionType:(ACZipCompressionType)type; //TODO: implement this...
+ (BOOL)compressFiles:(NSArray *)files destination:(NSString *)dest compressionType:(ACZipCompressionType)type completion:(ACZipCompletion)comp; //TODO: implement this...

@end
