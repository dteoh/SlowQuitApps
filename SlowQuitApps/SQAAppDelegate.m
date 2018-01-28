@import Carbon;
#import "SQAAppDelegate.h"
#import "SQACmdQStream.h"
#import "SQADialogs.h"
#import "SQAOverlayWindowController.h"
#import "SQAPreferences.h"
#import "SQATerminator.h"

@interface SQAAppDelegate() {
@private
    SQACmdQStream *stream;
    SQATerminator *terminator;
    id<SQAOverlayViewInterface> overlayView;
}
@end

@implementation SQAAppDelegate

- (id)init {
    self = [super init];
    if (self) {
        overlayView = [[SQAOverlayWindowController alloc] init];
        terminator = [[SQATerminator alloc] init];
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    SQADialogs *dialogs = [[SQADialogs alloc] init];

    if ([self registerGlobalHotkey]) {
        [dialogs askAboutAutoStart];

        // Hide from dock, command tab, etc.
        // Not using LSBackgroundOnly so that we can display NSAlerts beforehand
        [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    } else {
        [dialogs informHotkeyRegistrationFailure];
        [NSApp terminate:self];
    }
}

- (BOOL)registerGlobalHotkey {
    EventHotKeyRef hotKeyRef;
    EventHotKeyID hotKeyID;
    EventTypeSpec eventType;
    eventType.eventClass = kEventClassKeyboard;
    eventType.eventKind = kEventHotKeyPressed;

    InstallApplicationEventHandler(&cmdQHandler, 1, &eventType, (__bridge void *)self, NULL);
    hotKeyID.signature = 'sqad';
    hotKeyID.id = 1;

    OSStatus result = RegisterEventHotKey(kVK_ANSI_Q, cmdKey, hotKeyID, GetApplicationEventTarget(),
                        kEventHotKeyExclusive, &hotKeyRef);
    return result != eventHotKeyExistsErr;
}

- (void)cmdQPressed {
    __weak typeof(terminator) weakTerminator = terminator;
    __weak typeof (overlayView) weakOverlay = overlayView;

    [terminator newMission:^{
        [weakOverlay hideOverlay];
        [weakOverlay resetOverlay];
    }];
    [overlayView showOverlay:terminator.missionDurationInSeconds];

    stream = [[SQACmdQStream alloc] init];
    __weak typeof(stream) weakStream = stream;

    stream.observer = ^(BOOL pressed) {
        if (pressed) {
            [weakTerminator updateMission];
        } else {
            [weakOverlay hideOverlay];
            [weakOverlay resetOverlay];
            [weakStream close];
        }
    };
    [stream open];
}

NSRunningApplication* findActiveApp() {
    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
        if ([app isActive]) {
            return app;
        }
    }
    return NULL;
}

BOOL shouldHandleCmdQ() {
    NSRunningApplication *activeApp = findActiveApp();
    if (activeApp == NULL) {
        return NO;
    }
    if ([activeApp.bundleIdentifier isEqualToString:@"com.apple.finder"]) {
        return NO;
    }
    for (NSString *bundleId in [SQAPreferences whitelist]) {
        if ([activeApp.bundleIdentifier isEqualToString:bundleId]) {
            return NO;
        }
    }
    return YES;
}

OSStatus cmdQHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData) {
    if (shouldHandleCmdQ()) {
        SQAAppDelegate *delegate = (__bridge SQAAppDelegate *)userData;
        [delegate cmdQPressed];
        return noErr;
    } else {
        CGEventRef keyDownCmd, keyDownQ, keyUpQ, keyUpCmd;
        keyDownCmd = CGEventCreateKeyboardEvent(NULL, kVK_Command, true);
        keyDownQ = CGEventCreateKeyboardEvent(NULL, kVK_ANSI_Q, true);
        keyUpQ = CGEventCreateKeyboardEvent(NULL, kVK_ANSI_Q, false);
        keyUpCmd = CGEventCreateKeyboardEvent(NULL, kVK_Command, false);

        CGEventPost(kCGAnnotatedSessionEventTap, keyDownCmd);
        CGEventPost(kCGAnnotatedSessionEventTap, keyDownQ);
        CGEventPost(kCGAnnotatedSessionEventTap, keyUpQ);
        CGEventPost(kCGAnnotatedSessionEventTap, keyUpCmd);

        CFRelease(keyDownCmd);
        CFRelease(keyDownQ);
        CFRelease(keyUpQ);
        CFRelease(keyUpCmd);

        // For some reason, this does not work, which is why we generate
        // the synthetic keyboard events above.
        // I could not find authoritative reasons why it doesn't work,
        // but others speculate that shortcuts associated with menu items
        // are different from hotkey events.
        return eventNotHandledErr;
    }
}

@end
