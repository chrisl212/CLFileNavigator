//
//  CLFileCell.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/18/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLFileCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *fileNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *fileSizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *fileLastModifiedDateLabel;
@property (weak, nonatomic) IBOutlet UIImageView *fileIconImageView;

@end
