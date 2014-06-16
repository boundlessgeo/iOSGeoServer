//
//  GEOAppDelegate.h
//  iOSGeoServer
//
//  Created by Justin Deoliveira on 2014-05-06.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RoutingHTTPServer;

@interface GEOAppDelegate : UIResponder <UIApplicationDelegate>
{
    RoutingHTTPServer *http;
}

@property (strong, nonatomic) UIWindow *window;

@end
