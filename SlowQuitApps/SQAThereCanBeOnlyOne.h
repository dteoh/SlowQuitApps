@import Foundation;

typedef void(^victory_celebration_t)(void);

@interface SQAThereCanBeOnlyOne : NSObject

- (id)initWithCelebration:(victory_celebration_t)block;
- (void)iWin;

@end
