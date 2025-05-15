//
//  ViewController.m
//  SmartLib iOS Sample App
//
//  Created by Pierre-Olivier on 14/12/2022.
//

// @import SmartLib;

#import "VodAdTrackingContentController.h"

@interface VodAdTrackingContentController ()

@property (nonatomic, strong) id<BMPPlayer> player;
@property (nonatomic,strong) StreamingSession *session;

@property (nonatomic,assign) long adEndPosition;
@property (nonatomic,assign) long adBreakEndPosition;

@end

@implementation VodAdTrackingContentController

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
    [self.session activateAdvertising];
    [self.session setAdDataListener:self];
    [self.session setAdEventsListener:self];
    
    // Run getURL in a thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        // Start the session and retrieve the streaming URL
        StreamingSessionResult *result = [self.session getURL:@"https://d1z4ze793wle15.cloudfront.net/9bf31c7ff062936a41f7268a788903b1/AVOD/TOS-original-24fps-1080p/conditioned/stream.m3u8?bpkio_mids=69.91%2C257.91%2C588.40&bpkio_mids_offset=0&package=basic&category=all"];
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
- (void)onAdBreakBegin:(AdBreakData *)adBreakData {
    NSLog(@"onAdBreakBegin %@ %ld %ld %d", adBreakData.adBreakId, adBreakData.startPosition, adBreakData.duration, adBreakData.adCount);
}

- (void)onAdBreakEnd:(AdBreakData *)adBreakData {
    NSLog(@"onAdBreakEnd %@", adBreakData.adBreakId);
    
}

- (void)onAdBegin:(AdData *)adData adBreakData:(AdBreakData *)adBreakData {
    NSLog(@"onAdBegin %@ %ld %ld %@ %d %d", adData.adId, adData.startPosition, adData.duration, adData.clickURL, adData.index, adBreakData.adCount);
}

- (void)onAdSkippable:(AdData *)adData adBreakData:(AdBreakData *)adBreakData adSkippablePosition:(long)adSkippablePosition adEndPosition:(long)adEndPosition adBreakEndPosition:(long)adBreakEndPosition {
    self.adEndPosition = adEndPosition;
    self.adBreakEndPosition = adBreakEndPosition;
    NSLog(@"onAdSkippable %@ %ld %ld %ld", adData.adId, adSkippablePosition, adEndPosition, adBreakEndPosition);
}

- (void)onAdEnd:(AdData *)adData adBreakData:(AdBreakData *)adBreakData {
    NSLog(@"onAdEnd %@", adData.adId);
}

- (void)onAdData:(nonnull NSArray<AdBreakData *> *)adList {
    NSLog(@"onAdData %@", adList);
}

- (IBAction)onSkipAd:(id)sender {
    NSTimeInterval seekTo = self.adEndPosition / 1000.0;
    NSLog(@"onSkipAd, seek to %f", seekTo);
    [self.player seek:seekTo];
}


- (IBAction)onSkipAdBreak:(id)sender {
    NSTimeInterval seekTo = self.adBreakEndPosition / 1000.0;
    NSLog(@"onSkipAdBreak, seek to %f", seekTo);
    [self.player seek:seekTo];
}

@end
