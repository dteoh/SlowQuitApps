@import ServiceManagement;
#import "SQAAutostart.h"

@implementation SQAAutostart

NSString * const LauncherBundleIdentifier = @"com.dteoh.SlowQuitAppsLauncher";

+ (BOOL)isEnabled {
    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
        if ([app.bundleIdentifier isEqualToString:LauncherBundleIdentifier]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)shouldRegisterLoginItem:(BOOL)enabled {
    return SMLoginItemSetEnabled((__bridge CFStringRef)(LauncherBundleIdentifier), enabled);
}

+ (BOOL)enable {
    return [self shouldRegisterLoginItem:YES];
}

+ (BOOL)disable {
    return [self shouldRegisterLoginItem:NO];
}

@end
