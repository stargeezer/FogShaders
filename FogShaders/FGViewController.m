//
//  FGViewController.m
//  FogShaders
//
//  Created by Mark Strand on 12/5/12.
//  Copyright (c) 2012 Mark Strand. All rights reserved.
//

#import "FGViewController.h"

@interface FGViewController ()

@end

@implementation FGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // this sets up the app to support landscape only
    if ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) | (interfaceOrientation == UIInterfaceOrientationLandscapeRight))
    {
        return YES;
    }
    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
