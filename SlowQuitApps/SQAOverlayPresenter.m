#import "SQAOverlayPresenter.h"

@interface SQAOverlayPresenter() {
@private
    CFTimeInterval start;
    CFTimeInterval stop;
}
@end

@implementation SQAOverlayPresenter

- (void)cmdQPressed {
    start = CACurrentMediaTime();
    [self.overlayView showOverlay];
}

- (void)cmdQHeldDown {
    const CFTimeInterval elapsed = (CACurrentMediaTime() - start) * 1000;
    [self.overlayView setProgress:elapsed / 1000.0];
    if (1000 <= elapsed) {
        [self terminateActiveApplication];
    }
}

- (void)cmdQReleased {
    [self.overlayView hideOverlay];
    [self.overlayView resetOverlay];
}

// TODO should this be here?
- (void)terminateActiveApplication {
    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
        if ([app isActive]) {
            [app terminate];
            return;
        }
    }
}

@end
