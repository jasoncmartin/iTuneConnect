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
#import <CommonCrypto/CommonDigest.h>

#import "iTunesServer.h"
#import "TuneConnectServer.h"
#import "Common.h"

@interface iTunesServer (PrivateMethods)

- (NSArray *)composeTrackArray:(NSDictionary *)params;
- (NSString *)createPlaylistSignature:(NSArray *)tracks;

@end


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
			[dictionary setValue:item.genre forKey:@"genre"];
		
		if([[params valueForKey:@"rating"] boolValue])
			[dictionary setValue:[NSString stringWithFormat:@"%i", item.rating] forKey:@"rating"];
		
		if([[params valueForKey:@"composer"] boolValue])
			[dictionary setValue:item.composer forKey:@"composer"];
		
		if([[params valueForKey:@"playCount"] boolValue])
			[dictionary setValue:[NSString stringWithFormat:@"%i", item.playCount] forKey:@"playCount"];
	}
	
	[server sendDictionary:dictionary asJSON:AS_JSON];
}

- (void)currentTrack:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"name"];

	if([[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem] != nil) {
		MPMediaItem *item = [[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem];
		
		[dictionary setValue:[item valueForProperty:MPMediaItemPropertyTitle] forKey:@"name"];
		[dictionary setValue:[item valueForProperty:MPMediaItemPropertyArtist] forKey:@"artist"];
		[dictionary setValue:[item valueForProperty:MPMediaItemPropertyAlbumTitle] forKey:@"album"];
		[dictionary setValue:[item valueForProperty:MPMediaItemPropertyPlaybackDuration] forKey:@"duration"];
		
		if([[params valueForKey:@"genre"] boolValue])
			[dictionary setValue:item.genre forKey:@"genre"];
		
		if([[params valueForKey:@"rating"] boolValue])
			[dictionary setValue:[NSNumber numberWithInt:item.rating] forKey:@"rating"];
		
		if([[params valueForKey:@"composer"] boolValue])
			[dictionary setValue:item.composer forKey:@"composer"];
		
		if([[params valueForKey:@"playCount"] boolValue])
			[dictionary setValue:[NSNumber numberWithInt:item.playCount] forKey:@"playCount"];
	}
	
	[server sendDictionary:dictionary asJSON:AS_JSON];
}

- (void)playerStatus:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
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
	[dictionary setValue:[NSNumber numberWithFloat:volume * 100] forKey:@"volume"];
	[dictionary setValue:[NSNumber numberWithInt:progress] forKey:@"progress"];
	[dictionary setValue:state forKey:@"playState"];
	
	[server sendDictionary:dictionary asJSON:AS_JSON];
}

- (void)setPlayerPosition:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	if(![params valueForKey:@"position"])
		[server sendFourOhFour:AS_JSON];
	
	[[MPMusicPlayerController iPodMusicPlayer] setCurrentPlaybackTime:[[params valueForKey:@"position"] intValue]];
	
	[server sendSuccess:AS_JSON];
}

- (void)playSettings:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	MPMusicRepeatMode repeatMode = [[MPMusicPlayerController iPodMusicPlayer] repeatMode];
	
	NSString *repeat = @"repeat-off";
	
	if(repeatMode == MPMusicRepeatModeOne) {
		repeat = @"repeat-one";
	} else if(repeatMode == MPMusicRepeatModeAll) {
		repeat = @"repeat-all";
	}
	
	[server sendDictionary:[NSDictionary dictionaryWithObjectsAndKeys:repeat, @"repeat", [NSNumber numberWithBool:([[MPMusicPlayerController iPodMusicPlayer] shuffleMode] == MPMusicShuffleModeSongs || [[MPMusicPlayerController iPodMusicPlayer] shuffleMode] == MPMusicShuffleModeAlbums)], @"shuffle", nil] asJSON:AS_JSON];
}

- (void)setPlaySettings:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	MPMusicRepeatMode repeatMode = MPMusicRepeatModeNone;
	
	if([[params valueForKey:@"repeat"] isEqualToString:@"repeat-one"]) {
		repeatMode = MPMusicRepeatModeOne;
	} else if([[params valueForKey:@"repeat"] isEqualToString:@"repeat-all"]) {
		repeatMode = MPMusicRepeatModeAll;
	}
	
	[[MPMusicPlayerController iPodMusicPlayer] setRepeatMode:repeatMode];
	
	if([[params valueForKey:@"shuffle"] boolValue]) {
		[[MPMusicPlayerController iPodMusicPlayer] setShuffleMode:MPMusicShuffleModeSongs];
	} else {
		[[MPMusicPlayerController iPodMusicPlayer] setShuffleMode:MPMusicShuffleModeOff];
	}
	
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
							  item.name, @"name",
							  [NSString stringWithFormat:@"%@:%@", [NSNumber numberWithUnsignedLongLong:item.persistentID], [params valueForKey:@"ofSource"]], @"ref",
							  nil
							  ]];
		} else {
			[items addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							  [NSNumber numberWithUnsignedLongLong:item.persistentID], @"id",
							  item.name, @"name",
							  [params valueForKey:@"ofSource"], @"source",
							  [NSNumber numberWithUnsignedInt:[item count]], @"trackCount",
							  [NSNumber numberWithBool:item.isSmart], @"isSmart",
							  nil
							]];
		}
	}
	
	[server sendDictionary:[NSDictionary dictionaryWithObject:items forKey:@"playlists"] asJSON:AS_JSON];
}

- (void)getTracks:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	NSArray *tracks = [self composeTrackArray:params];
	
	NSMutableDictionary *response = [NSMutableDictionary dictionaryWithObject:tracks forKey:@"tracks"];
	
	if([[params valueForKey:@"signature"] boolValue]) {
		[response setValue:[self createPlaylistSignature:tracks] forKey:@"signature"];
	}
	
	if([params hasKey:@"range"]) {
		NSLog(@"%@", [params valueForKey:@"range"]);
	}
	
	[server sendDictionary:response asJSON:AS_JSON];
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

// TODO: Finish implementation
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
							  [NSNumber numberWithUnsignedLongLong:item.persistentID], @"id",
							  item.name, @"name",
							  [refParts objectAtIndex:1], @"source",
							  [NSNumber numberWithInt:[item count]], @"trackCount",
							  @"", @"specialKind",
							  [NSNumber numberWithInt:item.duration], @"duration",
							  nil
							  ];
		
		[server sendDictionary:playlist asJSON:AS_JSON];
		
		return;
	} else if([refParts count] == 3) {
		MPMediaQuery *query = [MPMediaQuery songsQuery];
		
		[query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[refParts objectAtIndex:0] forProperty:MPMediaItemPropertyPersistentID]];
		
		MPMediaItem *item = [[query items] objectAtIndex:0];
		
		NSMutableDictionary *song = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 item.title, @"name",
									 [NSNumber numberWithInt:item.persistentID], @"id",
									 [refParts objectAtIndex:1], @"playlist",
									 [refParts objectAtIndex:2], @"source",
									 [NSNumber numberWithInt:item.playbackDuration], @"duration",
									 item.albumTitle, @"album",
									 item.artist, @"artist",
									 @"none", @"videoType",
									 nil
									 ];
		
		if([[params valueForKey:@"genre"] boolValue]) {
			[song setValue:item.genre forKey:@"genre"];
		}
		
		if([[params valueForKey:@"rating"] boolValue]) {
			[song setValue:[NSString stringWithFormat:@"%i", item.rating] forKey:@"rating"];
		}
		
		if([[params valueForKey:@"composer"] boolValue]) {
			[song setValue:item.composer forKey:@"composer"];
		}
		
		// Comments, Date Added, Bitrate, and Samplerate are currently not supported. But we have to provide something, otherwise the client will crash :(
		
		if([[params valueForKey:@"comments"] boolValue]) {
			[song setValue:[NSString string] forKey:@"comments"];
		}
		
		if([[params valueForKey:@"datesAdded"] boolValue]) {
			NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
			formatter.dateFormat = @"yyyy-mm-ddThh:mm:ssZ";
			
			[song setValue:[formatter stringFromDate:[NSDate date]] forKey:@"datesAdded"];
			[formatter release];
		}
		
		if([[params valueForKey:@"bitrate"] boolValue]) {
			[song setValue:[NSNumber numberWithInt:160] forKey:@"bitrate"];
		}
		
		if([[params valueForKey:@"sampleRate"] boolValue]) {
			[song setValue:[NSNumber numberWithInt:44100] forKey:@"sampleRate"];
		}
		
		if([[params valueForKey:@"playCounts"] boolValue]) {
			[song setValue:[NSNumber numberWithInt:item.playCount] forKey:@"playCount"];
		}
		
		[server sendDictionary:song asJSON:AS_JSON];
		
		return;
	}
	
	[server sendFourHundred:AS_JSON];
}

- (void)signature:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	NSDictionary *dictionary = [NSDictionary dictionaryWithObject:[self createPlaylistSignature:[self composeTrackArray:params]] forKey:@"signature"];
	
	[server sendDictionary:dictionary asJSON:AS_JSON];
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
		volume = 1.0;
	
	[[MPMusicPlayerController iPodMusicPlayer] setVolume:volume];
	
	[server sendSuccess:AS_JSON];
}

- (void)volumeDown:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	float volume = [[MPMusicPlayerController iPodMusicPlayer] volume] - .1;
	
	if(volume < 0.0)
		volume = 0.0;
	
	[[MPMusicPlayerController iPodMusicPlayer] setVolume:volume];
	
	[server sendSuccess:AS_JSON];
}

- (void)playPlaylist:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	if(![[params valueForKey:@"playlist"] boolValue]) {
		[server sendFourHundred:AS_JSON];
		
		return;
	}
	
	NSArray *parts = [[[params valueForKey:@"playlist"] stringByReplacingOccurrencesOfString:@"%3A" withString:@":"] componentsSeparatedByString:@":"];
	
	NSString *playlistID = [parts objectAtIndex:0];
	
	MPMediaQuery *query = [MPMediaQuery playlistsQuery];
	[query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithUnsignedLongLong:[playlistID unsignedLongLongValue]] forProperty:MPMediaPlaylistPropertyPersistentID]];
	
	if([[query collections] count] > 0) {
		MPMediaPlaylist *playlist = [[query collections] objectAtIndex:0];
		[[MPMusicPlayerController iPodMusicPlayer] setQueueWithItemCollection:playlist];
		[[MPMusicPlayerController iPodMusicPlayer] play];
	} else {
		[server sendFailure:AS_JSON];
	}
	
	[server sendSuccess:AS_JSON];
}

- (void)playTrack:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	if(![[params valueForKey:@"track"] boolValue]) {
		[server sendFourHundred:AS_JSON];
		
		return;
	}
	
	NSArray *parts = [[[params valueForKey:@"track"] stringByReplacingOccurrencesOfString:@"%3A" withString:@":"] componentsSeparatedByString:@":"];
	
	NSString *songID = [parts objectAtIndex:0];
	
	MPMediaQuery *query = [MPMediaQuery songsQuery];
	[query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithUnsignedLongLong:[songID unsignedLongLongValue]] forProperty:MPMediaItemPropertyPersistentID]];
	
	if([[query items] count] > 0) {
		MPMediaItem *song = [[query items] objectAtIndex:0];
		[[MPMusicPlayerController iPodMusicPlayer] setNowPlayingItem:song];
	} else {
		[server sendFailure:AS_JSON];
	}
	
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
#pragma mark Static Methods - Methods that return the same thing every time.

- (void)preload:(SimpleHTTPConnection *)connection withServer:(TuneConnectServer *)server andParameters:(NSDictionary *)params {
	[server sendDictionary:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"libraryReady"] asJSON:AS_JSON];
}

#pragma mark -
#pragma mark Private Methods

// TODO: Finish implementation of this.

- (NSArray *)composeTrackArray:(NSDictionary *)params {
	NSArray *parts = [[[params valueForKey:@"ofPlaylist"] stringByReplacingOccurrencesOfString:@"%3A" withString:@":"] componentsSeparatedByString:@":"];
	
	NSMutableArray *tracks = [NSMutableArray array];
	
	NSString *playlistID = [parts objectAtIndex:0];
	NSString *sourceID = [parts objectAtIndex:1];
	
	MPMediaQuery *query = [MPMediaQuery playlistsQuery];
	[query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithUnsignedLongLong:[playlistID unsignedLongLongValue]] forProperty:MPMediaPlaylistPropertyPersistentID]];
	
	NSArray *items = query.items;
	NSMutableDictionary *track;
	
	for(MPMediaItem *item in items) {
		track = [NSMutableDictionary dictionary];
		
		[track setValue:[item title] forKey:@"name"];
		
		if([[params valueForKey:@"dehydrated"] boolValue]) {
			[track setValue:[NSString stringWithFormat:@"%qu:%@:%@", item.persistentID, playlistID, sourceID] forKey:@"ref"];
		} else {
			[track setValue:[NSNumber numberWithUnsignedLongLong:item.persistentID] forKey:@"id"];
			[track setValue:[NSNumber numberWithInt:[playlistID intValue]] forKey:@"playlist"];
			[track setValue:[NSNumber numberWithInt:[sourceID intValue]] forKey:@"source"];
			[track setValue:[NSNumber numberWithInt:item.playbackDuration] forKey:@"duration"];
			[track setValue:item.albumTitle forKey:@"album"];
			[track setValue:item.artist forKey:@"artist"];
			[track setValue:@"none" forKey:@"videoType"];
		}
		
		if([[params valueForKey:@"genres"] boolValue]) {
			[track setValue:item.genre forKey:@"genre"];
		}
		
		if([[params valueForKey:@"ratings"] boolValue]) {
			[track setValue:[NSString stringWithFormat:@"%i", item.rating] forKey:@"rating"];
		}
		
		if([[params valueForKey:@"composers"] boolValue]) {
			[track setValue:item.composer forKey:@"composer"];
		}
		
		// Comments, Date Added, Bitrate, and Samplerate are currently not supported. But we have to provide something, otherwise the client will crash :(
		
		if([[params valueForKey:@"comments"] boolValue]) {
			[track setValue:[NSString string] forKey:@"comments"];
		}
		
		if([[params valueForKey:@"datesAdded"] boolValue]) {
			NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
			formatter.dateFormat = @"yyyy-mm-ddThh:mm:ssZ";
			
			[track setValue:[formatter stringFromDate:[NSDate date]] forKey:@"datesAdded"];
			[formatter release];
		}
		
		if([[params valueForKey:@"bitrate"] boolValue]) {
			[track setValue:[NSNumber numberWithInt:160] forKey:@"bitrate"];
		}
		
		if([[params valueForKey:@"sampleRate"] boolValue]) {
			[track setValue:[NSNumber numberWithInt:44100] forKey:@"sampleRate"];
		}
		
		if([[params valueForKey:@"playCounts"] boolValue]) {
			[track setValue:[NSNumber numberWithInt:item.playCount] forKey:@"playCount"];
		}
		
		// TODO: Add in filtering in the future.
		
		[tracks addObject:track];
	}
	
	return tracks;
}

- (NSString *)createPlaylistSignature:(NSArray *)tracks {
	return [[tracks JSONRepresentation] md5];
}

@end
