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
//  SettingsViewController.m
//  iTuneConnect
//
//  Created by Grant Butler on 10/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SettingsViewController.h"
#import "Common.h"

enum SettingsRows {
	SettingsRowsPasswordOnOff = 0,
	SettingsRowsPasswordEntry = 1,
	SettingsRowsPort = 2
};

@implementation SettingsViewController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	tv.allowsSelection = NO;
	
	activeTextField = nil;
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark UITableViewDataSource Methods
#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(section)
		return 1;
	
	if([[NSUserDefaults standardUserDefaults] boolForKey:NSDefaultPasswordEnabled])
		return 2;
	
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsRow"];
	
	if(cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SettingsRow"] autorelease];
	}
	
	if (indexPath.section) {
		[cell.textLabel setText:@"Port"];
		
		UITextField *portField = [[UITextField alloc] initWithFrame:CGRectMake(91, 0, 210, 44.0)];
		[portField setClearButtonMode:UITextFieldViewModeWhileEditing];
		[portField setText:[[NSUserDefaults standardUserDefaults] stringForKey:NSDefaultPort]];
		[portField setKeyboardType:UIKeyboardTypeNumberPad];
		[portField setTextAlignment:UITextAlignmentRight];
		[portField setDelegate:self];
		[cell addSubview:portField];
		[portField release];
		
		return cell;
	}
	
	switch (indexPath.row) {
		case SettingsRowsPasswordOnOff:
			[cell.textLabel setText:@"Use Password?"];
			
			UISwitch *aSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(205.0, 9.0, 94.0, 27.0)];
			aSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:NSDefaultPasswordEnabled];
			aSwitch.exclusiveTouch = YES;
			[aSwitch setTag:SettingsRowsPasswordOnOff];
			[aSwitch addTarget:self action:@selector(saveSetting:) forControlEvents:UIControlEventValueChanged];
			[cell addSubview:aSwitch];
			[aSwitch release];
			
			break;
		case SettingsRowsPasswordEntry:
			[cell.textLabel setText:@"Password"];
			
			UITextField *portField = [[UITextField alloc] initWithFrame:CGRectMake(91, 0, 210, 44.0)];
			[portField setClearButtonMode:UITextFieldViewModeWhileEditing];
			[portField setText:[[NSUserDefaults standardUserDefaults] stringForKey:NSDefaultPassword]];
			[portField setTextAlignment:UITextAlignmentRight];
			[portField setSecureTextEntry:YES];
			[portField setTag:SettingsRowsPasswordEntry];
			[portField setDelegate:self];
			[cell addSubview:portField];
			[portField release];
			
			break;
		default:
			break;
	}
	
	return cell;
}

- (IBAction)saveSetting:(id)sender {
	if ([activeTextField canResignFirstResponder]) {
		[activeTextField resignFirstResponder];
		
		activeTextField = nil;
	}
	
	if([sender isKindOfClass:[UISwitch class]]) {
		if([sender tag] == SettingsRowsPasswordOnOff) {
			if([sender isOn]) {
				[tv beginUpdates];
				
				[[NSUserDefaults standardUserDefaults] setBool:YES forKey:NSDefaultPasswordEnabled];
				
				[tv insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
				
				[tv endUpdates];
			} else {
				[tv beginUpdates];
				
				[[NSUserDefaults standardUserDefaults] setBool:NO forKey:NSDefaultPasswordEnabled];
				
				[tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
				
				[tv endUpdates];
			}
		}
	}
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	activeTextField = textField;
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if([textField tag] == SettingsRowsPasswordEntry) {
		[[NSUserDefaults standardUserDefaults] setValue:[textField text] forKey:NSDefaultPassword];
	} else {
		[[NSUserDefaults standardUserDefaults] setValue:[textField text] forKey:NSDefaultPort];
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	
	activeTextField = nil;
	
	return YES;
}

#pragma mark UITAbleViewDelegate Methods
#pragma mark -

- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Delete";
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
	return proposedDestinationIndexPath;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
