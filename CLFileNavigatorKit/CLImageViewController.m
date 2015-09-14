//
//  CLImageViewController.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/19/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "CLImageViewController.h"

NSString *const CLImageFileNameKey = @"fname";
NSString *const CLImageImageKey = @"img";

@implementation CLImageViewController

- (instancetype)init
{
    return [self initWithImages:@[] firstIndex:0];
}

- (instancetype)initWithImage:(UIImage *)image
{
    NSDictionary *dict = @{CLImageFileNameKey: @"", CLImageImageKey: image};
    return [self initWithImages:@[dict] firstIndex:0];
}

- (id)initWithContentsOfFile:(NSString *)file
{
    NSDictionary *dict = @{CLImageFileNameKey: file.lastPathComponent, CLImageImageKey: [UIImage imageWithContentsOfFile:file]};
    return [self initWithImage:dict];
}

- (id)initWithImages:(NSArray *)images firstIndex:(NSInteger)idx
{
    if (self = [super init])
    {
        self.navigationController.navigationBar.translucent = NO;
        self.navigationController.toolbar.translucent = NO;
        
        UIImage *transparency = [UIImage imageNamed:@"transparency.jpg"];
        self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
        self.scrollView.contentSize = self.view.frame.size;
        self.scrollView.maximumZoomScale = 10.0;
        self.scrollView.minimumZoomScale = 1.0;
        self.scrollView.delegate = self;
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [self.scrollView addSubview:self.imageView];
        [self.view addSubview:self.scrollView];
        
        self.images = images;
        [self changeImageToIndex:idx];
        
        self.view.backgroundColor = [UIColor colorWithPatternImage:transparency];
        self.scrollView.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleBars)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoom)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTapGestureRecognizer];
    
    UISwipeGestureRecognizer *previousImageGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(previousImage)];
    previousImageGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:previousImageGestureRecognizer];
    
    UISwipeGestureRecognizer *nextImageGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextImage)];
    nextImageGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:nextImageGestureRecognizer];
    
}

- (void)zoom
{
    self.scrollView.zoomScale = self.scrollView.zoomScale+1.0;
}

- (void)toggleBars
{
    BOOL hidden = (self.navigationController.isNavigationBarHidden) ? NO : YES;
    [self.navigationController setToolbarHidden:hidden animated:YES];
    [self.navigationController setNavigationBarHidden:hidden animated:YES];
}

- (void)changeImageToIndex:(NSInteger)idx
{
    self.navigationItem.title = self.images[idx][CLImageFileNameKey];
    self.currentImage = self.images[idx][CLImageImageKey];
    self.imageView.image = self.currentImage;
}

- (void)nextImage
{
    NSInteger currentIndex = [self.images indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop)
                              {
                                  UIImage *image = obj[CLImageImageKey];
                                  
                                  *stop = NO;
                                  if (![image isEqual:self.currentImage])
                                      return NO;
                                  *stop = YES;
                                  return YES;
                              }];
    NSInteger queueCount = self.images.count;
    NSInteger nextIndex = (currentIndex == (queueCount-1)) ? 0 : currentIndex + 1;
    
    [self changeImageToIndex:nextIndex];
}

- (void)previousImage
{
    NSInteger currentIndex = [self.images indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop)
                              {
                                  UIImage *image = obj[CLImageImageKey];
                                  
                                  *stop = NO;
                                  if (![image isEqual:self.currentImage])
                                      return NO;
                                  *stop = YES;
                                  return YES;
                              }];
    NSInteger queueCount = self.images.count;
    NSInteger previousIndex = (currentIndex == 0) ? queueCount-1 : currentIndex-1;
    
    [self changeImageToIndex:previousIndex];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
    
    UIBarButtonItem *previousImage = [[UIBarButtonItem alloc] initWithTitle:@"<" style:UIBarButtonItemStylePlain target:self action:@selector(previousImage)];
    UIBarButtonItem *nextImage = [[UIBarButtonItem alloc] initWithTitle:@">" style:UIBarButtonItemStylePlain target:self action:@selector(nextImage)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.toolbarItems = @[previousImage, flex, nextImage];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

@end
