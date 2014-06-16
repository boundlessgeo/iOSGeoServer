//
//  GEOJSONWriter.m
//  iOSGeoServer
//
//  Created by Justin Deoliveira on 2014-05-06.
//  Copyright (c) 2014 Justin Deoliveira. All rights reserved.
//

#import "GEOJSONWriter.h"
#import "OrderedDictionary.h"
#import "ogr_api.h"

@implementation GEOJSONWriter

-(id)initWithStream:(NSOutputStream *)stream {
    self = [super init];
    if (self) {
        _stream = stream;
    }
    return self;
}

-(id)point:(double)xval y:(double)yval {
    NSMutableDictionary *obj = [[OrderedDictionary alloc] init];
    [obj setObject:@"Point" forKey:@"type"];

    NSMutableArray *coord = [[NSMutableArray alloc]init];
    [coord addObject:[NSNumber numberWithFloat: xval]];
    [coord addObject:[NSNumber numberWithFloat: yval]];
                             
    [obj setObject:coord forKey:@"coordinates"];

    [NSJSONSerialization writeJSONObject:obj toStream:_stream
                                 options:0 error:NULL];
    return self;
}

-(id)features:(OGRLayerH)layer {
    NSMutableDictionary *obj = [[OrderedDictionary alloc] init];
    [obj setObject:@"FeatureCollection" forKey:@"type"];

    NSMutableArray *features = [[NSMutableArray alloc]init];
    [obj setObject:features forKey:@"features"];

    OGRFeatureH f;
    OGR_L_ResetReading(layer);
    while((f = OGR_L_GetNextFeature(layer)) != NULL) {
        [features addObject:[self encodeFeature: f]];
        OGR_F_Destroy(f);
    }
    
    [NSJSONSerialization writeJSONObject:obj toStream:_stream
                                 options:0 error:NULL];
    return self;
}

-(NSMutableDictionary*)encodeFeature:(OGRFeatureH)f {
    
    NSMutableDictionary *obj = [[OrderedDictionary alloc] init];
    [obj setObject:@"Feature" forKey:@"type"];

    NSMutableDictionary *props = [[NSMutableDictionary alloc]init];
    [obj setObject:props forKey:@"properties"];

    OGRGeometryH geom = OGR_F_GetGeometryRef(f);
    if (geom != NULL) {
        [obj setObject:[self encodeGeometry:geom] forKey: @"geometry"];
    }
    OGRFeatureDefnH schema = OGR_F_GetDefnRef(f);
    for(int i = 0; i < OGR_FD_GetFieldCount(schema); i++ )
    {
        OGRFieldDefnH field = OGR_FD_GetFieldDefn( schema, i );

        const char *fieldName =OGR_Fld_GetNameRef(field);
        NSString *key = [NSString stringWithUTF8String:fieldName];

        if( OGR_Fld_GetType(field) == OFTInteger ) {
            [props setObject:[NSNumber numberWithInt:OGR_F_GetFieldAsInteger(f, i)] forKey: key];
        }
        else if( OGR_Fld_GetType(field) == OFTReal ) {
            [props setObject:[NSNumber numberWithDouble:OGR_F_GetFieldAsDouble(f, i)] forKey: key];
        }
        else {
            [props setObject:[NSString stringWithUTF8String:OGR_F_GetFieldAsString(f, i)] forKey: key];
        }
    }

    return obj;
}

-(NSMutableDictionary*)encodeGeometry:(OGRGeometryH)g {
    NSMutableDictionary *geom = [[OrderedDictionary alloc]init];

    int gtype = wkbFlatten(OGR_G_GetGeometryType(g));
    if (gtype == wkbGeometryCollection) {
        [geom setObject:@"GeometryCollection" forKey:@"type"];
        [geom setObject:[self encodeGeometryCollection:g] forKey:@"geometries"];
    }
    else {
        NSString* type;
        NSMutableArray *coords;
        
        switch(gtype) {
            case wkbPoint:
                type = @"Point";
                coords = [self encodePoint:g index:0];
                break;
            case wkbLineString:
                type = @"LineString";
                coords = [self encodeLineString:g];
                break;
            case wkbPolygon:
                type = @"Polygon";
                coords = [self encodePolygon:g];
                break;
            case wkbMultiPoint:
                type = @"MultiPoint";
                coords = [self encodeMultiPoint:g];
                break;
            case wkbMultiLineString:
                type = @"MultiLineString";
                coords = [self encodeMultiLineString:g];
                break;
            case wkbMultiPolygon:
                type = @"MultiPolygon";
                coords = [self encodeMultiPolygon:g];
                break;
        }
        [geom setObject:type forKey:@"type"];
        [geom setObject:coords forKey:@"coordinates"];

    }
    
    return geom;
}

-(NSMutableArray*)encodePoint:(OGRGeometryH)p index:(int)i {
    NSMutableArray *coord = [[NSMutableArray alloc] init];
    [coord addObject:[NSNumber numberWithDouble:OGR_G_GetX(p, i)]];
    [coord addObject:[NSNumber numberWithDouble:OGR_G_GetY(p, i)]];
    return coord;
}

-(NSMutableArray*)encodeLineString:(OGRGeometryH)l {
    NSMutableArray *coords = [[NSMutableArray alloc] init];
    int n = OGR_G_GetPointCount(l);
    for (int i = 0; i < n; i++) {
        [coords addObject:[self encodePoint:l index:i]];
    }
    return coords;
}

-(NSMutableArray*)encodePolygon:(OGRGeometryH)p {
    NSMutableArray *coord = [[NSMutableArray alloc] init];
    int n = OGR_G_GetGeometryCount(p);
    for (int i = 0; i < n; i++) {
        [coord addObject:[self encodeLineString:OGR_G_GetGeometryRef(p, i)]];
    }
    return coord;
}

-(NSMutableArray*)encodeMultiPoint:(OGRGeometryH)mp {
    NSMutableArray *coord = [[NSMutableArray alloc] init];
    int n = OGR_G_GetGeometryCount(mp);
    for (int i = 0; i < n; i++) {
        [coord addObject:[self encodePoint:OGR_G_GetGeometryRef(mp, i) index:0]];
    }
    return coord;
}

-(NSMutableArray*)encodeMultiLineString:(OGRGeometryH)ml {
    NSMutableArray *coord = [[NSMutableArray alloc] init];
    int n = OGR_G_GetGeometryCount(ml);
    for (int i = 0; i < n; i++) {
        [coord addObject:[self encodeLineString:OGR_G_GetGeometryRef(ml, i)]];
    }
    return coord;
}

-(NSMutableArray*)encodeMultiPolygon:(OGRGeometryH)mp {
    NSMutableArray *coord = [[NSMutableArray alloc] init];
    int n = OGR_G_GetGeometryCount(mp);
    for (int i = 0; i < n; i++) {
        [coord addObject:[self encodePolygon:OGR_G_GetGeometryRef(mp, i)]];
    }
    return coord;
}

-(NSMutableArray*)encodeGeometryCollection:(OGRGeometryH)gc {
    NSMutableArray *geoms = [[NSMutableArray alloc] init];
    int n = OGR_G_GetGeometryCount(gc);
    for (int i = 0; i < n; i++) {
        [geoms addObject:[self encodeGeometry: OGR_G_GetGeometryRef(gc, i)]];
    }
    return geoms;
}
@end
