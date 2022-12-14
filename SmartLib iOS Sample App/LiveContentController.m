//
//  ViewController.m
//  SmartLib iOS Sample App
//
//  Created by Pierre-Olivier on 14/12/2022.
//

#import "LiveContentController.h"

@import SmartLib;

@interface LiveContentController ()

@property (nonatomic,strong) StreamingSession *session;

@end

@implementation LiveContentController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Create the player
    AVPlayer *player = [AVPlayer playerWithPlayerItem:nil];
    
    // Create SmartLib session
    self.session = [SmartLib createStreamingSession];
    
    // Attach the player on the same thread
    [self.session attachPlayer:player];
    
    // Run getURL in a thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        // Start the session and retrieve the streaming URL
        StreamingSessionResult *result = [self.session getURL:@"https://pf6.broadpeak-vcdn.com/bpk-vod/VOD/default/Broadtatou/index.m3u8"];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (![result isError]) {
                // Prepare the player
                [player replaceCurrentItemWithPlayerItem:[self playerItemFromURL:[result getURL]]];
                self.player = player;
                
                // Start the playback
                [self.player play];
            } else {
                // Stop the session if error
                [self.session stopStreamingSession];
            }
        });
    });
}


- (void)viewDidDisappear:(BOOL)animated {
    // Stop the session when closing the UI
    if (self.session != nil) {
        [self.player pause];
    
        [self.session stopStreamingSession];
        [self.player replaceCurrentItemWithPlayerItem:nil];
    }
    
    [super viewDidDisappear:animated];
}

- (AVPlayerItem*)playerItemFromURL:(NSString *)url {
    // Prepare asset.
    AVURLAsset *assetUrl = [AVURLAsset assetWithURL: [NSURL URLWithString: url]];
    AVPlayerItem *itemToPlay = [AVPlayerItem playerItemWithAsset: assetUrl];
    
    return itemToPlay;
}

@end
