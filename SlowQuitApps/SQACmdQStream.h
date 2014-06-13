@import Foundation;

typedef void(^cmd_q_observer_t)(BOOL);

@interface SQACmdQStream : NSObject

@property (strong) cmd_q_observer_t observer;

- (void)open;
- (void)close;

@end
