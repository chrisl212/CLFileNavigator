//
//  ACTextEditorViewController.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/23/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "CLTextEditorViewController.h"
#import "CLFile.h"

@implementation CLTextEditorViewController

- (id)initWithFile:(CLFile *)file
{
    return [self initWithFiles:@[file] firstIndex:0];
}

- (id)initWithFilePath:(NSString *)path
{
    return [self initWithFiles:@[[CLFile fileWithPath:path error:nil]] firstIndex:0];
}

- (id)initWithFiles:(NSArray *)files firstIndex:(NSInteger)idx
{
    if (self = [super init])
    {
        self.items = files;
        self.currentItem = self.items[idx];
        
        self.textView = [[UITextView alloc] initWithFrame:self.view.frame];
        
        UIToolbar *inputAccessoryToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *dismissKeyboard = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self.textView action:@selector(resignFirstResponder)];
        inputAccessoryToolbar.items = @[flex, dismissKeyboard];
        
        self.textView.inputAccessoryView = inputAccessoryToolbar;
        [self.view addSubview:self.textView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
        
        [self changeToItemAtIndex:idx];
    }
    return self;
}

- (id)initWithFilePaths:(NSArray *)paths firstIndex:(NSInteger)idx
{
    NSMutableArray *files = [NSMutableArray array];
    for (NSString *filePath in paths)
        [files addObject:[CLFile fileWithPath:filePath error:nil]];
    return [self initWithFiles:files firstIndex:idx];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    [self.navigationController setToolbarHidden:NO];
    
    UIBarButtonItem *previousItem = [[UIBarButtonItem alloc] initWithTitle:@"<" style:UIBarButtonItemStylePlain target:self action:@selector(previousItem)];
    UIBarButtonItem *nextItem = [[UIBarButtonItem alloc] initWithTitle:@">" style:UIBarButtonItemStylePlain target:self action:@selector(nextItem)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = @[previousItem, flex, nextItem];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)keyboardWasShown:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    self.textView.contentInset = UIEdgeInsetsMake(/*self.navigationController.navigationBar.frame.size.height + 20.0*/0, 0, keyboardSize.height, 0);
    self.textView.scrollIndicatorInsets = self.textView.contentInset;
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    self.textView.contentInset = UIEdgeInsetsZero;
    self.textView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

- (void)save
{
    [self.textView.text writeToFile:self.currentItem.filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [self dismiss];
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)previousItem
{
    NSInteger currentIndex = [self.items indexOfObject:self.currentItem];
    NSInteger queueCount = self.items.count;
    NSInteger previousIndex = (currentIndex == 0) ? queueCount-1 : currentIndex-1;
    [self changeToItemAtIndex:previousIndex];
}

- (void)nextItem
{
    NSInteger currentIndex = [self.items indexOfObject:self.currentItem];
    NSInteger queueCount = self.items.count;
    NSInteger nextIndex = (currentIndex == (queueCount-1)) ? 0 : currentIndex + 1;
    [self changeToItemAtIndex:nextIndex];
}

- (void)changeToItemAtIndex:(NSInteger)idx
{
    self.currentItem = self.items[idx];
    self.navigationItem.title = self.currentItem.fileName;
    
    self.textView.text = [NSString stringWithContentsOfFile:self.currentItem.filePath encoding:NSUTF8StringEncoding error:nil];
}

@end
