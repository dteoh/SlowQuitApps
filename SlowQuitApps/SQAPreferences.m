#import "SQAPreferences.h"

@implementation SQAPreferences


+ (NSUserDefaults *)defaults {
    static BOOL defaultsRegistered;
    if (!defaultsRegistered) {
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"delay": @1000, @"whitelist": @[]}];
        defaultsRegistered = YES;
    }
    return [NSUserDefaults standardUserDefaults];
}

+ (NSInteger)delay {
    static NSInteger delay;
    if (delay == 0) {
        delay = [[self defaults] integerForKey:@"delay"];
        if (delay <= 0) {
            delay = 1000;
        }
    }
    return delay;
}

+ (NSArray<NSString *> *)whitelist {
    static NSArray<NSString *> *whitelist;
    if (whitelist == NULL) {
        whitelist = [[self defaults] stringArrayForKey:@"whitelist"];
    }
    return whitelist;
}


@end
