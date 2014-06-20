@import Foundation;

@protocol SQAOverlayViewInterface <NSObject>

- (void)showOverlay;
- (void)hideOverlay;
- (void)resetOverlay;

// progress is a value between 0.0 and 1.0
- (void)setProgress:(CGFloat)progress;

@end
