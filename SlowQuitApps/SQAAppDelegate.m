@import Carbon;
#import "SQAAppDelegate.h"
#import "SQACmdQStream.h"
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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
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

- (void)cmdQPressed
{
    [terminator newMission];
    __weak typeof(terminator) weakTerminator = terminator;

    [overlayView showOverlay];
    __weak typeof (overlayView) weakOverlay = overlayView;

    terminator.missionComplete = ^{
        [weakOverlay hideOverlay];
        [weakOverlay resetOverlay];
    };

    stream = [[SQACmdQStream alloc] init];
    __weak typeof(stream) weakStream = stream;

    stream.observer = ^(BOOL pressed) {
        if (pressed) {
            [weakTerminator updateMission];
            [weakOverlay setProgress:weakTerminator.progress];
        } else {
            [weakOverlay hideOverlay];
            [weakOverlay resetOverlay];
            [weakStream close];
        }
    };
    [stream open];
}


OSStatus cmdQHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData) {
    SQAAppDelegate *delegate = (__bridge SQAAppDelegate *)userData;
    [delegate cmdQPressed];
    return noErr;
}

@end
