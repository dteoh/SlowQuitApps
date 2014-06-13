@import Carbon;
#import "SQAAppDelegate.h"
#import "SQACmdQStream.h"

@interface SQAAppDelegate() {
@private
    SQACmdQStream *stream;
}
@end

@implementation SQAAppDelegate

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
    NSLog(@"Cmd-Q pressed");
    stream = [[SQACmdQStream alloc] init];
    __weak typeof(stream) weakStream = stream;
    stream.observer = ^(BOOL pressed) {
        if (pressed) {
            NSLog(@"Still pressed");
        } else {
            NSLog(@"Not pressed");
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
