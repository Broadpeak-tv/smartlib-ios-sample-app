//
//  ViewController.h
//  SmartLib iOS Sample App
//
//  Created by Pierre-Olivier on 14/12/2022.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import "SmartLib.h"

@interface VodAdTrackingContentController : AVPlayerViewController <AdEventsListener, AdDataListener>


@end

