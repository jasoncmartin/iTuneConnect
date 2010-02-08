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
	
	uint8_t result[CC_SHA1_DIGEST_LENGTH] = {0};
	
	CC_SHA1(keyData.bytes, keyData.length, result);
	
	return [NSString stringWithFormat:
			@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15],
			result[16], result[17], result[18], result[19]
			];
}

- (NSString *)md5 {
	NSData *keyData = [self dataUsingEncoding:NSASCIIStringEncoding];
	
	uint8_t result[CC_MD5_DIGEST_LENGTH];
	
	CC_MD5([keyData bytes], [keyData length], result);
	
	return [NSString stringWithFormat:
			@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]
			];
}

- (unsigned long long)unsignedLongLongValue {
	return strtoull([self UTF8String], NULL, 0);
}

@end
