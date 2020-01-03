@import QuartzCore;
#import "SQAOverlayView.h"

@interface SQAOverlayView() {
@private
    CAShapeLayer *bar;
    CAShapeLayer *outline;
    CAShapeLayer *track;
}
@end

@implementation SQAOverlayView

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        CALayer *layer = [CALayer layer];
        self.wantsLayer = YES;
        self.layer = layer;

        // TODO this magic 20 should ideally be calculated from line widths, etc.
        CGRect chartRect = smallerCenteredRect(frameRect, 20);

        track = makeTemplate(chartRect);
        track.fillColor = NSColor.clearColor.CGColor;
        track.strokeColor = [[NSColor colorWithRed:0.11 green:0.11 blue:0.11 alpha:0.8] CGColor];
        track.lineWidth = 30;
        [layer addSublayer:track];

        outline = makeTemplate(chartRect);
        outline.fillColor = NSColor.clearColor.CGColor;
        outline.strokeColor = NSColor.controlAccentColor.CGColor;
        outline.lineWidth = 30;
        outline.lineCap = @"round";
        outline.strokeEnd = 0;
        [layer addSublayer:outline];

        bar = makeTemplate(chartRect);
        bar.fillColor = NSColor.clearColor.CGColor;
        bar.strokeColor = [[NSColor colorWithRed:0.04 green:0.04 blue:0.04 alpha:1] CGColor];
        bar.lineWidth = 27;
        bar.lineCap = @"round";
        bar.strokeEnd = 0;
        [layer addSublayer:bar];
    }
    return self;
}

- (BOOL)wantsUpdateLayer {
    return YES;
}

- (void)updateLayer {
    [outline removeAllAnimations];
    [bar removeAllAnimations];

    CABasicAnimation *strokeAnim = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    strokeAnim.fromValue = [NSNumber numberWithFloat:0];
    strokeAnim.toValue = [NSNumber numberWithFloat:1];
    strokeAnim.duration = self.progressDuration;

    strokeAnim.fillMode = kCAFillModeForwards;
    strokeAnim.removedOnCompletion = NO;

    [outline addAnimation:strokeAnim forKey:@"strokeAnim"];
    [bar addAnimation:strokeAnim forKey:@"strokeAnim"];
}

- (void)reset {
    [bar removeAllAnimations];
    bar.strokeEnd = 0;
}

#pragma mark - Helpers

CGFloat deg2Rad(const CGFloat deg) {
    return deg * M_PI / 180;
}

CGRect smallerCenteredRect(const CGRect rect, const CGFloat pixels) {
    return CGRectMake(CGRectGetMinX(rect) + pixels,
                      CGRectGetMinY(rect) + pixels,
                      CGRectGetWidth(rect) - (pixels * 2),
                      CGRectGetHeight(rect) - (pixels * 2));
}

CAShapeLayer * makeTemplate(const CGRect frame) {
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.bounds = frame;
    layer.position = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));

    {
        CGPathRef circle = CGPathCreateWithEllipseInRect(frame, NULL);
        layer.path = circle;
        CFRelease(circle);
    }

    // These transformations make the stroke start at 12 o'clock and move
    // clockwise.
    CATransform3D flip = CATransform3DIdentity;
    flip.m22 = -1;
    CGAffineTransform rotate2d = CGAffineTransformMakeRotation(deg2Rad(90));
    CATransform3D rotate = CATransform3DMakeAffineTransform(rotate2d);
    layer.transform = CATransform3DConcat(flip, rotate);

    return layer;
}

@end
