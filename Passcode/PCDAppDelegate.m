//
//  PCDAppDelegate.m
//  Passcode
//
//  Created by Matt on 8/7/12.
//  Copyright (c) 2012 Matt Zanchelli. All rights reserved.
//

#import "PCDAppDelegate.h"
#import "UITextField+Selections.h"

#if RUN_KIF_TESTS
#import "EXTestController.h"
#endif

@implementation PCDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// Register the preference defaults early.
    NSDictionary *appDefaults = @{kPCDSavePassword: @YES, kPCDHasLaunchedApp: @NO};
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
	
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	
	PCDViewController *mainViewController;
	
	if ( [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ) {
		mainViewController = [[PCDViewController alloc] initWithNibName:@"PCDViewController" bundle:nil];
	} else {
		mainViewController = [[PCDViewController alloc] initWithNibName:@"PCDViewController_iPad" bundle:nil];
	}
	
	self.mainViewController = mainViewController;
	self.window.rootViewController = self.mainViewController;
	self.window.tintColor = [PCDAppDelegate appKeyColor];
    [self.window makeKeyAndVisible];
	
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
	if ( [url.absoluteString hasPrefix:@"passcode://"] ) {
		NSArray *components = [url.host componentsSeparatedByString:@"."];
		[self.mainViewController.domainField setText:components[components.count-2]];
		[self.mainViewController textDidChange:self];
		[self.mainViewController.domainField moveCursorToEnd];
		//	Automatically copy to clipboard and return to Safari?
		//	Perhaps this can be done in Safari javascript anyways?
		return YES;
	} else {
		return NO;
	}
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	
	[self.mainViewController checkPasteboard];
	[self.mainViewController.domainField becomeFirstResponder];
	if ( self.mainViewController.domainField.text.length > 0 ) {
		[self.mainViewController.domainField selectAll:self];
	}
}

+ (UIColor *)appKeyColor
{
	return [UIColor colorWithHue:151.0f/360.0f
					  saturation:0.79f
					  brightness:0.7f
						   alpha:1.0f];
}

@end
