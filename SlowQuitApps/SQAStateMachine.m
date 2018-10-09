#import "SQAStateMachine.h"
#import "SQAPreferences.h"

typedef NS_ENUM(NSInteger, SQAMachineState) {
    SQAStateMachineInitialized,
    SQAStateMachineHolding,
    SQAStateMachineCompleted,
    SQAStateMachineCancelled
};

@interface SQAStateMachine() {
@private
    SQAMachineState currentState;
    CFTimeInterval start;
    CFTimeInterval lastUpdate;
}
@end

@implementation SQAStateMachine
@synthesize onStart;
@synthesize onHolding;
@synthesize onCancelled;
@synthesize onCompletion;

- (id)init {
    self = [super init];
    if (!self) return self;

    currentState = SQAStateMachineInitialized;

    return self;
}

- (void)holding {
    switch (currentState) {
        case SQAStateMachineInitialized:
            start = lastUpdate = CACurrentMediaTime();
            currentState = SQAStateMachineHolding;
            if (onStart) {
                onStart();
            }
            break;
        case SQAStateMachineHolding:
            lastUpdate = CACurrentMediaTime();
            if (onHolding) {
                onHolding();
            }
            if (self.progress < 1) {
                return;
            }
            currentState = SQAStateMachineCompleted;
            if (onCompletion) {
                onCompletion();
            }
            break;
        default:
            break;
    }
}

- (void)cancelled {
    if (currentState == SQAStateMachineCancelled) {
        return;
    }
    currentState = SQAStateMachineCancelled;
    if (onCancelled) {
        onCancelled();
    }
}

- (CGFloat)completionDurationInMilliseconds {
    return (CGFloat)[SQAPreferences delay];
}

- (CGFloat)completionDurationInSeconds {
    return self.completionDurationInMilliseconds / 1000.0;
}

- (CGFloat)progress {
    CFTimeInterval elapsed = (lastUpdate - start) * 1000;
    return elapsed / self.completionDurationInMilliseconds;
}

@end
