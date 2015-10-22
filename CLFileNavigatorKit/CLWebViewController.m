//
//  CLWebViewController.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/19/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "CLWebViewController.h"
#import "CLFile.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation CLWebViewController
{
    NSString *fileName;
}

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
        
        //TODO: decide on which one - First causes memory issues (FALSE), second doesn't open files without proper extensions
        
        NSString *pathExtension = path.pathExtension;
        NSString *UTI = (__bridge NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)pathExtension, NULL);
        NSString *MIME = (__bridge NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
        
        NSData *fileData = [NSData dataWithContentsOfFile:path];
        [webView loadData:fileData MIMEType:MIME textEncodingName:@"utf-8" baseURL:nil];
        //NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]];
        //[webView loadRequest:request];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
        self.navigationItem.title = path.lastPathComponent;
        fileName = path.lastPathComponent;
        
        [self.view addSubview:webView];
    }
    return self;
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

- (UIImage *)hidingIcon
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(50.0, 50.0), NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillRect(context, CGRectMake(0.0, 0.0, 50.0, 50.0));
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
    
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:fileName attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:10.0], NSForegroundColorAttributeName: [UIColor whiteColor], NSParagraphStyleAttributeName: paragraphStyle}];
    [string drawInRect:CGRectMake(2.0, 12.5, 46.0, 25.0)];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

@end
