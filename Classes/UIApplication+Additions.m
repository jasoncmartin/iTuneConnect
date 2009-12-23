//
//  UIApplication+Additions.m
//  iTuneConnect
//
//  Created by Jason C. Martin on 12/23/09.
//  Copyright 2009 New Media Geekz. All rights reserved.
//

#import "UIApplication+Additions.h"


@implementation UIApplication (KeyboardView)

- (UIView *)keyboardView
{
    NSArray *windows = [self windows];
    for (UIWindow *window in [windows reverseObjectEnumerator])
    {
        for (UIView *view in [window subviews])
        {
			if (!strcmp(object_getClassName(view), "UIKeyboard"))
			{
				return view;
			}
        }
    }
	
    return nil;
}

@end
