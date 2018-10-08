@import Carbon;
#import "SQAAppDelegate.h"
#import "SQAQResolver.h"
#import "SQACmdQStream.h"
#import "SQADialogs.h"
#import "SQAOverlayWindowController.h"
#import "SQAPreferences.h"
#import "SQATerminator.h"

@interface SQAAppDelegate() {
@private
    SQACmdQStream *stream;
    SQATerminator *terminator;
    SQAQResolver *qResolver;
    id<SQAOverlayViewInterface> overlayView;
}
@end

@implementation SQAAppDelegate

- (id)init {
    self = [super init];
    if (self) {
        terminator = [[SQATerminator alloc] init];
        qResolver = [[SQAQResolver alloc] init];
        if ([SQAPreferences displayOverlay]) {
            overlayView = [[SQAOverlayWindowController alloc] init];
        }
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    SQADialogs *dialogs = [[SQADialogs alloc] init];

    if (!hasAccessibility()) {
        [dialogs informAccessibilityRequirement];
        // If we terminate now, the special accesibility alert/dialog
        // from the framework/OS will dissappear immediately.
        return;
    }

    if ([self registerGlobalHotkey] && [self registerGlobalHotkeyCG]) {
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

    OSStatus result = RegisterEventHotKey(qResolver.keyCode, cmdKey, hotKeyID, GetApplicationEventTarget(),
                        kEventHotKeyExclusive, &hotKeyRef);
    return result != eventHotKeyExistsErr;
}

- (BOOL)registerGlobalHotkeyCG {
    // TODO properly release when application quits.
    CGEventMask eventMask = (1 << kCGEventFlagsChanged) | (1 << kCGEventKeyDown);
    CFMachPortRef eventTapPort = CGEventTapCreate(kCGHIDEventTap,
                                                  kCGHeadInsertEventTap,
                                                  kCGEventTapOptionDefault, eventMask,
                                                  &eventTapHandler, (__bridge void *)self);
    if (!eventTapPort) {
        return false;
    }

    CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTapPort, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(eventTapPort, true);
    CFRunLoopRun();
    return true;
}

- (void)cmdQPressed {
    __weak typeof(terminator) weakTerminator = terminator;

    void (^hideOverlay)(void) = NULL;
    if (overlayView) {
        __weak typeof(overlayView) weakOverlay = overlayView;
        hideOverlay = ^{
            [weakOverlay hideOverlay];
            [weakOverlay resetOverlay];
        };
    } else {
        hideOverlay = ^{}; // NOOP
    }

    [terminator newMission:hideOverlay];
    if (overlayView) {
        [overlayView showOverlay:terminator.missionDurationInSeconds];
    }

    stream = [[SQACmdQStream alloc] initWithQResolver:qResolver];
    __weak typeof(stream) weakStream = stream;

    stream.observer = ^(BOOL pressed) {
        if (pressed) {
            [weakTerminator updateMission];
        } else {
            hideOverlay();
            [weakStream close];
        }
    };
    [stream open];
}

- (CGKeyCode)qKeyCode {
    return [qResolver keyCode];
}

NSRunningApplication* findActiveApp() {
    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
        if ([app isActive]) {
            return app;
        }
    }
    return NULL;
}

BOOL hasAccessibility() {
#if defined(DEBUG)
    return YES;
#else
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    return AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
#endif
}

BOOL shouldHandleCmdQ() {
    NSRunningApplication *activeApp = findActiveApp();
    if (activeApp == NULL) {
        return NO;
    }
    if ([activeApp.bundleIdentifier isEqualToString:@"com.apple.finder"]) {
        return NO;
    }

    BOOL invertList = [SQAPreferences invertList];
    for (NSString *bundleId in [SQAPreferences whitelist]) {
        if ([activeApp.bundleIdentifier isEqualToString:bundleId]) {
            return (invertList ? YES : NO);
        }
    }
    return (invertList ? NO : YES);
}

OSStatus cmdQHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData) {
    SQAAppDelegate *delegate = (__bridge SQAAppDelegate *)userData;

    if (shouldHandleCmdQ()) {
        [delegate cmdQPressed];
        return noErr;
    } else {
        CGEventRef keyDownCmd, keyDownQ, keyUpQ, keyUpCmd;
        keyDownCmd = CGEventCreateKeyboardEvent(NULL, kVK_Command, true);
        keyDownQ = CGEventCreateKeyboardEvent(NULL, [delegate qKeyCode], true);
        keyUpQ = CGEventCreateKeyboardEvent(NULL, [delegate qKeyCode], false);
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

CGEventRef eventTapHandler(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *userInfo) {
    if (type != kCGEventFlagsChanged && type != kCGEventKeyDown) {
        return event;
    }

    SQAAppDelegate *delegate = (__bridge SQAAppDelegate *)userInfo;
    BOOL command = (CGEventGetFlags(event) & kCGEventFlagMaskCommand) > 0;

    UniCharCount actualStringLength = 0;
    UniChar unicodeString[1];
    CGEventKeyboardGetUnicodeString(event, 1, &actualStringLength, unicodeString);
    NSString *key = [NSString stringWithCharacters:unicodeString length:actualStringLength];

    NSLog(@"command=%hhd key=%@", command, key);

    return event;
}

@end
