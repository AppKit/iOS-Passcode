//
//  PCDViewController.m
//  Passcode
//
//  Created by Matt on 8/7/12.
//  Copyright (c) 2012 Matt Zanchelli. All rights reserved.
//

//	Copyright (c) 2012, individual contributors
//
//	Permission to use, copy, modify, and/or distribute this software for any
//	purpose with or without fee is hereby granted, provided that the above
//	copyright notice and this permission notice appear in all copies.
//
//	THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//	WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//	MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
//	ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//	WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//	ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
//	OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

#import "PCDViewController.h"
#import "PCDPasscodeGenerator.h"
#import "NSURL+DomainName.h"
#import "UITextField+Selections.h"
#import "PCDField.h"
@import LocalAuthentication;


NSString *const kPCDServiceName = @"Passcode";
NSString *const kPCDAccountName = @"me";

#define STATUS_BAR_HEIGHT 20
#define NAV_BAR_HEIGHT 44

@interface PCDViewController () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UIView *verticalCenteringView;
@property (strong, nonatomic) IBOutlet UIView *container;
@property (weak, nonatomic) IBOutlet PCDField *secretCodeField;
@property (weak, nonatomic) IBOutlet PCDField *serviceNameField;
@property (strong, nonatomic) IBOutlet MTZButton *generateButton;
@property (strong, nonatomic) IBOutlet MTZSlideToReveal *reveal;
@property (strong, nonatomic) MTZAppearWindow *copiedWindow;

@end

@implementation PCDViewController

#pragma mark - Initialization and View Loading

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self setup];
	}
	return self;
}

- (id)init
{
	self = [super init];
	if (self) {
		[self setup];
	}
	return self;
}

- (void)setup
{
	
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = @"Passcode";
	
	self.secretCodeField.titleLabel.text = NSLocalizedString(@"Secret Code", nil);
	self.secretCodeField.textField.placeholder = NSLocalizedString(@"your secret code", nil);
	self.secretCodeField.textField.secureTextEntry = YES;
	self.secretCodeField.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
	self.secretCodeField.textField.returnKeyType = UIReturnKeyNext;
	self.secretCodeField.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.secretCodeField.textField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.secretCodeField.textField.enablesReturnKeyAutomatically = YES;
	self.secretCodeField.textField.delegate = self;
	[self.secretCodeField.textField addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
	
	self.serviceNameField.titleLabel.text = NSLocalizedString(@"Service Name", nil);
	self.serviceNameField.textField.placeholder = NSLocalizedString(@"e.g. apple", nil);
	self.serviceNameField.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
	self.serviceNameField.textField.returnKeyType = UIReturnKeyGo;
	self.serviceNameField.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.serviceNameField.textField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.serviceNameField.textField.enablesReturnKeyAutomatically = YES;
	self.serviceNameField.textField.delegate = self;
	[self.serviceNameField.textField addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
	
	// Find the larger of the two widths (to fully fit text in label) and set it for both.
	CGSize secretCodeFieldTitleSize = [self.secretCodeField.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: self.secretCodeField.titleLabel.font}];
	CGSize serviceNameFieldTitleSize = [self.serviceNameField.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: self.serviceNameField.titleLabel.font}];
	CGFloat largerWidth = ceil(MAX(secretCodeFieldTitleSize.width, serviceNameFieldTitleSize.width));
	self.secretCodeField.titleLabelWidth = largerWidth;
	self.serviceNameField.titleLabelWidth = largerWidth;
	
	// Set up the popover.
	_copiedWindow = [[MTZAppearWindow alloc] init];
	_copiedWindow.autoresizingMask = UIViewAutoresizingFlexibleMargins;
	_copiedWindow.image = [UIImage imageNamed:@"Copied"];
	_copiedWindow.text = NSLocalizedString(@"Copied", nil);
	
	_serviceNameField.tintColor = [UIColor appColor];
	_secretCodeField.tintColor = [UIColor appColor];
	
	// Load idiom-specific UI.
	switch ( [UIDevice currentDevice].userInterfaceIdiom ) {
		case UIUserInterfaceIdiomPad:
			[self loadViewForiPad];
			break;
		case UIUserInterfaceIdiomPhone:
			[self loadViewForiPhone];
			break;
		default:
			break;
	}
	
	// Add gesture recognizers on the generate button.
	UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didGestureOnButton:)];
	[_generateButton addGestureRecognizer:longPressGesture];
	
	UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didGestureOnButton:)];
	[_generateButton addGestureRecognizer:panGesture];
	
	// Color the button.
	[_generateButton setTopColor:[UIColor colorWithRed: 52.0f/255.0f
												 green:196.0f/255.0f
												  blue:126.0f/255.0f
												 alpha:1.0f]
						forState:UIControlStateNormal];
	[_generateButton setBottomColor:[UIColor colorWithRed: 12.0f/255.0f
													green:150.0f/255.0f
													 blue: 86.0f/255.0f
													alpha:1.0f]
						forState:UIControlStateNormal];
	
	[_generateButton setTopColor:[UIColor colorWithRed: 45.0f/255.0f
												 green:171.0f/255.0f
												  blue:110.0f/255.0f
												 alpha:1.0f]
						forState:UIControlStateHighlighted];
	[_generateButton setBottomColor:[UIColor colorWithRed: 10.0f/255.0f
													green:125.0f/255.0f
													 blue: 71.0f/255.0f
													alpha:1.0f]
						   forState:UIControlStateHighlighted];
	
	[_generateButton setTopColor:[UIColor colorWithWhite:1.0f alpha:0.12f]
						forState:UIControlStateDisabled];
	[_generateButton setBottomColor:[UIColor colorWithWhite:1.0f alpha:0.05f]
						   forState:UIControlStateDisabled];
	
	[_generateButton setBorderColor:[UIColor colorWithRed:213.0f/255.0f green:217.0f/255.0f blue:223.0f/255.0f alpha:1.0f]
						   forState:UIControlStateDisabled];
	
	_reveal.hidden = YES;
	
	[self checkSecuritySetting];
}

- (void)loadViewForiPhone
{
}

- (void)loadViewForiPad
{
	[self registerForKeyboardNotifications];
}


#pragma mark - View Controller Events

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// This is such a hack, but it was the only way to get it to work properly.
	[self performSelector:@selector(makeDomainFieldBecomeFirstResponder)
			   withObject:nil
			   afterDelay:0];
}

- (void)makeDomainFieldBecomeFirstResponder
{
	if ( !_serviceNameField.textField.isFirstResponder ) {
		[_serviceNameField.textField becomeFirstResponder];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// Display About if app hasn't been launched before.
	if ( ![[NSUserDefaults standardUserDefaults] boolForKey:kPCDHasLaunchedApp] ) {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPCDHasLaunchedApp];
		[self viewAbout:self];
	}
}

- (NSUInteger)supportedInterfaceOrientations
{
	if ( [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ) {
		return UIInterfaceOrientationMaskPortrait;
    } else {
		return UIInterfaceOrientationMaskAll;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	if ( [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ) {
		return toInterfaceOrientation == UIInterfaceOrientationPortrait;
    } else {
		return YES;
    }
}

/*
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}
 */


#pragma mark - Public API

- (void)setServiceName:(NSString *)serviceName
{
	_serviceNameField.textField.text = serviceName;
	[self textDidChange:self];
	[_serviceNameField.textField moveCursorToEnd];
}

- (void)viewControllerDidBecomeActive
{
	[self checkPasteboard];
	[_serviceNameField.textField becomeFirstResponder];
	if ( _serviceNameField.textField.text.length > 0 ) {
		[_serviceNameField.textField selectAll:self];
	}
}


#pragma mark - Checks

- (void)checkPasteboard
{
	NSURL *url = [NSURL URLWithString:[[UIPasteboard generalPasteboard] string]];
	if (!url) {
		return;
	}
	
	NSString *domainName = [url domainName];
	if (domainName) {
		_serviceNameField.textField.text = domainName;
		[self textDidChange:_serviceNameField];
	}
}

- (void)checkSecuritySetting
{
	// If preference says to save password, authenticate.
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kPCDSavePassword] == YES) {
		[self authenticateWithLocalAuthentication];
	}
	// Otherwise, clear any saved password.
	else {
		_secretCodeField.textField.text = @"";
		[self textDidChange:_secretCodeField];
		[self updateSavedPassword];
	}
}

/// Try to authenticate with local authentication, otherwise authenticate normally.
- (void)authenticateWithLocalAuthentication
{
	if ([LAContext class]) {
		LAContext *myContext = [[LAContext alloc] init];
		NSError *authError = nil;
		if ([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError]) {
			[myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
					  localizedReason:NSLocalizedString(@"Unlock Master Password", nil)
								reply:^(BOOL success, NSError *error) {
									if (success) {
										// User authenticated successfully, take appropriate action.
										[self authenticate];
									} else {
										// User did not authenticate successfully, look at error and take appropriate action.
									}
								}];
		} else {
			// Could not evaluate policy; look at authError and present an appropriate message to user
			[self authenticate];
		}
	} else {
		[self authenticate];
	}
}

/// Authenticate normally.
- (void)authenticate
{
	NSString *passwordString = [SSKeychain passwordForService:kPCDServiceName account:kPCDAccountName];
	if (passwordString) {
		// Update the UI.
		dispatch_async(dispatch_get_main_queue(), ^{
			_secretCodeField.textField.text = passwordString;
			[self textDidChange:_secretCodeField];
		});
	}
}

/// Update the saved password using the current password in the secret code field.
- (void)updateSavedPassword
{
	[SSKeychain setPassword:_secretCodeField.textField.text
				 forService:kPCDServiceName
					account:kPCDAccountName];
}


#pragma mark - Generate Button

- (IBAction)generateAndCopy:(id)sender
{
	// Store the password in keychain.
	[SSKeychain setPassword:_secretCodeField.textField.text forService:@"Passcode" account:@"me"];
	
	NSString *password = [[PCDPasscodeGenerator sharedInstance] passcodeForDomain:_serviceNameField.textField.text
																andMasterPassword:_secretCodeField.textField.text];
	
	// Copy it to pasteboard.
	[UIPasteboard generalPasteboard].string = password;
	
	// Center the appear window to the container.
	UIView *centeringView = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? _verticalCenteringView : _container;
	_copiedWindow.center = centeringView.center;
	
	// Tell the user that the generated passcode has been copied.
	[_copiedWindow display];
}

- (void)generateAndSetReveal:(id)sender
{
	NSString *password = [[PCDPasscodeGenerator sharedInstance] passcodeForDomain:_serviceNameField.textField.text
																andMasterPassword:_secretCodeField.textField.text];
	
	_reveal.hiddenWord = password;
}

- (void)didGestureOnButton:(UIGestureRecognizer *)sender
{
	switch (sender.state) {
		case UIGestureRecognizerStateBegan:
			[self generateAndSetReveal:sender];
			_reveal.hidden = NO;
			_generateButton.hidden = YES;
		case UIGestureRecognizerStateChanged:
			break;
		case UIGestureRecognizerStateEnded:
		case UIGestureRecognizerStateCancelled:
			_reveal.hidden = YES;
			_generateButton.hidden = NO;
			break;
		default:
			break;
	}
	[_reveal didGesture:sender];
}


#pragma mark - Navigation

- (IBAction)viewAbout:(id)sender
{
	PCDAboutViewController *about;
	UIStoryboard *sb = [UIStoryboard storyboardWithName:@"PCDAboutViewController" bundle:nil];
	about = [sb instantiateViewControllerWithIdentifier:@"PCDAboutViewController"];
	
	[self viewModalViewController:about];
}

- (IBAction)viewSettings:(id)sender
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

- (IBAction)viewRestrictions:(id)sender
{
	PCDRestrictionsViewController *requirements = [[PCDRestrictionsViewController alloc] initWithStyle:UITableViewStyleGrouped];
	
	[self viewModalViewController:requirements];
}

- (void)viewModalViewController:(UIViewController *)vc
{
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
	[navigationController setModalPresentationStyle:UIModalPresentationFormSheet];
	[self presentViewController:navigationController animated:YES completion:nil];
}


#pragma mark - Text Field Delegate Methods

- (IBAction)textDidChange:(id)sender
{
	if ( _serviceNameField.textField.text.length > 0 && _secretCodeField.textField.text.length > 0 ) {
		_generateButton.enabled = YES;
	} else {
		_generateButton.enabled = NO;
	}
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	if ( _serviceNameField.textField.text.length > 0 ) {
		_secretCodeField.textField.returnKeyType = UIReturnKeyGo;
	} else {
		_secretCodeField.textField.returnKeyType = UIReturnKeyNext;
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if ( _serviceNameField.textField.text.length > 0 && _secretCodeField.textField.text.length > 0 ) {
		[self generateAndCopy:nil];
		return NO;
	}
	
	[_serviceNameField.textField becomeFirstResponder];
	
	return YES;
}


#pragma mark - Handle Keyboard Notifications

- (void)keyboardChanged:(id)object
{
	// Based on implentation in Genesis.
	// See License: https://raw.github.com/peterhajas/Genesis/master/License
	
    // Grab the dictionary out of the object
    NSDictionary* keyboardGeometry = [object userInfo];
    
    // Get the end frame rectangle of the keyboard
    NSValue* endFrameValue = [keyboardGeometry valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect endFrame = [endFrameValue CGRectValue];
    
    // Convert the rect into view coordinates from the window, this accounts for rotation
    UIWindow* appWindow = [[[UIApplication sharedApplication] delegate] window];
    CGRect keyboardFrame = [[self view] convertRect:endFrame fromView:appWindow];
    
	// Our new frame will be centered within the width of the keyboard
	// and a height that is centered between the navBarHeight and the top of the keyboard (it's y origin)
	CGFloat keyboardWidth  = keyboardFrame.size.width;
	CGFloat keyboardHeight = keyboardFrame.origin.y;
	
	CGFloat width  = _container.frame.size.width;
	CGFloat height = _container.frame.size.height;
	
	CGRect newFrame = CGRectMake(floorl(ABS(keyboardWidth - width)/2),
								 floorl(ABS(keyboardHeight - height)/2),
								 width,
								 height);
	
	[_container setFrame:newFrame];
}

// Subscribe to keyboard notifications
- (void)registerForKeyboardNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardChanged:)
												 name:UIKeyboardWillShowNotification
											   object:nil];
}


#pragma mark - Dealloc

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
