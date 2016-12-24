@import QuartzCore;
#import "SQAOverlayView.h"

@interface SQAOverlayView() {
@private
    CAShapeLayer *outerCircle;
    CAShapeLayer *innerCircle;
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

        innerCircle = makeInnerCirle(smallerCenteredRect(frameRect, 21));
        innerCircle.strokeEnd = 0;
        [layer addSublayer:innerCircle];
    }
    return self;
}

- (BOOL)wantsUpdateLayer {
    return YES;
}

- (void)updateLayer {
    [innerCircle removeAllAnimations];

    CABasicAnimation *strokeAnim = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    strokeAnim.fromValue = [NSNumber numberWithFloat:0];
    strokeAnim.toValue = [NSNumber numberWithFloat:1];
    strokeAnim.duration = self.progressDuration;

    [innerCircle addAnimation:strokeAnim forKey:@"strokeAnim"];
}

- (void)reset {
    [innerCircle removeAllAnimations];
    innerCircle.strokeEnd = 0;
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

CAShapeLayer * makeOuterCircle(const CGRect frame) {
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.bounds = frame;
    layer.position = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));

    {
        CGPathRef circle = CGPathCreateWithEllipseInRect(frame, NULL);
        layer.path = circle;
        CFRelease(circle);
    }

    layer.fillColor = NSColor.blackColor.CGColor;

    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.position = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    mask.bounds = frame;

    CGFloat thickness = 20;
    CGFloat diameter = CGRectGetWidth(frame) - thickness * 2;

    // This wizardry creates the circle cutout effect on the base layer.
    {
        CGPathRef circle = CGPathCreateWithEllipseInRect(CGRectMake(thickness, thickness, diameter, diameter), NULL);
        CGPathRef framePath = CGPathCreateWithRect(frame, NULL);
        CGMutablePathRef mutCircle = CGPathCreateMutableCopy(circle);
        CGPathAddPath(mutCircle, NULL, framePath);

        mask.path = mutCircle;

        CFRelease(mutCircle);
        CFRelease(framePath);
        CFRelease(circle);
    }
    mask.fillColor = [[NSColor colorWithDeviceWhite:1 alpha:0.7] CGColor];
    mask.fillRule = kCAFillRuleEvenOdd;

    layer.mask = mask;

    return layer;
}

CAShapeLayer * makeInnerCirle(const CGRect frame) {
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.bounds = frame;
    layer.position = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));

    {
        CGPathRef circle = CGPathCreateWithEllipseInRect(frame, NULL);
        layer.path = circle;
        CFRelease(circle);
    }

    // We will be animating the stroke property
    layer.fillColor = NSColor.clearColor.CGColor;
    layer.strokeColor = NSColor.blackColor.CGColor;
    layer.lineWidth = CGRectGetWidth(frame);

    // These transformations make the stroke start at 12 o'clock and move
    // clockwise.
    CATransform3D flip = CATransform3DIdentity;
    flip.m22 = -1;
    CGAffineTransform rotate2d = CGAffineTransformMakeRotation(deg2Rad(90));
    CATransform3D rotate = CATransform3DMakeAffineTransform(rotate2d);
    layer.transform = CATransform3DConcat(flip, rotate);

    // If we don't use a mask, we just see a rectangle shape because of the
    // layer stroke
    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.position = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    mask.bounds = frame;
    {
        CGPathRef circle = CGPathCreateWithEllipseInRect(frame, NULL);
        mask.path = circle;
        CFRelease(circle);
    }
    mask.fillColor = [[NSColor colorWithDeviceWhite:1 alpha:0.7] CGColor];

    layer.mask = mask;

    return layer;
}

@end
