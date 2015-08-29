//
//  CLAudioItem.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/20/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "CLAudioItem.h"
#import "CLFile.h"
#import <AVFoundation/AVFoundation.h>

@implementation CLAudioItem

- (id)initWithFilePath:(NSString *)path
{
    if (self = [super init])
    {
        self.filePath = path;
        
        self.title = [path lastPathComponent];
        self.artist = @"";
        self.album = @"";
        self.year = @"";
        
        NSDictionary *itemMetadata = [self metadataForItem:path];
        if (itemMetadata[@"title"])
            self.title = itemMetadata[@"title"];
        if (itemMetadata[@"album"])
            self.album = itemMetadata[@"album"];
        if (itemMetadata[@"artist"])
            self.artist = itemMetadata[@"artist"];
        if (itemMetadata[@"year"])
            self.year = itemMetadata[@"year"];
        
        NSArray *albumArtworks = [self artworksForFileAtPath:path];
        if (albumArtworks.count > 0)
        {
            self.albumArtworkImage = albumArtworks[0];
            self.albumArtwork = [[MPMediaItemArtwork alloc] initWithImage:self.albumArtworkImage];
        }
        else
        {
            self.albumArtworkImage = [UIImage imageNamed:@"noart.png"];
            self.albumArtwork = nil;
        }
    }
    return self;
}

- (id)initWithFile:(CLFile *)file
{
    return [self initWithFilePath:file.filePath];
}

- (NSDictionary *)metadataForItem:(NSString *)path
{
    AVAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:path]];
    NSMutableDictionary *metadataDictionary = [NSMutableDictionary dictionary];
    
    for (NSString *format in [asset availableMetadataFormats])
    {
        for (AVMetadataItem *item in [asset metadataForFormat:format])
        {
            if ([item.commonKey isEqualToString:AVMetadataCommonKeyTitle])
            {
                [metadataDictionary setValue:(NSString *)item.value forKey:@"title"];
            }
            else if ([item.commonKey isEqualToString:AVMetadataCommonKeyAlbumName])
            {
                [metadataDictionary setValue:(NSString *)item.value forKey:@"album"];
            }
            else if ([item.commonKey isEqualToString:AVMetadataCommonKeyArtist])
            {
                [metadataDictionary setValue:(NSString *)item.value forKey:@"artist"];
            }
            //else if ([(NSString *)item.key isEqualToString:AVMetadataID3MetadataKeyYear])
            {
              //  [metadataDictionary setValue:(NSString *)item.value forKey:@"year"];
            }
        }
    }
    return metadataDictionary;
}

- (NSArray *)artworksForFileAtPath:(NSString *)path
{
    /* Gets album artwork for song */
    NSMutableArray *artworkImages = [NSMutableArray array];
    NSURL *u = [NSURL fileURLWithPath:path];
    AVURLAsset *a = [AVURLAsset URLAssetWithURL:u options:nil];
    NSArray *artworks = [AVMetadataItem metadataItemsFromArray:a.commonMetadata  withKey:AVMetadataCommonKeyArtwork keySpace:AVMetadataKeySpaceCommon];
    if (artworks)
    {
        for (AVMetadataItem *i in artworks)
        {
            // NSString *keySpace = i.keySpace;
            UIImage *image = [UIImage imageWithData:[i.value copyWithZone:nil]];
            if (image)
                [artworkImages addObject:image];
        }
    }
    return artworkImages;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[CLAudioItem class]])
        return [self.filePath isEqualToString:[(CLAudioItem *)object filePath]];
    return [super isEqual:object];
}

@end
