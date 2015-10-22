//
//  CLMoviePlayerViewController.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 9/13/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "CLMoviePlayerViewController.h"
#import "CLFile.h"

@interface CLMoviePlayerViewController ()

@property (strong, nonatomic) MPMoviePlayerController *moviePlayerController;

@end

@implementation CLMoviePlayerViewController

- (id)initWithFile:(CLFile *)file
{
    return [self initWithFilePath:file.filePath];
}

- (id)initWithFilePath:(NSString *)path
{
    if (self = [super init])
    {
        self.canHide = NO;
        self.moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:path]];
        self.navigationItem.title = path.lastPathComponent;
        
        self.moviePlayerController.view.frame = self.view.bounds;
        self.moviePlayerController.view.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds) - 64.0);
        [self.view addSubview:self.moviePlayerController.view];
        [self.moviePlayerController play];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBar.opaque = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
}

- (void)hideBars
{
    BOOL hidden = (self.navigationController.isNavigationBarHidden) ? NO : YES;
    [self.navigationController setNavigationBarHidden:hidden animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
