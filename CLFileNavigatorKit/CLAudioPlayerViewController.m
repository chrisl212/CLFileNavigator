//
//  CLAudioPlayerViewController.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/20/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "CLAudioPlayerViewController.h"
#import "CLFile.h"
#import "CLAudioItem.h"
#import "ACAlertView.h"
#import "CLFilePropertiesViewController.h"

#define REWIND_TAG 0
#define FAST_FORWARD_TAG 1

@implementation CLAudioPlayerViewController
{
    NSTimer *infoUpdateTimer;
}

#pragma mark - Initialization

- (id)initWithFile:(CLFile *)file
{
    return [self initWithFilePath:file.filePath];
}

- (id)initWithFilePath:(NSString *)path
{
    return [self initWithItems:@[[[CLAudioItem alloc] initWithFilePath:path]] firstIndex:0];
}

- (id)initWithItems:(NSArray *)items firstIndex:(NSInteger)idx
{
    if (self = [super initWithNibName:@"CLAudioPlayerViewController" bundle:nil])
    {
        self.queue = items;
        
        self.currentItem = self.queue[idx];
        
        NSError *error;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
        if (error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                ACAlertView *errorAlert = [ACAlertView alertWithTitle:@"Error" style:ACAlertViewStyleTextView delegate:nil buttonTitles:@[@"Close"]];
                errorAlert.textView.text = error.localizedDescription;
                [errorAlert show];
            });
        }
        
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if (error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                ACAlertView *errorAlert = [ACAlertView alertWithTitle:@"Error" style:ACAlertViewStyleTextView delegate:nil buttonTitles:@[@"Close"]];
                errorAlert.textView.text = error.localizedDescription;
                [errorAlert show];
            });
        }
        
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    }
    return self;
}

#pragma mark - View Methods

- (NSString *)formattedTime:(NSTimeInterval)totalSeconds
{
    NSInteger seconds = (NSInteger)totalSeconds % 60;
    NSInteger minutes = ((NSInteger)totalSeconds / 60) % 60;
    
    return [NSString stringWithFormat:@"%ld:%02ld", (long)minutes, (long)seconds];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self becomeFirstResponder];

    self.volumeSlider.backgroundColor = [UIColor clearColor];
    [self.timeSlider addTarget:self action:@selector(seek) forControlEvents:UIControlEventValueChanged];
    
    UILongPressGestureRecognizer *rewindLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(rewindPress:)];
    UILongPressGestureRecognizer *fastForwardLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(fastForwardPress:)];
    
    [self.fastForwardButton addGestureRecognizer:fastForwardLongPress];
    [self.rewindButton addGestureRecognizer:rewindLongPress];

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 10), NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor lightGrayColor] CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, 1, 10));

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.timeSlider setThumbImage:newImage forState:UIControlStateNormal];
    
    
    infoUpdateTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(updateInformation) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:infoUpdateTimer forMode:NSRunLoopCommonModes];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(openFileProperties)];
}

- (void)openFileProperties
{
    CLFilePropertiesViewController *propertiesViewController = [[CLFilePropertiesViewController alloc] initWithFilePath:self.currentItem.filePath];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:propertiesViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self updateAudioPlayer];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismiss
{
    [self.audioPlayer stop];
    [infoUpdateTimer invalidate];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self resignFirstResponder];
    NSError *error;
    [[AVAudioSession sharedInstance] setActive:NO error:&error];
    if (error)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            ACAlertView *errorAlert = [ACAlertView alertWithTitle:@"Error" style:ACAlertViewStyleTextView delegate:nil buttonTitles:@[@"Close"]];
            errorAlert.textView.text = error.localizedDescription;
            [errorAlert show];
        });
    }
    
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    
    center.nowPlayingInfo = nil;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark -

- (void)updateInformation
{
    self.timeElapsedLabel.text = [self formattedTime:self.audioPlayer.currentTime];
    self.timeRemainingLabel.text = [self formattedTime:self.audioPlayer.duration-self.audioPlayer.currentTime];
    self.timeSlider.value = self.audioPlayer.currentTime/self.audioPlayer.duration;
    
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    NSMutableDictionary *songInfo = @{MPMediaItemPropertyArtist: self.currentItem.artist, MPMediaItemPropertyTitle: self.currentItem.title, MPMediaItemPropertyAlbumTitle: self.currentItem.album, MPMediaItemPropertyPlaybackDuration: @(self.audioPlayer.duration), MPNowPlayingInfoPropertyElapsedPlaybackTime: @(self.audioPlayer.currentTime)}.mutableCopy;
    
    if (self.currentItem.albumArtwork)
        songInfo[MPMediaItemPropertyArtwork] = self.currentItem.albumArtwork;

    center.nowPlayingInfo = [NSDictionary dictionaryWithDictionary:songInfo];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
    if (receivedEvent.type == UIEventTypeRemoteControl)
    {
        switch (receivedEvent.subtype)
        {
                
            case UIEventSubtypeRemoteControlPause:
                [self play:nil];
                break;
                
            case UIEventSubtypeRemoteControlPlay:
                [self play:nil];
                break;
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [self play:nil];
                break;
                
            case UIEventSubtypeRemoteControlPreviousTrack:
                [self previousSong];
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                [self nextSong];
                break;
                
            case UIEventSubtypeRemoteControlBeginSeekingBackward:
                //[self rewind:nil];
                break;
                
            case UIEventSubtypeRemoteControlBeginSeekingForward:
                //[self fastForward:nil];
                break;
                
            case UIEventSubtypeRemoteControlEndSeekingBackward:
                //[self rewind:nil];
                break;
                
            case UIEventSubtypeRemoteControlEndSeekingForward:
                //[self fastForward:nil];
                break;
                
            default:
                break;
        }
    }
}

#pragma mark - Controlling Playback Location

- (void)rewindPress:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan || sender.state == UIGestureRecognizerStateEnded)
        ;
}

- (void)fastForwardPress:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan || sender.state == UIGestureRecognizerStateEnded)
        ;
}

- (void)seek
{
    self.audioPlayer.currentTime = self.timeSlider.value*self.audioPlayer.duration;
}

- (void)play:(id)sender
{
    if (self.audioPlayer.isPlaying)
    {
        [self.audioPlayer pause];
        [self.playButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
    }
    else
    {
        [self.audioPlayer play];
        [self.playButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
    }
}

#pragma mark - Changing Songs

- (void)nextSong
{
    NSInteger currentIndex = [self.queue indexOfObject:self.currentItem];
    NSInteger queueCount = self.queue.count;
    NSInteger nextIndex = (currentIndex == (queueCount-1)) ? 0 : currentIndex + 1;
    
    self.currentItem = self.queue[nextIndex];
    [self updateAudioPlayer];
}

- (void)previousSong
{
    NSInteger currentIndex = [self.queue indexOfObject:self.currentItem];
    NSInteger queueCount = self.queue.count;
    NSInteger previousIndex = (currentIndex == 0) ? queueCount-1 : currentIndex-1;
    
    self.currentItem = self.queue[previousIndex];
    [self updateAudioPlayer];
}

- (void)changeSong:(id)sender
{
    if ([(UIButton *)sender tag] == REWIND_TAG)
    {
        [self previousSong];
    }
    else if ([(UIButton *)sender tag] == FAST_FORWARD_TAG)
    {
        [self nextSong];
    }
}

- (void)updateAudioPlayer
{
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:self.currentItem.filePath] error:nil];
    self.audioPlayer.delegate = self;
    [self.audioPlayer prepareToPlay];
    
    self.artistLabel.text = [NSString stringWithFormat:@"%@ - %@", self.currentItem.artist, self.currentItem.album];
    self.titleLabel.text = self.currentItem.title;
    self.albumArtworkImageView.image = self.currentItem.albumArtworkImage;
    
    [self play:nil];
}

#pragma mark - Audio Player Delegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self nextSong];
}

@end
