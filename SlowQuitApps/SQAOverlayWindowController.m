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
        [panel center];
        panel.backgroundColor = NSColor.clearColor;
        panel.level = NSScreenSaverWindowLevel;

        overlayView = [[SQAOverlayView alloc] initWithFrame:contentRect];
        panel.contentView = overlayView;

        self.window = panel;
    }
    return self;
}

#pragma - SQAOverlayViewInterface implementation

- (void)showOverlay {
    [self showWindow:nil];
}

- (void)hideOverlay {
    [self close];
}

- (void)resetOverlay {
    [overlayView resetProgress];
}

- (void)setProgress:(CGFloat)progress {
    overlayView.progress = progress;
    [overlayView updateLayer];
}

@end
