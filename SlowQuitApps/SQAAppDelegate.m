@import Carbon;
#import "SQAAppDelegate.h"
#import "SQACmdQStream.h"
#import "SQALoginItem.h"
#import "SQAOverlayWindowController.h"
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
    [self registerGlobalHotkey];

    SQALoginItem *loginItem = [[SQALoginItem alloc] init];
    [loginItem askAboutAutoStart];

    // Hide from dock, command tab, etc.
    // Not using LSBackgroundOnly so that we can display NSAlerts beforehand
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
}

- (void)registerGlobalHotkey {
    EventHotKeyRef hotKeyRef;
    EventHotKeyID hotKeyID;
    EventTypeSpec eventType;
    eventType.eventClass = kEventClassKeyboard;
    eventType.eventKind = kEventHotKeyPressed;

    InstallApplicationEventHandler(&cmdQHandler, 1, &eventType, (__bridge void *)self, NULL);
    hotKeyID.signature = 'sqad';
    hotKeyID.id = 1;

    RegisterEventHotKey(kVK_ANSI_Q, cmdKey, hotKeyID, GetApplicationEventTarget(),
                        kEventHotKeyExclusive, &hotKeyRef);
}

- (void)cmdQPressed {
    __weak typeof (overlayView) weakOverlay = overlayView;

    [terminator newMission:^{
        [weakOverlay hideOverlay];
        [weakOverlay resetOverlay];
    }];
    [overlayView showOverlay:terminator.missionDurationInSeconds];

    stream = [[SQACmdQStream alloc] init];
    __weak typeof(stream) weakStream = stream;

    stream.observer = ^(BOOL pressed) {
        if (!pressed) {
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
    return YES;
}

OSStatus cmdQHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData) {
    if (shouldHandleCmdQ()) {
        SQAAppDelegate *delegate = (__bridge SQAAppDelegate *)userData;
        [delegate cmdQPressed];
    }
    return noErr;
}

@end
