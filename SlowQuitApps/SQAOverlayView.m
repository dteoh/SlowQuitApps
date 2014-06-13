@import QuartzCore;
#import "SQAOverlayView.h"

@interface SQAOverlayView() {
@private
    CAShapeLayer *outerCircle;
}
@end

@implementation SQAOverlayView

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        CALayer *layer = [CALayer layer];
        self.wantsLayer = YES;
        self.layer = layer;

        outerCircle = makeOuterCircle(frameRect);
        [layer addSublayer:outerCircle];

        [self redraw];
    }
    return self;
}

CAShapeLayer * makeOuterCircle(CGRect frame) {
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.bounds = frame;
    layer.position = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    layer.path = CGPathCreateWithEllipseInRect(frame, NULL);
    layer.fillColor = NSColor.blackColor.CGColor;

    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.position = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    mask.bounds = frame;

    CGFloat thickness = 20;
    CGFloat diameter = CGRectGetWidth(frame) - thickness * 2;

    // This wizardry creates the circle cutout effect on the base layer.
    CGMutablePathRef circle = CGPathCreateMutableCopy(CGPathCreateWithEllipseInRect(
        CGRectMake(thickness, thickness, diameter, diameter), NULL));
    CGPathAddPath(circle, NULL, CGPathCreateWithRect(frame, NULL));
    mask.path = circle;
    mask.fillColor = [[NSColor colorWithDeviceWhite:1 alpha:0.7] CGColor];
    mask.fillRule = kCAFillRuleEvenOdd;

    layer.mask = mask;

    return layer;
}

- (void)redraw {
    [self.layer needsDisplay];
}

@end
