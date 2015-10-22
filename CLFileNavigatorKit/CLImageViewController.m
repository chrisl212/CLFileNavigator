//
//  CLImageViewController.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/19/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "CLImageViewController.h"
#import "ACAlertView.h"

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
    NSDictionary *dict = @{CLImageFileNameKey: file, CLImageImageKey: [UIImage imageWithContentsOfFile:file]};
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
    
    [self.navigationController setToolbarHidden:NO];
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
    self.navigationItem.title = [self.images[idx][CLImageFileNameKey] lastPathComponent];
    self.currentImage = self.images[idx][CLImageImageKey];
    self.imageView.image = self.currentImage;
    
    if (([[self.images[[self indexOfImage:self.currentImage]][CLImageFileNameKey] pathExtension] caseInsensitiveCompare:@"png"] == NSOrderedSame || [[self.images[[self indexOfImage:self.currentImage]][CLImageFileNameKey] pathExtension] caseInsensitiveCompare:@"jpg"] == NSOrderedSame || [[self.images[[self indexOfImage:self.currentImage]][CLImageFileNameKey] pathExtension] caseInsensitiveCompare:@"jpeg"] == NSOrderedSame) && !self.isEditing)
        self.navigationItem.leftBarButtonItem = self.editButtonItem;
    else if (self.isEditing)
        self.navigationItem.leftBarButtonItem = self.navigationItem.leftBarButtonItem;
    else
        self.navigationItem.leftBarButtonItem = nil;
}

- (NSInteger)indexOfImage:(UIImage *)img
{
    return [self.images indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop)
            {
                UIImage *image = obj[CLImageImageKey];
                
                *stop = NO;
                if (![image isEqual:img])
                    return NO;
                *stop = YES;
                return YES;
            }];
}

- (void)nextImage
{
    NSInteger currentIndex = [self indexOfImage:self.currentImage];
    NSInteger queueCount = self.images.count;
    NSInteger nextIndex = (currentIndex == (queueCount-1)) ? 0 : currentIndex + 1;
    
    [self changeImageToIndex:nextIndex];
}

- (void)previousImage
{
    NSInteger currentIndex = [self indexOfImage:self.currentImage];
    NSInteger queueCount = self.images.count;
    NSInteger previousIndex = (currentIndex == 0) ? queueCount-1 : currentIndex-1;
    
    [self changeImageToIndex:previousIndex];
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
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

- (void)cancelEditing
{
    NSInteger index = [self indexOfImage:self.currentImage];
    NSMutableArray *images = self.images.mutableCopy;
    [images replaceObjectAtIndex:index withObject:@{CLImageImageKey: [UIImage imageWithContentsOfFile:self.images[index][CLImageFileNameKey]], CLImageFileNameKey: self.images[index][CLImageFileNameKey]}];
    self.images = [NSArray arrayWithArray:images];
    
    [self changeImageToIndex:index];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
    UIBarButtonItem *previousImage = [[UIBarButtonItem alloc] initWithTitle:@"<" style:UIBarButtonItemStylePlain target:self action:@selector(previousImage)];
    UIBarButtonItem *nextImage = [[UIBarButtonItem alloc] initWithTitle:@">" style:UIBarButtonItemStylePlain target:self action:@selector(nextImage)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.toolbarItems = @[previousImage, flex, nextImage];
    self.editing = NO;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    if (editing)
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditing)];
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
        
        UIBarButtonItem *resize = [[UIBarButtonItem alloc] initWithTitle:@"Resize" style:UIBarButtonItemStylePlain target:self action:@selector(resizeImage)];
        UIBarButtonItem *filters = [[UIBarButtonItem alloc] initWithTitle:@"Filters" style:UIBarButtonItemStylePlain target:self action:@selector(filterImage)];
        
        self.toolbarItems = @[resize, filters];
    }
    else
    {
        NSString *filePath = self.images[[self indexOfImage:self.currentImage]][CLImageFileNameKey];
        NSData *imageData;
        if ([filePath.pathExtension caseInsensitiveCompare:@"png"] == NSOrderedSame)
            imageData = UIImagePNGRepresentation(self.currentImage);
        else
            imageData = UIImageJPEGRepresentation(self.currentImage, 1.0);
        [imageData writeToFile:filePath atomically:YES];
        
        self.navigationItem.leftBarButtonItem = self.editButtonItem;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
        UIBarButtonItem *previousImage = [[UIBarButtonItem alloc] initWithTitle:@"<" style:UIBarButtonItemStylePlain target:self action:@selector(previousImage)];
        UIBarButtonItem *nextImage = [[UIBarButtonItem alloc] initWithTitle:@">" style:UIBarButtonItemStylePlain target:self action:@selector(nextImage)];
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        self.toolbarItems = @[previousImage, flex, nextImage];
    }
}

#pragma mark - Image Edits

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)resizeImage
{
    ACAlertView *alertView = [ACAlertView alertWithTitle:@"Resize" style:ACAlertViewStyleTextField delegate:nil buttonTitles:@[@"Cancel", @"Resize"]];
    alertView.textField.text = [NSString stringWithFormat:@"%.0lFx%.0lF", self.currentImage.size.width, self.currentImage.size.height];
    alertView.textField.keyboardType = UIKeyboardTypeDecimalPad;
    alertView.textField.selectedTextRange = [alertView.textField textRangeFromPosition:[alertView.textField beginningOfDocument] toPosition:[alertView.textField positionFromPosition:alertView.textField.beginningOfDocument offset:[[alertView.textField.text componentsSeparatedByString:@"x"][0] length]]];
    
    [alertView showWithSelectionHandler:^(ACAlertView *alert, NSString *buttonTitle)
     {
         if ([buttonTitle isEqualToString:@"Cancel"])
         {
             [alert dismiss];
             return;
         }
         if ([alert.textField.text rangeOfString:@"([0-9]*(x)[0-9]*)" options:NSRegularExpressionSearch].location != NSNotFound)
         {
             NSArray *components = [alert.textField.text componentsSeparatedByString:@"x"];
             CGFloat width = [components[0] doubleValue];
             CGFloat height = [components[1] doubleValue];
             
             NSInteger index = [self indexOfImage:self.currentImage];
             NSMutableArray *images = self.images.mutableCopy;
             [images replaceObjectAtIndex:index withObject:@{CLImageImageKey: [self imageWithImage:self.currentImage scaledToSize:CGSizeMake(width, height)], CLImageFileNameKey: self.images[index][CLImageFileNameKey]}];
             self.images = [NSArray arrayWithArray:images];

             [self changeImageToIndex:index];
             [alert dismiss];
         }
         else
         {
             alert.textField.text = [NSString stringWithFormat:@"%lFx%lF", self.currentImage.size.width, self.currentImage.size.height];
             alert.textField.selectedTextRange = [alertView.textField textRangeFromPosition:[alertView.textField beginningOfDocument] toPosition:[alertView.textField positionFromPosition:alertView.textField.beginningOfDocument offset:[[alertView.textField.text componentsSeparatedByString:@"x"][0] length]]];
         }
     }];
}

- (void)filterImage
{
    CLImageFilterViewController *filterViewController = [[CLImageFilterViewController alloc] initWithImage:self.currentImage delegate:self];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:filterViewController];
    navController.navigationController.navigationBar.translucent = YES;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)filterWasAppliedToImage:(UIImage *)image
{
    NSInteger index = [self indexOfImage:self.currentImage];
    NSMutableArray *images = self.images.mutableCopy;
    [images replaceObjectAtIndex:index withObject:@{CLImageImageKey: image, CLImageFileNameKey: self.images[index][CLImageFileNameKey]}];
    self.images = [NSArray arrayWithArray:images];
    
    [self changeImageToIndex:index];
}

#pragma mark - Hide

- (UIImage *)hidingIcon
{
    return self.currentImage;
}

@end
