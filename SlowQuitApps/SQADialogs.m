#import "SQADialogs.h"
@import ServiceManagement;

@implementation SQADialogs

NSString * const LauncherBundleIdentifier = @"com.dteoh.SlowQuitAppsLauncher";

- (void)askAboutAutoStart {
    if ([self isRegisteredAsLoginItem]) {
        return;
    }

    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleInformational;
    alert.messageText = NSLocalizedString(@"Automatically launch SlowQuitApps on login?", nil);
    alert.informativeText = NSLocalizedString(@"Would you like to register SlowQuitApps to automatically launch when you login?", nil);
    [alert addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"No", nil)];
    if ([alert runModal] != NSAlertFirstButtonReturn) {
        return;
    }

    if ([self registerLoginItem]) {
        return;
    }

    NSAlert *warning = [[NSAlert alloc] init];
    warning.alertStyle = NSAlertStyleWarning;
    warning.messageText = NSLocalizedString(@"Failed to register SlowQuitApps to launch on login", nil);
    [warning addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [warning runModal];
}

- (BOOL)isRegisteredAsLoginItem {
    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
        if ([app.bundleIdentifier isEqualToString:LauncherBundleIdentifier]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)registerLoginItem {
    return SMLoginItemSetEnabled((__bridge CFStringRef)(LauncherBundleIdentifier), YES);
}

- (void)informHotkeyRegistrationFailure {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleCritical;
    alert.messageText = NSLocalizedString(@"SlowQuitApps cannot register ⌘Q", nil);
    alert.informativeText = NSLocalizedString(@"Another application has exclusive control of ⌘Q, SlowQuitApps cannot continue. SlowQuitApps will exit.", nil);
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [alert runModal];
}

- (void)informAccessibilityRequirement {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleInformational;
    alert.messageText = NSLocalizedString(@"SlowQuitApps requires permissions to control your computer", nil);
    alert.informativeText = NSLocalizedString(@"SlowQuitApps needs accessibility permissions to handle ⌘Q.\r\rAfter adding SlowQuitApps to System Preferences -> Security & Privacy -> Privacy -> Accessibility, please restart the app.", nil);
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [alert runModal];
}

@end
