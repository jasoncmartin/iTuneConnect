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
//  iTuneConnectAppDelegate.h
//  iTuneConnect
//
//  Created by Jason C. Martin on 10/16/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TuneConnectServer;

@interface iTuneConnectAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	UIViewController *controller;
	
	TuneConnectServer *server;
	
	IBOutlet UIImageView *artworkView;

	IBOutlet UILabel *titleLabel;
	IBOutlet UILabel *artistLabel;
	IBOutlet UILabel *albumLabel;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIViewController *controller;

- (IBAction)showSettings:(id)unused;

@end

