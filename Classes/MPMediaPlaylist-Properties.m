//
//  MPMediaPlaylist-Properties.m
//  iTuneConnect
//
//  Created by Jason C. Martin on 11/30/09.
//  Copyright 2009 New Media Geekz. All rights reserved.
//

#import "MPMediaPlaylist-Properties.h"


@implementation MPMediaPlaylist (Properties)

- (NSTimeInterval)duration {
	static NSTimeInterval interval = -1;
	
	if(interval == -1) {
		interval = 0;
		
		for(MPMediaItem *item in [self items]) {
			interval += [item valueForProperty:MPMediaItemPropertyPlaybackDuration];
		}
	}
	
	return interval;
}

- (long long)persistentID {
	return [[self valueForProperty:MPMediaPlaylistPropertyPersistentID] longLongValue];
}

- (NSString *)name {
	return [self valueForProperty:MPMediaPlaylistPropertyName];
}

- (NSArray *)seedItems {
	return [self valueForProperty:MPMediaPlaylistPropertySeedItems];
}

- (BOOL)isOnTheGo {
	return [[self valueForProperty:MPMediaPlaylistPropertyPlaylistAttributes] intValue] & MPMediaPlaylistAttributeOnTheGo;
}

- (BOOL)isGenius {
	return [[self valueForProperty:MPMediaPlaylistPropertyPlaylistAttributes] intValue] & MPMediaPlaylistAttributeGenius;
}

- (BOOL)isSmart {
	return [[self valueForProperty:MPMediaPlaylistPropertyPlaylistAttributes] intValue] & MPMediaPlaylistAttributeSmart;
}

@end
