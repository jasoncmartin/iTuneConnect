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
//  NSString+Additions.m
//  iTuneConnect
//
//  Created by Jason C. Martin on 10/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSString+Additions.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (OutAdditions)

- (NSString *)sha1 {
	NSData *keyData = [self dataUsingEncoding:NSASCIIStringEncoding];
	
	uint8_t digest[CC_SHA1_DIGEST_LENGTH] = {0};
	
	CC_SHA1(keyData.bytes, keyData.length, digest);
	
	return [[[NSString alloc] initWithData:[NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH] encoding:NSASCIIStringEncoding] autorelease];
}

- (NSString *)md5 {
	NSData *keyData = [self dataUsingEncoding:NSASCIIStringEncoding];
	
	uint8_t digest[CC_MD5_DIGEST_LENGTH];
	
	CC_MD5([keyData bytes], [keyData length], digest);
	
	return [[[NSString alloc] initWithData:[NSData dataWithBytes:digest length:CC_MD5_DIGEST_LENGTH] encoding:NSASCIIStringEncoding] autorelease];
}

@end
