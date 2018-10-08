@import Foundation;

typedef void(^state_callback_t)(void);

NS_ASSUME_NONNULL_BEGIN

@interface SQAStateMachine : NSObject

@property (strong) state_callback_t onStart;
@property (strong) state_callback_t onHolding;
@property (strong) state_callback_t onCancelled;
@property (strong) state_callback_t onCompletion;

- (CGFloat)completionDurationInSeconds;

- (void)holding;
- (void)cancelled;

@end

NS_ASSUME_NONNULL_END
