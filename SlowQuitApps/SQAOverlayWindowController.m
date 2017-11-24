#import "SQAOverlayWindowController.h"
#import "SQAOverlayView.h"


@interface SQAOverlayWindowController () {
@private
    SQAOverlayView *overlayView;
}
@end

@implementation SQAOverlayWindowController

- (id)init {
    self = [super initWithWindowNibName:@"SQAOverlayWindow"];
    if (self) {
        NSRect contentRect = NSMakeRect(0, 0, 300, 300);
        NSPanel *panel = [[NSPanel alloc] initWithContentRect:contentRect
                                                    styleMask:NSBorderlessWindowMask|NSNonactivatingPanelMask
                                                      backing:NSBackingStoreBuffered
                                                        defer:YES];
        [panel setOpaque:NO];
        panel.backgroundColor = NSColor.clearColor;
        panel.level = NSScreenSaverWindowLevel;

        overlayView = [[SQAOverlayView alloc] initWithFrame:contentRect];
        panel.contentView = overlayView;

        self.window = panel;
    }
    return self;
}

#pragma mark - SQAOverlayViewInterface implementation

- (void)showOverlay:(CGFloat)duration {
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
