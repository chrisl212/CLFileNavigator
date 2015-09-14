//
//  ACAlertView.m
//  ACFileNavigator
//
//  Created by Chris on 1/19/14.
//  Copyright (c) 2014 A and C Studios. All rights reserved.
//

#import "ACAlertView.h"

@implementation ACAlertView

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (id)initWithTitle:(NSString *)title style:(ACAlertViewStyle)style delegate:(id<ACAlertViewDelegate>)delegate buttonTitles:(NSArray *)titles
{
    if (self = [super init])
    {
        self.delegate = delegate;
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationChanged)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        CGRect alertFrame, progressViewFrame;
        CGPoint labelCenter;
        NSTextAlignment alignment;
        self.alertViewStyle = style;
        self.pickerViewItems = @[@""];
        
        switch (style)
        {
            case ACAlertViewStyleTextView:
                alertFrame = CGRectMake(0, 0, 250, 175);
                labelCenter = CGPointMake(CGRectGetMidX(alertFrame), 20);
                alignment = NSTextAlignmentCenter;
                self.frame = alertFrame;
                
                self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 240, 90)];
                self.textView.center = self.center;
                self.textView.editable = NO;
                self.textView.textColor = [UIColor whiteColor];
                self.textView.backgroundColor = [UIColor clearColor];
                self.textView.font = [UIFont systemFontOfSize:18.0];
                [self addSubview:self.textView];
                break;
                
            case ACAlertViewStyleProgressView:
                alertFrame = CGRectMake(0, 0, 200, 175);
                labelCenter = CGPointMake(CGRectGetMidX(alertFrame), 20);
                alignment = NSTextAlignmentCenter;
                progressViewFrame = CGRectMake(0, 0, 90.0, 90.0);
                self.frame = alertFrame;
                
                self.progressView = [[ACCircularProgressView alloc] initWithFrame:progressViewFrame];
                self.progressView.progress = 0.0;
                self.progressView.center = self.center;
                self.progressView.color = [UIColor whiteColor];
                self.progressView.backgroundColor = [UIColor clearColor];
                [self addSubview:self.progressView];
                break;
                
            case ACAlertViewStyleSpinner:
            {
                CGFloat height = 50.0;
                if (titles.count > 0)
                    height = 90.0;
                alertFrame = CGRectMake(0, 0, 200, height);
                labelCenter = CGPointMake(CGRectGetMidX(alertFrame), CGRectGetMidY(alertFrame));
                alignment = NSTextAlignmentLeft;
                self.frame = alertFrame;
                
                self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
                self.spinner.center = CGPointMake(170, CGRectGetMidY(alertFrame));
                [self.spinner startAnimating];
                [self addSubview:self.spinner];
                break;
            }
            
            case ACAlertViewStyleTextField:
                alertFrame = CGRectMake(0, 0, 250, 125);
                labelCenter = CGPointMake(CGRectGetMidX(alertFrame), 20);
                alignment = NSTextAlignmentCenter;
                self.frame = alertFrame;

                self.textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 225, 40)];
                self.textField.center = self.center;
                self.textField.borderStyle = UITextBorderStyleLine;
                self.textField.backgroundColor = [UIColor whiteColor];
                [self.textField addTarget:self.textField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
                [self addSubview:self.textField];
                break;
                
            case ACAlertViewStylePickerView:
                alertFrame = CGRectMake(0, 0, 250, 125);
                labelCenter = CGPointMake(CGRectGetMidX(alertFrame), 20);
                alignment = NSTextAlignmentCenter;
                self.frame = alertFrame;
                
                self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)];
                self.pickerView.delegate = self;
                self.pickerView.dataSource = self;
                self.pickerView.hidden = NO;
                self.pickerView.backgroundColor = [UIColor whiteColor];
                [[UIApplication sharedApplication].keyWindow addSubview:self.pickerView];
                
                self.pickerViewButton = [UIButton buttonWithType:UIButtonTypeSystem];
                self.pickerViewButton.frame = CGRectMake(0, 0, 320, 40);
                self.pickerViewButton.center = self.center;
                [self.pickerViewButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [self.pickerViewButton addTarget:self action:@selector(unhidePicker) forControlEvents:UIControlEventTouchUpInside];
                [self addSubview:self.pickerViewButton];
                break;
                
            case ACAlertViewStyleTextFieldAndPickerView:
                alertFrame = CGRectMake(0, 0, 250, 175);
                labelCenter = CGPointMake(CGRectGetMidX(alertFrame), 20);
                alignment = NSTextAlignmentCenter;
                self.frame = alertFrame;
                
                self.textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 225, 40)];
                self.textField.center = CGPointMake(self.center.x, self.center.y - 25);
                self.textField.borderStyle = UITextBorderStyleLine;
                self.textField.backgroundColor = [UIColor whiteColor];
                [self.textField addTarget:self.textField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
                self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
                self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                self.textField.returnKeyType = UIReturnKeyDone;
                [self addSubview:self.textField];
                
                self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)];
                self.pickerView.delegate = self;
                self.pickerView.dataSource = self;
                self.pickerView.hidden = YES;
                self.pickerView.backgroundColor = [UIColor whiteColor];
                [[UIApplication sharedApplication].keyWindow addSubview:self.pickerView];
                
                self.pickerViewButton = [UIButton buttonWithType:UIButtonTypeSystem];
                self.pickerViewButton.frame = CGRectMake(0, 0, 320, 40);
                self.pickerViewButton.center = CGPointMake(CGRectGetMidX(alertFrame), self.center.y + 20);
                [self.pickerViewButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [self.pickerViewButton addTarget:self action:@selector(unhidePicker) forControlEvents:UIControlEventTouchUpInside];
                [self addSubview:self.pickerViewButton];
                break;

            default:
                break;
        }

        if (titles)
        {
            CGFloat width = alertFrame.size.width/titles.count;
            NSInteger x = 0;
            for (NSString *title in titles)
            {
                UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
                button.frame = CGRectMake(x, alertFrame.size.height - 40, width, 40);
                [button setTitle:title forState:UIControlStateNormal];
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [button addTarget:self action:@selector(clickedButton:) forControlEvents:UIControlEventTouchUpInside];
                [self addSubview:button];
                x += width;
            }
        }
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 170, 40)];
        self.titleLabel.text = title;
        self.titleLabel.center = labelCenter;
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.textAlignment = alignment;
        [self addSubview:self.titleLabel];
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.9];
        self.layer.cornerRadius = 8;
        NSInteger x = self.frame.size.width/2;
        NSInteger y = self.frame.size.height/2 + 40;
        self.hidingCenter = CGPointMake(x, y);
    }
    return self;
}

+ (id)alertWithTitle:(NSString *)title style:(ACAlertViewStyle)style delegate:(id<ACAlertViewDelegate>)delegate buttonTitles:(NSArray *)titles
{
    return [[self alloc] initWithTitle:title style:style delegate:delegate buttonTitles:titles];
}

- (void)clickedButton:(UIButton *)sender
{
    NSString *buttonTitle = sender.titleLabel.text;
    if ([buttonTitle isEqualToString:@"Close"] || [buttonTitle isEqualToString:@"Dismiss"] || [buttonTitle isEqualToString:@"Cancel"])
    {
        [self dismiss];
    }
    if ([buttonTitle isEqualToString:@"Hide"])
    {
        [self hide];
    }
    
    if (completionHandler)
        completionHandler(self, buttonTitle);
    
    if ([self.delegate respondsToSelector:@selector(alertView:didClickButtonWithTitle:)])
        [self.delegate alertView:self didClickButtonWithTitle:buttonTitle];
}

- (void)showWithSelectionHandler:(ACAlertViewCompletionHandler)completion
{
    completionHandler = completion;
    [self show];
}

- (void)show
{
    UIWindow *currentWindow = [UIApplication sharedApplication].keyWindow;
    //for (UIView *subview in currentWindow.subviews)
    //{
    //TODO: uncomment this if you want all other views disabled when the alert is presented
    //[subview setUserInteractionEnabled:NO];
    //}
    self.center = currentWindow.center;
    self.alpha = 0.0;
    [currentWindow addSubview:self];
    [UIView animateWithDuration:0.6 animations:^{
        self.alpha = 1.0;
    }];
    if ([self.delegate respondsToSelector:@selector(alertViewDidAppear:)])
        [self.delegate alertViewDidAppear:self];
    self.pickerView.userInteractionEnabled = YES;
    [self becomeFirstResponder];
    if (self.textField)
        [self.textField becomeFirstResponder];
}

- (void)hide
{
    if (!self.isHiding)
    {
        self.hiding = YES;
        [UIView animateWithDuration:0.4 animations:^{
            CGAffineTransform scale;
            for (UIView *view in self.subviews)
            {
                if (![view isKindOfClass:[ACCircularProgressView class]])
                    view.hidden = YES, scale = CGAffineTransformMakeScale(0.35, 0.35);
                else
                    scale = CGAffineTransformMakeScale(0.75, 0.75);
                [view setTransform:scale];
            }
            scale = CGAffineTransformMakeScale(0.35, 0.35);
            [self setTransform:scale];
            self.center = self.hidingCenter;
        }];
    }
    else
    {
        self.hidingCenter = self.center;
        self.hiding = NO;
        [UIView animateWithDuration:0.4 animations:^{
            CGAffineTransform scale = CGAffineTransformMakeScale(1.0, 1.0);
            for (UIView *view in self.subviews)
            {
                [view setTransform:scale];
                view.hidden = NO;
            }
            [self setTransform:scale];
            UIWindow *currentWindow = [UIApplication sharedApplication].keyWindow;
            self.center = currentWindow.center;
        }];
    }
}

- (void)dismiss
{
    for (UIView *subview in self.superview.subviews)
    {
        [subview setUserInteractionEnabled:YES];
    }
    [self.pickerView removeFromSuperview];
    [UIView animateWithDuration:0.6 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL isCompleted){
        if (isCompleted)
        {
            [self removeFromSuperview];
            [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            
            if ([self.delegate respondsToSelector:@selector(alertViewDidDismiss:)])
                [self.delegate alertViewDidDismiss:self];
            [self resignFirstResponder];
        }
    }];
}

-(void)orientationChanged
{
    UIDeviceOrientation o = [UIDevice currentDevice].orientation;
    
    CGFloat angle = 0;
    if ( o == UIDeviceOrientationLandscapeLeft ) angle = M_PI_2;
    else if ( o == UIDeviceOrientationLandscapeRight ) angle = -M_PI_2;
    else if ( o == UIDeviceOrientationPortraitUpsideDown ) angle = M_PI;
    
    [UIView beginAnimations:@"rotate" context:nil];
    [UIView setAnimationDuration:0.3];
    self.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(160.0f - self.center.x, 240.0f - self.center.y), angle);
    [UIView commitAnimations];
}

- (void)setPickerViewItems:(NSArray *)pickerViewItems
{
    _pickerViewItems = pickerViewItems;
    [self.pickerViewButton setTitle:pickerViewItems[0] forState:UIControlStateNormal];
    [self.pickerView reloadAllComponents];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.isHiding)
    {
        self.moving = YES;
        UITouch *touch = [touches anyObject];
        CGPoint newCenter = [touch locationInView:self.superview];
        self.center = newCenter;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.isHiding && !self.isMoving)
        [self hide];
    else if (self.isMoving)
        self.moving = NO;
}

#pragma mark - Picker view stuff

- (void)unhidePicker
{
    self.pickerView.hidden = NO;
    [self.pickerView reloadAllComponents];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.pickerViewItems.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.pickerViewItems[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self.pickerViewButton setTitle:self.pickerViewItems[row] forState:UIControlStateNormal];
    //[self.pickerView setHidden:YES];
}

@end
