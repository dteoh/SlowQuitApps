@import Foundation;

typedef void(^mission_complete_t)();
typedef void(^mission_report_t)(CGFloat);

@interface SQATerminator : NSObject

- (void)newMission:(mission_complete_t)block;
- (void)updateMission:(mission_report_t)block;
- (CGFloat)missionDurationInSeconds;

@end
