@import Foundation;

#import "SQAOverlayViewInterface.h"

@interface SQAOverlayPresenter : NSObject

@property (strong) id<SQAOverlayViewInterface> overlayView;

- (void)cmdQPressed;
- (void)cmdQHeldDown;
- (void)cmdQReleased;

@end
