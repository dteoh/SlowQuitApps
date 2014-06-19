@import Carbon;
#import "SQAAppDelegate.h"
#import "SQACmdQStream.h"
#import "SQAOverlayPresenter.h"
#import "SQAOverlayWindowController.h"


@interface SQAAppDelegate() {
@private
    SQACmdQStream *stream;
    SQAOverlayPresenter *presenter;
    SQAOverlayWindowController *overlayWindow;
}
@end

@implementation SQAAppDelegate

- (id)init {
    self = [super init];
    if (self) {
        presenter = [[SQAOverlayPresenter alloc] init];
        overlayWindow = [[SQAOverlayWindowController alloc] init];
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [overlayWindow showWindow:nil];

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
    [presenter cmdQPressed];
    __weak typeof(presenter) weakPresenter = presenter;

    stream = [[SQACmdQStream alloc] init];
    __weak typeof(stream) weakStream = stream;

    stream.observer = ^(BOOL pressed) {
        if (pressed) {
            [weakPresenter cmdQHeldDown];
        } else {
            [weakPresenter cmdQReleased];
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
