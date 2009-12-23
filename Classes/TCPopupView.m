//
//  TCPopupView.m
//  iTuneConnect
//
//  Created by Jason C. Martin on 12/22/09.
//  Copyright 2009 New Media Geekz. All rights reserved.
//

#import "TCPopupView.h"
#import "Common.h"

static CGFloat kBorderGray[4] = {0.3, 0.3, 0.3, 0.8};
static CGFloat kTransitionDuration = 0.3;
static CGFloat kBorderWidth = 10;
static CGFloat kPadding = 10;

@implementation TCPopupView

- (void)addRoundedRectToPath:(CGContextRef)context rect:(CGRect)rect radius:(float)radius {
	CGContextBeginPath(context);
	CGContextSaveGState(context);
	
	if (radius == 0) {
		CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
		CGContextAddRect(context, rect);
	} else {
		rect = CGRectOffset(CGRectInset(rect, 0.5, 0.5), 0.5, 0.5);
		CGContextTranslateCTM(context, CGRectGetMinX(rect)-0.5, CGRectGetMinY(rect)-0.5);
		CGContextScaleCTM(context, radius, radius);
		float fw = CGRectGetWidth(rect) / radius;
		float fh = CGRectGetHeight(rect) / radius;
		
		CGContextMoveToPoint(context, fw, fh/2);
		CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
		CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
		CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
		CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
	}
	
	CGContextClosePath(context);
	CGContextRestoreGState(context);
}

- (void)drawRect:(CGRect)rect fill:(const CGFloat*)fillColors radius:(CGFloat)radius {
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	
	if (fillColors) {
		CGContextSaveGState(context);
		CGContextSetFillColor(context, fillColors);
		if (radius) {
			[self addRoundedRectToPath:context rect:rect radius:radius];
			CGContextFillPath(context);
		} else {
			CGContextFillRect(context, rect);
		}
		CGContextRestoreGState(context);
	}
	
	CGColorSpaceRelease(space);
}

- (void)bounce1AnimationStopped {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration/2];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounce2AnimationStopped)];
	self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
	[UIView commitAnimations];
}

- (void)bounce2AnimationStopped {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration/2];
	self.transform = CGAffineTransformIdentity;
	[UIView commitAnimations];
}

- (void)postDismissCleanup {
	[self removeFromSuperview];
	
	[_window resignKeyWindow];
	[_window setHidden:YES];
	[_window release];
}

- (void)sizeToFitOrientation:(BOOL)transform {
//	if (transform) {
//		self.transform = CGAffineTransformIdentity;
//	}
	
	CGRect frame = [UIScreen mainScreen].applicationFrame;
	CGPoint center = CGPointMake(
								 frame.origin.x + ceil(frame.size.width/2),
								 frame.origin.y + ceil(frame.size.height/2));
	
	CGFloat width = frame.size.width - kPadding * 2;
	CGFloat height = frame.size.height - kPadding * 2;
	
//	_orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
		self.frame = CGRectMake(kPadding, kPadding, height, width);
	} else {
		self.frame = CGRectMake(kPadding, kPadding, width, height);
	}
	self.center = center;
	
//	if (transform) {
//		self.transform = [self transformForOrientation];
//	}
}

- (void)cancel {
	[self dismiss:YES];
}

- (id)init {
    if (self = [super initWithFrame:CGRectZero]) {
        // Initialization code
		self.backgroundColor = [UIColor clearColor];
		self.autoresizesSubviews = YES;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.contentMode = UIViewContentModeRedraw;
		
		_contentView = [[UIView alloc] initWithFrame:CGRectZero];
		[self addSubview:_contentView];
		
		UIImage *closeImage = [UIImage imageNamed:@"closebox.png"];
		_closeButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		[_closeButton setImage:closeImage forState:UIControlStateNormal];
		[_closeButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
		_closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
		[self addSubview:_closeButton];
    }
    return self;
}

- (void)show {
	[self sizeToFitOrientation:NO];
	
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	[_window addSubview:self];
	[_window setWindowLevel:UIWindowLevelStatusBar + 1.0f];
	[_window makeKeyAndVisible];
	
	_contentView.frame = CGRectMake(kBorderWidth, kBorderWidth, [self frame].size.width - kBorderWidth * 2, [self frame].size.height - kBorderWidth * 2);
	
	_closeButton.frame = CGRectMake(self.frame.size.width - [_closeButton imageForState:UIControlStateNormal].size.width, 0, [_closeButton imageForState:UIControlStateNormal].size.width, [_closeButton imageForState:UIControlStateNormal].size.height);
	
	self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.001, 0.001);
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration/1.5];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounce1AnimationStopped)];
	self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
	[UIView commitAnimations];
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
	CGRect grayRect = CGRectOffset(rect, -0.5, -0.5);
	[self drawRect:grayRect fill:kBorderGray radius:10];
}

- (void)dismiss:(BOOL)animated {
	if (animated) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:kTransitionDuration];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(postDismissCleanup)];
		self.alpha = 0;
		[UIView commitAnimations];
	} else {
		[self postDismissCleanup];
	}	
}

- (void)addSubview:(UIView *)view {
	// Modify the view's frame to fit into the space provided.
	if(view == _contentView || view == _closeButton) {
		[super addSubview:view];
		
		return;
	}
	
	CGFloat width = [view frame].size.width;
	CGFloat height = [view frame].size.height;
	
	CGRect frame = [UIScreen mainScreen].applicationFrame;
	
	if(width > frame.size.width - kBorderWidth * 2) {
		width = frame.size.width - kBorderWidth * 2;
	}
	
	if(height > frame.size.height - kBorderWidth * 2) {
		height = frame.size.height - kBorderWidth * 2;
	}
	
	view.frame = CGRectMake([view frame].origin.x, [view frame].origin.y, width - kBorderWidth * 2, height - kBorderWidth * 2);
	
	[_contentView addSubview:view];
}

- (void)dealloc {
	[_contentView release];
	_contentView = nil;
	
	[_closeButton release];
	_closeButton = nil;
	
    [super dealloc];
}


@end
