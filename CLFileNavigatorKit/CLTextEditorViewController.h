//
//  ACTextEditorViewController.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/23/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLFileDisplayViewController.h"

@class CLFile;

@interface CLTextEditorViewController : CLFileDisplayViewController

@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic) NSArray *items;
@property (strong, nonatomic) CLFile *currentItem;

- (id)initWithFilePath:(NSString *)path;
- (id)initWithFilePaths:(NSArray *)paths firstIndex:(NSInteger)idx;
- (id)initWithFile:(CLFile *)file;
- (id)initWithFiles:(NSArray *)files firstIndex:(NSInteger)idx;

@end
