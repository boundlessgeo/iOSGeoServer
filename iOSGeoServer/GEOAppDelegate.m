//
//  GEOAppDelegate.m
//  iOSGeoServer
//
//  Created by Justin Deoliveira on 2014-05-06.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "GEOAppDelegate.h"
#import "GEOJSONWriter.h"
#import "RoutingHttpServer.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "ogr_api.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation GEOAppDelegate

- (void)startServer
{
	NSError *error;
	if([http start:&error])
	{
		DDLogInfo(@"Started HTTP Server on port %hu", [http listeningPort]);
        DDLogInfo(@"Data directory is %@", [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Geodata"]);
	}
	else
	{
		DDLogError(@"Error starting HTTP Server: %@", error);
	}
}

- (void)encodeAsGeoJSON:(OGRLayerH)layer withStream:(NSOutputStream *) stream {
    GEOJSONWriter *w = [[GEOJSONWriter alloc]initWithStream:stream];
    [w features:layer];
}

- (void)loadData:(RouteRequest *)req withResponse:(RouteResponse*) res
{
    NSString *name = [req param:@"name"];
 
    NSString *dataPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Geodata"];
    NSString *shpfile = [NSString stringWithFormat:@"%@/%@.shp", dataPath, name];
 
    if (![[NSFileManager defaultManager] fileExistsAtPath: shpfile]) {
        [res setStatusCode:404];
        [res respondWithString:[NSString stringWithFormat: @"Layer %@ not found", name]];

        return;
    }

    OGRDataSourceH shp = OGROpen([shpfile UTF8String], FALSE, NULL);
    OGRLayerH states = OGR_DS_GetLayerByName(shp, [name UTF8String]);

    NSOutputStream *stream = [NSOutputStream outputStreamToMemory];
    [stream open];
    
    [self encodeAsGeoJSON:states withStream:stream];
    NSData *data = [stream propertyForKey: NSStreamDataWrittenToMemoryStreamKey];
    
    [res setHeader:@"Content-Type" value:@"application/json"];
    [res respondWithData:data];
    
    [stream close];

    OGR_DS_Destroy(shp);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // configure logging
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	
    // initialize ogr
    OGRRegisterAll();

    // setup the http server
    http = [[RoutingHTTPServer alloc]init];
    [http setDocumentRoot:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"]];
    [http setPort:8000];
    [http handleMethod:@"GET" withPath: @"/features/:name" block:^(RouteRequest *request, RouteResponse *response) {
        [self loadData:request withResponse: response];
    }];
    
    [self startServer];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [http stop];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self startServer];
    //[application openURL:[NSURL URLWithString:@"http://localhost:8000"]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{


}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

@end
