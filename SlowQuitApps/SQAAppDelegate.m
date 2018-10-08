@import Carbon;
#import "SQAAppDelegate.h"
#import "SQAQResolver.h"
#import "SQACmdQStream.h"
#import "SQADialogs.h"
#import "SQAOverlayWindowController.h"
#import "SQAPreferences.h"
#import "SQATerminator.h"
#import "SQAStateMachine.h"

@interface SQAAppDelegate() {
@private
    SQACmdQStream *stream;
    SQATerminator *terminator;
    SQAQResolver *qResolver;
    SQAStateMachine *stateMachine;
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

    if ([self registerGlobalHotkeyCG]) {
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

- (void)destroyStateMachine {
    stateMachine = nil;
}

- (void)cmdQPressed {
    if (stateMachine) {
        [stateMachine holding];
        return;
    }

    __weak typeof(self) weakSelf = self;
    stateMachine = [[SQAStateMachine alloc] init];
    __weak typeof(stateMachine) weakSM = stateMachine;

    __weak typeof(overlayView) weakOverlay = overlayView;

    if (overlayView) {
        stateMachine.onStart = ^{
            [weakOverlay showOverlay:weakSM.completionDurationInSeconds];
        };
        stateMachine.onCompletion = ^{
            NSRunningApplication *app = findActiveApp();
            if (app) {
                [app terminate];
            }
            [weakOverlay hideOverlay];
            [weakOverlay resetOverlay];
            [weakSelf destroyStateMachine];
        };
        stateMachine.onCancelled = ^{
            [weakOverlay hideOverlay];
            [weakOverlay resetOverlay];
            [weakSelf destroyStateMachine];
        };
    } else {
        stateMachine.onCompletion = ^{
            NSRunningApplication *app = findActiveApp();
            if (app) {
                [app terminate];
            }
            [weakSelf destroyStateMachine];
        };
        stateMachine.onCancelled = ^{
            [weakSelf destroyStateMachine];
        };
    }

    [stateMachine holding];
}

- (void)cmdQNotPressed {
    if (stateMachine) {
        [stateMachine cancelled];
    }
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
    BOOL q = [@"q" isEqualToString:stringFromCGKeyboardEvent(event)];
    if (!command || !q) {
        [delegate cmdQNotPressed];
        return event;
    }

    if (shouldHandleCmdQ()) {
        [delegate cmdQPressed];
        return NULL;
    }

    [delegate cmdQNotPressed];
    return event;
}

NSString * stringFromCGKeyboardEvent(CGEventRef event) {
    UniCharCount actualStringLength = 0;
    UniChar unicodeString[1];
    CGEventKeyboardGetUnicodeString(event, 1, &actualStringLength, unicodeString);
    return [NSString stringWithCharacters:unicodeString length:actualStringLength];
}

@end
