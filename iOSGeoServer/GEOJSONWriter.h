//
//  GEOJSONWriter.h
//  iOSGeoServer
//
//  Created by Justin Deoliveira on 2014-05-06.
//  Copyright (c) 2014 Justin Deoliveira. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ogr_api.h"

@interface GEOJSONWriter : NSObject

@property NSOutputStream* stream;

-(id)initWithStream:(NSOutputStream*)stream;
-(id)features:(OGRLayerH)layer;

@end
