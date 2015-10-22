//
//  CLFilterCell.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 10/6/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLFilterCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (strong, nonatomic) UIColor *selectedLabelColor;
@property (strong, nonatomic) UIColor *selectedTextColor;

@end
