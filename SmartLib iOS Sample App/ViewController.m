//
//  ViewController.m
//  SmartLib iOS Sample App
//
//  Created by Pierre-Olivier on 14/12/2022.
//

#import "ViewController.h"

@import SmartLib; // on iOS

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [SmartLib initSmartLib:@"http://analytics-players.broadpeak.tv/"
               nanoCDNHost:@""
      broadpeakDomainNames:@"pf6.broadpeak-vcdn.com,bpk67.broadpeak-vcdn.com,stream.broadpeak.io"];
}


@end
