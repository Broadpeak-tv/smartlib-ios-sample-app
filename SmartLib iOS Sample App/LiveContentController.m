//
//  ViewController.m
//  SmartLib iOS Sample App
//
//  Created by Pierre-Olivier on 14/12/2022.
//

@import SmartLib;

#import "LiveContentController.h"

@interface LiveContentController ()

@property (nonatomic, strong) id<BMPPlayer> player;
@property (nonatomic,strong) StreamingSession *session;

@end

@implementation LiveContentController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Disable Bitmovin logging
    BMPDebugConfig.logging.logger = nil;
    
    // Do any additional setup after loading the view.
    BMPPlayerConfig *playerConfig = [BMPPlayerConfig new];
    playerConfig.key = @"<your_license_here>";
    self.player = [BMPPlayerFactory createWithPlayerConfig:playerConfig];
    
    // Create the player view and pass the player instance to it
    BMPPlayerView *playerView = [[BMPPlayerView alloc] initWithPlayer:self.player frame:CGRectZero];
    playerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    playerView.frame = self.view.bounds;
    
    [self.view addSubview:playerView];
    [self.view bringSubviewToFront:playerView];
    
    // Create SmartLib session
    self.session = [SmartLib createStreamingSession];
    // Attach the player on the same thread
    [self.session attachPlayer:self.player];
    
    // Run getURL in a thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        // Start the session and retrieve the streaming URL
        StreamingSessionResult *result = [self.session getURL:@"https://pf7.broadpeak-vcdn.com/bpk-tv/Arte/default/index.m3u8"];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (![result isError]) {
                // Add source
                NSURL *nsURL = [NSURL URLWithString:[result getURL]];
                
                BMPSourceConfig *sourceConfig = [[BMPSourceConfig alloc] initWithUrl:nsURL type: BMPSourceTypeHls];
                [self.player loadSourceConfig:sourceConfig];
                [self.player play];
            } else {
                NSLog(@"Error: %@", [result getErrorMessage]);
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
    }
    
    [super viewDidDisappear:animated];
}

@end
