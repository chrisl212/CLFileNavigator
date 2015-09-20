//
//  CLDirectoryViewController.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/18/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "CLDirectoryViewController.h"
#import "CLFile.h"
#import "NSFileManager+CLFile.h"
#import "CLFileCell.h"
#import "UIImage+CLFile.h"
#import "CLFileOpener.h"
#import "ACZip.h"
#import "CLFileTransfer.h"
#import "CLFilePropertiesViewController.h"
#import "CLSettingsViewController.h"
#import "CLIconPackViewController.h"
#import "CLAudioItem.h"
#import <AVFoundation/AVFoundation.h>

#define COPYPASTE_ACTIONSHEET 0
#define FILEOPTIONS_ACTIONSHEET 1

NSString *const CLDirectoryViewControllerRefreshNotification = @"shouldRefresh";

NSString *const CLDirectoryViewControllerDisplayThumbnailsOption = @"thumbs";
NSString *const CLDirectoryViewControllerDateDisplayOption = @"date";

@implementation CLDirectoryViewController
{
    CLFileTransfer *fileTransfer;
    NSDateFormatter *dateFormatter;
}

- (UIView *)tableFooter
{
    UIView *diskSpaceView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
    
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    progressView.frame = CGRectMake(0, 0, diskSpaceView.frame.size.width/1.25, 5);
    
    UILabel *diskSpaceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, diskSpaceView.frame.size.width, 15)];
    diskSpaceLabel.textAlignment = NSTextAlignmentCenter;
    diskSpaceLabel.font = [UIFont systemFontOfSize:12.0];

    CLFileSize totalSpace, freeSpace, usedSpace;
    
    [[NSFileManager defaultManager] getFreeSpace:&freeSpace totalSpace:&totalSpace];
    usedSpace = totalSpace - freeSpace;
    
    progressView.progress = (double)usedSpace/(double)totalSpace;
    
    NSString *totalSpaceString = [[NSFileManager defaultManager] formattedSizeStringForBytes:totalSpace];
    NSString *usedSpaceString = [[NSFileManager defaultManager] formattedSizeStringForBytes:usedSpace];
    
    diskSpaceLabel.text = [NSString stringWithFormat:@"%@ used out of %@", usedSpaceString, totalSpaceString];
    
    progressView.center = CGPointMake(CGRectGetMidX(diskSpaceView.frame), CGRectGetMidY(diskSpaceView.frame) - 2.5);
    diskSpaceLabel.center = CGPointMake(CGRectGetMidX(diskSpaceView.frame), CGRectGetMidY(diskSpaceView.frame) + 7.5);
    
    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    settingsButton.frame = CGRectMake(0, 0, diskSpaceView.frame.size.width, 20);
    
    settingsButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
    [settingsButton setTitle:@"Settings" forState:UIControlStateNormal];
    [settingsButton addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
    settingsButton.center = CGPointMake(CGRectGetMidX(diskSpaceView.frame), CGRectGetMidY(diskSpaceView.frame) + (settingsButton.frame.size.height/2.0) + 10);
    
    [diskSpaceView addSubview:diskSpaceLabel];
    [diskSpaceView addSubview:progressView];
    [diskSpaceView addSubview:settingsButton];
    
    return diskSpaceView;
}

- (void)openSettings
{
    CLSettingsViewController *settingsViewController = [[CLSettingsViewController alloc] init];
    UINavigationController *settingsNavController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    CLIconPackViewController *iconPackViewController = [[CLIconPackViewController alloc] init];
    UINavigationController *iconNavController = [[UINavigationController alloc] initWithRootViewController:iconPackViewController];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[settingsNavController, iconNavController];
    
    [self presentViewController:tabBarController animated:YES completion:nil];
}

#pragma mark - Initialization

- (instancetype)init
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [self initWithDirectoryPath:documentsDirectory];
}

- (id)initWithDirectory:(CLFile *)dir
{
    if (self = [super initWithStyle:UITableViewStylePlain])
    {
        self.options = @{CLDirectoryViewControllerDateDisplayOption: @"Modification", CLDirectoryViewControllerDisplayThumbnailsOption: @(NO)};
        
        NSError *err;
        self.files = [[NSFileManager defaultManager] filesFromDirectoryAtPath:dir.filePath error:&err];
        if (err)
            NSLog(@"%@", err);
        
        [self.tableView registerNib:[UINib nibWithNibName:@"CLFileCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"FileCell"];
        
        self.directory = dir;
        
        self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        self.searchController.searchResultsUpdater = self;
        self.searchController.searchBar.delegate = self;
        self.searchController.delegate = self;
        self.searchController.searchBar.scopeButtonTitles = @[];
        
        self.tableView.tableHeaderView = self.searchController.searchBar;
        self.definesPresentationContext = YES;
        [self.searchController.searchBar sizeToFit];
        self.searchController.dimsBackgroundDuringPresentation = NO;
        self.navigationItem.title = self.directory.fileName;
        
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.refreshControl addTarget:self action:@selector(refreshFiles) forControlEvents:UIControlEventValueChanged];
        
        self.tableView.tableFooterView = [self tableFooter];
        self.tableView.allowsMultipleSelectionDuringEditing = YES;
        
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(openFileOptions:)];
        longPressGestureRecognizer.minimumPressDuration = 0.8;
        [self.tableView addGestureRecognizer:longPressGestureRecognizer];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshFiles) name:CLDirectoryViewControllerRefreshNotification object:nil];
    }
    return self;
}

- (id)initWithDirectoryPath:(NSString *)path
{
    return [self initWithDirectory:[CLFile fileWithPath:path error:nil]]; //error checking TBD
}

#pragma mark - View Methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self refreshFiles];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)refreshFiles
{
    NSError *error;
    self.files = [[NSFileManager defaultManager] filesFromDirectoryAtPath:self.directory.filePath error:&error];
    if (error)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            ACAlertView *errorAlert = [ACAlertView alertWithTitle:@"Error" style:ACAlertViewStyleTextView delegate:nil buttonTitles:@[@"Close"]];
            errorAlert.textView.text = error.localizedDescription;
            //[errorAlert show];
        });
    }
    [self.tableView reloadData];
    
    if (self.refreshControl.isRefreshing)
        [self.refreshControl endRefreshing];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLFileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FileCell" forIndexPath:indexPath];
    
    CLFile *file = self.files[indexPath.row];
    
    cell.fileNameLabel.text = file.fileName;
    cell.fileSizeLabel.text = [file fileSizeString];
    
    if (!dateFormatter)
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    }
    
    if ([self.options[CLDirectoryViewControllerDateDisplayOption] isEqualToString:@"Modification"])
        cell.fileLastModifiedDateLabel.text = [dateFormatter stringFromDate:file.lastModifiedDate];
    else if ([self.options[CLDirectoryViewControllerDateDisplayOption] isEqualToString:@"Creation"])
        cell.fileLastModifiedDateLabel.text = [dateFormatter stringFromDate:file.creationDate]; //for use with myDownload
    
    if ((file.fileType != CLFileTypeImage && file.fileType != CLFileTypeMusic && file.fileType != CLFileTypeMovie) || ![self.options[CLDirectoryViewControllerDisplayThumbnailsOption] boolValue])
        cell.fileIconImageView.image = [UIImage iconForFileType:file.fileType];
    else if (file.fileType == CLFileTypeMovie)
    {
        dispatch_async(dispatch_queue_create("com.ac.table", NULL), ^{
            UIImage *thumbnail = nil;
            NSURL *url = [NSURL fileURLWithPath:file.filePath];
            AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
            AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
            generator.appliesPreferredTrackTransform = YES;
            NSError *error = nil;
            CMTime time = CMTimeMake(1, 1); // 3/1 = 3 second(s)
            CGImageRef imgRef = [generator copyCGImageAtTime:time actualTime:nil error:&error];
            if (error != nil)
                NSLog(@"%@: %@", self, error);
            thumbnail = [[UIImage alloc] initWithCGImage:imgRef];
            CGImageRelease(imgRef);
            
            UIImage *image = thumbnail;
            if (!thumbnail)
                image = [UIImage iconForFileType:file.fileType];
            
            if (image) //decompression (speed)
            {
                UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
                
                [image drawAtPoint:CGPointZero];
                
                image = UIGraphicsGetImageFromCurrentImageContext();
                
                UIGraphicsEndImageContext();
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.fileIconImageView.image = image;
            });
        });
    }
    else if (file.fileType == CLFileTypeImage)
    {
        dispatch_async(dispatch_queue_create("com.ac.table", NULL), ^{
            UIImage *image = [UIImage imageWithContentsOfFile:file.filePath];
            if (!image)
                image = [UIImage iconForFileType:file.fileType];
            if (image) //decompression (speed)
            {
                UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
                
                [image drawAtPoint:CGPointZero];
                
                image = UIGraphicsGetImageFromCurrentImageContext();
                
                UIGraphicsEndImageContext();
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.fileIconImageView.image = image;
            });
        });
    }
    else if (file.fileType == CLFileTypeMusic)
    {
        dispatch_async(dispatch_queue_create("com.ac.table", NULL), ^{
            CLAudioItem *audioItem = [[CLAudioItem alloc] initWithFile:file];
            UIImage *image = audioItem.albumArtworkImage;
            if ([audioItem.albumArtworkImage isEqual:[UIImage imageNamed:@"noart.png"]])
                image = [UIImage iconForFileType:file.fileType];
            if (image) //decompression (speed)
            {
                UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
                
                [image drawAtPoint:CGPointZero];
                
                image = UIGraphicsGetImageFromCurrentImageContext();
                
                UIGraphicsEndImageContext();
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.fileIconImageView.image = image;
            });
        });
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.isEditing)
        return;
    
    CLFile *selectedFile = self.files[indexPath.row];
    
    [CLFileOpener openFile:selectedFile sender:self];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:[self.files[indexPath.row] filePath] error:&error];
        if (error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                ACAlertView *errorAlert = [ACAlertView alertWithTitle:@"Error" style:ACAlertViewStyleTextView delegate:nil buttonTitles:@[@"Close"]];
                errorAlert.textView.text = error.localizedDescription;
                [errorAlert show];
            });
            
            return;
        }
        
        self.files = [[NSFileManager defaultManager] filesFromDirectoryAtPath:self.directory.filePath error:&error];
        if (error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                ACAlertView *errorAlert = [ACAlertView alertWithTitle:@"Error" style:ACAlertViewStyleTextView delegate:nil buttonTitles:@[@"Close"]];
                errorAlert.textView.text = error.localizedDescription;
                [errorAlert show];
            });
            return;
        }
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if (editing)
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createFile)];
        [self.navigationController setToolbarHidden:NO animated:YES];
        
        UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteFiles)];
        UIBarButtonItem *flex1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *compress = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"archive-50.png"] style:UIBarButtonItemStylePlain target:self action:@selector(compressFiles)];
        UIBarButtonItem *flex2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *bluetooth = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bluetooth-50.png"] style:UIBarButtonItemStylePlain target:self action:@selector(bluetooth)];
        
        UIBarButtonItem *flex3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *copyPaste = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(copyPaste)];
        
        [self setToolbarItems:@[deleteButton, flex1, compress, flex2, bluetooth, flex3, copyPaste] animated:YES];
    }
    else
    {
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
        [self.navigationController setToolbarHidden:YES animated:YES];
    }
}

- (void)openFileOptions:(UILongPressGestureRecognizer *)sender
{
    if (sender.state != UIGestureRecognizerStateBegan)
        return;
    
    CGPoint swipeLocation = [sender locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    CLFile *file = self.files[indexPath.row];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:file.filePath delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Open as..." otherButtonTitles:@"Properties", @"Compress", @"Copy", @"Cut", nil];// @"More...", nil];
    actionSheet.tag = FILEOPTIONS_ACTIONSHEET;
    [actionSheet showInView:self.tableView];
}

#pragma mark - File Operations

- (void)bluetooth
{
    NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
    if (selectedIndexPaths.count > 0)
    {
        NSMutableArray *filePaths = [NSMutableArray array];
        for (NSIndexPath *indexPath in selectedIndexPaths)
        {
            [filePaths addObject:[self.files[indexPath.row] filePath]];
        }
        NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *outputFilePath = [cachesDirectory stringByAppendingPathComponent:@"FILE_TRANSFER.zip"];
        dispatch_async(dispatch_queue_create("com.ac", NULL), ^{
            
            [ACZip compressFiles:filePaths destination:outputFilePath compressionType:ACZipCompressionTypeZip completion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    fileTransfer = [[CLFileTransfer alloc] initWithDisplayName:[[UIDevice currentDevice] name] filePath:outputFilePath];
                    [self presentViewController:fileTransfer.browserViewController animated:YES completion:^{
                        [fileTransfer.browserViewController.browser startBrowsingForPeers];
                    }];
                });
            }];
        });
    }
    else
    {
        if (fileTransfer)
            return;
        fileTransfer = [[CLFileTransfer alloc] initWithDisplayName:[[UIDevice currentDevice] name] filePath:nil];
        fileTransfer.directoryPath = self.directory.filePath;
    }
}

- (void)compressFiles
{
    ACAlertView *alertView = [ACAlertView alertWithTitle:@"Compress Files" style:ACAlertViewStyleTextField delegate:self buttonTitles:@[@"Cancel", @"Compress"]];
    alertView.textField.text = @"File.zip";
    [alertView show];
    alertView.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    alertView.textField.keyboardType = UIKeyboardTypeWebSearch;
    
    [alertView.textField becomeFirstResponder];
    alertView.textField.selectedTextRange = [alertView.textField textRangeFromPosition:alertView.textField.beginningOfDocument toPosition:[alertView.textField positionFromPosition:alertView.textField.beginningOfDocument offset:4]];
}

- (void)deleteFiles
{
    NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
    if (selectedIndexPaths)
    {
        for (NSIndexPath *indexPath in selectedIndexPaths)
        {
            CLFile *file = self.files[indexPath.row];
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:file.filePath error:&error];
            if (error)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    ACAlertView *errorAlert = [ACAlertView alertWithTitle:@"Error" style:ACAlertViewStyleTextView delegate:nil buttonTitles:@[@"Close"]];
                    errorAlert.textView.text = error.localizedDescription;
                    [errorAlert show];
                });
                break;
            }
        }
    }
    [self refreshFiles];
}

- (void)copyPaste
{
    UIPasteboard *pasteboard = [UIPasteboard pasteboardWithName:@"CLFileNavigatorPaths" create:YES];
    BOOL paste = ([pasteboard strings]) ? YES : NO;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Copy", @"Cut", (paste) ? @"Paste" : nil, nil];
    actionSheet.tag = COPYPASTE_ACTIONSHEET;
    [actionSheet showFromToolbar:self.navigationController.toolbar];
}

- (void)createFile
{
    ACAlertView *alertView = [ACAlertView alertWithTitle:@"New Item" style:ACAlertViewStyleTextFieldAndPickerView delegate:self buttonTitles:@[@"Cancel", @"Done"]];
    alertView.pickerViewItems = @[@"File", @"Folder"];
    alertView.textField.text = @"Item name";
    [alertView show];
    [alertView.textField selectAll:nil];
}

#pragma mark - Search Results

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchText = searchController.searchBar.text;
    NSMutableArray *newFiles = [NSMutableArray array];
    NSError *error;
    self.files = [[NSFileManager defaultManager] filesFromDirectoryAtPath:self.directory.filePath error:&error];
    if (error)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            ACAlertView *errorAlert = [ACAlertView alertWithTitle:@"Error" style:ACAlertViewStyleTextView delegate:nil buttonTitles:@[@"Close"]];
            errorAlert.textView.text = error.localizedDescription;
            [errorAlert show];
        });
        
        return;
    }
    
    for (CLFile *file in self.files)
        if ([file.fileName rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound)
            [newFiles addObject:file];
    self.files = [NSArray arrayWithArray:newFiles];
    [self.tableView reloadData];
}

- (void)didDismissSearchController:(UISearchController *)searchController
{
    NSError *error;
    self.files = [[NSFileManager defaultManager] filesFromDirectoryAtPath:self.directory.filePath error:&error];
    if (error)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            ACAlertView *errorAlert = [ACAlertView alertWithTitle:@"Error" style:ACAlertViewStyleTextView delegate:nil buttonTitles:@[@"Close"]];
            errorAlert.textView.text = error.localizedDescription;
            [errorAlert show];
        });
        
        return;
    }
    [self.tableView reloadData];
}

#pragma mark - Alert View Delegate

- (void)alertView:(ACAlertView *)alertView didClickButtonWithTitle:(NSString *)title
{
    [alertView dismiss];
    
    if ([title isEqualToString:@"Cancel"])
        return;
    
    if ([title isEqualToString:@"Compress"])
    {
        NSString *zipFilePath = [self.directory.filePath stringByAppendingPathComponent:alertView.textField.text];
        
        NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
        NSMutableArray *filePaths = [NSMutableArray array];
        for (NSIndexPath *indexPath in indexPaths)
            [filePaths addObject:[self.files[indexPath.row] filePath]];
        
        dispatch_async(dispatch_queue_create("com.aczip", NULL), ^{
            [ACZip compressFiles:filePaths destination:zipFilePath compressionType:ACZipCompressionTypeZip];
        });
        
        return;
    }
    
    NSString *itemType = alertView.pickerViewButton.titleLabel.text;
    NSString *itemPath = [self.directory.filePath stringByAppendingPathComponent:alertView.textField.text];
    
    if ([itemType isEqualToString:@"File"])
        [[NSFileManager defaultManager] createFileAtPath:itemPath contents:nil attributes:nil];
    else if ([itemType isEqualToString:@"Folder"])
    {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:itemPath withIntermediateDirectories:NO attributes:nil error:&error];
        if (error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                ACAlertView *errorAlert = [ACAlertView alertWithTitle:@"Error" style:ACAlertViewStyleTextView delegate:nil buttonTitles:@[@"Close"]];
                errorAlert.textView.text = error.localizedDescription;
                [errorAlert show];
            });
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:CLDirectoryViewControllerRefreshNotification object:nil];
}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [actionSheet cancelButtonIndex])
        return;
    
    if (actionSheet.tag == COPYPASTE_ACTIONSHEET)
    {
        UIPasteboard *pathsPasteboard = [UIPasteboard pasteboardWithName:@"CLFileNavigatorPaths" create:YES];
        UIPasteboard *modePasteboard = [UIPasteboard pasteboardWithName:@"CLFileNavigatorMode" create:YES];
        
        if (buttonIndex == 0 || buttonIndex == 1)
        {
            NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
            if (!selectedIndexPaths)
                return;
            NSMutableArray *filePaths = [NSMutableArray array];
            for (NSIndexPath *indexPath in selectedIndexPaths)
            {
                CLFile *file = self.files[indexPath.row];
                [filePaths addObject:file.filePath];
            }
            NSString *mode = (buttonIndex == 0) ? @"copy" : @"cut";
            
            [pathsPasteboard setStrings:filePaths];
            [modePasteboard setString:mode];
            return;
        }
        
        NSString *mode = [modePasteboard string];
        NSArray *filePaths = [pathsPasteboard strings];
        
        for (NSString *path in filePaths)
        {
            NSString *newPath = [self.directory.filePath stringByAppendingPathComponent:path.lastPathComponent];
            
            NSError *error;
            ([mode isEqualToString:@"copy"]) ? [[NSFileManager defaultManager] copyItemAtPath:path toPath:newPath error:&error] : [[NSFileManager defaultManager] moveItemAtPath:path toPath:newPath error:&error];
            if (error)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    ACAlertView *errorAlert = [ACAlertView alertWithTitle:@"Error" style:ACAlertViewStyleTextView delegate:nil buttonTitles:@[@"Close"]];
                    errorAlert.textView.text = error.localizedDescription;
                    [errorAlert show];
                });
                
                return;
            }
        }
        
        [self refreshFiles];
    }
    else if (actionSheet.tag == FILEOPTIONS_ACTIONSHEET)
    {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        NSString *filePath = actionSheet.title;
        
        if ([buttonTitle isEqualToString:@"Cancel"])
            return;
        else if ([buttonTitle isEqualToString:@"Open as..."])
        {
            NSTimer *alertTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(presentOpenAsForFile:) userInfo:@{@"path" : filePath} repeats:NO];
            [[NSRunLoop currentRunLoop] addTimer:alertTimer forMode:NSRunLoopCommonModes];
        }
        else if ([buttonTitle isEqualToString:@"Properties"])
        {
            CLFilePropertiesViewController *propertiesViewController = [[CLFilePropertiesViewController alloc] initWithFilePath:filePath];
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:propertiesViewController];
            [self presentViewController:navController animated:YES completion:nil];
        }
        else if ([buttonTitle isEqualToString:@"Compress"])
        {
            CLFile *file = [CLFile fileWithPath:filePath error:nil];
            if ([file isDirectory])
            {
                NSTimer *alertTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(compressDirectory:) userInfo:@{@"path" : filePath} repeats:NO];
                [[NSRunLoop currentRunLoop] addTimer:alertTimer forMode:NSRunLoopCommonModes];
                return;
            }
            NSTimer *alertTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(presentCompressAsForFile:) userInfo:@{@"path" : filePath} repeats:NO];
            [[NSRunLoop currentRunLoop] addTimer:alertTimer forMode:NSRunLoopCommonModes];
        }
        else if ([buttonTitle isEqualToString:@"Copy"] || [buttonTitle isEqualToString:@"Cut"])
        {
            UIPasteboard *pathsPasteboard = [UIPasteboard pasteboardWithName:@"CLFileNavigatorPaths" create:YES];
            UIPasteboard *modePasteboard = [UIPasteboard pasteboardWithName:@"CLFileNavigatorMode" create:YES];
            
            NSString *mode = buttonTitle.lowercaseString;
            
            [pathsPasteboard setStrings:@[filePath]];
            [modePasteboard setString:mode];
        }
        else if ([buttonTitle isEqualToString:@"More..."])
        {

        }
    }
}

- (void)compressDirectory:(NSTimer *)timer
{
    NSString *filePath = timer.userInfo[@"path"];
    CLFile *file = [CLFile fileWithPath:filePath error:nil];
    
    NSMutableArray *filePaths = [NSMutableArray array];
    for (CLFile *f in file.directoryContents)
    {
        [filePaths addObject:f.filePath];
    }
    
    dispatch_async(dispatch_queue_create("com.ac", NULL), ^{
        [ACZip compressFiles:filePaths destination:[filePath.stringByDeletingPathExtension stringByAppendingPathExtension:@"zip"] compressionType:ACZipCompressionTypeZip];
    });
}

- (void)presentCompressAsForFile:(NSTimer *)timer
{
    NSString *path = timer.userInfo[@"path"];
    ACAlertView *alertView = [ACAlertView alertWithTitle:@"Compress" style:ACAlertViewStylePickerView delegate:nil buttonTitles:@[@"Cancel", @"Compress"]];
    alertView.pickerViewItems = @[@"Zip", @"Gzip", @"Bzip2"];
    
    NSArray *compressionTypes = @[@(ACZipCompressionTypeZip), @(ACZipCompressionTypeGzip), @(ACZipCompressionTypeBzip2)];
    [alertView showWithSelectionHandler:^(ACAlertView *alertView, NSString *buttonTitle)
     {
         [alertView dismiss];
         
         if ([buttonTitle isEqualToString:@"Cancel"])
             return;
         
         NSInteger idx = [alertView.pickerViewItems indexOfObject:alertView.pickerViewButton.titleLabel.text];
         [ACZip compressFile:path compressionType:[compressionTypes[idx] integerValue]];
     }];
}

- (void)presentOpenAsForFile:(NSTimer *)path
{
    [CLFileOpener openFileAtPath:path.userInfo[@"path"] type:CLFileTypeUnknown sender:self];
}

@end
