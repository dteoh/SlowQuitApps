#import "SQAPreferences.h"

@implementation SQAPreferences


+ (NSUserDefaults *)defaults {
    static BOOL defaultsRegistered;
    if (!defaultsRegistered) {
      NSDictionary *defaults = @{
                                 @"delay": @1000,
                                 @"whitelist": @[],
                                 @"invertList": @NO,
                                 @"displayOverlay": @YES,
                                 @"disableAutostart": @NO
                                 };
      [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
        defaultsRegistered = YES;
    }
    return [NSUserDefaults standardUserDefaults];
}

+ (BOOL)displayOverlay {
    static BOOL displayOverlay;
    if (!displayOverlay) {
        displayOverlay = [[self defaults] boolForKey:@"displayOverlay"];
    }
    return displayOverlay;
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

+ (BOOL)invertList {
    static BOOL invertList;
    if (!invertList) {
        invertList = [[self defaults] boolForKey:@"invertList"];
    }
    return invertList;
}

+ (BOOL)disableAutostart {
    static BOOL disableAutostart;
    if (!disableAutostart) {
        disableAutostart = [[self defaults] boolForKey:@"disableAutostart"];
    }
    return disableAutostart;
}

@end
