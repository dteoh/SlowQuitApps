#import "SQALAppDelegate.h"

@implementation SQALAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)_ {
    BOOL alreadyRunning = NO;
    for (NSRunningApplication *app in NSWorkspace.sharedWorkspace.runningApplications) {
        if ([app.bundleIdentifier isEqualToString:@"com.dteoh.SlowQuitApps"]) {
            alreadyRunning = YES;
            break;
        }
    }

    if (!alreadyRunning) {
        NSString *path = NSBundle.mainBundle.bundlePath;
        path = [path stringByDeletingLastPathComponent];
        path = [path stringByDeletingLastPathComponent];
        path = [path stringByDeletingLastPathComponent];
        path = [path stringByDeletingLastPathComponent];
        [NSWorkspace.sharedWorkspace launchApplication:path];
    }

    [NSApp terminate:self];
}

@end
