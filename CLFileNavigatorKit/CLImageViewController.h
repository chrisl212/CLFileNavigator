//
//  CLImageViewController.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/19/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const CLImageFileNameKey;
FOUNDATION_EXPORT NSString *const CLImageImageKey;

@interface CLImageViewController : UIViewController <UIScrollViewDelegate>

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) NSArray *images;
@property (strong, nonatomic) UIImage *currentImage;

- (id)initWithImage:(NSDictionary *)image;
- (id)initWithImages:(NSArray *)images firstIndex:(NSInteger)idx;
- (id)initWithContentsOfFile:(NSString *)file;

@end
