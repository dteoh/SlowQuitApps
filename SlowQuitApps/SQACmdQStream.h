@import Foundation;
#import "SQAQResolver.h"

typedef void(^cmd_q_observer_t)(BOOL);

@interface SQACmdQStream : NSObject

@property (strong) cmd_q_observer_t observer;

- (instancetype)initWithQResolver:(SQAQResolver *)resolver;
- (void)open;
- (void)close;

@end
