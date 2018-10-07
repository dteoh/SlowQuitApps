@import Foundation;

@interface SQAPreferences : NSObject

+ (NSInteger)delay;
+ (BOOL)displayOverlay;
+ (NSArray<NSString *> *)whitelist;
+ (BOOL)invertList;

@end
