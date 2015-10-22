//
//  CLFileOpener.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/19/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <CLFileNavigatorKit/CLFileNavigatorKit.h>
#import <MediaPlayer/MediaPlayer.h>

@implementation CLFileOpener
{
    NSMutableArray *fileDisplayControllers;
    CGRect preHidingNavFrame;
    CGRect preHidingControllerFrame;
    CGRect preHidingDisplayFrame;
}

+ (id)fileOpener
{
    static CLFileOpener *fileOpener = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fileOpener = [[self alloc] init];
    });
    return fileOpener;
}

- (instancetype)init
{
    if (self = [super init])
    {
        fileDisplayControllers = @[].mutableCopy;
    }
    return self;
}

- (void)errorAlert:(NSError *)error
{
    ACAlertView *alertView = [ACAlertView alertWithTitle:@"Error" style:ACAlertViewStyleTextView delegate:nil buttonTitles:@[@"Close"]];
    alertView.textView.text = error.localizedDescription;
    [alertView show];
}

- (void)openFileAtPath:(NSString *)path type:(NSInteger)type sender:(UIViewController<CLFileDisplayDelegate> *)vc
{
    CLFileDisplayViewController __block *viewController;
    switch (type)
    {
        case CLFileTypeDirectory:
        {
            CLDirectoryViewController *directoryViewController = [[CLDirectoryViewController alloc] initWithDirectoryPath:path];
            directoryViewController.options = @{CLDirectoryViewControllerDisplayThumbnailsOption: @(YES), CLDirectoryViewControllerDateDisplayOption: @"Modification"};
            [vc.navigationController pushViewController:directoryViewController animated:YES];
            return;
        }
            
        case CLFileTypeImage:
        {
            NSString *directoryPath = path.stringByDeletingLastPathComponent;
            
            NSError *error;
            NSArray *directoryFiles = [[NSFileManager defaultManager] filesFromDirectoryAtPath:directoryPath error:&error];
            if (error)
            {
                [self errorAlert:error];
                break;
            }
            
            BOOL pathInArray = NO;
            
            NSMutableArray *imageObjects = [NSMutableArray array];
            for (CLFile *file in directoryFiles)
            {
                if (file.fileType == CLFileTypeImage)
                {
                    UIImage *image = [UIImage imageWithContentsOfFile:file.filePath];
                    if (!image)
                        image = [[UIImage alloc] init];
                    NSDictionary *dict = @{CLImageFileNameKey: file.filePath, CLImageImageKey: image};
                    [imageObjects addObject:dict];
                    if ([file.filePath isEqualToString:path])
                        pathInArray = YES;
                }
            }
            
            UIImage *image = [UIImage imageWithContentsOfFile:path];
            if (!image)
                image = [[UIImage alloc] init];
            NSDictionary *dict = @{CLImageFileNameKey: path, CLImageImageKey: image};
            if (!pathInArray)
                [imageObjects addObject:dict];
            
            NSInteger idx = [imageObjects indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop)
                             {
                                 *stop = NO;
                                 NSString *fname = obj[CLImageFileNameKey];
                                 if (![fname isEqualToString:path])
                                     return NO;
                                 *stop = YES;
                                 return YES;
                             }];
            viewController = [[CLImageViewController alloc] initWithImages:imageObjects firstIndex:idx];
            break;
        }
            
        case CLFileTypeMovie:
        {
            //MPMoviePlayerViewController *moviePlayerController = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:path]];
            CLMoviePlayerViewController *moviePlayerController = [[CLMoviePlayerViewController alloc] initWithFilePath:path];
            UINavigationController *moviePlayerNavController = [[UINavigationController alloc] initWithRootViewController:moviePlayerController];
            [vc presentViewController:moviePlayerNavController animated:YES completion:nil];
            return;
        }
            
        case CLFileTypeMusic:
        {
            NSString *directoryPath = path.stringByDeletingLastPathComponent;
            
            NSError *error;
            NSArray *directoryFiles = [[NSFileManager defaultManager] filesFromDirectoryAtPath:directoryPath error:&error];
            if (error)
            {
                [self errorAlert:error];
                break;
            }
            
            NSMutableArray *musicObjects = [NSMutableArray array];
            
            for (CLFile *file in directoryFiles)
                if (file.fileType == CLFileTypeMusic)
                    [musicObjects addObject:[[CLAudioItem alloc] initWithFile:file]];
            
            CLAudioItem *audioItem = [[CLAudioItem alloc] initWithFilePath:path];
            if (![musicObjects containsObject:audioItem])
                [musicObjects addObject:audioItem];
            NSInteger firstIndex = [musicObjects indexOfObject:audioItem];
            viewController = [[CLAudioPlayerViewController alloc] initWithItems:musicObjects firstIndex:firstIndex];
            break;
        }
            
        case CLFileTypePDF:
        {
            viewController = [[CLWebViewController alloc] initWithFileAtPath:path];
            break;
        }
            
        case CLFileTypeRichText:
            //fall through to next
        case CLFileTypeText:
        {
            NSString *directoryPath = path.stringByDeletingLastPathComponent;
            
            NSError *error;
            NSArray *directoryFiles = [[NSFileManager defaultManager] filesFromDirectoryAtPath:directoryPath error:&error];
            if (error)
            {
                [self errorAlert:error];
                break;
            }
            
            NSMutableArray *textFiles = [NSMutableArray array];
            for (CLFile *f in directoryFiles)
                if (f.fileType == CLFileTypeText || f.fileType == CLFileTypeRichText)
                    [textFiles addObject:f];
            CLFile *file = [CLFile fileWithPath:path error:nil];
            if (![textFiles containsObject:file])
                [textFiles addObject:file];
            
            viewController = [[CLTextEditorViewController alloc] initWithFiles:textFiles firstIndex:[textFiles indexOfObject:file]];
            break;
        }
            
        case CLFileTypeUnknown:
        {
            ACAlertView *alertView = [ACAlertView alertWithTitle:@"Open as..." style:ACAlertViewStylePickerView delegate:nil buttonTitles:@[@"Cancel", @"Open"]];
            NSArray *pickerViewItems = @[@"Text File", @"Image File", @"Music File", @"Video File", @"PDF File", @"Web File", @"Compressed File", @"Rich Text File"];
            alertView.pickerViewItems = pickerViewItems;
            
            [alertView showWithSelectionHandler:^(ACAlertView *alertView, NSString *buttonTitle)
             {
                 if ([buttonTitle isEqualToString:@"Cancel"])
                     return;
                 
                 NSInteger index = [pickerViewItems indexOfObject:alertView.pickerViewButton.titleLabel.text];
                 NSArray *fileTypes = @[@(CLFileTypeText), @(CLFileTypeImage), @(CLFileTypeMusic), @(CLFileTypeMovie), @(CLFileTypePDF), @(CLFileTypeWeb), @(CLFileTypeZip), @(CLFileTypeRichText)];
                 CLFileType fileType = [fileTypes[index] integerValue];
                 
                 [self openFileAtPath:path type:fileType sender:vc];
                 [alertView dismiss];
             }];
            break;
        }
            
        case CLFileTypeWeb:
        {
            viewController = [[CLWebViewController alloc] initWithFileAtPath:path];
            break;
        }
            
        case CLFileTypeZip:
        {
            ACUnzipFileType fileType = ACUnzipFileTypeZip;
            
            NSString *fileExtension = path.pathExtension;
            
            if ([fileExtension caseInsensitiveCompare:@"zip"] == NSOrderedSame)
                fileType = ACUnzipFileTypeZip;
            else if ([fileExtension caseInsensitiveCompare:@"gz"] == NSOrderedSame)
                fileType = ACUnzipFileTypeGZip;
            else if ([fileExtension caseInsensitiveCompare:@"bz2"] == NSOrderedSame)
                fileType = ACUnzipFileTypeBZip2;
            else if ([fileExtension caseInsensitiveCompare:@"tar"] == NSOrderedSame)
                fileType = ACUnzipFileTypeTar;
            
            if (fileType == ACUnzipFileTypeGZip || fileType == ACUnzipFileTypeBZip2)
                [ACUnzip decompressFile:path fileType:fileType];
            else if (fileType == ACUnzipFileTypeTar)
            {
                NSString *newDirectoryPath = [path stringByDeletingPathExtension];
                [ACUnzip decompressFiles:path toDirectory:newDirectoryPath fileType:fileType];
            }
            else
            {
                CLActionSheet *actionSheet = [[CLActionSheet alloc] initWithTitle:path.lastPathComponent delegate:nil cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Unzip" otherButtonTitles:@"Zip Viewer", nil];
                actionSheet.completionHandler = ^(NSString *buttonTitle)
                {
                    if ([buttonTitle isEqualToString:@"Cancel"])
                        return;
                    else if ([buttonTitle isEqualToString:@"Unzip"])
                    {
                        NSString *newDirectoryPath = [path stringByDeletingPathExtension];
                        [ACUnzip decompressFiles:path toDirectory:newDirectoryPath fileType:fileType];
                    }
                    else
                    {
                        viewController = [[CLZipViewController alloc] initWithFile:path];
                        [self performSelector:@selector(displayController:) withObject:viewController afterDelay:0.5];
                    }
                };
                [actionSheet showInView:vc.view];
            }
            
            break;
        }
            
        default:
            break;
    }
    
    if (!viewController)
        return;
    
    [self displayController:viewController];
}

- (void)displayController:(CLFileDisplayViewController *)viewController
{
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    viewController.fileDisplayDelegate = self;
    CLFileDisplayView *displayView = [[CLFileDisplayView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    navController.view.frame = [[UIScreen mainScreen] bounds];
    [displayView addSubview:navController.view];
    [viewController viewDidAppear:YES];
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    displayView.frame = CGRectMake(0.0, keyWindow.frame.size.height, displayView.frame.size.width, displayView.frame.size.height);
    [keyWindow addSubview:displayView];
    [viewController.fileDisplayDelegate fileDisplayControllerWasCreated:(CLFileDisplayViewController *)navController];
    
    [UIView animateWithDuration:0.25 animations:^{
        displayView.center = keyWindow.center;
    }];
}

- (void)openFile:(CLFile *)file sender:(UIViewController<CLFileDisplayDelegate> *)vc
{
    [self openFileAtPath:file.filePath type:file.fileType sender:vc];
}

#pragma mark - File Display Delegate

- (void)fileDisplayControllerWasCreated:(CLFileDisplayViewController *)controller
{
    [fileDisplayControllers addObject:controller];
}

- (void)fileDisplayControllerShouldHide:(CLFileDisplayViewController *)controller
{
    preHidingNavFrame = controller.navigationController.view.frame;
    preHidingControllerFrame = controller.view.frame;
    preHidingDisplayFrame = controller.navigationController.view.superview.frame;
    
    [UIView animateWithDuration:0.25 animations:^{
        CLFileDisplayView *displayView = (CLFileDisplayView *)controller.navigationController.view.superview;
        displayView.frame = CGRectMake(0, 0, 50.0, 50.0);
        //controller.navigationController.view.frame = CGRectMake(0, 0, 50.0, 50.0);
        //controller.view.frame = CGRectMake(0, 0, 50.0, 50.0);
        [controller setHiding:YES];
        displayView.center = controller.hidingCenter;
    }];
}

- (void)fileDisplayControllerShouldUnhide:(CLFileDisplayViewController *)controller
{
    CLFileDisplayView *displayView = (CLFileDisplayView *)controller.navigationController.view.superview;
    UIView *superView = displayView.superview;
    [superView bringSubviewToFront:displayView];
    
    controller.hidingCenter = displayView.center;
    
    [UIView animateWithDuration:0.25 animations:^{
        displayView.frame = preHidingDisplayFrame;
        [controller setHiding:NO];
    }];
}

- (void)fileDisplayControllerWasClosed:(CLFileDisplayViewController *)controller
{
    [fileDisplayControllers removeObject:controller];
}

@end
