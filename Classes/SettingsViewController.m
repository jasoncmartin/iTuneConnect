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
//  Created by Jason C. Martin on 10/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SettingsViewController.h"
#import "Common.h"
#import "TCPopupView.h"


enum SettingsRows {
	SettingsRowsPasswordOnOff = 0,
	SettingsRowsPasswordEntry = 1,
	SettingsRowsPort = 2
};

@implementation SettingsViewController

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	tv.allowsSelection = NO;
	[tv setScrollEnabled:NO];
	
	activeTextField = nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shownKeyboard:) name:UIKeyboardDidShowNotification object:nil];
	
	[super viewDidLoad];
}

- (IBAction)goBack:(id)sender {
	[[self parentViewController] dismissModalViewControllerAnimated:YES];
}


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
		[cell.textLabel setText:NSLocalizedString(@"Port", @"Port")];
		
		UITextField *portField = [[UITextField alloc] initWithFrame:CGRectMake(91, 11, 210, 27.0)];
		[portField setClearButtonMode:UITextFieldViewModeNever];
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
			[cell.textLabel setText:NSLocalizedString(@"Use Password?", @"Use Password?")];
			
			UISwitch *aSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(205.0, 9.0, 94.0, 27.0)];
			aSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:NSDefaultPasswordEnabled];
			aSwitch.exclusiveTouch = YES;
			[aSwitch setTag:SettingsRowsPasswordOnOff];
			[aSwitch addTarget:self action:@selector(saveSetting:) forControlEvents:UIControlEventValueChanged];
			[cell addSubview:aSwitch];
			[aSwitch release];
			
			break;
		case SettingsRowsPasswordEntry:
			[cell.textLabel setText:NSLocalizedString(@"Password", @"Password")];
			
			UITextField *portField = [[UITextField alloc] initWithFrame:CGRectMake(91, 9.0, 210, 27.0)];
			[portField setClearButtonMode:UITextFieldViewModeWhileEditing];
			[portField setText:[[NSUserDefaults standardUserDefaults] stringForKey:NSDefaultPassword]];
			[portField setReturnKeyType:UIReturnKeyDone];
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

- (IBAction)showHelp:(id)sender {
	TCPopupView *popupView = [[TCPopupView alloc] init];
	
	UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 300, 440)];
	[popupView addSubview:webView];
	[webView loadHTMLString:NSLocalizedString(@"HelpHTML", @"HelpHTML") baseURL:nil];
	[webView release];
	
	[popupView show];
	[popupView release];
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
				
				[tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
				
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
		[[NSUserDefaults standardUserDefaults] setValue:[textField text]  forKey:NSDefaultPassword];
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
	if(indexPath.row == SettingsRowsPasswordEntry) {
		[[(UITextField *)[tv cellForRowAtIndexPath:indexPath] viewWithTag:SettingsRowsPasswordEntry] becomeFirstResponder];
	} else if(indexPath.row == SettingsRowsPort) {
		[[(UITextField *)[tv cellForRowAtIndexPath:indexPath] viewWithTag:SettingsRowsPort] becomeFirstResponder];
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
	return NSLocalizedString(@"Delete", @"Delete");
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

#pragma mark -
#pragma mark Notifications

- (void)shownKeyboard:(NSNotification *)note {
	UIView *keyboard = [[UIApplication sharedApplication] keyboardView];
	
	if(!keyboard)
		return;
	
	if([activeTextField keyboardType] != UIKeyboardTypeNumberPad)
		return;
	
	UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    doneButton.frame = CGRectMake(0, 163, 106, 53);
    doneButton.adjustsImageWhenHighlighted = NO;
    [doneButton setImage:[UIImage imageNamed:@"doneup.png"] forState:UIControlStateNormal];
    [doneButton setImage:[UIImage imageNamed:@"donedown.png"] forState:UIControlStateHighlighted];
    [doneButton addTarget:self action:@selector(saveSetting:) forControlEvents:UIControlEventTouchUpInside];
	
	[keyboard addSubview:doneButton];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
    [super dealloc];
}


@end
