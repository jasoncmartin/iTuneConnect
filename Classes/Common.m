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
//  Common.m
//  iTuneConnect
//
//  Created by Jason C. Martin on 10/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Common.h"
#import <objc/runtime.h>

NSString *UIApplicationBackgroundingNotification = @"UIApplicationBackgroundingNotification";

// Thanks, three20!
void TTSwapMethods(Class cls, SEL originalSel, SEL newSel) {
	Method originalMethod = class_getInstanceMethod(cls, originalSel);
	Method newMethod = class_getInstanceMethod(cls, newSel);
	method_exchangeImplementations(originalMethod, newMethod);
}

@implementation Common

@end
