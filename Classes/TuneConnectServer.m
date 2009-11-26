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
//  TuneConnectServer.m
//  iTuneConnect
//
//  Created by Grant Butler on 10/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Common.h"
#import "TuneConnectServer.h"
#import "iTunesServer.h"

@interface TuneConnectServer (Private)

- (SEL)convertToSelector:(NSString *)aPath;
- (BOOL)authorizationValid:(SimpleHTTPConnection *)connection withParams:(NSDictionary *)params;

@end


@implementation TuneConnectServer

@synthesize port, password;

- (id)init {
	if(self = [super init]) {
		port = 4242;
		password = @"";
	}
	
	return self;
}

- (void)start {
	// Get device name
	NSString *hostname = [[UIDevice currentDevice] name];//[[NSProcessInfo processInfo] hostName]; - Not exactly user friendly
	
	// Start Bonjour service to tell TuneConnect Apps we're here.
	service = [[NSNetService alloc] initWithDomain:@"" type:@"_tunage._tcp" name:hostname port:port];
	[service setDelegate:self];
	[service publish];
	
	// Start the HTTP server to serve our info.
	server = [[SimpleHTTPServer alloc] initWithTCPPort:port delegate:self];
	
	itunes = [[iTunesServer alloc] init];
}

- (void)stop {
	[service stop];
	[service release];
	service = nil;
	
	for(SimpleHTTPConnection *connection in [server connections]) {
		[server closeConnection:connection];
	}
	
	[server release];
	server = nil;
	
	[itunes release];
	itunes = nil;
}

#pragma mark -
#pragma mark NSNetService Delegate Methods

- (void)netServiceWillPublish:(NSNetService *)netService {
	
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Unable to start server (%@)", [errorDict valueForKey:NSNetServicesErrorCode]] delegate:nil cancelButtonTitle:@"" otherButtonTitles:@"OK"];
	[alert show];
	[alert release];
}

- (void)processURL:(NSURL *)URL connection:(SimpleHTTPConnection *)connection {
	//NSLog(@"Full URL:%@, path:%@, query:%@", URL, [URL path], [URL query]);
	
	NSString *path = [URL path];
	
	if([path hasPrefix:@"/"]) {
		path = [path substringFromIndex:1];
	}
	
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	
	// parse through the query string
	for(NSString *component in [[URL query] componentsSeparatedByString:@"&"]) {
		NSArray *parts = [component componentsSeparatedByString:@"="];
		
		[params setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
	}
	
	//NSLog(@"%@", [path stringByAppendingString:@":withServer:andParameters:"]);
	
	if([path isEqualToString:@"serverInfo.txt"]) {
		// Okay, they want server info. Let's give it to them!
		[self sendDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
							[NSNumber numberWithFloat:1.2], @"version",
							@"", @"suffix",
							[NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:NSDefaultPasswordEnabled]], @"requiresPassword",
							[NSNumber numberWithBool:YES], @"supportsArtwork",
							[NSArray array], @"extensions",
							nil
							  ] asJSON:![[params valueForKey:@"asPlist"] boolValue]];
		
		return;
	} else if([itunes respondsToSelector:[self convertToSelector:path]]) {
		if([[NSUserDefaults standardUserDefaults] boolForKey:NSDefaultPasswordEnabled]) {
			if(![self authorizationValid:connection withParams:params]) {
				[self sendFourOhThree:![[params valueForKey:@"asPlist"] boolValue]];
				
				return;
			}
		}
		
		[itunes performSelector:[self convertToSelector:path] withObject:connection withObject:self withObject:params];
		
		return;
	}
	
	[self sendFourOhFour:![[params valueForKey:@"asPlist"] boolValue]];
}

- (BOOL)authorizationValid:(SimpleHTTPConnection *)connection withParams:(NSDictionary *)params {
	NSString *passcode = [[NSString stringWithFormat:@"%@%@", [[NSUserDefaults standardUserDefaults] stringForKey:NSDefaultPassword], [connection address]] sha1];
	
	return ([[params valueForKey:@"authKey"] isEqualToString:passcode]);
}

- (void)sendSuccess:(BOOL)asJson {
	[self sendDictionary:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"success"] asJSON:asJson withCode:200];
}

- (void)sendFourOhFour:(BOOL)asJson {
	[self sendDictionary:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"error"] asJSON:asJson withCode:404];
}

- (void)sendFourOhThree:(BOOL)asJson {
	[self sendDictionary:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"error"] asJSON:asJson withCode:403];
}

- (void)sendFourHundred:(BOOL)asJson {
	[self sendDictionary:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"error"] asJSON:asJson withCode:400];
}

- (void)sendDictionary:(NSDictionary *)json asJSON:(BOOL)asJson {
	[self sendDictionary:json asJSON:asJson withCode:200];
}

- (void)sendDictionary:(NSDictionary *)json asJSON:(BOOL)asJson withCode:(NSInteger)aCode {
	NSData *response;
	
	if(asJson) {
		response = [[json JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
	} else {
		response = [NSPropertyListSerialization dataFromPropertyList:json format:kCFPropertyListXMLFormat_v1_0 errorDescription:nil];
	}
	
	//NSLog(@"%@", [[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding] autorelease]);
	
	[server replyWithStatusCode:aCode data:response MIMEType:((asJson) ? @"text/plain" : @"text/xml")];
}

- (void)replyWithStatusCode:(int)code headers:(NSDictionary *)headers body:(NSData *)body {
	[server replyWithStatusCode:code headers:headers body:body];
}

- (SEL)convertToSelector:(NSString *)aPath {
	return NSSelectorFromString([aPath stringByAppendingString:@":withServer:andParameters:"]);
}

@end
