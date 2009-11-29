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
//  Common.h
//  iTuneConnect
//
//  Created by Jason C. Martin on 10/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSON.h"
#import "NSObject+Additions.h"
#import "NSString+Additions.h"
#import "NSDictionary+Additions.h"
#import "MPMediaItem-Properties.h"
#import "SimpleHTTPServer.h"
#import "SimpleHTTPConnection.h"

#define NSDefaultLibraryExpiryTime @"libraryExpiryTime"
#define NSDefaultPasswordEnabled   @"passwordEnabled"
#define NSDefaultPassword		   @"password"
#define NSDefaultPort			   @"port"
#define NSDefaultUseLibraryFile	   @"useLibraryFile"
#define NSDefaultDsThreshold	   @"dsThreshold"

void TTSwapMethods(Class cls, SEL originalSel, SEL newSel);

extern NSString *UIApplicationBackgroundingNotification;

@interface Common : NSObject {

}

@end
