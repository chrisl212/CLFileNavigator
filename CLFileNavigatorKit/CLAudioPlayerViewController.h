//
//  CLAudioPlayerViewController.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/20/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "CLFileDisplayViewController.h"

@class CLFile, CLAudioItem;

@interface CLAudioPlayerViewController : CLFileDisplayViewController <AVAudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *albumArtworkImageView;
@property (weak, nonatomic) IBOutlet UISlider *timeSlider;
@property (weak, nonatomic) IBOutlet MPVolumeView *volumeSlider;
@property (weak, nonatomic) IBOutlet UILabel *timeElapsedLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeRemainingLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *fastForwardButton;
@property (weak, nonatomic) IBOutlet UIButton *rewindButton;
@property (strong, nonatomic) NSArray *queue;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) CLAudioItem *currentItem;

- (id)initWithFilePath:(NSString *)path;
- (id)initWithFile:(CLFile *)file;
- (id)initWithItems:(NSArray *)items firstIndex:(NSInteger)idx;//array of CLAudioItems
- (IBAction)play:(id)sender;
- (IBAction)changeSong:(id)sender;

@end
