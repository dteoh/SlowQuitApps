@import Foundation;

@interface SQAPreferences : NSObject

+ (NSInteger)delay;
+ (NSArray<NSString *> *)whitelist;
+ (BOOL)invertList;
+ (BOOL)displayOverlay;
+ (BOOL)disableAutostart;

@end
