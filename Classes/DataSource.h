//
//  DataSource.h
//  PagingScrollView
//
//  Created by Matt Gallagher on 24/01/09.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import <UIKit/UIKit.h>

@interface DataSource : NSObject
{
	NSArray *dataPages;
}

+ (DataSource *)sharedDataSource;
- (NSInteger)numDataPages;
- (NSString *)dataForPage:(NSInteger)pageIndex;

@end
