//
//  CLImageFilterViewController.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 10/6/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CLImageFilterViewControllerDelegate <NSObject>

- (void)filterWasAppliedToImage:(UIImage *)image;

@end

@interface CLImageFilterViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UICollectionViewFlowLayout *collectionViewLayout;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSArray *filterNames;
@property (weak, nonatomic) id<CLImageFilterViewControllerDelegate> delegate;

- (id)initWithImage:(UIImage *)image delegate:(id<CLImageFilterViewControllerDelegate>)delegate;

@end
