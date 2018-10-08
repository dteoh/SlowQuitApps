@import Carbon;
#import "SQAAppDelegate.h"
#import "SQAQResolver.h"
#import "SQADialogs.h"
#import "SQAOverlayWindowController.h"
#import "SQAPreferences.h"
#import "SQAStateMachine.h"

@interface SQAAppDelegate() {
@private
    SQAStateMachine *stateMachine;
    id<SQAOverlayViewInterface> overlayView;
    CFMachPortRef eventTapPort;
    CFRunLoopSourceRef eventRunLoop;
}
@end

@implementation SQAAppDelegate

- (id)init {
    self = [super init];
    if (self) {
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

- (void)applicationWillTerminate:(NSNotification *)notification {
    if (eventTapPort) {
        CFRelease(eventTapPort);
    }
    if (eventRunLoop) {
        CFRelease(eventRunLoop);
    }
}

- (BOOL)registerGlobalHotkeyCG {
    CGEventMask eventMask = (1 << kCGEventFlagsChanged) | (1 << kCGEventKeyDown);
    CFMachPortRef port = CGEventTapCreate(kCGHIDEventTap,
                                          kCGHeadInsertEventTap,
                                          kCGEventTapOptionDefault, eventMask,
                                          &eventTapHandler, (__bridge void *)self);
    if (!port) {
        return false;
    }

    CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(port, true);
    CFRunLoopRun();

    eventTapPort = port;
    eventRunLoop = runLoopSource;

    return true;
}

- (void)cmdQPressed {
    if (stateMachine) {
        [stateMachine holding];
        return;
    }

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
        };
        stateMachine.onCancelled = ^{
            [weakOverlay hideOverlay];
            [weakOverlay resetOverlay];
        };
    } else {
        stateMachine.onCompletion = ^{
            NSRunningApplication *app = findActiveApp();
            if (app) {
                [app terminate];
            }
        };
    }

    [stateMachine holding];
}

- (void)cmdQNotPressed {
    if (stateMachine) {
        [stateMachine cancelled];
    }
    stateMachine = nil;
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
    UniChar unicodeString[4] = {0, 0, 0, 0};
    CGEventKeyboardGetUnicodeString(event, 1, &actualStringLength, unicodeString);
    return [NSString stringWithCharacters:unicodeString length:actualStringLength];
}

@end
