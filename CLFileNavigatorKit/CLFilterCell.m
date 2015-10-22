//
//  CLFilterCell.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 10/6/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "CLFilterCell.h"

@implementation CLFilterCell
{
    UIColor *deselectedTextColor;
}

- (void)awakeFromNib
{
    deselectedTextColor = self.textLabel.textColor;
    
    self.textLabel.layer.cornerRadius = 8.0;
    self.textLabel.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected
{
    if (selected)
    {
        self.textLabel.backgroundColor = self.selectedLabelColor;
        self.textLabel.textColor = self.selectedTextColor;
    }
    else
    {
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.textColor = deselectedTextColor;
    }
}

@end
