#import "SQAThereCanBeOnlyOne.h"

@implementation SQAThereCanBeOnlyOne

- (void)iWin {
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleId = [info objectForKey:@"CFBundleIdentifier"];

    NSRunningApplication *me = [NSRunningApplication currentApplication];

    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
        if ([app.bundleIdentifier isEqualToString:bundleId]) {
            if (![app isEqual:me]) {
                [app terminate];
            }
        }
    }
}

@end
