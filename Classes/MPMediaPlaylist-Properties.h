//
//  MPMediaPlaylist-Properties.h
//  iTuneConnect
//
//  Created by Jason C. Martin on 11/30/09.
//  Copyright 2009 New Media Geekz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface MPMediaPlaylist (Properties)

@property (nonatomic, readonly) NSTimeInterval duration;

@property (nonatomic, readonly) long long persistentID;
@property (nonatomic, readonly) NSString *name;

@property (nonatomic, readonly) BOOL isOnTheGo;
@property (nonatomic, readonly) BOOL isGenius;
@property (nonatomic, readonly) BOOL isSmart;

@property (nonatomic, readonly) NSArray *seedItems;

@end
