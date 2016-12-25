@import Foundation;

typedef void(^mission_complete_t)();
typedef void(^mission_report_t)(CGFloat);

@interface SQATerminator : NSObject

- (void)newMission:(mission_complete_t)block;
- (void)updateMission;
- (CGFloat)missionDurationInSeconds;

@end
