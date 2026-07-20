#import "SQALAppDelegate.h"

@implementation SQALAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)_ {
    BOOL alreadyRunning = NO;
    for (NSRunningApplication *app in NSWorkspace.sharedWorkspace.runningApplications) {
        if ([app.bundleIdentifier isEqualToString:@"com.dteoh.QuitSlowly"]) {
            alreadyRunning = YES;
            break;
        }
    }

    if (alreadyRunning) {
        [NSApp terminate:self];
        return;
    }

    NSString *path = NSBundle.mainBundle.bundlePath;
    path = [path stringByDeletingLastPathComponent];
    path = [path stringByDeletingLastPathComponent];
    path = [path stringByDeletingLastPathComponent];
    path = [path stringByDeletingLastPathComponent];

    NSURL *appURL = [NSURL fileURLWithPath:path];
    [NSWorkspace.sharedWorkspace openApplicationAtURL:appURL
                                        configuration:[NSWorkspaceOpenConfiguration configuration]
                                    completionHandler:^(NSRunningApplication *app, NSError *error) {
        if (error) {
            NSLog(@"SlowQuitAppsLauncher: failed to launch main app: %@", error.localizedDescription);
        }
        [NSApp terminate:self];
    }];
}

@end
