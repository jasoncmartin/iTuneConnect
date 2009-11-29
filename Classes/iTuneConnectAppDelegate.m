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

@interface UIApplication (BackgrounderStuff)

//- (BOOL)isBackgroundingEnabled;

@end


@interface iTuneConnectAppDelegate (private)

- (void)registerNotifications;
- (void)playingItemChanged:(id)unused;

@end

static void setBackgroundingEnabled(int signal)
{
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationBackgroundingNotification object:nil];
}

@implementation iTuneConnectAppDelegate

@synthesize window, controller;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
	if([[UIApplication sharedApplication] respondsToSelector:@selector(setBackgroundingEnabled:)]) {
		//TTSwapMethods([UIApplication class], @selector(setBackgroundingEnabled:), @selector(ourSetBackgroundingEnabled:));
		
		sigset_t block_mask;
		sigfillset(&block_mask);
		struct sigaction action;
		action.sa_handler = setBackgroundingEnabled;
		action.sa_mask = block_mask;
		action.sa_flags = 0;
		sigaction(SIGUSR1, &action, NULL);
	}
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSNumber numberWithInt:86400], NSDefaultLibraryExpiryTime,
															 [NSNumber numberWithBool:NO], NSDefaultPasswordEnabled,
															 @"", NSDefaultPassword,
															 [NSNumber numberWithInt:4242], NSDefaultPort,
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
	
	//NSLog(@"port: %i password: %@", [[NSUserDefaults standardUserDefaults] integerForKey:NSDefaultPort], [[NSUserDefaults standardUserDefaults] stringForKey:NSDefaultPassword]);
	
	[server setPort:[[NSUserDefaults standardUserDefaults] integerForKey:NSDefaultPort]];
	
	if([[NSUserDefaults standardUserDefaults] boolForKey:NSDefaultPasswordEnabled])
		[server setPassword:[[NSUserDefaults standardUserDefaults] stringForKey:NSDefaultPassword]];
	
	[server start];
	
	inBackground = NO;
	
	[self playingItemChanged:nil];
}

- (void)registerNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playingItemChanged:) name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playingItemChanged:) name:UIApplicationBackgroundingNotification object:nil];
}

- (void)playingItemChanged:(id)unused {
	// Update the UI to reflect this new item.
	
	// Check to see if we're running on a jailbroken iPhone in the background. If we are, we don't want to waste memory on updating the UI.
//	NSLog(@"%@ %@", [NSNumber numberWithBool:[UIApplication respondsToSelector:@selector(isBackgroundingEnabled)]], [NSNumber numberWithBool:[[UIApplication sharedApplication] respondsToSelector:@selector(isBackgroundingEnabled)]]);
	
//	if([[UIApplication sharedApplication] respondsToSelector:@selector(isBackgroundingEnabled)]) {
//		NSLog(@"%@", [NSNumber numberWithBool:[[UIApplication sharedApplication] isBackgroundingEnabled]]);
//		
//		if([[UIApplication sharedApplication] isBackgroundingEnabled]) {
//			if(!inBackground) {
//				// Update our UI to tell the user that we're running in the background and will not update the UI as such.
//				[UIView beginAnimations:@"" context:NULL];
//				
//				overlayView.alpha = 1.0;
//				
//				[UIView commitAnimations];
//				
//				inBackground = YES;
//			}
//			
//			return;
//		} else {
//			if(inBackground) {
//				[UIView beginAnimations:@"" context:NULL];
//				
//				overlayView.alpha = 0.0;
//				
//				[UIView commitAnimations];
//				
//				inBackground = NO;
//			}
//		}
//	}
	
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

- (void)applicationWillTerminate:(UIApplication *)application {
	[server stop];
	[server release];
	server = nil;
}

- (void)dealloc {
	[[MPMusicPlayerController iPodMusicPlayer] endGeneratingPlaybackNotifications];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[controller release];
	controller = nil;
	
    [window release];
	window = nil;
	
    [super dealloc];
}


@end
