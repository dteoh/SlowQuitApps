#import "SQATerminator.h"
#import "SQAPreferences.h"

@interface SQATerminator() {
@private
    BOOL missionInProgress;
    CFTimeInterval start;
    CFTimeInterval lastUpdate;
    mission_complete_t missionComplete;
}
@end

@implementation SQATerminator

- (void)newMission:(mission_complete_t)block {
    start = lastUpdate = CACurrentMediaTime();
    missionInProgress = YES;
    missionComplete = block;
}

- (void)updateMission:(mission_report_t)block {
    lastUpdate = CACurrentMediaTime();

    block(self.progress);

    if (self.progress < 1) {
        return;
    }

    if ([self hastaLaVistaBaby]) {
        missionInProgress = NO;
        missionComplete();
    }
}

- (CGFloat)missionDurationInMilliseconds {
    return (CGFloat)[SQAPreferences delay];
}

- (CGFloat)missionDurationInSeconds {
    return self.missionDurationInMilliseconds / 1000.0;
}

- (CGFloat)progress {
    CFTimeInterval elapsed = (lastUpdate - start) * 1000;
    return elapsed / self.missionDurationInMilliseconds;
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
