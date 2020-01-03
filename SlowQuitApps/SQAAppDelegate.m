@import Carbon;
#import "SQAAppDelegate.h"
#import "SQADialogs.h"
#import "SQAOverlayWindowController.h"
#import "SQAPreferences.h"
#import "SQAStateMachine.h"
#import "SQAAutostart.h"

@interface SQAAppDelegate() {
@private
    SQAStateMachine *stateMachine;
    id<SQAOverlayViewInterface> overlayView;
    CFMachPortRef eventTapPort;
    CFRunLoopSourceRef eventRunLoop;
    CGEventSourceRef appEventSource;
    BOOL appSwitcherActive;
}
@end

@implementation SQAAppDelegate

- (id)init {
    self = [super init];
    if (!self) { return self; }

    if ([SQAPreferences displayOverlay]) {
        overlayView = [[SQAOverlayWindowController alloc] init];
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

    if ([SQAPreferences disableAutostart]) {
        [SQAAutostart disable];
    } else if (![SQAAutostart isEnabled]) {
        [dialogs askAboutAutoStart];
    }

    if ([self registerGlobalHotkeyCG]) {
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
    if (appEventSource) {
        CFRelease(appEventSource);
    }
}

- (BOOL)registerGlobalHotkeyCG {
    CGEventMask eventMask = CGEventMaskBit(kCGEventFlagsChanged) | CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp);
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
    appEventSource = CGEventSourceCreate(kCGEventSourceStatePrivate);

    return true;
}

- (void)cmdQPressed {
    if (stateMachine) {
        [stateMachine holding];
        return;
    }

    stateMachine = [[SQAStateMachine alloc] initWithEventSource:appEventSource];
    __weak typeof(stateMachine) weakSM = stateMachine;
    __weak typeof(overlayView) weakOverlay = overlayView;
    __weak typeof(self) weakSelf = self;

    if (overlayView) {
        stateMachine.onStart = ^{
            NSString *appTitle = @"";
            NSRunningApplication *app = findActiveApp();
            if (app) {
                appTitle = [app localizedName];
            }
            [weakOverlay showOverlay:weakSM.completionDurationInSeconds
                           withTitle:appTitle];
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
            [weakSelf destroyStateMachine];
        };
    } else {
        stateMachine.onCompletion = ^{
            NSRunningApplication *app = findActiveApp();
            if (app) {
                [app terminate];
            }
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
    [self destroyStateMachine];
}

- (void)appSwitcherOpened {
    appSwitcherActive = YES;
}

- (void)appSwitcherClosed {
    appSwitcherActive = NO;
}

- (void)destroyStateMachine {
    stateMachine = nil;
}

- (CGEventSourceRef)appEventSource {
    return appEventSource;
}

- (BOOL)shouldHandleCmdQ {
    if (appSwitcherActive) {
        return NO;
    }

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

NSRunningApplication* findActiveApp() {
    return [[NSWorkspace sharedWorkspace] menuBarOwningApplication];
}

BOOL hasAccessibility() {
#if defined(DEBUG)
    return YES;
#else
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    return AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
#endif
}

CGEventRef eventTapHandler(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *userInfo) {
    if (type != kCGEventFlagsChanged && type != kCGEventKeyDown && type != kCGEventKeyUp) {
        return event;
    }
    SQAAppDelegate *delegate = (__bridge SQAAppDelegate *)userInfo;

    NSString *stringedKey = stringFromCGKeyboardEvent(event);

    BOOL command = (CGEventGetFlags(event) & kCGEventFlagMaskCommand) == kCGEventFlagMaskCommand;
    BOOL q = [@"q" isEqualToString:stringedKey];
    BOOL tab = [@"\t" isEqualToString:stringedKey];

    // Cannot override App Switcher functionality, so try to detect when it
    // is activated. Ideally the framework would give us a cleaner way to query
    // for this, but alas...
    if (command && tab) {
        [delegate appSwitcherOpened];
    } else if (!command && !tab) {
        [delegate appSwitcherClosed];
    }

    if (!command || !q) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate cmdQNotPressed];
        });
        return event;
    }

    if ([delegate shouldHandleCmdQ]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate cmdQPressed];
        });

        CGEventSetFlags(event, 0);
        CGEventSetIntegerValueField(event, kCGKeyboardEventKeycode, kVK_Command);
        CGEventSetIntegerValueField(event, kCGEventSourceStateID, CGEventSourceGetSourceStateID([delegate appEventSource]));
        return event;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [delegate cmdQNotPressed];
    });
    return event;
}

NSString * stringFromCGKeyboardEvent(CGEventRef event) {
    UniCharCount actualStringLength = 0;
    UniChar unicodeString[4] = {0, 0, 0, 0};
    CGEventKeyboardGetUnicodeString(event, 1, &actualStringLength, unicodeString);
    return [NSString stringWithCharacters:unicodeString length:actualStringLength];
}

@end
