//
//  TCPopupView.h
//  iTuneConnect
//
//  Created by Jason C. Martin on 12/22/09.
//  Copyright 2009 New Media Geekz. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TCPopupView : UIView {
	UIButton *_closeButton;
	
	UIView *_contentView;
}

- (void)show;

@end
