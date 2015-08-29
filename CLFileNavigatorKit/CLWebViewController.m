//
//  CLWebViewController.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/19/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "CLWebViewController.h"
#import "CLFile.h"

@implementation CLWebViewController

- (id)initWithFile:(CLFile *)file
{
    return [self initWithFileAtPath:file.filePath];
}

- (id)initWithFileAtPath:(NSString *)path
{
    if (self = [super init])
    {
        UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.frame];
        webView.scalesPageToFit = YES;
        
        //TODO: decide on which one - First causes memory issues, second doesn't open files without proper extensions
        
        //NSData *fileData = [NSData dataWithContentsOfFile:path];
        //[webView loadData:fileData MIMEType:nil textEncodingName:@"utf-8" baseURL:nil];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]];
        [webView loadRequest:request];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
        self.navigationItem.title = path.lastPathComponent;
        
        [self.view addSubview:webView];
    }
    return self;
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end