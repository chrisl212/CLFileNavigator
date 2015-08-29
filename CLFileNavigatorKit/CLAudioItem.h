//
//  CLAudioItem.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/20/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@class CLFile;

@interface CLAudioItem : NSObject

@property (strong, nonatomic) NSString *filePath;
@property (strong, nonatomic) UIImage *albumArtworkImage;
@property (strong, nonatomic) MPMediaItemArtwork *albumArtwork;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *artist;
@property (strong, nonatomic) NSString *album;
@property (strong, nonatomic) NSString *year;

- (id)initWithFilePath:(NSString *)path;
- (id)initWithFile:(CLFile *)file;

@end
