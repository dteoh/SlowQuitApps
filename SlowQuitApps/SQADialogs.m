#import "SQADialogs.h"

@implementation SQADialogs

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
    NSString *appPath = [[NSBundle mainBundle] bundlePath];

    NSArray *loginItems;
    {
        LSSharedFileListRef items = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
        UInt32 seed;
        loginItems = CFBridgingRelease(LSSharedFileListCopySnapshot(items, &seed));
        CFRelease(items);
    }

    for (id item in loginItems) {
        LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)(item);
        CFURLRef itemUrlRef;
        if (LSSharedFileListItemResolve(itemRef, 0, &itemUrlRef, NULL) == noErr) {
            NSURL *itemUrl = CFBridgingRelease(itemUrlRef);
            if ([[itemUrl path] compare:appPath] == NSOrderedSame) {
                return YES;
            }
        }
    }

    return NO;
}

- (BOOL)registerLoginItem {
    BOOL registered = NO;

    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    CFURLRef appUrlRef = CFBridgingRetain([NSURL fileURLWithPath:appPath]);

    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (!loginItems) goto appUrlRefCleanup;

    LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,
            kLSSharedFileListItemLast, NULL, NULL, appUrlRef, NULL, NULL);
    CFRelease(item);
    registered = YES;

    CFRelease(loginItems);

appUrlRefCleanup:
    CFRelease(appUrlRef);

    return registered;
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
