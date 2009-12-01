/* iTuneConnect
 * Copyright (C) 2009  Jason C. Martin
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

//
//  iTunesServer.m
//  iTuneConnect
//
//  Created by Jason C. Martin on 10/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <AudioToolbox/AudioToolbox.h>

#import "iTunesServer.h"
#import "TuneConnectServer.h"
#import "Common.h"

@implementation iTunesServer

#pragma mark -
#pragma mark iPod Status

- (void)fullStatus:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	float volume = [[MPMusicPlayerController iPodMusicPlayer] volume];
	NSTimeInterval progress = [[MPMusicPlayerController iPodMusicPlayer] currentPlaybackTime];
	MPMusicPlaybackState playbackstate = [[MPMusicPlayerController iPodMusicPlayer] playbackState];
	
	NSString *state = @"stopped";
	
	if(playbackstate == MPMusicPlaybackStatePlaying) {
		state = @"playing";
	} else if(playbackstate == MPMusicPlaybackStatePaused) {
		state = @"pasued";
	}
	
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"name"];
	[dictionary setValue:[NSNumber numberWithFloat:volume * 100] forKey:@"volume"];
	[dictionary setValue:[NSNumber numberWithInt:progress] forKey:@"progress"];
	[dictionary setValue:state forKey:@"playState"];
	
	if([[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem] != nil) {
		MPMediaItem *item = [[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem];
		
		[dictionary setValue:[item valueForProperty:MPMediaItemPropertyTitle] forKey:@"name"];
		[dictionary setValue:[item valueForProperty:MPMediaItemPropertyArtist] forKey:@"artist"];
		[dictionary setValue:[item valueForProperty:MPMediaItemPropertyAlbumTitle] forKey:@"album"];
		[dictionary setValue:[item valueForProperty:MPMediaItemPropertyPlaybackDuration] forKey:@"duration"];
		
		if([[params valueForKey:@"genre"] boolValue])
			[dictionary setValue:[item valueForProperty:MPMediaItemPropertyGenre] forKey:@"genre"];
		
		if([[params valueForKey:@"rating"] boolValue])
			[dictionary setValue:[item valueForProperty:MPMediaItemPropertyRating] forKey:@"rating"];
		
		if([[params valueForKey:@"composer"] boolValue])
			[dictionary setValue:[item valueForProperty:MPMediaItemPropertyComposer] forKey:@"composer"];
		
		if([[params valueForKey:@"playCount"] boolValue])
			[dictionary setValue:[item valueForProperty:MPMediaItemPropertyPlayCount] forKey:@"playCount"];
	}
	
	[server sendDictionary:dictionary asJSON:AS_JSON];
}

- (void)setPlayerPosition:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	if(![params valueForKey:@"position"])
		[server sendFourOhFour:AS_JSON];
	
	[[MPMusicPlayerController iPodMusicPlayer] setCurrentPlaybackTime:[[params valueForKey:@"position"] intValue]];
	
	[server sendSuccess:AS_JSON];
}

#pragma mark -
#pragma mark Sources and Playlists

- (void)getSources:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	// Only one kind of souce, doesn't really show up, so fake it.
	[server sendDictionary:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
																						@"Library", @"name",
																						@"39", @"id",
																						@"library", @"kind",
																						nil
																						]] forKey:@"sources"] asJSON:AS_JSON];
}

- (void)getPlaylists:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	MPMediaQuery *query = [MPMediaQuery playlistsQuery];
	
	NSArray *result = [query collections];
	
	NSMutableArray *items = [NSMutableArray array];
	
	for(MPMediaPlaylist *item in result) {
		if([[params valueForKey:@"dehydrated"] boolValue]) {
			[items addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							  [item valueForProperty:MPMediaPlaylistPropertyName], @"name",
							  [NSString stringWithFormat:@"%@:%@", [item valueForProperty:MPMediaPlaylistPropertyPersistentID], [params valueForKey:@"ofSource"]], @"ref",
							  nil
							  ]];
		} else {
			[items addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							  [item valueForProperty:MPMediaPlaylistPropertyPersistentID], @"id",
							  [item valueForProperty:MPMediaPlaylistPropertyName], @"name",
							  [params valueForKey:@"ofSource"], @"source",
							  [NSNumber numberWithUnsignedInt:[item count]], @"trackCount",
							  [NSNumber numberWithBool:[[item valueForProperty:MPMediaPlaylistPropertyPlaylistAttributes] intValue] & MPMediaPlaylistAttributeSmart], @"isSmart",
							  nil
							]];
		}
	}
	
	[server sendDictionary:[NSDictionary dictionaryWithObject:items forKey:@"playlists"] asJSON:AS_JSON];
}

- (void)artwork:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	MPMediaItemArtwork *artwork = [[[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem] valueForProperty:MPMediaItemPropertyArtwork];
	
	if(artwork == nil) {
		// send a 404, and return...
		[server sendFourOhFour:AS_JSON];
		return;
	}
	
	NSData *image = UIImagePNGRepresentation([artwork imageWithSize:[artwork bounds].size]);
	
	[server replyWithStatusCode:200 headers:[NSDictionary dictionaryWithObjectsAndKeys:
											 @"image/png", @"Content-type",
											 [NSNumber numberWithInt:[image length]], @"Content-Length",
											 nil
											 ]
						   body:image];
}

- (void)hydrate:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	if(![params hasKey:@"ref"]) {
		[server sendFourHundred:AS_JSON];
		
		return;
	}
	
	NSArray *refParts = [[[params valueForKey:@"ref"] stringByReplacingOccurrencesOfString:@"%3A" withString:@":"] componentsSeparatedByString:@":"];
	
	if([refParts count] == 2) {
		MPMediaQuery *query = [MPMediaQuery playlistsQuery];
		
		[query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[refParts objectAtIndex:0] forProperty:MPMediaPlaylistPropertyPersistentID]];
		
		MPMediaPlaylist *item = [[query collections] objectAtIndex:0];
		
		NSDictionary *playlist = [NSDictionary dictionaryWithObjectsAndKeys:
							  [item valueForProperty:MPMediaPlaylistPropertyPersistentID], @"id",
							  [item valueForProperty:MPMediaPlaylistPropertyName], @"name",
							  [refParts objectAtIndex:1], @"source",
							  [NSNumber numberWithUnsignedInt:[item count]], @"trackCount",
							  @"", @"specialKind",
							  nil
							  ];
		
		[server sendDictionary:playlist asJSON:AS_JSON];
		
		return;
	} else if([refParts count] == 3) {
		
	}
	
	[server sendFourHundred:AS_JSON];
}

#pragma mark -
#pragma mark iPod Control

- (void)play:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	[[MPMusicPlayerController iPodMusicPlayer] play];
	
	[server sendSuccess:AS_JSON];
}

- (void)pause:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	[[MPMusicPlayerController iPodMusicPlayer] pause];
	
	[server sendSuccess:AS_JSON];
}

- (void)playPause:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	if([[MPMusicPlayerController iPodMusicPlayer] playbackState] == MPMusicPlaybackStatePlaying)
		[[MPMusicPlayerController iPodMusicPlayer] pause];
	else
		[[MPMusicPlayerController iPodMusicPlayer] play];

	
	[server sendSuccess:AS_JSON];
}

- (void)stop:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	[[MPMusicPlayerController iPodMusicPlayer] stop];
	
	[server sendSuccess:AS_JSON];
}

- (void)nextTrack:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	[[MPMusicPlayerController iPodMusicPlayer] skipToNextItem];
	
	[server sendSuccess:AS_JSON];
}

- (void)prevTrack:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	[[MPMusicPlayerController iPodMusicPlayer] skipToPreviousItem];
	
	[server sendSuccess:AS_JSON];
}

- (void)setVolume:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	if(![[params valueForKey:@"volume"] boolValue])
		[server sendFourHundred:AS_JSON];
	
	// TuneConnect gives us a number between 0 and 100, but iPhone needs between 0.0 and 1.0.
	[[MPMusicPlayerController iPodMusicPlayer] setVolume:[[params valueForKey:@"volume"] floatValue] / 100];
	
	[server sendSuccess:AS_JSON];
}

- (void)volumeUp:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	float volume = [[MPMusicPlayerController iPodMusicPlayer] volume] + .1;
	
	if(volume > 1.0)
		volume == 1.0;
	
	[[MPMusicPlayerController iPodMusicPlayer] setVolume:volume];
	
	[server sendSuccess:AS_JSON];
}

- (void)volumeDown:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	float volume = [[MPMusicPlayerController iPodMusicPlayer] volume] - .1;
	
	if(volume < 0.0)
		volume == 0.0;
	
	[[MPMusicPlayerController iPodMusicPlayer] setVolume:volume];
	
	[server sendSuccess:AS_JSON];
}

#pragma mark -
#pragma mark Visualizations

- (void)visuals:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	// Fun part - this isn't supported on iPhone, so we have to fake it!
	[server sendDictionary:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
																						@"iTunes Classic Visualizer", @"name",
																						[NSNumber numberWithInt:26], @"id",nil]] forKey:@"visuals"] asJSON:AS_JSON];
}

- (void)visualSettings:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	// Fun part - this isn't supported on iPhone, so we have to fake it!
	[server sendDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
							@"iTunes Classic Visualizer", @"name",
							[NSNumber numberWithInt:26], @"id",
							[NSNumber numberWithBool:NO], @"fullScreen",
							[NSNumber numberWithBool:NO], @"displaying",
							@"large", @"size",
							nil
							] asJSON:AS_JSON];
}

#pragma mark -
#pragma mark Private Methods

// TODO: Finish implementation of this.

//- (NSArray *)composeTrackArray:(NSDictionary *)params {
//	NSArray *parts = [[params valueForKey:@"ofPlaylist"] componentsSeparatedByString:@":"];
//	
//	NSMutableArray *tracks = [NSMutableArray array];
//	
//	NSString *playlistID = [parts objectAtIndex:0];
//	NSString *sourceID = [parts objectAtIndex:1];
//	
//	NSArray *allTracks = [[[MPMediaQuery playlistsQuery] addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithUnsignedLongLong:[playlistID unsignedLongLongValue]] forProperty:MPMediaPlaylistPropertyPersistentID]] items];
//	
//	return nil;
//}

@end
