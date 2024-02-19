//
//  ViewController.m
//  SmartLib iOS Sample App
//
//  Created by Pierre-Olivier on 14/12/2022.
//

// @import SmartLib;

#import "VodAdTrackingContentController.h"

static void *PlaybackStatusObservationContext = &PlaybackStatusObservationContext;

@interface VodAdTrackingContentController ()

@property (nonatomic,strong) StreamingSession *session;

@property (nonatomic,assign) long adEndPosition;
@property (nonatomic,assign) long adBreakEndPosition;

@end

@implementation VodAdTrackingContentController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Create the player
    AVPlayer *player = [AVPlayer playerWithPlayerItem:nil];
    
    [self.player setAllowsExternalPlayback:NO];
    [self.player setUsesExternalPlaybackWhileExternalScreenIsActive:YES];
    [self.player setAllowsAirPlayVideo:YES];
    [self.player setUsesAirPlayVideoWhileAirPlayScreenIsActive:YES];
    
    // Create SmartLib session
    self.session = [SmartLib createStreamingSession];
    
    // Attach the player on the same thread
    [self.session attachPlayer:player];
    
    [self.session activateAdvertising];
    [self.session setAdDataListener:self];
    [self.session setAdEventsListener:self];
    
    // Run getURL in a thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        // Start the session and retrieve the streaming URL
        StreamingSessionResult *result = [self.session getURL:@"https://stream.broadpeak.io/98dce83da57b03956f8ea3c5b949919a/scte35/bpk-tv/jumping/default/index.m3u8"];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (![result isError]) {
                // Prepare the player
                [player replaceCurrentItemWithPlayerItem:[self playerItemFromURL:[result getURL]]];
                self.player = player;
                
                [self.player.currentItem addObserver:self
                                          forKeyPath:@"status"
                                             options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                             context:PlaybackStatusObservationContext];
                
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
        
        [self.player.currentItem removeObserver:self
                                     forKeyPath:@"status"];
    
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

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    // On non-recoverable error, stop the current session
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (status == AVPlayerStatusFailed) {
            [self.session stopStreamingSession];
        }
    } else {
            [super observeValueForKeyPath: keyPath
                                 ofObject: object
                                   change: change
                                  context: context];
    }
    
}

- (void)onAdBreakBegin:(AdBreakData *)adBreak {
    NSLog(@"onAdBreakBegin %ld %ld %d", adBreak.startPosition, adBreak.duration, adBreak.adCount);
}

- (void)onAdBreakEnd:(AdBreakData *)adBreakData {
    NSLog(@"onAdBreakEnd");
    
}

- (void)onAdBegin:(AdData *)adData adBreakData:(AdBreakData *)adBreakData {
    NSLog(@"onAdBegin %ld %ld %@ %d %d", adData.startPosition, adData.duration, adData.clickURL, adData.index, adBreakData.adCount);
}

- (void)onAdSkippable:(AdData *)adData adBreakData:(AdBreakData *)adBreakData adSkippablePosition:(long)adSkippablePosition adEndPosition:(long)adEndPosition adBreakEndPosition:(long)adBreakEndPosition {
    self.adEndPosition = adEndPosition;
    self.adBreakEndPosition = adBreakEndPosition;
    NSLog(@"onAdSkippable %ld %ld %ld", adSkippablePosition, adEndPosition, adBreakEndPosition);
}

- (void)onAdEnd:(AdData *)adData adBreakData:(AdBreakData *)adBreakData {
    NSLog(@"onAdEnd");
}

- (void)onAdData:(nonnull NSArray<AdBreakData *> *)adList {
    NSLog(@"onAdData %@", adList);
}

- (IBAction)onSkipAd:(id)sender {
    [self.player seekToTime:CMTimeMakeWithSeconds(self.adEndPosition / 1000.f, 1)];
}


- (IBAction)onSkipAdBreak:(id)sender {
    [self.player seekToTime:CMTimeMakeWithSeconds(self.adEndPosition / 1000.f, 1)];
}


@end
