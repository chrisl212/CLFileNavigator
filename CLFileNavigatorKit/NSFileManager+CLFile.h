//
//  NSFileManager+CLFile.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/19/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLFile.h"

@interface NSFileManager (CLFile)

/**
  Creates an array containing CLFile objects representing the the items contained in the directory at @p path.
 
  @param path A string containing a valid path to a directory.
  @param err An error object to be created if an error occurs.
  @return An array of @p CLFile objects upon success, or nil if an error occurred.
 */
- (NSArray *)filesFromDirectoryAtPath:(NSString *)path error:(NSError **)err;

- (void)getFreeSpace:(CLFileSize *)freeSpace totalSpace:(CLFileSize *)totalSpace;
- (NSString *)formattedSizeStringForBytes:(CLFileSize)bytes;

@end
