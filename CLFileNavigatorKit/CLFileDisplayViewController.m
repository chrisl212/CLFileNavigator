//
//  CLFileDisplayViewController.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 9/27/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "CLFileDisplayViewController.h"

@implementation CLFileDisplayViewController
{
    UIImageView *iconImageView;
    UIColor *bgColor;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.canHide = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    /*
    NSArray *subviews = self.navigationController.view.subviews;
    self.navigationController.view = [[CLFileDisplayView alloc] initWithFrame:self.navigationController.view.bounds];
    for (UIView *v in subviews)
    {
        [self.navigationController.view addSubview:v];
    }
     */
    self.hidingCenter = CGPointMake(100.0, 100.0);
        
    UIBarButtonItem *hide = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"minimize.png"] style:UIBarButtonItemStylePlain target:self action:@selector(hide)];
    UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"close.png"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];

    self.navigationItem.rightBarButtonItems = (self.canHide) ? @[close, hide] : @[close];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.view.frame = [[UIScreen mainScreen] bounds];
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)hide
{
    bgColor = self.view.backgroundColor;
    if ([self.fileDisplayDelegate respondsToSelector:@selector(fileDisplayControllerShouldHide:)])
        [self.fileDisplayDelegate fileDisplayControllerShouldHide:self];
}

- (void)dismiss
{
    if (self.parentViewController.tabBarController)
        [self.parentViewController.tabBarController.tabBar setHidden:NO];
    if (self.presentingViewController)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIView *displayView = self.navigationController.view.superview;

    [UIView animateWithDuration:0.25 animations:^{
        displayView.frame = CGRectMake(0.0, keyWindow.frame.size.height, displayView.frame.size.width, displayView.frame.size.height);
    } completion:^(BOOL fi){
        if (fi)
            [displayView removeFromSuperview];
    }];
    
    [self.navigationController removeFromParentViewController];
    [self.fileDisplayDelegate fileDisplayControllerWasClosed:(CLFileDisplayViewController *)self.navigationController];
}

- (UIImage *)hidingIcon
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(50.0, 50.0), YES, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, 50.0, 50.0));
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)setHiding:(BOOL)hiding
{
    _hiding = hiding;
    CLFileDisplayView *displayView = (CLFileDisplayView *)self.navigationController.view.superview;
    [displayView setHiding:hiding];
    [displayView setMoving:NO];
    [displayView setController:self];

    self.navigationController.navigationBar.hidden = hiding;
    self.navigationController.toolbar.hidden = hiding;
    self.navigationController.view.userInteractionEnabled = !hiding;

    for (UIView *subview in self.view.subviews)
    {
        if ([subview respondsToSelector:@selector(setHidden:)])
            [subview setHidden:hiding];
    }
    self.view.backgroundColor = (hiding) ? [UIColor blackColor] : bgColor;
    displayView.layer.cornerRadius = (hiding) ? displayView.frame.size.height/2.0 : 0.0;
    displayView.clipsToBounds = YES;
    if (hiding)
    {
        iconImageView = [[UIImageView alloc] initWithFrame:displayView.frame];
        iconImageView.image = self.hidingIcon;
        [displayView addSubview:iconImageView];
    }
    else
    {
        [iconImageView removeFromSuperview];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

@implementation CLFileDisplayView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.hiding)
        return;
    CGAffineTransform scale = CGAffineTransformMakeScale(1.2, 1.2);
    [UIView animateWithDuration:0.1 animations:^{
        [self setTransform:scale];
    }];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.hiding)
    {
        self.moving = YES;
        UITouch *touch = [touches anyObject];
        CGPoint newCenter = [touch locationInView:self.superview];
        self.center = newCenter;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [UIView animateWithDuration:0.1 animations:^{
        [self setTransform:CGAffineTransformIdentity];
    }];
    if (self.hiding && !self.moving)
        [self.controller.fileDisplayDelegate fileDisplayControllerShouldUnhide:self.controller];
    else if (self.moving)
        self.moving = NO;
}

@end
