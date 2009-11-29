//
//  NSDictionary+Additions.m
//  iTuneConnect
//
//  Created by Jason C. Martin on 10/31/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSDictionary+Additions.h"


@implementation NSDictionary (OurAdditions)

- (BOOL)hasKey:(id)testKey {
    return ([self objectForKey:testKey] != nil);
}

@end
