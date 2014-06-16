//
//  GEOViewController.m
//  iOSGeoServer
//
//  Created by Justin Deoliveira on 2014-05-06.
//  Copyright (c) 2014 Justin Deoliveira. All rights reserved.
//

#import "GEOViewController.h"
#import "ogr_api.h"

@implementation GEOViewController
-(void)viewDidLoad{
    [super viewDidLoad];
    NSURLRequest *url = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8000"]];
    [self.webView loadRequest:url];
}
@end
