#import "SQAOverlayWindowController.h"
#import "SQAOverlayView.h"


@interface SQAOverlayWindowController () {
@private
    SQAOverlayView *overlayView;
    NSTextField *titleView;
}
@end

@implementation SQAOverlayWindowController

- (id)init {
    self = [super initWithWindowNibName:@"SQAOverlayWindow"];
    if (self) {
        // TODO refactor this.
        // 240 = 200 (actual width of bar) + 20 (padding) + (20 padding)
        // 20 is defined in the internals of SQAOverlayView.
        const NSRect overlayFrame = NSMakeRect(0, 0, 240, 240);
        overlayView = [[SQAOverlayView alloc] initWithFrame:overlayFrame];

        titleView = [NSTextField labelWithString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"];
        titleView.editable = NO;
        titleView.alignment = NSTextAlignmentCenter;
        titleView.font = [NSFont labelFontOfSize:18];
        titleView.textColor = NSColor.labelColor;
        [titleView sizeToFit];

        NSVisualEffectView *titleFxView = [[NSVisualEffectView alloc] init];
        titleFxView.wantsLayer = YES;
        titleFxView.layer.masksToBounds = YES;
        titleFxView.layer.cornerRadius = 2;
        titleFxView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        titleFxView.material = NSVisualEffectMaterialSheet;
        titleFxView.state = NSVisualEffectStateActive;

        [titleFxView addSubview:titleView];

        NSStackView *stackView = [NSStackView stackViewWithViews:@[overlayView, titleFxView]];
        stackView.orientation = NSLayoutConstraintOrientationVertical;
        stackView.alignment = NSLayoutAttributeCenterX;
        stackView.spacing = 0;

        [NSLayoutConstraint activateConstraints:@[
            [overlayView.widthAnchor constraintEqualToConstant:overlayFrame.size.width],
            [overlayView.heightAnchor constraintEqualToConstant:overlayFrame.size.height],

            // Add some horizontal padding to the text field.
            [titleFxView.widthAnchor constraintEqualToAnchor:titleView.widthAnchor constant:5],
            // Not padding vertically because there is no easy way to have vertically centered text...
            [titleFxView.heightAnchor constraintEqualToAnchor:titleView.heightAnchor],
        ]];

        NSPanel *panel = [[NSPanel alloc] initWithContentRect:stackView.frame
                                                    styleMask:NSWindowStyleMaskBorderless|NSWindowStyleMaskNonactivatingPanel
                                                      backing:NSBackingStoreBuffered
                                                        defer:YES];
        panel.opaque = NO;
        panel.backgroundColor = NSColor.clearColor;
        panel.level = NSScreenSaverWindowLevel;
        panel.contentView = stackView;

        self.window = panel;
    }
    return self;
}

#pragma mark - SQAOverlayViewInterface implementation

- (void)showOverlay:(CGFloat)duration withTitle:(NSString * _Nonnull)title {
    titleView.stringValue = title;
    [titleView sizeToFit];

    [self showWindow:nil];
    [self.window center];
    [self.window makeKeyAndOrderFront:self];

    overlayView.progressDuration = duration;
    [overlayView updateLayer];
}

- (void)hideOverlay {
    [self close];
}

- (void)resetOverlay {
    [overlayView reset];
}

@end
