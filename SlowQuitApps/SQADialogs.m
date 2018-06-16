#import "SQADialogs.h"

@implementation SQADialogs

- (void)askAboutAutoStart {
    if ([self isRegisteredAsLoginItem]) {
        return;
    }

    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Automatically launch SlowQuitApps on login?", nil)
                                     defaultButton:NSLocalizedString(@"Yes", nil)
                                   alternateButton:NSLocalizedString(@"No", nil)
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"Would you like to register SlowQuitApps to automatically launch when you login?", nil)];
    if ([alert runModal] != NSAlertDefaultReturn) {
        return;
    }

    if ([self registerLoginItem]) {
        return;
    }

    NSAlert *warning = [NSAlert alertWithMessageText:NSLocalizedString(@"Failed to register SlowQuitApps to launch on login", nil)
                                       defaultButton:NSLocalizedString(@"OK", nil)
                                     alternateButton:nil
                                         otherButton:nil
                           informativeTextWithFormat:@""];
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
