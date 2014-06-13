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
}

- (void)cmdQHeldDown {
    if (1000 <= ((CACurrentMediaTime() - start) * 1000)) {
        [self terminateActiveApplication];
    }
}

- (void)cmdQReleased {
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
