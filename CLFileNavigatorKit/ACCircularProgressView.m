//
//  ACCircularProgressView.m
//  ACFileNavigator
//
//  Created by Christopher Loonam on 7/15/15.
//  Copyright (c) 2015 A and C Studios. All rights reserved.
//

#import "ACCircularProgressView.h"

@implementation ACCircularProgressView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.color = [UIColor whiteColor];
        self.progress = 0.0;
        self.lineWidth = 5.0;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat offsetDegrees = 270.0;
    CGFloat offsetRadians = offsetDegrees * (M_PI/180.0);
    
    CGFloat angleDegrees = self.progress * 360.0;
    CGFloat angleRadians = angleDegrees * (M_PI/180.0);
    
    CGContextSetStrokeColorWithColor(context, self.color.CGColor);
    CGContextSetLineWidth(context, self.lineWidth);
    
    CGContextAddArc(context, center.x, center.y, rect.size.width/2.0 - self.lineWidth/2.0, offsetRadians, angleRadians + offsetRadians, 0);
    
    CGContextStrokePath(context);
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    [self setNeedsDisplay];
}

@end
