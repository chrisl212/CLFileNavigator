//
//  CLFileTransfer.h
//  CLFileNavigator
//
//  Created by Christopher Loonam on 8/26/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface CLFileTransfer : NSObject <MCSessionDelegate, MCAdvertiserAssistantDelegate, MCBrowserViewControllerDelegate>

@property (strong, nonatomic) MCSession *session;
@property (strong, nonatomic) MCPeerID *localPeerID;
@property (strong, nonatomic) MCAdvertiserAssistant *advertiserAssistant;
@property (strong, nonatomic) MCBrowserViewController *browserViewController;
@property (strong, nonatomic) NSString *filePath;
@property (strong, nonatomic) NSString *directoryPath; //if this device is receiving the file, the directory to which the files will be saved

- (id)initWithDisplayName:(NSString *)name filePath:(NSString *)path;

@end
