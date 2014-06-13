#import "SQAOverlayWindowController.h"
#import "SQAOverlayView.h"


@interface SQAOverlayWindowController ()
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
        panel.contentView = [[SQAOverlayView alloc] initWithFrame:contentRect];
        panel.level = NSScreenSaverWindowLevel;
        [panel center];
        self.window = panel;
    }
    return self;
}



@end
