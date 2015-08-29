//
//  CLFileTransfer.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/26/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "CLFileTransfer.h"
#import "ACAlertView.h"
#import "ACUnzip.h"

NSString *const CLFileTransferService = @"cl-file";

@implementation CLFileTransfer
{
    ACAlertView *progressAlertView;
}

- (id)initWithDisplayName:(NSString *)name filePath:(NSString *)path
{
    if (self = [super init])
    {
        self.localPeerID = [[MCPeerID alloc] initWithDisplayName:name];
        self.session = [[MCSession alloc] initWithPeer:self.localPeerID securityIdentity:nil encryptionPreference:MCEncryptionNone];
        self.session.delegate = self;
        
        self.browserViewController = [[MCBrowserViewController alloc] initWithServiceType:CLFileTransferService session:self.session];
        self.browserViewController.delegate = self;
        
        self.advertiserAssistant = [[MCAdvertiserAssistant alloc] initWithServiceType:CLFileTransferService discoveryInfo:nil session:self.session];
        self.advertiserAssistant.delegate = self;
        [self.advertiserAssistant start];
        
        self.filePath = path;
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"fractionCompleted"])
    {
        NSProgress *progress = (NSProgress *)object;
        dispatch_sync(dispatch_get_main_queue(), ^{
            progressAlertView.progressView.progress = progress.fractionCompleted;
        });
    }
}

#pragma mark - Session Delegate

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnected && self.filePath)
    {
        [self.session sendResourceAtURL:[NSURL fileURLWithPath:self.filePath] withName:self.filePath.lastPathComponent toPeer:peerID withCompletionHandler:^(NSError *err){
            [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:nil];
        }];
    }
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        progressAlertView = [ACAlertView alertWithTitle:@"Downloading..." style:ACAlertViewStyleProgressView delegate:nil buttonTitles:@[@"Hide"]];
        [progress addObserver:self forKeyPath:@"fractionCompleted" options:kNilOptions context:NULL];
        [progressAlertView show];
    });
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    [self.advertiserAssistant stop];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *temporaryFilePath = [documentsDirectory stringByAppendingPathComponent:resourceName];
    [[NSFileManager defaultManager] moveItemAtURL:localURL toURL:[NSURL fileURLWithPath:temporaryFilePath] error:nil];
    
    [ACUnzip decompressFiles:temporaryFilePath toDirectory:self.directoryPath fileType:ACUnzipFileTypeZip completion:^{
        [[NSFileManager defaultManager] removeItemAtPath:temporaryFilePath error:nil];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [progressAlertView dismiss];
        });
    }];
}

#pragma mark - Browser View Controller Delegate

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:nil];
    [self.browserViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    [self.browserViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Advertiser Assistant Delegate

@end
