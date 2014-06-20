@import Foundation;

typedef void(^mission_complete_t)();

@interface SQATerminator : NSObject

@property (strong) mission_complete_t missionComplete;

- (void)newMission;
- (void)updateMission;

- (CGFloat)progress;

@end
