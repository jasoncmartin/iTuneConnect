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
//  iTuneConnectAppDelegate.m
//  iTuneConnect
//
//  Created by Jason C. Martin on 10/16/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "iTuneConnectAppDelegate.h"
#import "TuneConnectServer.h"
#import "Common.h"
#import "SettingsViewController.h"
#import <MediaPlayer/MediaPlayer.h>


@interface iTuneConnectAppDelegate (private)

- (void)registerNotifications;
- (void)playingItemChanged:(id)unused;

@end

@implementation iTuneConnectAppDelegate

@synthesize window, controller;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSNumber numberWithBool:NO], NSDefaultPasswordEnabled,
															 @"", NSDefaultPassword,
															 [NSNumber numberWithInt:4242], NSDefaultPort,
															 
															 // TODO: Remove settings below this comment.
															 
															 [NSNumber numberWithInt:86400], NSDefaultLibraryExpiryTime,
															 [NSNumber numberWithBool:YES], NSDefaultUseLibraryFile,
															 [NSNumber numberWithFloat:.6], NSDefaultDsThreshold,
															 nil
															 ]];
	
    // Override point for customization after application launch
	[self registerNotifications];
	
	[[MPMusicPlayerController iPodMusicPlayer] beginGeneratingPlaybackNotifications];
	
	[window addSubview:[controller view]];
	[window makeKeyAndVisible];
	
	server = [[TuneConnectServer alloc] init];
	
	[server setPort:[[NSUserDefaults standardUserDefaults] integerForKey:NSDefaultPort]];
	
	if([[NSUserDefaults standardUserDefaults] boolForKey:NSDefaultPasswordEnabled])
		[server setPassword:[[NSUserDefaults standardUserDefaults] stringForKey:NSDefaultPassword]];
	
	[server start];
	
	//inBackground = NO;
	
	[self playingItemChanged:nil];
}

- (void)registerNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playingItemChanged:) name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playingItemChanged:) name:UIApplicationBackgroundingNotification object:nil];
}

- (void)playingItemChanged:(id)unused {
	// Update the UI to reflect this new item.
	if([[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem] == nil)
		return;
	
	MPMediaItem *item = [[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem];
	
	UIImage *artwork = [[item valueForProperty:MPMediaItemPropertyArtwork] imageWithSize:CGSizeMake(320, 320)];
	
	if(!artwork)
		artwork = [UIImage imageNamed:@"no-art.png"];
	
	[artworkView setImage:artwork];
	
	[titleLabel setText:[item valueForProperty:MPMediaItemPropertyTitle]];
	[artistLabel setText:[item valueForProperty:MPMediaItemPropertyArtist]];
	[albumLabel setText:[item valueForProperty:MPMediaItemPropertyAlbumTitle]];
}

- (IBAction)showSettings:(id)unused {
	SettingsViewController *svc = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
	
	svc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	
	[controller presentModalViewController:svc animated:YES];
	
	[svc release];
}

- (void)dealloc {
	[[MPMusicPlayerController iPodMusicPlayer] endGeneratingPlaybackNotifications];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[server stop];
	[server release];
	server = nil;
	
	[controller release];
	controller = nil;
	
    [window release];
	window = nil;
	
    [super dealloc];
}


@end
