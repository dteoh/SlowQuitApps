#import "SQAThereCanBeOnlyOne.h"

@interface SQAThereCanBeOnlyOne() {
@private
    BOOL victoryAchieved;
    victory_celebration_t celebration;
}
@end

@implementation SQAThereCanBeOnlyOne

- (id)initWithCelebration:(victory_celebration_t)block {
    if (self = [super init]) {
        victoryAchieved = NO;
        celebration = block;
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(appTerminated:)
                                                   name:@"OtherSQATerminated"
                                                 object:nil];
        [NSWorkspace.sharedWorkspace.notificationCenter addObserver:self
                                                           selector:@selector(appTerminated:)
                                                               name:NSWorkspaceDidTerminateApplicationNotification
                                                             object:nil];
    }
    return self;
}

- (void)iWin {
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleId = [info objectForKey:@"CFBundleIdentifier"];
    NSRunningApplication *me = [NSRunningApplication currentApplication];

    for (NSRunningApplication *app in NSWorkspace.sharedWorkspace.runningApplications) {
        if (![app.bundleIdentifier isEqualToString:bundleId]) {
            continue;
        }
        if ([app isEqual:me]) {
            continue;
        }
        [app terminate];
    }

    [NSNotificationCenter.defaultCenter postNotificationName:@"OtherSQATerminated"
                                                      object:nil];
}

- (void)appTerminated:(NSNotification *)note {
    if (victoryAchieved) {
        return;
    }
    if (otherSQARunning()) {
        return;
    }
    victoryAchieved = YES;
    celebration();
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [NSWorkspace.sharedWorkspace.notificationCenter removeObserver:self];
}

BOOL otherSQARunning() {
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleId = [info objectForKey:@"CFBundleIdentifier"];
    NSRunningApplication *me = [NSRunningApplication currentApplication];

    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
        if (![app.bundleIdentifier isEqualToString:bundleId]) {
            continue;
        }
        if ([app isEqual:me]) {
            continue;
        }
        return YES;
    }
    return NO;
}

@end
