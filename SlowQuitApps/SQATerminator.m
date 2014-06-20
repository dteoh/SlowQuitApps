#import "SQATerminator.h"

@interface SQATerminator() {
@private
    BOOL missionInProgress;
    CFTimeInterval start;
    CFTimeInterval lastUpdate;
}
@end

@implementation SQATerminator

- (void)newMission {
    start = lastUpdate = CACurrentMediaTime();
    missionInProgress = YES;
}

- (void)updateMission {
    lastUpdate = CACurrentMediaTime();
    if (self.progress < 1) {
        return;
    }
    if ([self hastaLaVistaBaby]) {
        missionInProgress = NO;
        self.missionComplete();
    }
}

- (CGFloat)progress {
    CFTimeInterval elapsed = (lastUpdate - start) * 1000;
    return elapsed / 1000.0F;
}

- (BOOL)hastaLaVistaBaby {
    if (!missionInProgress) {
        return NO;
    }
    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
        if ([app isActive]) {
            [app terminate];
            return YES;
        }
    }
    return NO;
}

@end
