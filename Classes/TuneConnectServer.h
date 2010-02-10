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
//  TuneConnectServer.h
//  iTuneConnect
//
//  Created by Jason C. Martin on 10/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SimpleHTTPServer, iTunesServer;

@interface TuneConnectServer : NSObject {
	NSInteger port;
	NSString *password;
	
	@private
	NSNetService *service;
	SimpleHTTPServer *server;
	iTunesServer *itunes;
	
	BOOL running;
}

@property (nonatomic, assign) NSInteger port;
@property (nonatomic, retain) NSString *password;
@property (readonly, assign, getter=isRunning) BOOL running;

- (void)start;
- (void)stop;

- (void)sendSuccess:(BOOL)asJson;
- (void)sendFailure:(BOOL)asJson;
- (void)sendFourHundred:(BOOL)asJson;
- (void)sendFourOhFour:(BOOL)asJson;
- (void)sendFourOhThree:(BOOL)asJson;
- (void)sendDictionary:(NSDictionary *)json asJSON:(BOOL)asJson;
- (void)sendDictionary:(NSDictionary *)json asJSON:(BOOL)asJson withCode:(NSInteger)aCode;
- (void)replyWithStatusCode:(int)code headers:(NSDictionary *)headers body:(NSData *)body;

@end
